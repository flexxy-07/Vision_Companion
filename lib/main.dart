import 'package:flutter/material.dart';
import 'package:vision_companion/core/theme/app_theme.dart';

void main() {
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