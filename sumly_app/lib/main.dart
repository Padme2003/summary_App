import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/audiobook_player_screen.dart';
import 'screens/processing_screen.dart';

void main() {
  runApp(const SumlyApp());
}

class SumlyApp extends StatelessWidget {
  const SumlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sumly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        // Animaciones de navegación globales
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/audiobook': (context) => const AudiobookPlayerScreen(),
      },
      // Rutas con argumentos
      onGenerateRoute: (settings) {
        if (settings.name == '/processing') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              mode: args?['mode'] ?? 'summary',
              documentId: args?['documentId'] ?? '',
            ),
          );
        }
        if (settings.name == '/summary') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => SummaryScreen(
              summaryId: args?['id'],
            ),
          );
        }
        return null;
      },
    );
  }
}
