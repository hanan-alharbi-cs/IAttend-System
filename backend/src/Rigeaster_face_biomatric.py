import io
import os
import sys
# -------------- 
import cv2
import numpy as np
from fastapi import UploadFile, File, HTTPException
from sqlmodel import select,Session
from supabase import create_client, Client
#--------------------
from models import Student
from database import engine
from siamese_model import create_encoder
#--------------------
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_WEIGHTS_PATH = os.path.join(BASE_DIR,  "weights", "face_final.weights.h5")
HAARCASCADE_PATH = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'

_model = None
_face_cascade = None

# Lazy loads Siamese encoder, applies pre-trained weights, sets inference mode.
def get_model():
    global _model
    if _model is None:
        _model = create_encoder()
        
        # Load pre-trained weights if they exist
        if os.path.exists(MODEL_WEIGHTS_PATH):
            _model.load_weights(MODEL_WEIGHTS_PATH)
        
        # Set model to inference mode
        _model.trainable = False
    
    return _model

#Load and return the Haar Cascade face detector
def get_face_cascade():

    global _face_cascade
    if _face_cascade is None:
        _face_cascade = cv2.CascadeClassifier(HAARCASCADE_PATH)
        if _face_cascade.empty():
            raise ValueError("Failed to load Haar Cascade classifier")
    return _face_cascade


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    
    # Convert bytes to numpy array
    nparr = np.frombuffer(image_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if frame is None:
        raise ValueError("Failed to decode image")
    
    # Face detection
    face_cascade = get_face_cascade()
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.2, 5)
    
    if len(faces) == 0:
        raise ValueError("No face detected")
    
    # Crop the first detected face
    (x, y, w, h) = faces[0]
    face_roi = frame[y:y+h, x:x+w]
    
    # Convert BGR to RGB
    face_roi = cv2.cvtColor(face_roi, cv2.COLOR_BGR2RGB)
    
    # Resize to model input size (224, 224)
    face_roi = cv2.resize(face_roi, (160, 160))
    
    # Normalize: divide by 255.0
    face_normalized = face_roi.astype('float32') / 255.0
    
    return face_normalized


def extract_embedding(face_image: np.ndarray) -> np.ndarray:
    
    model = get_model()
    
    # Add batch dimension: (1, 160, 160, 3)
    face_batch = np.expand_dims(face_image, axis=0)
    
    # Extract embedding  and to prevent server crashing
    embedding = model(face_batch, training=False)
    
    # Squeeze to remove batch dimension
    embedding = embedding.numpy().squeeze()
    
    return embedding


# ============================================================
# Supabase Database Integration
# ============================================================
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def save_face_embedding_to_db(student_id:int, embedding: list):
    
    response = supabase.table('face_template').upsert({
    "student_id": student_id, 
    "face_data": embedding
}, on_conflict="student_id").execute()
    
    if hasattr(response, 'error') and response.error:
        print(f"Error saving to DB: {response.error}")
        raise Exception(f" Database error: {response.error.message}")
    print(f"Succsessfully saved embedding for student: {student_id}")
    return response.data



async def register_face_biometric(
    user_id: str,
    image_file: UploadFile = File(...)
):
# open session to find to saerch for the right user id to this student id
 with Session(engine) as session:
   try:
       student_stmt = select(Student).where(Student.user_id == user_id)
       student = session.exec(student_stmt).first()
    
        # Validate input
       if not student:
         raise HTTPException(status_code=400, detail="student_id is required")
    
       if image_file is None:
         raise HTTPException(status_code=400, detail="image_file is required")
    
        # Check file type
         allowed_content_types = {"image/png", "image/jpeg", "image/jpg"}
         if image_file.content_type not in allowed_content_types:
          raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {allowed_content_types}"
         )
       
    
       internal_student_id= student.student_id
        # Read image bytes
       image_bytes = await image_file.read()
       face_image = preprocess_image(image_bytes)# Preprocess image and detect face
       embedding = extract_embedding(face_image)# Extract embedding
       embedding_list = embedding.tolist()# Convert numpy array to list for JSON serialization
        
       try:
            
            save_face_embedding_to_db(internal_student_id, embedding_list)
            
            
            return {
                "status": "success",
                "student_id": user_id, 
                "internal_id": internal_student_id,
                "message": "Face registered successfully"
            }
            
       except Exception as db_error:
            print(f"Database Error: {str(db_error)}")
            raise HTTPException(
                status_code=500, 
                detail=f"Failed to save to database: {str(db_error)}"
            )
          
   except ValueError as e:
     if "No face detected" in str(e):
        raise HTTPException(status_code=400, detail="No face detected in the image")
        
        
   except Exception as e:
    print(f"DEBUG ERROR: {str(e)}")
    raise HTTPException(status_code=500, detail="Internal server error")






