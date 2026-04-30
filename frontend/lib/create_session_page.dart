import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iattend_frontend/utils/constants.dart';

class creatSessionPage extends StatefulWidget 
{
  final int courseId;
  final String courseName;
  final String userId;

  const creatSessionPage({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.userId,
  });

  @override
  State<creatSessionPage> createState() => _creatSessionPageState();
}

class _creatSessionPageState extends State<creatSessionPage> 
{
  
  double? _latitude;
  double? _longitude;
  bool isOnline = false;
  bool _isCreating = false;
  bool _isGettingLocation = false;
  final TextEditingController _nameController = TextEditingController();
  
  Future<void> _fetchCurrentLocation() async 
  {
    setState(() => _isGettingLocation = true);
    try 
    {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) 
      {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() 
        {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room Location Successfully Identified"), backgroundColor: Colors.blue),
        );
      }
    } 
    catch (e) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location Fetching Went Wrong $e"), backgroundColor: Colors.red),
      );
    } 
    finally 
    {
      setState(() => _isGettingLocation = false);
    }
  }

  // send data to Backend
  Future<void> _submitSession() async 
  {
    if (!isOnline && (_latitude == null || _longitude == null)) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Specify Location")),
      );
      return;
    }

    setState(() => _isCreating = true);
    try 
    {
      final response = await http.post(
        Uri.parse("${ApiConstsnts.baseUrl}/create-session-full"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "course_id": widget.courseId,
          "session_name": _nameController.text.isEmpty ? "Lecture Session" : _nameController.text,
          "start_time": DateTime.now().toIso8601String(),
          "end_time": DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          "location_enabled": !isOnline,
          "latitude": isOnline ? null : _latitude,
          "longitude": isOnline ? null : _longitude,
        }),
      );

      if (response.statusCode == 200) 
      {
        
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session successfully created"), backgroundColor: Colors.green),
        );
      }
      else
      {
        print("Error: ${response.body}");
      }
    }
     catch (e) 
    {
      print("Exception: $e");
    } 
    finally 
    {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B46),
      appBar: AppBar(title: Text("Creating Session For ${widget.courseName}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Session Name",
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.deepPurpleAccent),
              ),
              prefixIcon: const Icon(Icons.edit, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _typeCard("On Person", Icons.groups, !isOnline, () => setState(() => isOnline = false))),
                const SizedBox(width: 15),
                Expanded(child: _typeCard("Online", Icons.laptop, isOnline, () => setState(() => isOnline = true))),
              ],
            ),
            const Spacer(),
            if (!isOnline) ...[
              if (_latitude != null) 
                Text("The Specified Location: $_latitude, $_longitude", style: const TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _fetchCurrentLocation,
                icon: _isGettingLocation ? const CircularProgressIndicator() : const Icon(Icons.location_on),
                label: const Text("Identify My Current Location As Lecture Room Location"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _submitSession,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isCreating ? const CircularProgressIndicator() : const Text("Confirm And Creat Session"),
              ),
            ),
          ],
        ),
      ),
    );
  }
//UI for session card
  Widget _typeCard(String title, IconData icon, bool isSelected, VoidCallback onTap) 
  {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
          ],
        ),
      ),
    );
  }
}