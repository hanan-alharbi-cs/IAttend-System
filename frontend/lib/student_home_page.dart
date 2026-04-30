import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_face_page.dart';
import 'upload_schedule_page.dart';
import 'login_page.dart';
import 'utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view_attendance_history_page.dart';
import 'course_sessions_page.dart';

class StudentHomePage extends StatefulWidget 
{
  
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> 
{
  
  List<Map<String, dynamic>> _courses = [];
  bool hasCourses = false;
  bool _isLoading = false;
  String _studentEmail= "Loading...";
  String _studentName = "Student";

  void _showSnackBar(String message, Color color) 
  {
    if (mounted) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  void _navigateToRegisterFace() 
  {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterFacePage()),
    );
  }

  void _navigateToAttendanceHistory()
  {
    final user = Supabase.instance.client.auth.currentUser;
    Navigator.of(context).push(MaterialPageRoute(builder: (context)=>  ViewAttendanceHistoryPage(userId: user?.id)));
  }

  void _navigateToCourseSessions(String courseId, String courseName) 
  {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CourseSessionsPage(
        courseId: int.parse(courseId), 
        courseName: courseName,
      ),
    ),
  );
}

//bring schedule and show it in the page
 Future<void> _fetchSchedule() async 
 {
  
  setState(() => _isLoading = true);
  
  try {
  
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id'); 

   
    if (userId == null) 
    {
      final user = Supabase.instance.client.auth.currentUser;
      userId = user?.id;
    }

    if (userId == null) 
    {
     
      _showSnackBar('No active session. Please login.', Colors.orange);
      return;
    }

    
    final url = '${ApiConstsnts.baseUrl}${ApiConstsnts.mySchedule}$userId';
   

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    

    if (response.statusCode == 200) 
    {
      final data = jsonDecode(response.body);
      

      if (data['status'] == "success") 
      {
        final List<dynamic> scheduleData = data['schedule'] ?? [];
        
        setState(() 
        {
          
          _courses = scheduleData.map((item) 
          {
            return 
            {
              'course_id': item['course_id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'code': item['code']?.toString() ?? '',
              'section': item['section']?.toString() ?? '',
            };
          }).toList();

          hasCourses = _courses.isNotEmpty;
        });
      }
       else 
      {
        _showSnackBar(data['message'] ?? 'Error fetching schedule', Colors.orange);
      }
    } 
    else 
    {
      
      _showSnackBar('Failed to fetch schedule: ${response.statusCode}', Colors.orange);
    }
  } 
  catch (e) 
  {
    
    _showSnackBar('Network error: $e', Colors.red);
  } 
  finally 
  {
    
    if (mounted) 
    {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _navigateToUploadSchedule() async 
  {
  // fetch id from local storage
  final prefs = await SharedPreferences.getInstance();
  final String? userId = prefs.getString('user_id');

  if (userId != null) 
  {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadSchedulePage(),
      ),
    );
    _fetchSchedule(); // update schedule in home page aftare returning 
  } 
  else 
  {
    // in case id not found in local storage
    _showSnackBar('Session expired. Please login again.', Colors.red);
  }
}

  @override
  void initState() 
  {
    super.initState();
    _fetchSchedule();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async 
  {
  final prefs = await SharedPreferences.getInstance();
  
  setState(() 
   {
    _studentEmail = prefs.getString('user_email') ?? "No Email found";
    _studentName = prefs.getString('full_name') ?? "Student Name";
   });
  }

  

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IAttend - Home Page', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName:  Text(_studentName),
              accountEmail: Text(_studentEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple[700]!, Colors.deepPurple[900]!],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.face, color: Colors.deepPurple),
              title: const Text('Register Face'),
              onTap: ()
              {
                Navigator.pop(context);
                _navigateToRegisterFace();
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.deepPurple),
              title: const Text('Link Schedule'),
              onTap: () 
              {
                Navigator.pop(context);
                _navigateToUploadSchedule();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.deepPurple,),
              title: const Text('Attendance History'),
              onTap: ()
              {
                Navigator.pop(context);
               _navigateToAttendanceHistory();

              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async 
              {
               // 1. check out from subabase
               await Supabase.instance.client.auth.signOut();
    
               // 2   delet session data from  SharedPreferences (ID، emile, name)
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear(); 
    
              // 3. delet all the previous pages and go to login page
              if (context.mounted) 
              {
              Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()), 
             (route) => false, // desont allow to user to go pack home page
              );
             }
            },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : hasCourses 
              ? _buildCoursesList() 
              : _buildEmptyState(),
        ),
      ),
    );
  }
//UI to show if there is no courses to display
  Widget _buildEmptyState() 
  {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_outlined, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            const Text(
              'No courses registered. Please upload your schedule to register courses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _navigateToUploadSchedule,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
//UI for the courses list
  Widget _buildCoursesList() 
  {
    return ListView.separated(
      itemCount: _courses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) 
      {
        final course = _courses[index];
        return Card(
          color: Colors.deepPurple.shade50,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            onTap: () 
          {
            _navigateToCourseSessions(
              course['course_id'], 
              course['name']
            );
          },
            leading: Icon(Icons.book, color: Colors.deepPurple[300]),
            title: Text(
              '${course['code'] ?? ''} - ${course['name'] ?? ''} (${course['section'] ?? ''})',
              style: TextStyle(color: Colors.deepPurple[900], fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
