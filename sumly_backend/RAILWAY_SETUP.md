# 🚂 Configuración para Railway

## Variables de Entorno Requeridas

Configura estas variables en Railway (Settings → Variables):

### 1. Variables Básicas
```bash
PORT=5000
NODE_ENV=production
```

### 2. Base de Datos (MongoDB Atlas)
```bash
MONGODB_URI=mongodb+srv://usuario:contraseña@cluster.mongodb.net/sumly_db?retryWrites=true&w=majority
```

**IMPORTANTE:** En MongoDB Atlas, asegúrate de:
- Ir a Network Access → Add IP Address → Allow Access from Anywhere (0.0.0.0/0)

### 3. Autenticación
```bash
JWT_SECRET=tu_secreto_seguro_aqui_cambialo_en_produccion
```

### 4. IA - Google Gemini
```bash
GEMINI_API_KEY=tu_api_key_de_gemini
```

### 5. Text-to-Speech - Google Cloud (OPCIONAL)

**Opción A: Con credenciales completas**
```bash
GOOGLE_TTS_CREDENTIALS={"type":"service_account","project_id":"tu-proyecto","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...@....iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"...","universe_domain":"googleapis.com"}
```

**Opción B: Sin Text-to-Speech**
- No configures `GOOGLE_TTS_CREDENTIALS`
- El servicio de Text-to-Speech estará deshabilitado
- Las demás funcionalidades seguirán funcionando

---

## 🚀 Pasos para Desplegar

### 1. Conectar Repositorio
1. Ve a [Railway](https://railway.app)
2. New Project → Deploy from GitHub repo
3. Selecciona tu repositorio `summary_App`
4. Railway detectará automáticamente el proyecto

### 2. Configurar Root Directory
1. Ve a Settings
2. En "Root Directory" configura: `sumly_backend`
3. Guarda los cambios

### 3. Agregar Variables de Entorno
1. Ve a Variables
2. Agrega cada variable mencionada arriba
3. Para `GOOGLE_TTS_CREDENTIALS`, pega TODO el JSON en una sola línea

### 4. Desplegar
1. Railway desplegará automáticamente
2. Espera a que termine la compilación
3. El script `setup-railway.js` se ejecutará automáticamente y:
   - Creará la carpeta `uploads/`
   - Creará la carpeta `credentials/`
   - Generará el archivo `google-tts.json` desde `GOOGLE_TTS_CREDENTIALS`

### 5. Obtener URL Pública
1. Ve a Settings → Networking
2. Haz clic en "Generate Domain"
3. Railway te dará una URL como: `https://tu-app.up.railway.app`

---

## ✅ Verificar que Funciona

Visita: `https://tu-app.up.railway.app/`

Deberías ver:
```json
{
  "message": "API de SUMLY funcionando correctamente",
  "version": "1.0.0",
  "endpoints": {
    "auth": "/api/auth",
    "users": "/api/users",
    "documents": "/api/documents",
    "summaries": "/api/summaries",
    "audiobooks": "/api/audiobooks"
  }
}
```

---

## 🐛 Solución de Problemas

### El despliegue falla con "Cannot find module canvas"
- Railway instalará `canvas` automáticamente durante el build
- Si falla, verifica que `canvas` esté en `package.json` dependencies

### MongoDB no se conecta
- Verifica que MongoDB Atlas permita IPs desde cualquier lugar (0.0.0.0/0)
- Verifica que `MONGODB_URI` esté correctamente configurada

### Google TTS no funciona
- Verifica que `GOOGLE_TTS_CREDENTIALS` sea JSON válido
- Asegúrate de que las credenciales tengan los permisos correctos en Google Cloud
- Si no necesitas TTS, simplemente no configures la variable

---

## 📱 Conectar App Flutter

En tu app Flutter, cambia la URL base:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://tu-app.up.railway.app';
}
```

¡Listo! 🎉
