import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iattend_frontend/face_verification_page.dart';
import 'package:iattend_frontend/location.dart';

class AttendanceOrchestrator 
{
  static Future<void> startCheckIn({
    required BuildContext context,
    required String sessionId,
  }) async
   {
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');

    if (userId == null) 
    {
      _showSnackBar(context, "User Not Found", Colors.red);
      return;
    }

    
    _showLoadingDialog(context, "Your Current Location is Being Verivied...");
    bool isInLocation = await LocationService().verifyStudentLocation(sessionId.toString());
  
    Navigator.of(context, rootNavigator: true).pop();

    if (!isInLocation) 
    {
      _showSnackBar(context, "Invalid Location", Colors.orange);
      return; 
    }

    
    
    final bool? isSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FaceVerificationPage(
          sessionId: sessionId,
          userId: userId,
        ),
      ),
    );

    
    if (isSuccess == true) 
    {
      _showSnackBar(context, "Attendance Successfully Recorded", Colors.green);
    }
  }

  static void _showSnackBar(BuildContext context, String message, Color color) 
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }


static Future<void> startCheckOut({
  required BuildContext context,
  required String sessionId,
}) async {
  
  _showLoadingDialog(context, "Verifying location for check-out...");
  bool isInLocation = await LocationService().verifyStudentLocation(sessionId.toString());
  Navigator.of(context, rootNavigator: true).pop();

  if (isInLocation) 
  {
    _showSnackBar(context, "Check-out Successful", Colors.green);
  } 
  else 
  {
    _showSnackBar(context, "You are too far to check-out", Colors.orange);
  }
}

  static void _showLoadingDialog(BuildContext context, String message) 
  {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded( 
            child: Text(message),
          ),
        ],
      ),
    ),
  );
}
}