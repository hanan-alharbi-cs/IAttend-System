import os
from pydantic import BaseModel
from supabase import Client




# Pydantic model updated to accept university ID instead of email for login requests.
class LoginRequest(BaseModel):
    user_id: str  # University ID (e.g., '44100') entered by student/faculty
    password: str


# Service function to handle user login via Supabase auth.
async def perform_login(request: LoginRequest, supabase: Client):
    try:
        # Programming workaround: Map university ID to virtual email format accepted by Supabase auth.
        # Example: ID "44100" becomes "44100@iattend.com" for sign_in_with_password.
        virtual_email = f"{request.user_id}@iattend.com"
        
        response = supabase.auth.sign_in_with_password({
            "email": virtual_email,
            "password": request.password
        })

        user_query = supabase.table("users").select("name").eq("academic_id", int(request.user_id)).execute()
        user_name = user_query.data[0].get("name", "Student") if user_query.data else "Student"
        return{
            "status": "success",
            "message": "Logged in successfully",
            "user_id": request.user_id,
            "supabase_uid": response.user.id,
            "email": virtual_email,
            "user": 
            {
                "name": user_name
            }
            
        }
        
    except Exception as e:
        print(f"Login error: {str(e)}")
        return {
            "status": "error", 
            "message": "ID or Password is not correct"
        }