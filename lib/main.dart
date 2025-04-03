import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyCFYTJkeXSgX0L-tDvMu5CwAcKCcRBGfzE",
          appId: "1:581226119738:web:03804996d9087aaca5ab03",
          messagingSenderId: "581226119738",
          projectId: "sugar-tracker-app",
        ),
      );
    }
  } catch (e) {
    if (e.toString().contains('Firebase App named "[DEFAULT]" already exists')) {
    } else {
      rethrow;
    }
  }

  runApp(const SugarTrackerApp());
}

class SugarTrackerApp extends StatelessWidget {
  const SugarTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sugar Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(),
    );
  }
}