import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/firebase_options.dart';
import 'package:robolearn/services/connection_state.dart' as robot_conn;
import 'package:robolearn/services/language_notifier.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LanguageNotifier.instance.initialize();
  robot_conn.ConnectionState().markDisconnected();

  runApp(const RoboLearnApp());
}

class RoboLearnApp extends StatelessWidget {
  const RoboLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LangScope(
      notifier: LanguageNotifier.instance,
      child: MaterialApp(
        title: 'RoboLearn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DD0C4)),
          useMaterial3: true,
          textTheme: GoogleFonts.nunitoTextTheme(),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
