import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'FacultySessionsPage.dart';
import 'upload_schedule_page.dart';
import 'attendance_report_screen.dart';

class FacultyHomePage extends StatefulWidget 
{
  const FacultyHomePage({super.key});

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> 
{
  List<Map<String, dynamic>> _courses = [];
  bool hasCourses = false;
  bool _isLoading = false;
  String? _facultyId;
  String _facultyEmail = "Loading...";
  String _facultyName = "Faculty";

  void _showSnackBar(String message, Color color) 
  {
    if (mounted) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }
  

  void _navigateToReports()
  {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const AttendanceReportScreen(),
    ),
  );
  }

  void _navigateToCourseSessions(String courseId, String courseName) 
  {
    
    if (_facultyId == null) 
    {
      _showSnackBar("Faculty data is still loading...", Colors.orange);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FacultySessionsPage(
          courseId: int.parse(courseId),
          courseName: courseName,
          facultyId: _facultyId!, 
        ),
      ),
    );
  }

  Future<void> _fetchSchedule() async 
  {
    
    setState(() => _isLoading = true);

    try 
    {
      
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

  @override
  void initState() 
  {
    super.initState();
    _fetchSchedule();
    _loadFacultyData();
  }

  Future<void> _loadFacultyData() async 
  {
    final prefs = await SharedPreferences.getInstance();
    setState(()
    {
      _facultyId = prefs.getString('user_id');
      _facultyEmail = prefs.getString('user_email') ?? "No Email found";
      _facultyName = prefs.getString('full_name') ?? "Faculty Name";
    });
    
  }

  Future<void> _navigateToUploadSchedule() async 
  {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');

    if (userId != null) 
    {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UploadSchedulePage(),
        ),
      );
      _fetchSchedule(); // Update Schedule Aftare Returning from Upload Schedule
    } 
    else 
    {
      _showSnackBar('Session Expired,Login Again', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome,Faculty', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_facultyName),
              accountEmail: Text(_facultyEmail),
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
              leading: const Icon(Icons.upload_file, color: Colors.deepPurple),
              title: const Text('Upload Schedule'),
              onTap: () 
              {
                Navigator.pop(context);
                _navigateToUploadSchedule();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.deepPurple),
              title: const Text('Attendance Reports'),
              onTap: () 
              {
                Navigator.pop(context);
                _navigateToReports();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async 
              {
                await Supabase.instance.client.auth.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) 
                {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
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
//UI when there are no courses to display
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
            const Icon(Icons.calendar_today_outlined, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            const Text(
              'No courses found,Please upload your schedule',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _navigateToUploadSchedule,
              icon: const Icon(Icons.upload),
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
// UI when there courses to display
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
            onTap: () {
              _navigateToCourseSessions(course['course_id'], course['name']);
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