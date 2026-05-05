from datetime import datetime,timedelta
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr
from fastapi import Depends, FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select
from supabase import create_client, Client
from face_service import face_service_instance
import os
from datetime import datetime
import numpy as np
from dotenv import load_dotenv
from creat_leacture import router as session_router
from database import get_session_dep, create_db_and_tables
from models import(
    AttendanceRecord,
    Course,
    Enrollment,
    Faculty,
    Student,
    User,
    LectureSession,
    Notification,
    Report,
    CourseFacultyLink,
    FaceTemplate,
)
from schedule_service import process_course_schedule_manual
from Rigeaster_face_biomatric import register_face_biometric
from login import LoginRequest, perform_login


# Database and Supabase Configuration
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL") 
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# Root

app = FastAPI(
    title="IAttend API",
    version="1.0.0",
    description="Face Biometric + Course, Enrollment, Session, Attendance, Report, Notification API"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],  
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

app.include_router(session_router)


# Health Check

@app.get("/")
async def root():
    return {
        "status": "running",
        "message": "IAttend API is active",
        "endpoints": 
        {
            "register_face": "POST /register-face",
            "create_course": "POST /create-course",
            "enroll_student": "POST /enroll-student",
            "submit_manual_schedule": "POST /submit-manual-schedule",
            "create_session": "POST /create-session-full",
            "edit_session": "PUT /edit-session/{session_id}",
            "mark_attendance": "POST /mark-attendance",
            "attendance_report": "GET /attendance-report/{session_id}",
            "generate_report": "POST /generate-report",
            "send_notification": "POST /send-notification"
        }
    }


# Request body schemas (API input)

class CreateAccount(BaseModel):
    username:str 
    name:str
    email: EmailStr
    password: str

class LoginRequest(BaseModel):
    user_id: str
    password: str


class CreateCourseRequest(BaseModel):
    faculty_id: int
    name: str


class EnrollStudentRequest(BaseModel):
    student_id: int
    course_id: int

class UpdateSessionStatusRequest(BaseModel):
    status: str

class CreateSessionRequest(BaseModel):
    course_id: int
    session_name: str 
    start_time: datetime
    end_time: datetime
    status: str = "pending"


class MarkAttendanceRequest(BaseModel):
    session_id: str
    student_id: int
    status: str = "Present"


class GenerateReportRequest(BaseModel):
    course_id: int
    session_id: Optional[int] = None
    format: Optional[str] = None
    file_path: Optional[str] = None


class SendNotificationRequest(BaseModel):
    recipient_id: str
    message: str

class ManualCourseEntry(BaseModel):
    code: str
    name: str
    section: str


class ManualScheduleRequest(BaseModel):
    user_id: str
    courses: List[ManualCourseEntry]

class CourseFacultyLink(BaseModel):
    course_id: int
    faculty_id: int

class EditSessionRequest(BaseModel):
    session_name: str
    location_enabled: bool
    latitude: float | None = None
    longitude: float | None = None
    session_type: str

class LiveAttendanceStudent(BaseModel):
    student_id: int
    user_id: str
    academic_id: int | None = None
    name: str
    status: str
    check_in_time: str | None = None

class AttendanceUpdate(BaseModel):
    student_id: int
    session_id: str
    status: str

#LOGIN
@app.post("/login", tags=["Authentication"])
async def login_endpoint(request: LoginRequest):
    return await perform_login(request, supabase)

    

# Face Biometric Registration
@app.post("/register-face", tags=["Face Biometric"])
async def register_face_endpoint(
    user_id: str = Form(..., description="The student's unique ID"),
    image_file: UploadFile = File(..., description="Image file (PNG, JPG, JPEG)")
):
   return await register_face_biometric(user_id, image_file)


    

#  Academic    
@app.post("/submit-manual-schedule", tags=["Academic"])
async def submit_manual_schedule(body: ManualScheduleRequest, session: Session = Depends(get_session_dep)):
    
    try:
        courses_list = [c.dict() for c in body.courses]
        return process_course_schedule_manual(session, body.user_id, courses_list)
    
    except Exception as e:
        session.rollback()
        print(f"Error in Schedule: {e}")
        return {"status": "Error", "message": "Someting Went Wrong"}

