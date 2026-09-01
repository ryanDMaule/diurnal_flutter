import 'package:flutter/material.dart';

import 'screens/today_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiurnalApp());
}

class DiurnalApp extends StatelessWidget {
  const DiurnalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diurnal',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter',
      ),
      home: const TodayScreen(),
    );
  }
}
