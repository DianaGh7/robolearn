import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RoboLearnApp());
}

class RoboLearnApp extends StatelessWidget {
  const RoboLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoboLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DD0C4)),
        useMaterial3: true,
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}