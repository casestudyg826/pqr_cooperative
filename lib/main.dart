import 'package:flutter/material.dart';

import 'controller/app_controller.dart';
import 'screen/login_screen.dart';
import 'screen/main_shell_screen.dart';

void main() {
  runApp(
    AppScope(controller: AppController(), child: const PqrCooperativeApp()),
  );
}

class PqrCooperativeApp extends StatelessWidget {
  const PqrCooperativeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PQR Cooperative',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF235347),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F3),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF17211D),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE0E4DD)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: app.auth.isLoggedIn ? const MainShellScreen() : const LoginScreen(),
    );
  }
}
