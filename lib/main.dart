import 'package:flutter/material.dart';

import 'home_shell.dart';

void main() => runApp(const WayfarerApp());

class WayfarerApp extends StatelessWidget {
  const WayfarerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wayfarer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5BA8)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const HomeShell(),
    );
  }
}