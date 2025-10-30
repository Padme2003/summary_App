import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (opcional - solo si los archivos de configuración existen)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ Firebase inicializado correctamente');

    // Configurar handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inicializar servicio de notificaciones
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️  Firebase no configurado (esto es normal si no has agregado google-services.json)');
    debugPrint('   Para habilitar Firebase, sigue las instrucciones en FIREBASE_SETUP.md');
  }

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
