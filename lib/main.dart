import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:duet_smart_bus_tracker/splash_screen.dart';
import 'package:duet_smart_bus_tracker/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init(); // Session লোড করা হচ্ছে
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DUET Smart Bus Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF00ACC1),
          surface: const Color(0xFFF9F9FF),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9F9FF),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF191C21),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF191C21)),
        ),
      ),
      // Automatically show splash screen on app start
      home: const SplashScreen(),
    );
  }
}
