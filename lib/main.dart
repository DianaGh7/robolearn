import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/firebase_options.dart';
import 'package:robolearn/services/connection_state.dart' as conn_state;
import 'package:robolearn/services/language_notifier.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  conn_state.ConnectionState().markDisconnected();

  await LanguageNotifier.instance.initialize();

  runApp(const RoboLearnApp());
}

class RoboLearnApp extends StatefulWidget {
  const RoboLearnApp({super.key});

  @override
  State<RoboLearnApp> createState() => _RoboLearnAppState();
}

class _RoboLearnAppState extends State<RoboLearnApp> {
  final _lang = LanguageNotifier.instance;

  @override
  Widget build(BuildContext context) {
    return LangScope(
      notifier: _lang,
      child: AnimatedBuilder(
        animation: _lang,
        builder: (context, _) => MaterialApp(
          title: 'RoboLearn',
          debugShowCheckedModeBanner: false,
          locale: _lang.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DD0C4)),
            useMaterial3: true,
            textTheme: GoogleFonts.nunitoTextTheme(),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
