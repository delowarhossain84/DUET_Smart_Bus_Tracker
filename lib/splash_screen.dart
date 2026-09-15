import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:duet_smart_bus_tracker/login_screen.dart';
import 'package:duet_smart_bus_tracker/admin_screen.dart';
import 'package:duet_smart_bus_tracker/driver_screen.dart';
import 'package:duet_smart_bus_tracker/main_screen.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';
import 'package:duet_smart_bus_tracker/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Widget destination;
        
        // Auto-Login logic
        if (AuthService.currentUser != null && AuthService.bearerToken != null) {
          final role = AuthService.currentUser!.role;
          if (role == UserRole.admin) {
            destination = const AdminScreen();
          } else if (role == UserRole.driver) {
            destination = const DriverScreen();
          } else {
            destination = const MainScreen();
          }
        } else {
          destination = kIsWeb ? const AdminScreen() : const LoginScreen();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Primary DUET Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Title
            const Text(
              "DUET Smart Bus Tracker",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Reliable Campus Mobility",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 60),
            // Loading Indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
