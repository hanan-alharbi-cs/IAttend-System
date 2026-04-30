import cv2
import numpy as np
import tensorflow as tf
import os
from scipy.spatial.distance import euclidean
from siamese_model import create_encoder 

class FaceService:
    def __init__(self):
      
        self.MODEL_WEIGHTS_PATH = r"D:\IAeetand_system\backend\weights\face_final.weights.h5"
        self.HAARCASCADE_PATH = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'

        if os.path.exists(self.MODEL_WEIGHTS_PATH):
            self.embedder = create_encoder()
            self.embedder.load_weights(self.MODEL_WEIGHTS_PATH)
            self.embedder.trainable = False
            
        else:
            self.embedder = None 

        
        self.face_cascade = cv2.CascadeClassifier(self.HAARCASCADE_PATH)
        
    def extract_face_vector(self, image_bytes: bytes):
        
        try:
            
            nparr = np.frombuffer(image_bytes, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if frame is None:
                return None, "Faild To Process The Image"
                
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)# Converit To Black and White to reveal faces
            
            results = self.face_cascade.detectMultiScale(gray, 1.1, 5)

            if len(results) == 0:
                return None, "Face Not Found"

            faces_list = np.array(results).astype(int)
            x, y, w, h = faces_list[0]
            face_roi = frame[int(y):int(y+h), int(x):int(x+w)]
            
            if face_roi.size == 0:
                return None, "Cut-out face Area is Empty"

            #Preparing the Face for The Model
            face_roi = cv2.cvtColor(face_roi, cv2.COLOR_BGR2RGB)
            face_roi = cv2.resize(face_roi, (160, 160))
            
            face_normalized = face_roi.astype('float32') / 255.0

            face_batch = np.expand_dims(face_normalized, axis=0)
            
            # Extracting the Embedding from the model
            if self.embedder is not None:
                embedding = self.embedder(face_batch, training=False)
                
                return embedding.numpy().squeeze(), "Success"
            else:
                return None, "AI model was not successfully loaded"

        except Exception as e:
            return None, f"Internal Error {str(e)}"

    def verify_attendance(self, captured_embedding, saved_embedding, threshold=0.7):
        captured_embedding = np.array(captured_embedding)
        saved_embedding = np.array(saved_embedding)
        dist = euclidean(captured_embedding, saved_embedding)
        is_match = dist <= threshold
        similarity_score = max(0, 100 * (1 - dist))
        return is_match, similarity_score

face_service_instance = FaceService()