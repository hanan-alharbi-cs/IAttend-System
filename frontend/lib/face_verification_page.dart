import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:iattend_frontend/utils/constants.dart'; 
import 'package:http_parser/http_parser.dart';

class FaceVerificationPage extends StatefulWidget 
{
  final String sessionId;
  final String userId;

  const FaceVerificationPage({
    super.key,
    required this.sessionId,
    required this.userId,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> 
{
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _message = "Put Your Face In Front Of The Camera";

  @override
  void initState() 
  {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async 
  {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _message = "Camera Not Found");
        return;
      }
      
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) 
      {
        setState(() => _isInitialized = true);
      }
    } 
    catch (e) 
    {
      setState(() => _message = "Could Not Open The Camera $e");
    }
  }

  // التقاط وإرسال الصورة
  Future<void> _captureAndSend() async 
  {
    if (_isProcessing || !_isInitialized) return;

    setState(()
    {
      _isProcessing = true;
      _message = "Processing Face...";
    });

    try 
    {
      final XFile image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final uri = Uri.parse('${ApiConstsnts.baseUrl}${ApiConstsnts.markAttendes}');
      var request = http.MultipartRequest('POST', uri);
      request.fields['student_id'] = widget.userId;
      request.fields['session_id'] = widget.sessionId;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file', 
        bytes,
        filename: 'student_face.jpg',
        contentType: MediaType('image', 'jpeg'), 
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) 
      {
        var data = jsonDecode(response.body);
        
        if (data['status'] == 'success') 
        {
          setState(() => _message = "Face Matched Successfully");
          Future.delayed(const Duration(seconds: 1), () 
          {
            Navigator.pop(context, true);
          });
        } 
        else 
        {
          setState(() => _message = "Face Not Recognized");
        }
      }
      else
      {
        setState(() => _message = "Connection Error ${response.statusCode}");
      }
    } 
    catch (e) 
    {
      setState(() => _message = "Something Went Wrong $e");
    } 
    finally 
    {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() 
  {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(title: const Text("Liveness Detection")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 3),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _isInitialized 
                  ? AspectRatio(aspectRatio: 1, child: CameraPreview(_controller!))
                  : const Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndSend,
              icon: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt),
              label: const Text("Capture Photo For Verification"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}