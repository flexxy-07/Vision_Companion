import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'firebase_env_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: FirebaseEnvOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const VisionCompanionApp());
}

class VisionCompanionApp extends StatelessWidget {
  const VisionCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: Text('Vision Companion')),
      ),
    );
  }
}