"""
SQLModel table models for IAttend (matches sql/schema.sql).
Use these with the Supabase PostgreSQL connection for a single ORM layer.
"""
from datetime import datetime
from typing import List, Optional  
from sqlmodel import SQLModel, Field, Relationship,text  
from sqlmodel import Field, SQLModel
from sqlmodel import SQLModel, Field
from sqlalchemy import Column, JSON
from typing import List, Any
import uuid

# -----------------------------------------------------------------------------
# 1. User (table: users)
# -----------------------------------------------------------------------------
class User(SQLModel, table=True):
    __tablename__ = "users"
    __table_args__ = {"extend_existing": True}

    user_id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()), 
        primary_key=True,
        index=True)
    name: str
    email: str = Field(unique=True, index=True)
    password: str
    user_type: str = Field(index=True)  # 'Student' | 'Faculty' | 'Admin'
    academic_id: int
    student: Optional["Student"] = Relationship(back_populates="user")
    faculty: Optional["Faculty"] = Relationship(back_populates="user")
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# -----------------------------------------------------------------------------
# 2. Notification
# -----------------------------------------------------------------------------
class Notification(SQLModel, table=True):
    __tablename__ = "notification"
    __table_args__ = {"extend_existing": True}

    notification_id: Optional[int] = Field(default=None, primary_key=True)
    recipient_id: str = Field(foreign_key="users.user_id", index=True)
    message: str
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    read_at: Optional[datetime] = None


# -----------------------------------------------------------------------------
# 3. DeviceAudit
# -----------------------------------------------------------------------------
class DeviceAudit(SQLModel, table=True):
    __tablename__ = "device_audit"
    __table_args__ = {"extend_existing": True}

    audit_id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(foreign_key="users.user_id", index=True)
    device_id: Optional[str] = None
    action: str
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    device_type: Optional[str] = None


# -----------------------------------------------------------------------------
# 4. CourseFacultyLink
# -----------------------------------------------------------------------------
class CourseFacultyLink(SQLModel, table=True):
    __tablename__ = "coursefacultylink"
    course_id: int = Field(foreign_key="course.course_id", primary_key=True)
    faculty_id: int = Field(foreign_key="faculty.faculty_id", primary_key=True)

# -----------------------------------------------------------------------------
# 5. Course
# -----------------------------------------------------------------------------
class Course(SQLModel, table=True):
    __tablename__ = "course"
    __table_args__ = {"extend_existing": True}

    course_id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    code: str = Field(index=True)
    section: Optional[str] = Field(default=None, index=True)
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    instructors: List["Faculty"] = Relationship(
        back_populates="courses", 
        link_model=CourseFacultyLink)
    enrolled_students: List["Enrollment"] = Relationship(back_populates="course")

# -----------------------------------------------------------------------------
# 6. Faculty
# -----------------------------------------------------------------------------
class Faculty(SQLModel, table=True):
    __tablename__ = "faculty"
    __table_args__ = {"extend_existing": True}

    faculty_id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(foreign_key="users.user_id", unique=True, index=True)
    department: Optional[str] = None
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    courses: List["Course"] = Relationship(
        back_populates="instructors", 
        link_model=CourseFacultyLink 
    )
    user: Optional[User] = Relationship(back_populates="faculty")


# -----------------------------------------------------------------------------
# 7. Student
# -----------------------------------------------------------------------------
class Student(SQLModel, table=True):
    __tablename__ = "student"
    __table_args__ = {"extend_existing": True}

    student_id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(foreign_key="users.user_id", unique=True, index=True)
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    user: Optional[User] = Relationship(back_populates="student")
    enrollments: List["Enrollment"] = Relationship(back_populates="student")







# -----------------------------------------------------------------------------
# 8. LectureSession (table: session; name avoids clash with sqlmodel.Session)
# -----------------------------------------------------------------------------
class LectureSession(SQLModel, table=True):
    __tablename__ = "session"
    __table_args__ = {"extend_existing": True}

    session_id: Optional[ str] = Field(default=None, primary_key=True)
    course_id: int = Field(foreign_key="course.course_id", index=True)
    session_name: str = Field(default="Lecture Session")
    start_time: datetime
    end_time: datetime
    status: str = Field(default="pending")  # 'pending' | 'active' | 'ended'
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# -----------------------------------------------------------------------------
# 9. FaceTemplate (face_data is binary)
# -----------------------------------------------------------------------------
class FaceTemplate(SQLModel, table=True):
    __tablename__ = "face_template"
    __table_args__ = {"extend_existing": True}

    face_template_id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="student.student_id", unique=True, index=True)
    face_data: Any = Field(sa_column=Column(JSON))
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# -----------------------------------------------------------------------------
# 10. Enrollment (Student <-> Course)
# -----------------------------------------------------------------------------
class Enrollment(SQLModel, table=True):
    __tablename__ = "enrollment"
    __table_args__ = {"extend_existing": True}

    enrollment_id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="student.student_id", index=True)
    course_id: int = Field(foreign_key="course.course_id", index=True)
    enrolled_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    student: "Student" = Relationship(back_populates="enrollments")
    course: "Course" = Relationship(back_populates="enrolled_students")


# -----------------------------------------------------------------------------
# 11. GpsValidation
# -----------------------------------------------------------------------------
class GpsValidation(SQLModel, table=True):
    __tablename__ = "gps_validation"
    __table_args__ = {"extend_existing": True}

    validation_id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="student.student_id", index=True)
    session_id: int = Field(foreign_key="session.session_id", index=True)
    latitude: float
    longitude: float
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    valid: bool = True


# -----------------------------------------------------------------------------
# 12. AttendanceRecord
# -----------------------------------------------------------------------------
class AttendanceRecord(SQLModel, table=True):
    __tablename__ = "attendance_record"
    __table_args__ = {"extend_existing": True}

    attendance_id: Optional[int] = Field(default=None, primary_key=True)
    session_id: str = Field(foreign_key="session.session_id", index=True)
    student_id: int = Field(foreign_key="student.student_id", index=True)
    status: str  # 'Present' | 'Absent' | 'Late'
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)


# -----------------------------------------------------------------------------
# 13. Report
# -----------------------------------------------------------------------------
class Report(SQLModel, table=True):
    __tablename__ = "report"
    __table_args__ = {"extend_existing": True}

    report_id: Optional[int] = Field(default=None, primary_key=True)
    course_id: int = Field(foreign_key="course.course_id", index=True)
    session_id: Optional[str] = Field(default=None, foreign_key="session.session_id", index=True)
    generated_on: Optional[datetime] = Field(default_factory=datetime.utcnow)
    format: Optional[str] = None  # 'PDF' | 'CSV'
    file_path: Optional[str] = None

