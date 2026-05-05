import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'student_home_page.dart'; 
import 'faculty_home_page.dart';

class CreateAccountPage extends StatefulWidget 
{
  
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
{
  final TextEditingController userIdController = TextEditingController(); 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

Future<void> createAccount() async
{
  final supabase = Supabase.instance.client;
  try
  {
    
    String id = userIdController.text.trim();
    String name = nameController.text.trim();
    String password = passwordController.text.trim();

    if(id.isEmpty || name.isEmpty || password.isEmpty)
    {
      _showError("Pleas fill in all the fields");
      return;
    }

    String virtualEmail = "$id@iattend.com";
    String assignedRole = " ";

    if(id.startsWith('4') && id.length == 7)
    {
      assignedRole = 'student'; 
    }
    else if(id.startsWith('1') && id.length == 5)
    {
     assignedRole ='faculty';
    }
    else
    {
      _showError("ID format is incorrect");
      return;
    }

    
    final AuthResponse res = await supabase.auth.signUp(email: virtualEmail,password: password,
    data:
    {
      'username': id, 
      'full_name': name,
      'role':assignedRole,
    },
    );

    if(res.user != null)
    {
      await supabase.from('users').insert({
        'user_id': res.user!.id,
        'academic_id': int.parse(id),      
        'name': name,
        'email': virtualEmail,
        'password': password,         
        'user_type': assignedRole,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', res.user!.id); 
      await prefs.setString('student_academic_id', id); 
      await prefs.setString('full_name', name);
      await prefs.setString('user_email', virtualEmail);
      await prefs.setString('role', assignedRole);
      await prefs.setBool('is_logged_in', true);
      

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar
      (
      const SnackBar(content: Text("   Account created successfully"), backgroundColor: Colors.green),);
      if(assignedRole=='student')
      {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomePage()));
      }else if (assignedRole == 'faculty')
      {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FacultyHomePage()));
      }
     }
  }

  on AuthException catch (error) 
  {
    _showError(error.message);
  } catch (error) 
  {
    _showError("Error");
  }
}

@override
  Widget build(BuildContext context)
  {
    
     return Scaffold
     (
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding
      (
        padding: const EdgeInsets.all(20),
        child: Column
        (
          children: [
            TextField
            (
              controller: userIdController,
              decoration: const InputDecoration(labelText: "Enter ID"),
            ),
            const SizedBox(height: 10),
            TextField
            (
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 10),
            TextField
            (
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton
            (
              onPressed: createAccount,
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }

void _showError(String message) 
{
    if (mounted) 
    {
      ScaffoldMessenger.of(context).showSnackBar
      (
        SnackBar
        (
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
}
}
