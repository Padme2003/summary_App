import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumly_app/main.dart';

void main() {
  group('SUMLY App Tests', () {
    testWidgets('Splash screen muestra el nombre de la app', (
      WidgetTester tester,
    ) async {
      // Construir la app
      await tester.pumpWidget(const SumlyApp());

      // Verificar que el splash screen muestra "Sumly"
      expect(find.text('Sumly'), findsOneWidget);
      expect(find.text('Resúmenes inteligentes'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    });

    testWidgets('Navegación de Splash a Login funciona', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());

      // Esperar 3 segundos (duración del splash)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verificar que ahora estamos en LoginScreen
      expect(find.text('Bienvenido a Sumly'), findsOneWidget);
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    });

    testWidgets('Login screen tiene campos de email y contraseña', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());

      // Saltar al login
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verificar campos
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
        findsOneWidget,
      );
    });

    testWidgets('Validación de email vacío', (WidgetTester tester) async {
      await tester.pumpWidget(const SumlyApp());

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Intentar login sin llenar campos
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      // Verificar mensaje de error
      expect(find.text('Por favor ingresa tu email'), findsOneWidget);
    });

    testWidgets('HomeScreen tiene 3 tabs de navegación', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());

      // Navegar directamente al home (simulando login exitoso)
      await tester.pumpAndSettle();

      // Navegar a home manualmente
      final context = tester.element(find.byType(SumlyApp));
      Navigator.of(context).pushReplacementNamed('/home');
      await tester.pumpAndSettle();

      // Verificar que hay 3 destinos de navegación
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('Upload screen tiene selector de modo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SumlyApp));
      Navigator.of(context).pushNamed('/upload');
      await tester.pumpAndSettle();

      // Verificar modos
      expect(find.text('Resumen IA'), findsOneWidget);
      expect(find.text('Audiolibro'), findsOneWidget);
      expect(find.text('Subir Archivo'), findsOneWidget);
      expect(find.text('Pegar Texto'), findsOneWidget);
    });
  });

  group('Widget Tests - Componentes', () {
    testWidgets('Botón de procesar está deshabilitado sin contenido', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SumlyApp));
      Navigator.of(context).pushNamed('/upload');
      await tester.pumpAndSettle();

      // Buscar botón
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Generar Resumen'),
      );

      // Verificar que está deshabilitado
      expect(button.onPressed, isNull);
    });

    testWidgets('Settings screen tiene opciones de configuración', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SumlyApp));
      Navigator.of(context).pushNamed('/settings');
      await tester.pumpAndSettle();

      // Verificar secciones
      expect(find.text('Apariencia'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Modo oscuro'), findsOneWidget);
    });
  });

  group('Validaciones', () {
    testWidgets('Validación de email inválido', (WidgetTester tester) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Ingresar email inválido
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalido',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      expect(find.text('Ingresa un email válido'), findsOneWidget);
    });

    testWidgets('Validación de contraseña corta', (WidgetTester tester) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        '123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
      await tester.pump();

      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });
  });

  group('Navegación', () {
    testWidgets('Navegación de Login a Register', (WidgetTester tester) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap en "Regístrate"
      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();

      // Verificar que estamos en RegisterScreen
      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Regístrate para comenzar'), findsOneWidget);
    });

    testWidgets('Botón de volver funciona', (WidgetTester tester) async {
      await tester.pumpWidget(const SumlyApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SumlyApp));
      Navigator.of(context).pushNamed('/upload');
      await tester.pumpAndSettle();

      // Verificar que hay botón de volver
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap en volver
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });
  });
}
