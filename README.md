IAttend – Intelligent Attendance Management System
IAttend is a mobile-based attendance management system for higher education institutions. It combines facial verification with GPS-based location validation to help confirm a student's identity and presence before an attendance record is submitted.

The system provides separate workflows for students and faculty members, including face registration, attendance sessions, course and schedule management, live attendance monitoring, attendance history, and PDF reports.
Project Links
- GitHub Repository: hanan-alharbi-cs/IAttend-System
- Project Walkthrough Video: Watch the IAttend walkthrough
- Project Report: [View the final project report](docs/IAttend-Project-Report.pdf)
- Face Verification Model Weights: Access the trained model weights
The video is a project walkthrough explaining the system and its user flow; it is not presented as a live interactive demo.

Problem Statement
Traditional attendance processes can be time-consuming and may allow proxy attendance. Manual recording also adds administrative work for faculty members and makes it harder to manage attendance records across courses and sessions.
Proposed Solution
IAttend automates attendance workflows through two verification factors:
1. Facial verification to check the student's identity.
2. GPS-based location validation to check whether the student is within the permitted attendance location when location verification is enabled.
Faculty members can create and manage sessions and choose whether location validation is required. For online sessions, the system can use facial verification without location validation.
Key Features
Student Features
- Create an account and log in.
- Register a face image for facial verification.
- Complete attendance check-in using facial verification.
- Validate attendance location using GPS when required.
- View course sessions and attendance history.
- Upload course schedules.
- View attendance status and confirmation.
Faculty Features
- Faculty account login and role-based access.
- Create, edit, and manage attendance sessions.
- Manage course sessions and session settings.
- Enable or disable location verification according to the session type.
- Monitor live attendance.
- Review attendance records and history.
- Generate PDF attendance reports.
How It Works
IAttend follows a multi-factor attendance verification workflow:
1. Face Registration: A student selects a facial image in the mobile application and submits it to the backend for processing and enrollment.
2. Face Detection and Verification: The face-processing workflow uses OpenCV for image handling and a FaceNet-based Siamese model for face representation and matching. MTCNN is used in the model training/testing workflow for face detection.
3. Face Matching: The face-verification service compares face representations using Euclidean distance to support the matching decision.
4. Location Validation: The Flutter application obtains the device's current position using the Geolocator package. The Haversine formula is used to calculate the distance between the student and the lecture location.
5. Attendance Recording: When the required verification checks are satisfied, the attendance workflow submits the record to the backend.
For online sessions, location validation can be disabled while facial verification remains available.
Technology Stack
Component	Technologies
Mobile Application	Flutter, Dart
Mobile UI & Device Features	Flutter Material, Camera, Image Picker, Shared Preferences
Mobile Networking & Uploads	HTTP, http_parser
Backend API	Python, FastAPI, Uvicorn, Pydantic, python-multipart
Database Layer	SQLModel, SQLAlchemy
Backend Data Services	Supabase client, PostgreSQL, Supabase Storage
Face Recognition	FaceNet (InceptionResNetV1), Siamese Network, Keras-FacNet
Computer Vision & Image Processing	OpenCV, MTCNN, Pillow, NumPy
Model Development & Evaluation	TensorFlow, Keras, scikit-learn, SciPy, Pandas
Model Evaluation & Visualization	Matplotlib, Seaborn, tqdm
Location Services	Geolocator, Haversine formula
Reports & File Handling	PDF, Printing, File Picker


Model Development and Evaluation
The repository includes model training and testing scripts in addition to the application code. These scripts use TensorFlow/Keras and FaceNet for the face-verification model workflow, MTCNN for face detection, and scikit-learn metrics to evaluate model results. Pandas, NumPy, SciPy, Pillow, Matplotlib, Seaborn, and tqdm are also used in the data preparation, image-processing, evaluation, or visualization scripts.
System Architecture
IAttend follows a client-server architecture:
- Flutter Mobile Application: Provides student and faculty interfaces, captures or selects face images, accesses device location, communicates with the backend, and displays attendance information.
- FastAPI Backend: Exposes API endpoints for authentication-related workflows, face registration and verification, session management, schedule processing, and attendance operations.
- Face Verification Pipeline: Uses TensorFlow/Keras with a FaceNet-based Siamese model, alongside OpenCV and NumPy for image-processing tasks.
- Database Layer: Uses SQLModel/SQLAlchemy for database models and operations. Supabase services are integrated for application data and storage; PostgreSQL is used as the database service.
- Location Verification: Uses Geolocator in the mobile application and the Haversine formula for distance calculation.
Project Screenshots
The following screenshots showcase the main interfaces and features of the IAttend system.
Attendance History

Attendance Reports

Course Sessions

Error Screen

Login Error Screen

On-Person Attendance Session

Student Home Screen

Face Registration

Online Session Creation

Live Attendance Monitoring

Schedule Upload

My Contribution
My contributions to the collaborative graduation project included:
- Developing the database implementation in database.py and working with the SQLModel database models.
- Implementing and supporting user account creation and login workflows.
- Implementing attendance session creation and management.
- Working on face registration and face-verification functionality.
- Contributing to GPS-based location verification.
- Working on attendance history and course-session features.
- Contributing to faculty session functionality and attendance workflows.
Project Structure
IAttend-System/
│
├── backend/
│   ├── ai_lab/                 # Face-verification model training scripts
│   ├── src/                    # FastAPI application and backend services
│   ├── weights/                # Model-weight access information
│   └── requirements.txt        # Python dependencies
│
├── frontend/
│   ├── lib/                    # Flutter application screens and services
│   ├── pubspec.yaml            # Flutter dependencies
│   └── pubspec.lock
│
├── docs/
│   └── IAttend-Project-Report.pdf
│
├── screenshots/                # Project interface screenshots
└── README.md
Project Information
- Project Type: Graduation Project
- University: Taibah University
- Field: Computer Science
- Project Team: Collaborative Team Project
Notes on Dependencies
The backend requirements file and Flutter dependency manifest describe the application dependencies. Some libraries used by the model training and evaluation scripts (including MTCNN, SciPy, Pandas, scikit-learn, Matplotlib, Seaborn, and tqdm) are referenced by source files but are not all currently listed in backend/requirements.txt. Add the required packages to that file before expecting a clean environment setup for every training and evaluation script.
IAttend – Combining Facial Verification and Location Validation for Smarter Attendance Management.
