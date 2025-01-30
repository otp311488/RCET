import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:rcet_shuttle_bus/Driver_Dashboard.dart';
import 'package:rcet_shuttle_bus/Signup_Screen.dart';
import 'package:rcet_shuttle_bus/Student_Dashboard.dart';

import '../welcome_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  Future<void> checkLoginStatus(BuildContext context) async {
    // Check if the user is logged in with Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch user data from Firestore to get the role
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc['role']; // Retrieve role from Firestore

          // Navigate based on the user's role
          if (role == 'driver') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DriverLocationMarker()),
            );
          } else if (role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          } else {
            // If role is unknown, navigate to signup screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
            );
          }
        } else {
          // If Firestore document doesn't exist, log out and go to WelcomeScreen
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } catch (e) {
        // Handle Firestore errors
        print('Error fetching user data: $e');
        await FirebaseAuth.instance.signOut(); // Log out if there's an error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      // If not logged in, navigate to WelcomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check login status as soon as the splash screen is shown
    Future.delayed(const Duration(seconds: 3), () {
      checkLoginStatus(context);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/c44674bf-abc7-4fe5-9a6f-b28dabbc6d3e.jpeg', // Update the path as per your asset location
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
