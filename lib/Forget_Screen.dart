import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rcet_shuttle_bus/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText; // Holds validation errors

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    setState(() {
      _errorText = _validateEmail(_emailController.text);
    });

    if (_errorText != null) return; // Stop execution if validation fails

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('reset_email', _emailController.text.trim());

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      showCustomSnackBar(
        context,
        'Password reset email sent. Please check your inbox.',
        Icons.email,
        Colors.green,
      );
    } catch (e) {
      setState(() {
        _errorText = e.toString(); // Display Firebase error inside the field
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove default back button
      title: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(), // Replace with your LoginPage widget
            ),
          );
        },
        child: const Text(
          "Return to Login page",
          style: TextStyle(
          color: Color(0xFF1A237E), // Blue color
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/b0ea7c31-2b2f-4503-815c-1338d7c72b35.jpeg',
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Your Password',
              style: TextStyle(color: Color(0xFF1A237E), fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Enter your email',
                prefixIcon: const Icon(Icons.email, color: Color(0xFF1A237E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                errorText: _errorText, // Displays validation errors inside the field
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      backgroundColor: const Color(0xFF1A237E),
                    ),
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}
}

void showCustomSnackBar(BuildContext context, String message, IconData icon, Color backgroundColor) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
