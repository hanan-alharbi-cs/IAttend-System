import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'dart:convert';




class UploadSchedulePage extends StatefulWidget 
{
  
  const UploadSchedulePage({super.key});

  @override
  State<UploadSchedulePage> createState() => _UploadSchedulePageState();
}

class _UploadSchedulePageState extends State<UploadSchedulePage>
 {
  final List<Map<String, String>> _courses = [];
  final List<TextEditingController> _controllers = [];
  String? _currentUserId;

  @override
  void initState() 
  {
    super.initState();
    _loadUserData(); 
  }

  Future<void> _loadUserData() async
   {
    final prefs = await SharedPreferences.getInstance();
    setState(()
    {
      _currentUserId = prefs.getString('user_id'); 
    });
  }

  void _addCourse() 
  {
    setState(() 
    {
      _courses.add({'code': '', 'name': '', 'section': ''});
      _controllers.add(TextEditingController());
      _controllers.add(TextEditingController());
      _controllers.add(TextEditingController());
    });
  }

  void _removeCourse(int index) 
  {
    setState(() 
    {
      _courses.removeAt(index);
      _controllers.removeRange(index * 3, (index * 3) + 3);
    });
  }

     
  Future<bool> _submitSchedule() async 
  {
    if(_currentUserId == null)
     {
      _showSnackBar('Erro: Cant Found University ID Try Agian', Colors.red);
      return false;
     }
     
    if (_courses.isEmpty) 
    {
      _showSnackBar('Please add at least one course', Colors.red);
      return false;
    }

    bool allValid = true;
    for (var course in _courses) 
    {
      if (course['code']!.isEmpty || course['name']!.isEmpty || course['section']!.isEmpty) 
      {
        allValid = false;
        break;
      }
    }

    if (!allValid) 
    {
      _showSnackBar(' Fill All Fields For All Courses', Colors.orange);
      return false;
    }

    try 
    {
      final url = Uri.parse("${ApiConstsnts.baseUrl}${ApiConstsnts.submitManualSchedule}");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
        {
          'user_id': _currentUserId,
          'courses': _courses,
        }),
      );

      if (response.statusCode == 200) 
      {
        _showSnackBar('Schedule uploaded successfully!', Colors.green);
        Navigator.pop(context, true);
        return true;
      } 
      else 
      {
        _showSnackBar('Upload failed: ${response.body}', Colors.red);
        return false;
      }
    }
    catch (e)
    {
      _showSnackBar('Network error: $e', Colors.red);
      return false;
    }
  }

  void _showSnackBar(String message, Color color) 
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() 
  {
    for (var controller in _controllers) 
    {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Schedule', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _courses.isEmpty
                  ? const Center(
                      child: Text(
                        'No courses added. Tap + to add courses.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) 
                      {
                        final course = _courses[index];
                        final codeCtrl = TextEditingController(text: course['code']);
                        final nameCtrl = TextEditingController(text: course['name']);
                        final sectionCtrl = TextEditingController(text: course['section']);
                        _controllers[index * 3] = codeCtrl;
                        _controllers[index * 3 + 1] = nameCtrl;
                        _controllers[index * 3 + 2] = sectionCtrl;

                        return Card(
                          color: Colors.deepPurple.shade50,
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Course ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple[900],
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red[400]),
                                      onPressed: () => _removeCourse(index),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: codeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Course Code',
                                    prefixIcon: Icon(Icons.code, color: Colors.deepPurple),
                                  ),
                                  onChanged: (value) => course['code'] = value,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Course Name',
                                    prefixIcon: Icon(Icons.book, color: Colors.deepPurple),
                                  ),
                                  onChanged: (value) => course['name'] = value,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: sectionCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Section',
                                    prefixIcon: Icon(Icons.group, color: Colors.deepPurple),
                                  ),
                                  onChanged: (value) => course['section'] = value,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: FloatingActionButton(
                        heroTag: 'add',
                        onPressed: _addCourse,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        child: const Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _courses.isEmpty ? null : _submitSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _courses.isNotEmpty ? null : FloatingActionButton(
        onPressed: _addCourse,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
