import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iattend_frontend/utils/constants.dart';



class RegisterFacePage extends StatefulWidget 
{
  

  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> 
{
  XFile? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String _displayId = "Loading...";
  String? _currentStudentId;

  @override
void initState() 
{
  super.initState();
  _loadId(); 
  _displayId = _currentStudentId ?? "No ID Found";
}
Future<void> _loadId() async 
{
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString('user_id');
  if (id != null) 
  {
    setState(() 
    {
      _currentStudentId = id;
      _displayId = id; 
      
    });
  } 
  else 
  {
    setState(() 
    {
      _displayId = "No ID Found";
    });
  }
}

  Future<void> _pickImage() async 
  {
    try 
    {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) 
      {
        setState(() 
        {
          _selectedImage = pickedFile;
        });
      }
    } 
    catch (e) 
    {
      if (mounted) 
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registerFace() async 
  {
    

    if (_currentStudentId== null)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
        content: Text('Error: No login data found. pleas log in again'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        )
      );
      setState(() { _isLoading = false; });
      return;
    }

    if (_selectedImage == null) 
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() 
    {
      _isLoading = true;
    });

    try 
    {
      
      final uri = Uri.parse(ApiConstsnts.baseUrl + ApiConstsnts.registerFace);
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = _currentStudentId!;
      final imageBytes = await _selectedImage!.readAsBytes();
      final imageName = _selectedImage!.name;
      final mimeType = _getMimeType(imageName);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageBytes,
          filename: imageName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (mounted) 
      {
        setState(()
        {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) 
        {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face registered successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() 
          {
            _selectedImage = null;
            _isLoading = false;
          });
        } 
        else 
        {
          
          String errorMessage = 'Registration failed';
          try
           {
            final errorData = jsonDecode(response.body);
            if (errorData is Map && errorData.containsKey('detail')) 
            {
              errorMessage = errorData['detail'].toString();
            }
             else if (errorData is Map && errorData.containsKey('message')) 
            {
              errorMessage = errorData['message'].toString();
            } 
            else if (errorData is String) 
            {
              errorMessage = errorData;
            }
          } 
          catch (_) 
          {
            errorMessage = 'Error: ${response.statusCode}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } 
    catch (e) 
    {
      if (mounted)
      {
        setState(() 
        {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMimeType(String fileName)
   {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) 
    {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF4A148C), 
              Color(0xFF311B92), 
            ],
          ),
        ),
        child: SafeArea(
        child: Stack( 
          children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Face Biometric\nRegistration',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Student ID display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Student ID: $_displayId',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                                width: 250,
                                height: 250,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.face,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select image',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text(
                    'Select Image from Gallery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A148C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registerFace,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.face_retouching_natural),
                  label: _isLoading
                      ? const Text(
                          'Registering...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Text(
                          'Register Face',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionItem(
                        '1.',
                        'Select a clear photo from your gallery',
                      ),
                      _buildInstructionItem(
                        '2.',
                        'Ensure your face is clearly visible',
                      ),
                      _buildInstructionItem(
                        '3.',
                        'Good lighting improves recognition',
                      ),
                      _buildInstructionItem(
                        '4.',
                        'Tap "Register Face" to complete registration',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
        top: 10,
        left: 10,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ),
        ]
      ),
        ),
      )
    );
  }

  Widget _buildInstructionItem(String number, String text) 
  {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