#scheule feching
@app.get("/my-schedule/{user_id}", tags=["Academic"])
async def get_user_schedule(user_id: str, session: Session = Depends(get_session_dep)):
    try:
        if "-" in user_id:
            user_stmt = select(User).where(User.user_id == user_id)
        else:
            user_stmt = select(User).where(User.academic_id == int(user_id))
            
        user = session.exec(user_stmt).first()
        if not user:
            return {"status": "error", "message": "User not found"}

        user_type = user.user_type.lower()
        courses_list = []

        if user_type == "student":
            
            stmt = (
                select(Course)
                .join(Enrollment, Enrollment.course_id == Course.course_id)
                .join(Student, Student.student_id == Enrollment.student_id)
                .where(Student.user_id == user.user_id))
            courses_list = session.exec(stmt).all()

        elif user_type == "faculty":
            faculty_stmt = select(Faculty).where(Faculty.user_id == user.user_id)
            faculty = session.exec(faculty_stmt).first()
            if faculty:   
                courses_list = faculty.courses 
            else:
                return {"status": "error", "message": "Faculty record not found"}
            
        res_data = {
            "status": "success",
            "user_type": user_type,
            "schedule": [
                {
                    "course_id": c.course_id,
                    "name": c.name,
                    "code": c.code,
                    "section": c.section
                } for c in courses_list
            ]
        }
        return res_data
    
    except Exception as e:
        print(f"DEBUG ERROR: {str(e)}")
        return {"status": "error", "message": f"Server error: {str(e)}"}
    

# get Session 
@app.get("/get-sessions/{course_id}", tags=["Session Management"])
async def get_sessions(course_id: int):
    try:
        response = supabase.table("session").select("*").eq("course_id", course_id).order("created_at", desc=True).execute()
        return {
            "status": "success",
            "message": "Attendance Session Started Successfully!",
            "data": response.data
        }
    except Exception as e:
        return {
            "status": "Error", 
            "message": str(e)
        }

# Get session Location
@app.get("/get-session-location/{session_id}", tags=["Attendance Tracking"])
async def get_session_location(session_id: str):
    
    try:
        response = supabase.table("session").select("latitude, longitude").eq("session_id", session_id).execute()
        if not response.data:
            return {"status": "error","message": "Session Not Found"}

        session_info = response.data[0]
        return {"status": "success","latitude": session_info.get("latitude"),"longitude": session_info.get("longitude")}
    
    except Exception as e:
        print(f"Location Fetch Error: {e}")
        return {"status": "error","message":"Internal Server Error"}
    

# Update Session Status
@app.post("/update-session-status/{session_id}", tags=["Session Management"])
async def update_session_status(session_id: str, body: UpdateSessionStatusRequest):
    try:
        response = supabase.table("session").update({"status": body.status}).eq("session_id", session_id).execute()
        
        print(f"Update Result for {session_id}: {response.data}")
        return {
            "status": "success",
            "message": f"Session status updated to {body.status}",
            "data": response.data
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }


# Edit Session Settings 
@app.put("/edit-session/{session_id}", tags=["Session Management"])
async def edit_session(session_id: str, body: EditSessionRequest):
    try:
        update_data = {
            "session_name": body.session_name,
            "session_type": body.session_type,
            "latitude": body.latitude if body.location_enabled else None,
            "longitude": body.longitude if body.location_enabled else None,
        }

        response = supabase.table("session").update(update_data).eq("session_id", session_id).execute()

        if not response.data:
            return {"status": "error", "message": "Session not found"}

        return {
            "status": "success",
            "message": "Session settings updated successfully!",
            "data": response.data
        }
    except Exception as e:
        print(f"DEBUG ERROR: {str(e)}")
        return {"status": "error", "message": str(e)}

