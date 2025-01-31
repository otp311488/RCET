import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId;

    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor!;
    } else {
      deviceId = 'unknown';
    }

    return deviceId;
  }

  Future<void> _saveToPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String deviceId = await _getDeviceId();

    await prefs.setString('name', _nameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('password', _passwordController.text.trim());
    await prefs.setString('role', _role);
    await prefs.setString('deviceId', deviceId);
  }

 
    

Future<void> _register() async {
  setState(() {
    _nameError = _nameController.text.trim().length < 3
        ? 'Name must be at least 3 characters'
        : null;
    _emailError = !_emailController.text.contains('@') || 
                  !_emailController.text.contains('gmail') || 
                  !_emailController.text.contains('.com')
        ? 'Enter a valid email'
        : null;
    _passwordError = _passwordController.text.length < 8
        ? 'Password must be at least 8 characters'
        : null;
  });

  if (_nameError != null || _emailError != null || _passwordError != null) {
    return;
  }

  try {
    // Check if the email is already registered in Firebase Auth
    final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text.trim());

    if (signInMethods.isNotEmpty) {
      setState(() {
        _emailError = 'Email is already registered';
      });
      return;
    }

    // Check if email is already registered in Firestore
    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: _emailController.text.trim())
        .get();

    if (existingUser.docs.isNotEmpty) {
      setState(() {
        _emailError = 'Email is already registered';
      });
      return;
    }

  } catch (e) {
    showCustomSnackBar(
      context,
      'Error checking email: ${e.toString()}',
      Icons.error,
      Colors.red,
    );
    return;
  }

  if (_role == 'driver') {
    try {
      final driverCountSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      if (driverCountSnapshot.docs.length >= 8) {
        showCustomSnackBar(
          context,
          'Registration failed: Maximum of 8 drivers are allowed.',
          Icons.error,
          Colors.red,
        );
        return;
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        'Error checking driver limit: ${e.toString()}',
        Icons.error,
        Colors.red,
      );
      return;
    }
  }

  try {
    await _saveToPreferences();

    // Register the user in Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,
      'deviceId': await _getDeviceId(),
      'uid': userCredential.user!.uid,
    });

    showCustomSnackBar(context, 'Registration successful.', Icons.check_circle, Colors.green);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthenticationScreen(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _role,
        ),
      ),
    );
  } catch (e) {
    showCustomSnackBar(
      context,
      'Failed to register user: ${e.toString()}',
      Icons.error,
      Colors.red,
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,  // Aligning the text to the top-left corner
              child: GestureDetector(
                onTap: () {
                  // Pop back to the previous screen (Homepage in your case)
                  Navigator.pop(context);
                },
                child: const Text(
                  "Return to Homepage",
                  style: TextStyle(
                    color: Color(0xFF1A237E), // Blue color
                    fontWeight: FontWeight.bold, // Bold text
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/073d88d7-bda9-4454-81a1-a8fc5db5c95e.jpeg',
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _nameController,
              hintText: 'Enter your name',
              icon: Icons.person,
              errorText: _nameError,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _emailController,
              hintText: 'Enter your email',
              icon: Icons.email,
              errorText: _emailError,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _passwordController,
              hintText: 'Enter your password',
              icon: Icons.lock,
              obscureText: !_isPasswordVisible,
              errorText: _passwordError,
              isPasswordField: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(
                labelText: 'Select your role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'student',
                  child: Text('Student'),
                ),
                DropdownMenuItem(
                  value: 'driver',
                  child: Text('Driver'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  minimumSize: const Size(250, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? errorText,
    bool isPasswordField = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF1A237E),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        errorText: errorText,
      ),
    );
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
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
