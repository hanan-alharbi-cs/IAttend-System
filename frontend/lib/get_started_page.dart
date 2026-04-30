import 'package:flutter/material.dart';
import 'login_page.dart';
import 'creat_account.dart';

class GetStartedPage extends StatelessWidget
{
  const GetStartedPage({super.key});
  void _navigateToCreateAccount(BuildContext context)
  {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> const CreateAccountPage()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Navigate to sign Up Page")));
  }

  void _navigateToLogin(BuildContext context)
  {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> const LoginPage()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Navigate to Login Page")));
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E004B),
              Color(0xFF5A009C),
              Color(0xFF8A2BE2),
            ]
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
             children: [
              const Spacer(flex: 2),
              const Icon(
             Icons.school_rounded, 
            size: 80, 
            color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
           'IAttend',
           style: TextStyle(
           fontSize: 50,
           fontWeight: FontWeight.w900, 
           color: Colors.white,
           fontFamily: 'serif', 
           letterSpacing: 1.5,
           shadows:[
           Shadow(
            blurRadius: 10.0,
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(2.0, 2.0),
          ),
        ],
      ),
     ),
     const Spacer(flex: 3),
     _buildDynamicButton(
      context:context,
      text:'SIGN UP',
      icon: Icons.person_add_outlined,
      onPressed: () =>_navigateToCreateAccount(context),
     ),
     const SizedBox(height: 16),
     _buildDynamicButton(
      context: context,
      text: 'LOGIN',
      icon: Icons.login_outlined,
      onPressed:() => _navigateToLogin(context)
     ),
     const Spacer(flex: 1),
             ], 
            ), 
          ), 
        ), 
      ), 
    ); 
  } 

  Widget _buildDynamicButton
  ({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) 
  {
    return Container
    (
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration
      (
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material
      (
        color: Colors.transparent,
        child: InkWell
        (
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle
                (
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
