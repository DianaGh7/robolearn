import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:robolearn/firebase_options.dart';
import 'package:robolearn/services/connection_state.dart' as robot_conn;
import 'package:robolearn/services/language_notifier.dart';
import 'package:robolearn/services/notification_service.dart';
import 'package:robolearn/services/session_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LanguageNotifier.instance.initialize();
  robot_conn.ConnectionState().markDisconnected();
  await NotificationService().init();
  await NotificationService().cancelAll();

  runApp(const RoboLearnApp());
}

class RoboLearnApp extends StatefulWidget {
  const RoboLearnApp({super.key});

  @override
  State<RoboLearnApp> createState() => _RoboLearnAppState();
}

class _RoboLearnAppState extends State<RoboLearnApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final childName = SessionService().lastKnownChildName;
      SessionService().endSession();
      NotificationService().scheduleReminder(childName: childName);
    } else if (state == AppLifecycleState.resumed) {
      NotificationService().cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageNotifier.instance,
      builder: (context, _) {
        return LangScope(
          notifier: LanguageNotifier.instance,
          child: MaterialApp(
            title: 'RoboLearn',
            debugShowCheckedModeBanner: false,
            locale: LanguageNotifier.instance.locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF4DD0C4)),
              useMaterial3: true,
              textTheme: GoogleFonts.nunitoTextTheme(),
            ),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
