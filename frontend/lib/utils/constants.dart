class ApiConstsnts{
  // Base backend API URL (local dev; switch to Render production URL).
  static const String baseUrl = "http://localhost:8000"; //"https://iattend-backend.onrender.com";

 // subabase links and key
 static const String supabaseUrl = "https://okfpfwmkeppscjloekzi.supabase.co";
 static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rZnBmd21rZXBwc2NqbG9la3ppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjIwMzIsImV4cCI6MjA4NzY5ODAzMn0.yQ8S_vnf_Hcp29iSsz4DE7r-AB3eLF5C_j2Fg76TU9A";
// Face biometric registration endpoint path.
static const String registerFace = "/register-face";
//ادارة المواد والطلاب (أكاديمي )
static const String creatCourse = "/create-course";
static const String enrollStudent = "/enroll-student";

// Session management endpoint for creating attendance sessions.
 static const String createSession = "/create-session";
 static const String updateSessionStatus = "/update-session-status";
 static const String getSessionLocation = "/get-session-location/";

// تسجيل الحضور 
static const String markAttendes = "/mark-attendance";
static const String attendanceHistoryTitle = "Attendance History";
// التقارير 
static const String attendanceReport = "/attendance-report/"; 
static const String generateReport = "/generate-report";

//ارسال التنبيهات 
static const String sendNotification = "/send-notification";

// رابط فحص حالة السيرفر
static const String healthCheck = "/";
static const String mySchedule = "/my-schedule/";
static const String submitManualSchedule = "/submit-manual-schedule";


    
}
