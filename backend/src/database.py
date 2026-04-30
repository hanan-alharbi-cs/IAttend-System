"""
SQLModel database engine and session for IAttend.
Uses Supabase's PostgreSQL connection string (Project Settings → Database).
"""
import os
from contextlib import contextmanager
from typing import Generator

from sqlmodel import Session, create_engine

from models import (
    AttendanceRecord,
    Course,
    DeviceAudit,
    Enrollment,
    FaceTemplate,
    Faculty,
    GpsValidation,
    LectureSession,
    Notification,
    Report,
    Student,
    User,
)

_DEFAULT_URL = "postgresql://postgres.okfpfwmkeppscjloekzi:IAttendFinal2026@aws-1-ap-south-1.pooler.supabase.com:6543/postgres"


def _get_database_url() -> str:
    url = os.environ.get("DATABASE_URL")
    if url:
        return url
    # Supabase-style: build from parts if you prefer
    supabase_db = os.environ.get("SUPABASE_DB_URL")
    if supabase_db:
        return supabase_db
    try:
        from dotenv import load_dotenv
        load_dotenv()
        return os.environ.get("DATABASE_URL", os.environ.get("SUPABASE_DB_URL", _DEFAULT_URL))
    except Exception:
        return _DEFAULT_URL


# Sync engine (simplest; use for FastAPI with Depends(get_session))
engine = create_engine(
    _get_database_url(),
    echo=os.environ.get("SQL_ECHO", "").lower() in ("1", "true", "yes"),
    future=True,
)


@contextmanager
def get_session() -> Generator[Session, None, None]:
    """Context manager for a single DB session. Use in endpoints or scripts."""
    with Session(engine) as session:
        yield session


def get_session_dep() -> Generator[Session, None, None]:
    """FastAPI dependency: inject a DB session into route handlers."""
    with Session(engine) as session:
        yield session


def create_db_and_tables() -> None:
    """Create all tables in the database. Run once (e.g. at app startup or a CLI)."""
    from sqlmodel import SQLModel
    SQLModel.metadata.create_all(engine)
