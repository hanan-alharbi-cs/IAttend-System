import json
from typing import List, Dict, Any
from sqlmodel import Session, select
from models import User, Faculty, Student, Course, Enrollment, CourseFacultyLink




# ----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def process_faculty_courses(session: Session, faculty_id: int, courses: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    processed = []
    for course_data in courses:
        course_stmt = select(Course).where(
            Course.code == course_data["code"], 
            Course.section == course_data["section"]
        )
        course = session.exec(course_stmt).first()
        
        if not course:
            course = Course(
                name=course_data["name"],
                code=course_data["code"],
                section=course_data["section"]
            )
            session.add(course)
            session.flush()
            action = "created"
        else:
            action = "found"

        link_stmt = select(CourseFacultyLink).where(
            CourseFacultyLink.course_id == course.course_id,
            CourseFacultyLink.faculty_id == faculty_id
        )
        if not session.exec(link_stmt).first():
            new_link = CourseFacultyLink(course_id=course.course_id, faculty_id=faculty_id)
            session.add(new_link)
            processed.append({"course_id": course.course_id, "action": f"{action}_And_Linked"})
        else:
            processed.append({"course_id": course.course_id, "action": "Already_linked"})
            
    return processed

# ----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
def process_student_courses(session: Session, student_id: int, courses: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    processed = []
    for course_data in courses:
        course_stmt = select(Course).where(
            Course.code == course_data["code"], 
            Course.section == course_data["section"]
        )
        course = session.exec(course_stmt).first()
        
        if course:
            enroll_stmt = select(Enrollment).where(
                Enrollment.student_id == student_id, 
                Enrollment.course_id == course.course_id
            )
            if not session.exec(enroll_stmt).first():
                enrollment = Enrollment(student_id=student_id, course_id=course.course_id)
                session.add(enrollment)
                processed.append({"course_id": course.course_id, "action": "Enrolled"})
            else:
                processed.append({"course_id": course.course_id, "action": "Already_Enrolled"})
        else:
            processed.append({"course": course_data, "action": "No_Matching_Course"})
            
    return processed

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
def process_course_schedule_manual(session: Session, user_id: str, courses: List[Dict[str, Any]]) -> Dict[str, Any]:
    
    
    user_stmt = select(User).where(User.user_id == user_id)
    user = session.exec(user_stmt).first()
    
    if not user:
        return {"status": "error", "message": "User not found"}
    
    try:
        processed_actions = []
        user_type_lower = user.user_type.lower()
        if user.user_type.lower() == "faculty":
            faculty_member = session.exec(select(Faculty).where(Faculty.user_id == user_id)).first()
            if not faculty_member:
                 return {"status": "error", "message": "Faculty Record Not Found"}
            processed_actions = process_faculty_courses(session, faculty_member.faculty_id, courses)
                
        elif user.user_type == "student":
            student = session.exec(select(Student).where(Student.user_id == user_id)).first()
            if not student:
                 return {"status": "error", "message": "Student Record Not Found"}
            processed_actions = process_student_courses(session, student.student_id, courses)
        
        session.commit()
        return {
            "status": "Success", 
            "message": f" processed {len(courses)}  Course Successfully",
            "processed": processed_actions
        }
    except Exception as e:
        session.rollback()
        return {"status": "Error", "message": str(e)}