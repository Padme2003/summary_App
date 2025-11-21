import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Guardar token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Obtener token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Guardar usuario
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(user.toJson());
    await prefs.setString(_userKey, jsonData);
    debugPrint('💾 Usuario guardado en SharedPreferences: ${user.name} (ID: ${user.id})');
    debugPrint('   JSON: $jsonData');
  }

  // Obtener usuario guardado
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      debugPrint('📖 Usuario recuperado de SharedPreferences: ${user.name} (ID: ${user.id})');
      return user;
    }
    debugPrint('⚠️ No hay usuario guardado en SharedPreferences');
    return null;
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('🔐 Limpiando sesión...');
    await prefs.remove(_tokenKey);
    debugPrint('   ✓ Token eliminado');
    await prefs.remove(_userKey);
    debugPrint('   ✓ Usuario eliminado');
  }

  // Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Registrar usuario
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['data']['token'];
        final user = User.fromJson(data['data']['user']);

        debugPrint('✅ Registro exitoso - Usuario: ${user.name} (${user.email})');
        await _saveToken(token);
        await _saveUser(user);

        return {
          'success': true,
          'user': user,
          'message': 'Registro exitoso',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final user = User.fromJson(data['data']['user']);

        debugPrint('✅ Login exitoso - Usuario: ${user.name} (${user.email})');
        debugPrint('   Respuesta del servidor: ${data['data']['user']}');
        await _saveToken(token);
        await _saveUser(user);

        return {
          'success': true,
          'user': user,
          'message': 'Login exitoso',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Obtener perfil actual
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final response = await http.get(
        Uri.parse(ApiConfig.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        debugPrint('📋 Perfil obtenido desde API: ${user.name} (${user.email})');
        await _saveUser(user);

        return {
          'success': true,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Actualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (avatar != null) body['avatar'] = avatar;

      final response = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        await _saveUser(user);

        return {
          'success': true,
          'user': user,
          'message': 'Perfil actualizado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Cambiar contraseña
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No autenticado',
        };
      }

      final response = await http.put(
        Uri.parse(ApiConfig.changePassword),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña actualizada',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al cambiar contraseña',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Solicitar recuperación de contraseña
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado a tu email',
          'code': data['code'], // Solo en desarrollo
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al enviar código',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Resetear contraseña con código
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña reseteada exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al resetear contraseña',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Configurar GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger el flujo de autenticación
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Usuario canceló el sign-in
        return {
          'success': false,
          'message': 'Sign-in cancelado',
        };
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear credenciales de Firebase
      final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in con Firebase
      final firebase_auth.UserCredential userCredential =
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return {
          'success': false,
          'message': 'Error al autenticar con Firebase',
        };
      }

      // Obtener el ID token de Firebase para enviarlo al backend
      final String? idToken = await firebaseUser.getIdToken();

      if (idToken == null) {
        return {
          'success': false,
          'message': 'Error al obtener token',
        };
      }

      // Aquí deberías crear un endpoint en tu backend para login/register con Google
      // Por ahora, creamos un usuario mock con los datos de Google

      // Registrar o hacer login en tu backend
      // Este endpoint debe verificar el idToken con Firebase Admin SDK
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'name': firebaseUser.displayName ?? 'Usuario',
          'email': firebaseUser.email ?? '',
          'avatar': firebaseUser.photoURL ?? '',
        }),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'];
        final user = User.fromJson(data['data']['user']);

        await _saveToken(token);
        await _saveUser(user);

        return {
          'success': true,
          'user': user,
          'message': 'Login exitoso con Google',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al autenticar con el servidor',
        };
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': 'Error de autenticación: ${e.message}',
      };
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {
        'success': false,
        'message': 'Error al iniciar sesión con Google: $e',
      };
    }
  }

  // Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn().signOut();
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }
}
