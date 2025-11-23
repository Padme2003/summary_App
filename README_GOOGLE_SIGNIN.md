# 🔐 Configuración de Google Sign-In

## ✅ Lo Que Ya Está Hecho

1. ✅ Proyecto Firebase creado: `sumly-d7dee`
2. ✅ App Android agregada a Firebase
3. ✅ `google-services.json` descargado y configurado
4. ✅ `firebase_options.dart` actualizado con credenciales
5. ✅ Google Sign-In habilitado en Firebase Console (Authentication > Sign-in method)
6. ✅ Backend con endpoint `/api/auth/google` implementado
7. ✅ Frontend con botones de Google Sign-In en login/register

## 🚨 LO QUE FALTA (CRÍTICO PARA QUE FUNCIONE)

### Paso 1: Obtener el SHA-1

El SHA-1 es **obligatorio** para que Google Sign-In funcione en Android.

**Opción 1: Usando el script automático**

```bash
cd /home/user/summary_App
./get_sha1.sh
```

**Opción 2: Manualmente**

Si el script no funciona, ejecuta:

```bash
cd sumly_app
flutter build apk --debug
```

Luego:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Busca la línea que dice `SHA1:` y copia el valor.

---

### Paso 2: Agregar SHA-1 a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona proyecto **sumly**
3. Haz clic en ⚙️ **Project Settings**
4. Desplázate hasta **"Your apps"**
5. Selecciona tu app **Android** (com.example.sumly_app)
6. En la sección **"SHA certificate fingerprints"**:
   - Haz clic en **"Add fingerprint"**
   - Pega el SHA-1 que obtuviste
   - Guarda

**⏰ IMPORTANTE:** Espera **5-10 minutos** después de agregar el SHA-1 antes de probar.

---

### Paso 3: Compilar y Probar la App

```bash
cd sumly_app
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Cómo Probar Google Sign-In

1. Abre la app en tu dispositivo/emulador
2. Ve a la pantalla de **Login**
3. Toca el botón **"Continuar con Google"**
4. Selecciona tu cuenta de Google
5. Deberías ser redirigido a la app con sesión iniciada

### Si funciona:
- ✅ Verás tu nombre y email en el perfil
- ✅ El backend creará automáticamente un usuario si no existe

### Si NO funciona:
- ❌ Error "API_NOT_ENABLED" → Espera más tiempo (5-10 min) después de agregar SHA-1
- ❌ Error "DEVELOPER_ERROR" → SHA-1 no agregado o incorrecto
- ❌ Error "NETWORK_ERROR" → Verifica conexión a internet

---

## 📱 Información del Proyecto

- **Project ID**: `sumly-d7dee`
- **Android Package**: `com.example.sumly_app`
- **App ID**: `1:481057013930:android:2cf8b30b130b81a0f0d0d3`
- **Backend Endpoint**: `/api/auth/google`

---

## 🔧 Troubleshooting

### "Google Sign-In sigue sin funcionar después de 10 minutos"

1. **Verifica que el SHA-1 esté agregado correctamente:**
   - Ve a Firebase Console > Project Settings > Your apps
   - Debería aparecer el SHA-1 en la lista

2. **Desinstala y reinstala la app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Verifica los logs:**
   - En consola de Flutter, busca errores de Firebase
   - Debería mostrar: `✅ Firebase inicializado correctamente`

### "Error: PlatformException(sign_in_failed)"

- Verifica que Google Sign-In esté habilitado en Firebase Console
- Verifica que el SHA-1 sea del keystore correcto (debug vs release)

### "Error: No se puede conectar al backend"

- Verifica que el backend esté corriendo
- Verifica la URL en `api_config.dart`
- El endpoint `/api/auth/google` debe estar disponible

---

## 📚 Próximos Pasos Opcionales

Una vez que Google Sign-In funcione:

1. **Facebook Sign-In** (opcional)
2. **Apple Sign-In** (requerido para iOS App Store)
3. **SHA-1 de release** (para app en producción)

---

## 🎉 ¿Todo Listo?

Una vez que agregues el SHA-1 a Firebase Console:
1. Espera 5-10 minutos
2. Compila la app: `flutter run`
3. Prueba el botón "Continuar con Google"
4. ¡Disfruta de Google Sign-In funcionando!

Si tienes problemas, consulta la [documentación de Firebase](https://firebase.google.com/docs/auth/android/google-signin) o el archivo `FIREBASE_SETUP.md`.
