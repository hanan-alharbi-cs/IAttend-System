from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import datetime
from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()
router = APIRouter()

# connect to Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# data coming from frontend
class CreateSessionRequest(BaseModel):
    course_id: int
    user_id: str
    session_name: str | None
    start_time: datetime
    end_time: datetime
    location_enabled: bool
    latitude: float | None = None
    longitude: float | None = None


@router.post("/create-session-full")
def create_session(body: CreateSessionRequest):

    # check time is correct
    if body.end_time <= body.start_time:
        raise HTTPException(status_code=400, detail="invalid time")
    faculty_data = supabase.table("faculty") \
        .select("faculty_id") \
        .eq("user_id", body.user_id) \
        .maybe_single() \
        .execute()

    if not faculty_data.data:
        raise HTTPException(status_code=404, detail="Faculty not found")
    
    f_id = faculty_data.data["faculty_id"] 

   
    link = supabase.table("coursefacultylink").select("*").eq("course_id", body.course_id).eq("faculty_id", f_id).execute()
    if not link.data:
        raise HTTPException(status_code=403, detail="not your course")

    # check location if enabled
    if body.location_enabled:
        if body.latitude is None or body.longitude is None:
            raise HTTPException(status_code=400, detail="location required")

    # set location values
    latitude = body.latitude if body.location_enabled else None
    longitude = body.longitude if body.location_enabled else None

    # create session
    data = {
        "course_id": body.course_id,
        "session_name": body.session_name,
        "start_time": body.start_time.isoformat(),
        "end_time": body.end_time.isoformat(),
        "status": "ended",
        "latitude": latitude,
        "longitude": longitude,
        "radius": 50
    }

    supabase.table("session").insert(data).execute()

    return {
        "message": "session created successfully"
    }
