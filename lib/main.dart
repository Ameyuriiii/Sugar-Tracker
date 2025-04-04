/// Initializes Firebase before launching the app.
/// Starts the app from the WelcomeScreen.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'welcome_screen.dart';

void main() async {
  // Ensures widgets are properly bound before Firebase init
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase only if it hasn't been initialized already
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
    // Handle "already initialized" exception gracefully
    if (e.toString().contains('Firebase App named "[DEFAULT]" already exists')) {
      // Do nothing, Firebase is already initialized
    } else {
      rethrow;
    }
  }
// Launch the app
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
      // Start from welcome screen
      home: const WelcomeScreen(),
    );
  }
}