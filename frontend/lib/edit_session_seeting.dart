import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iattend_frontend/utils/constants.dart';

class editSessionPage extends StatefulWidget 
{
  final Map sessionData; // Map: to recive all session data
  final String courseName;

  const editSessionPage({
    super.key,
    required this.sessionData,
    required this.courseName,
  });

  @override
  State<editSessionPage> createState() => _editSessionPageState();
}

class _editSessionPageState extends State<editSessionPage> 
{
  double? _latitude;
  double? _longitude;
  bool isOnline = false;
  bool _isUpdating = false;
  bool _isGettingLocation = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() 
  {
    super.initState();
    
    _nameController.text = widget.sessionData['session_name'] ?? "";
    //isOnline = !(widget.sessionData['location_enabled'] ?? true);
    isOnline = widget.sessionData['session_type'] == "Online";
    _latitude = widget.sessionData['latitude'];
    _longitude = widget.sessionData['longitude'];
  }

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
          const SnackBar(content: Text("Location updated successfully"), backgroundColor: Colors.blue),
        );
      }
    } 
    catch (e) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location error: $e"), backgroundColor: Colors.red),
      );
    } 
    finally 
    {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _updateSession() async 
  {
    if (!isOnline && (_latitude == null || _longitude == null)) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please determine the location first")),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try 
    {
      final sessionId = widget.sessionData['session_id'];
      final response = await http.put(
        Uri.parse("${ApiConstsnts.baseUrl}/edit-session/$sessionId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_name": _nameController.text.isEmpty ? "Lecture Session" : _nameController.text,
          "location_enabled": !isOnline,
          "latitude": isOnline ? null : _latitude,
          "longitude": isOnline ? null : _longitude,
          "session_type": isOnline ? "Online" : "In-Person",
        }),
      );

      if (response.statusCode == 200) 
      {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session updated successfully"), backgroundColor: Colors.green),
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
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B46),
      appBar: AppBar(title: Text("Edit Session: ${widget.courseName}")),
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
                Expanded(child: _typeCard("On-site", Icons.groups, !isOnline, () => setState(() => isOnline = false))),
                const SizedBox(width: 15),
                Expanded(child: _typeCard("Online", Icons.laptop, isOnline, () => setState(() => isOnline = true))),
              ],
            ),
            const Spacer(),
            if (!isOnline) ...[
              if (_latitude != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text("Location: $_latitude, $_longitude", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ),
              ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _fetchCurrentLocation,
                icon: _isGettingLocation 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.location_on),
                label: const Text("UPDATE CURRENT LOCATION"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size(double.infinity, 50)),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateSession,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                child: _isUpdating 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
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
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
