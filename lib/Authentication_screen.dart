import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rcet_shuttle_bus/login_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String role;

  const AuthenticationScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  }) : super(key: key);

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _canResend = true; // Always allow resend

  @override
  void initState() {
    super.initState();
    _registerAndSendVerificationEmail();
  }

void _registerAndSendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackBar(
          message: 'Verification email sent. Please check your email.',
          icon: Icons.email,
          color: Colors.green,
        );
      }
    } catch (e) {
      _showSnackBar(
        message: 'Error: ${e.toString()}',
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
 void _verifyAndStoreUser() async {
  setState(() => _isLoading = true);
  try {
    User? user = _auth.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': widget.name,
        'email': widget.email,
        'role': widget.role,
      });

      _showSnackBar(
        message: 'Verification successful!',
        icon: Icons.check_circle,
        color: Colors.green,
      );

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      _showSnackBar(
        message: 'Please verify your email before proceeding.',
        icon: Icons.info,
        color: Colors.red,
      );
    }
  } catch (e) {
    _showSnackBar(
      message: 'Error: ${e.toString()}',
      icon: Icons.error,
      color: Colors.red,
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/d645ddd9-e1de-4f92-9190-d61b9115d680.jpeg',
                height: 220,
              ),
              const SizedBox(height: 20),
              const Text(
                "Verify Your Email",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "A verification email has been sent to:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyAndStoreUser,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Color(0xFF1A237E),
                ),
                child: const Text("Verify and Continue", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
