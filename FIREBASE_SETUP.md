# 🔥 Guía de Configuración de Firebase

Esta guía te ayudará a configurar Firebase en tu proyecto Sumly para habilitar Google Sign-In y Push Notifications.

## 📋 Prerrequisitos

- Cuenta de Google/Gmail
- Acceso a [Firebase Console](https://console.firebase.google.com/)
- Proyecto Sumly funcionando localmente

## 🚀 Paso 1: Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto" o "Create a project"
3. Nombre del proyecto: `Sumly` (o el nombre que prefieras)
4. Habilita Google Analytics (opcional pero recomendado)
5. Acepta los términos y crea el proyecto

## 📱 Paso 2: Configurar Android

### 2.1 Agregar App Android

1. En la consola de Firebase, haz clic en el ícono de Android
2. Registra tu app con los siguientes datos:
   - **Package name**: `com.example.sumly_app` (o el que aparezca en `android/app/build.gradle`)
   - **App nickname**: `Sumly Android` (opcional)
   - **SHA-1**: (opcional por ahora, necesario para Google Sign-In)

### 2.2 Descargar google-services.json

1. Descarga el archivo `google-services.json`
2. Copia el archivo a: `sumly_app/android/app/google-services.json`

### 2.3 Modificar build.gradle (Proyecto)

Edita `android/build.gradle` y agrega:

```gradle
buildscript {
    dependencies {
        // ... otras dependencias
        classpath 'com.google.gms:google-services:4.4.0'  // Agregar esta línea
    }
}
```

### 2.4 Modificar build.gradle (App)

Edita `android/app/build.gradle` y agrega al final del archivo:

```gradle
apply plugin: 'com.google.gms.google-services'  // Agregar esta línea
```

## 🍎 Paso 3: Configurar iOS

### 3.1 Agregar App iOS

1. En la consola de Firebase, haz clic en el ícono de iOS
2. Registra tu app con los siguientes datos:
   - **Bundle ID**: Encuentra el valor en `ios/Runner.xcodeproj/project.pbxproj` (busca `PRODUCT_BUNDLE_IDENTIFIER`)
   - **App nickname**: `Sumly iOS` (opcional)

### 3.2 Descargar GoogleService-Info.plist

1. Descarga el archivo `GoogleService-Info.plist`
2. Copia el archivo a: `sumly_app/ios/Runner/GoogleService-Info.plist`
3. **IMPORTANTE**: Abre el proyecto en Xcode (`open ios/Runner.xcworkspace`)
4. Arrastra `GoogleService-Info.plist` al proyecto en Xcode (carpeta Runner)
5. Asegúrate de marcar "Copy items if needed"

## 🔐 Paso 4: Configurar Google Sign-In

### 4.1 Habilitar en Firebase Console

1. Ve a **Authentication** → **Sign-in method**
2. Habilita **Google** como proveedor
3. Agrega tu email de soporte del proyecto

### 4.2 Obtener SHA-1 para Android

Para obtener el SHA-1 certificate fingerprint:

```bash
cd android
./gradlew signingReport
```

Busca la línea que dice `SHA1:` en la sección `debug`.

### 4.3 Agregar SHA-1 a Firebase

1. Ve a **Project Settings** en Firebase Console
2. Selecciona tu app Android
3. Agrega el SHA-1 fingerprint en la sección "SHA certificate fingerprints"

### 4.4 iOS - Agregar URL Scheme

1. En `ios/Runner/Info.plist`, ya está configurado (no requiere cambios adicionales)
2. El código ya maneja el esquema automáticamente

## 🔔 Paso 5: Configurar Push Notifications (Firebase Cloud Messaging)

### 5.1 Android

1. En Firebase Console, ve a **Project Settings** → **Cloud Messaging**
2. La configuración básica ya está lista con `google-services.json`
3. No requiere pasos adicionales para Android

### 5.2 iOS

1. Ve a tu cuenta de [Apple Developer](https://developer.apple.com/)
2. Crea un **APNs Auth Key**:
   - Certificates, Identifiers & Profiles
   - Keys → Crear nueva key
   - Habilita "Apple Push Notifications service (APNs)"
   - Descarga el archivo `.p8`
3. En Firebase Console:
   - **Project Settings** → **Cloud Messaging**
   - Tab **iOS**
   - Sube el archivo `.p8` con el Key ID y Team ID

## ✅ Paso 6: Verificar Instalación

### 6.1 Compilar el proyecto

```bash
cd sumly_app
flutter pub get
```

### 6.2 Ejecutar en Android

```bash
flutter run
```

Deberías ver en la consola:
```
✅ Firebase inicializado correctamente
```

### 6.3 Ejecutar en iOS

```bash
flutter run -d ios
```

## 🧪 Paso 7: Probar Funcionalidades

### Google Sign-In

1. En la pantalla de login, toca "Continuar con Google"
2. Selecciona tu cuenta de Google
3. Deberías ser redirigido a la app con tu perfil

### Push Notifications

1. En la pantalla de perfil, verifica que las notificaciones estén habilitadas
2. Desde Firebase Console:
   - **Cloud Messaging** → **Send test message**
   - Ingresa tu FCM token (se mostrará en los logs de la app)
   - Envía la notificación de prueba

## 🐛 Troubleshooting

### Error: "google-services.json not found"

**Solución**: Asegúrate de que el archivo esté en `android/app/google-services.json`

### Error: "GoogleService-Info.plist not found"

**Solución**: Abre el proyecto en Xcode y arrastra el archivo al proyecto

### Google Sign-In no funciona en Android

**Solución**:
1. Verifica que agregaste el SHA-1 fingerprint
2. Espera 5-10 minutos después de agregar el SHA-1
3. Desinstala la app y vuelve a instalar

### Push Notifications no llegan en iOS

**Solución**:
1. Verifica que subiste el APNs Auth Key (.p8)
2. Asegúrate de tener permisos en Apple Developer
3. Prueba en un dispositivo real (no funciona en simulador)

## 📚 Recursos Adicionales

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)

## 🎉 ¡Listo!

Una vez completados estos pasos, tu app Sumly tendrá:
- ✅ Google Sign-In funcional
- ✅ Push Notifications configuradas
- ✅ Firebase Analytics (si lo habilitaste)

Si tienes problemas, revisa los logs de la consola o consulta la documentación de Firebase.
