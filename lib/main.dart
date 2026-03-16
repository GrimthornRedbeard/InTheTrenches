import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/menu_screen.dart';

void main() {
  runApp(const ProviderScope(child: TrenchDefenseApp()));
}

class TrenchDefenseApp extends StatelessWidget {
  const TrenchDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trench Defense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4A7C3F),
          secondary: const Color(0xFF8B7355),
          surface: const Color(0xFF1A2410),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A2410),
        fontFamily: 'Roboto',
      ),
      home: const MenuScreen(),
    );
  }
}
