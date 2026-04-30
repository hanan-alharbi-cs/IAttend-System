import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iattend_frontend/utils/constants.dart'; 
import 'student_home_page.dart';
import 'faculty_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget
{
 const LoginPage({super.key});
 @override
 State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{
  // to fetch the text from the user
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String baseUrl = ApiConstsnts.baseUrl;

  Future<void> loginUser() async
  {
    String id = idController.text.trim();
    String password = passwordController.text.trim();
    String assignedRole = "";
    
    if(id.isEmpty || password.isEmpty)
    {
      _showError("Please fill in all fields");
      return;
    }

    try
    {
      //sending the requst to the backend
      final respon = await http.post
      (
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type":"application/json"},
        body: jsonEncode(
            {
                "user_id":id,
                "password":password,
            })
      );

      if(respon.statusCode==200)
      {
        final data = jsonDecode(respon.body);
        if (data['status'] == "success")
        {
          if (id.startsWith('4') && id.length == 7)
        {
          assignedRole = 'student';
        } 
        else if (id.startsWith('1') && id.length == 5) 
        {
          assignedRole = 'faculty';
        }
            String supabaseUid = data['supabase_uid'];
            String userEmail = data['email']; // send 'email' filed
            String fullName = "Unknown User"; 
            if (data['user'] != null && data['user']['name'] != null)
            {
            fullName = data['user']['name'];
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', supabaseUid);
            await prefs.setString('user_email', userEmail);
            await prefs.setString('full_name', fullName);
            await prefs.setString('student_academic_id', id);
            await prefs.setString('role', assignedRole); 
            await prefs.setBool('is_logged_in', true);// check the state of the logging in

            if(!mounted) return;

            if(assignedRole == 'student')
            {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomePage()));
            }
            else if(assignedRole == 'faculty')
            {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FacultyHomePage()));
            } 
            else
            {
              _showError("ID format is incorrect");
              return;
            }
        }
        else
        {
          _showError(data['message'] ?? "Login Failed");

        }
    } 
       else 
        {
        _showError("Server Error: ${respon.statusCode}");
        }

      }
      catch (e) 
    {
      _showError("Connection Error: Make sure the backend is running");
    }
 }

 void _showError(String message) 
 {
    if (mounted) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) 
  {
   return Scaffold
   (
     appBar: AppBar(title: const Text("LOGIN")),
     body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            children: [
                TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "University ID")
                ),
                const SizedBox(height: 10),
                TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: loginUser, child: const Text("LOGIN")),
            ],
        ),
        ),
   );
  }
}