#  Ragestier Attendance 
@app.post("/mark-attendance", tags=["Attendance Tracking"])
async def mark_attendance(
    session_id: str = Form(...),
    student_id: str = Form(...), 
    image_file: UploadFile = File(...),
    db_session: Session = Depends(get_session_dep)
):
    try:
        image_bytes = await image_file.read()
        captured_embedding, msg = face_service_instance.extract_face_vector(image_bytes)
        
        if captured_embedding is None:
            return {"status": "error", "message": f"Face Not Recognized  {msg}"}

        student_stmt = select(Student).where(Student.user_id == student_id)
        student = db_session.exec(student_stmt).first()

        if not student:
            return {"status": "error", "message": "Student is Not reigsterd in The System"}

        face_stmt = select(FaceTemplate).where(FaceTemplate.student_id == student.student_id)
        face_record = db_session.exec(face_stmt).first()

        if not face_record or not face_record.face_data:
            return {"status": "error", "message":"There is No Recorded Face Data "}

        
        try:
            saved_embedding = face_record.face_data
            if isinstance(saved_embedding, str):
                import json
                saved_embedding = json.loads(saved_embedding)
                
            saved_embedding = np.array(saved_embedding)
        except Exception as e:
            print(f"Embedding Conversion Error: {e}")
            return {"status": "error", "message": "Error In Reading Face Data"}

        is_match, score = face_service_instance.verify_attendance(captured_embedding, saved_embedding)

        if is_match:
            record = AttendanceRecord(
                session_id=session_id,
                student_id=student.student_id,
                status="Present",
                timestamp=datetime.utcnow()
            )
            db_session.add(record)
            db_session.commit()
            
            return {
                "status": "success", 
                "message": "Identity Verified And Attendance is Recorded",
                "similarity": f"{score:.2f}%"
            }
        else:
            return {"status": "error", "message": "Verification Failed: Face does Not Match"}

    except Exception as e:
        return {"status": "error", "message": f"Internal Erro {str(e)}"}
        
#show attendance   
@app.get("/live-attendance/{session_id}", tags=["Attendance Tracking"])
async def get_live_attendance(session_id: str, db_session: Session = Depends(get_session_dep)):
    try:
        
        session_response = (
            supabase.table("session")
            .select("session_id, course_id, session_name, status")
            .eq("session_id", session_id)
            .maybe_single()
            .execute()
        )

        if not session_response.data:
            return {"status": "error", "message": "Session not found"}

        
        session_info = session_response.data
        course_id = session_info.get("course_id")

        
        students_stmt = (
            select(Student, User)
            .join(Enrollment, Enrollment.student_id == Student.student_id)
            .join(User, User.user_id == Student.user_id)
            .where(Enrollment.course_id == course_id)
            .order_by(User.academic_id)
        )
        student_rows = db_session.exec(students_stmt).all()
        

        
        attendance_stmt = (
            select(AttendanceRecord)
            .where(AttendanceRecord.session_id == session_id)
            .order_by(AttendanceRecord.timestamp.desc())
        )
        attendance_rows = db_session.exec(attendance_stmt).all()
        

        
        latest_attendance_by_student: Dict[int, AttendanceRecord] = {}
        for record in attendance_rows:
            if record.student_id not in latest_attendance_by_student:
                latest_attendance_by_student[record.student_id] = record

        
        students: List[LiveAttendanceStudent] = []
        for student, user in student_rows:
            
            matched_record = latest_attendance_by_student.get(student.student_id)
            students.append(
                LiveAttendanceStudent(
                    student_id=student.student_id,
                    user_id=str(student.user_id),
                    academic_id=user.academic_id,
                    name=user.name,
                    status=matched_record.status if matched_record else "Absent",
                    check_in_time=matched_record.timestamp.isoformat() if matched_record and matched_record.timestamp else None,
                )
            )

       
        present_count = sum(1 for s in students if s.status.lower() == "present")

        
        return {
            "status": "success",
            "session": {
                "session_id": session_info.get("session_id"),
                "session_name": session_info.get("session_name"),
                "course_id": course_id,
                "session_status": session_info.get("status"),
            },
            "summary": {
                "total_students": len(students),
                "present_students": present_count,
                "absent_students": len(students) - present_count,
            },
            "students": [s.dict() for s in students],
        }
    except Exception as e:
       
        print(f"Live Attendance Error: {e}")
        return {"status": "error", "message": f"Could not fetch live attendance: {str(e)}"}
    
 

