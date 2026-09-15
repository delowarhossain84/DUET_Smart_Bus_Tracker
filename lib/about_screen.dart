import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.info_outline, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "DUET Smart Bus Tracker",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "About the App",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "This application is designed for the students and staff of Dhaka University of Engineering & Technology (DUET) to track campus shuttle buses in real-time. Using GPS technology, the app provides accurate bus locations and estimated arrival times.",
            ),
            const SizedBox(height: 20),
            const Text(
              "Developed By",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Masum, Morshdul,Delowar, DUET."),
          ],
        ),
      ),
    );
  }
}
