import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iattend_frontend/utils/constants.dart';
import 'create_session_page.dart'; 
import 'edit_session_seeting.dart';

class FacultySessionsPage extends StatefulWidget 
{
  final int courseId;
  final String courseName;
  final String facultyId;

  const FacultySessionsPage({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.facultyId,
  }) : super(key: key);

  @override
  _FacultySessionsPageState createState() => _FacultySessionsPageState();
}

class _FacultySessionsPageState extends State<FacultySessionsPage> 
{
  int? facultyId;
  List<dynamic> sessions = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() 
  {
    super.initState();
    _getSessions();
  }

  
  Future<void> _getSessions() async 
  {
    try 
    {
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
            isLoading = false;
          });
        }
      } 
      else 
      {
        setState(() 
        {
          errorMessage = "Failed to load sessions";
          isLoading = false;
        });
      }
    } 
    catch (e) 
    {
      setState(() 
      {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }
  
  Future<void> _updateSessionStatus(String session_id, String newStatus) async
   {
  try 
  {
    final url = "${ApiConstsnts.baseUrl}${ApiConstsnts.updateSessionStatus}/$session_id";
    
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": newStatus}),
    );

    if (response.statusCode == 200) 
    {
      await _getSessions();
      
    }
  } 
  catch (e) 
  {
    print("Error: $e");
  }
}

@override
Widget build(BuildContext context) 
{
  return Scaffold(
    backgroundColor: Colors.transparent, 
    appBar: AppBar(
      title: Text(widget.courseName, style: const TextStyle(fontSize: 16, color: Colors.white)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.deepPurple), 
      actions: [
        TextButton.icon(
          onPressed: () async 
          {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => creatSessionPage(
                 courseId: widget.courseId,
                 courseName: widget.courseName,
                 userId: widget.facultyId,
                ),
              ),
            );
            if (result == true) 
            {
              _getSessions(); 
            }
          },
          icon: const Icon(Icons.add, color: Colors.greenAccent),
          label: const Text("Create New Session", style: TextStyle(color: Colors.deepPurple)),
        ),
      ],
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
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _getSessions,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(session);
                },
              ),
            ),
    ),
  );
}

Widget _buildSessionCard(dynamic session) 
{
  String currentStatus = session['status']; 
  String session_id = session['session_id']?.toString() ?? "";
  String sessionTitle = session['session_name'] ?? "Unnamed Session";

  return Card(
    key: ValueKey(session_id),
    color: Colors.white.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: Colors.white.withOpacity(0.2)),
    ),
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title:  Text(sessionTitle,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              "Date: ${session['start_time'].toString().split('T')[0]}",
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white60),
              onPressed: () 
              {
               Navigator.push(
               context,
               MaterialPageRoute(
               builder: (context) => editSessionPage(
               sessionData: session, 
               courseName: widget.courseName,
             ),
            ),
          ).then((value) 
          {
              if (value == true) 
              {
             _getSessions(); 
              }
           });
              }
          ),
          ),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: (currentStatus == 'active') ? null : () 
                {
                  _updateSessionStatus(session_id, 'active');
                  print("Navigating to Live Attendance...");
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text("Start"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: (currentStatus == 'ended') ? null : () 
                {
                  _updateSessionStatus(session_id, 'ended');
                },
                icon: const Icon(Icons.stop, size: 18),
                label: const Text("End"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}