# Attendance history   
@app.get("/students/{user_id}/attendance-history", tags=["Reporting"])
async def get_student_attendance_history(user_id: str, session: Session = Depends(get_session_dep)):
    try:
        
        student_stmt= select(Student).where(Student.user_id == user_id)
        student = session.exec(student_stmt).first()

        if not student:
          return {
            "status": "error", 
            "message": f"Student with user_id {user_id} not found in the local database.",
            "daily": [], "weekly": [], "semester": []
          }
         
        internal_student_id = student.student_id

        stmt = select(AttendanceRecord).where(AttendanceRecord.student_id==internal_student_id)
        records = session.exec(stmt).all()

        now = datetime.now()
        start_of_today = datetime(now.year, now.month, now.day)
        start_of_week = start_of_today - timedelta(days=now.weekday())
        start_of_semester = now - timedelta(days=120)

        def is_after(record_date, threshold):
            if record_date is None: return False
    
            return record_date.replace(tzinfo=None) >= threshold

        daily_records = [r for r in records if r.timestamp and r.timestamp >= start_of_today]
        weekly_records = [r for r in records if r.timestamp and r.timestamp >= start_of_week]
        semester_records = [r for r in records if r.timestamp and r.timestamp >= start_of_semester]

        def serialize(rec: AttendanceRecord):
            return {
                "attendance_id": rec.attendance_id,
                "session_id": rec.session_id,
                "student_id": rec.student_id,
                "status": rec.status,
                "timestamp": rec.timestamp.isoformat() if rec.timestamp else None,
            }

        return {
            "status": "success",
            "student_id": internal_student_id,
            "daily": [serialize(r) for r in daily_records],
            "weekly": [serialize(r) for r in weekly_records],
            "semester": [serialize(r) for r in semester_records],
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

#update atendanc
@app.patch("/update-student-status", tags=["Attendance Tracking"])
async def update_student_status(data: AttendanceUpdate, db_session: Session = Depends(get_session_dep)):
    try:
        
        stmt = select(AttendanceRecord).where(
            AttendanceRecord.session_id == data.session_id,
            AttendanceRecord.student_id == data.student_id
        )
        existing_record = db_session.exec(stmt).first()

        if existing_record:
            
            existing_record.status = data.status
            db_session.add(existing_record)
        else:
            
            new_record = AttendanceRecord(
                student_id=data.student_id,
                session_id=data.session_id,
                status=data.status,
                timestamp=datetime.now() 
            )
            db_session.add(new_record)
        
        db_session.commit()
        return {"status": "success", "message": f"Status updated to {data.status}"}
        
    except Exception as e:
        db_session.rollback()
        print(f"Update Error: {e}")
        return {"status": "error", "message": str(e)}

# Reporting
@app.get("/attendance-report/{session_id}", tags=["Reporting"])
async def get_attendance_report(session_id: int, session: Session = Depends(get_session_dep)):
    try:
        stmt = select(AttendanceRecord).where(AttendanceRecord.session_id == session_id)
        result = session.exec(stmt).all()
        if not result:
            return {
                "status": "info",
                "message": "No students have checked in for this session yet!",
            }
        students = [
            {"attendance_id": r.attendance_id, "session_id": r.session_id, "student_id": r.student_id, "status": r.status, "timestamp": r.timestamp}
            for r in result
        ]
        return {
            "status": "success",
            "session_id": session_id,
            "total_attended": len(students),
            "students": students,
        }
    except Exception as error:
        return {"status": "error", "message": f"Could not fetch report: {str(error)}"}


@app.post("/generate-report", tags=["Reporting"])
async def generate_report(body: GenerateReportRequest, session: Session = Depends(get_session_dep)):
    try:
        report = Report(
            course_id=body.course_id,
            session_id=body.session_id,
            format=body.format,
            file_path=body.file_path,
        )
        session.add(report)
        session.commit()
        session.refresh(report)
        return {"status": "success", "message": "Attendance report generated!", "report_id": report.report_id}
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}



# Communication
@app.post("/send-notification", tags=["Communication"])
async def send_notification(body: SendNotificationRequest, session: Session = Depends(get_session_dep)):
    try:
        notif = Notification(recipient_id=body.recipient_id, message=body.message)
        session.add(notif)
        session.commit()
        session.refresh(notif)
        return {"status": "success", "message": "Notification sent to user!", "notification_id": notif.notification_id}
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
