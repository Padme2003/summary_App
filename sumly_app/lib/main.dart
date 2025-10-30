import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/audiobook_player_screen.dart';
import 'screens/processing_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SumlyApp(),
    ),
  );
}

class SumlyApp extends StatelessWidget {
  const SumlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sumly',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
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
      },
    );
  }
}
