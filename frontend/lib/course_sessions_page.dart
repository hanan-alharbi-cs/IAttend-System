import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iattend_frontend/utils/constants.dart';
import 'attendance_orchestrator.dart';



class CourseSessionsPage extends StatefulWidget 
{
  final int courseId;
  final String courseName;

  const CourseSessionsPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  _CourseSessionsPageState createState() => _CourseSessionsPageState();
}

class _CourseSessionsPageState extends State<CourseSessionsPage> 
{
  List<dynamic> sessions = [];
  bool loading = true;
  String error = "";

  @override
  void initState() 
  {
    super.initState();
    _getSessions();
  }

  
  Future<void> _getSessions() async 
  {
    try {
      final url = "${ApiConstsnts.baseUrl}/get-sessions/${widget.courseId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) 
      {
        final data = json.decode(response.body);
        if (data['status'] == 'success') 
        {
          setState(() 
          {
            sessions = data['data'];
            loading = false;
          });
        }
      } 
      else 
      {
        setState(() 
        {
          error = "Failed to load sessions";
          loading = false;
        });
      }
    } 
    catch (e) 
    {
      setState(() 
      {
        error = "Connection error: $e";
        loading = false;
      });
    }
  }

 @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : sessions.isEmpty
                  ? const Center(child: Text("No sessions scheduled yet."))
                  : RefreshIndicator(
                      onRefresh: _getSessions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sessions.length,
                        itemBuilder: (context, index)
                        {
                          final session = sessions[index];
                          final String status = session['status'];
                          bool isCheckInActive = (status == "active");
                          bool isCheckOutActive = (status == "inactive" || status == "ended");
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        session['session_name'] ??
                                            "Lecture Session",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                      "Date: ${session['start_time'].toString().split('T')[0]}"),
                                  const Divider(height: 25),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: isCheckInActive
                                              ? () {
                                                  AttendanceOrchestrator.startCheckIn(
                                                  context: context,
                                                  sessionId: session['session_id'], 
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(Icons.login),
                                          label: const Text("Check-in"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isCheckInActive
                                                ? Colors.deepPurple[700]
                                                : Colors.grey[300],
                                            foregroundColor: isCheckInActive
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: isCheckOutActive
                                              ? ()=> AttendanceOrchestrator.startCheckOut(
                                                 context: context, 
                                                 sessionId: session['session_id'],
                                                )
                                                : null,
                                          icon: const Icon(Icons.logout),
                                          label: const Text("Check-out"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isCheckOutActive
                                                ? Colors.deepPurple[900]
                                                : Colors.grey[300],
                                            foregroundColor: isCheckOutActive
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }                              
  
  Widget _buildStatusBadge(String status) 
  {
    Color color = status == "active" ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}