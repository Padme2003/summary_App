# 🔧 DIAGNÓSTICO Y SOLUCIÓN DE PROBLEMAS - SUMLY

## 🚨 PROBLEMAS REPORTADOS

1. ❌ **No cargan los resúmenes**
2. ❌ **No se generan resúmenes**
3. ❌ **Algunas pantallas dan error**

---

## 📋 CHECKLIST DE DIAGNÓSTICO

### **PASO 1: Verifica que el Backend esté corriendo**

```bash
cd sumly_backend
npm start
```

**✅ Debes ver:**
```
🚀 Servidor corriendo en http://192.168.18.54:5000
✅ MongoDB conectado exitosamente
```

**❌ Si ves errores:**

#### Error: "Cannot find module"
```bash
npm install
npm start
```

#### Error: "EADDRINUSE" (puerto ocupado)
```bash
# Windows
netstat -ano | findstr :5000
taskkill /F /PID [número_del_PID]

# Linux/Mac
lsof -ti:5000 | xargs kill -9
```

#### Error: MongoDB connection failed
- Verifica que el MONGODB_URI en `.env` sea correcto
- Prueba la conexión: https://cloud.mongodb.com/

---

### **PASO 2: Verifica la IP del Backend**

1. **Obtén tu IP local:**

```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

2. **Busca tu IPv4** (ejemplo: `192.168.18.54`)

3. **Actualiza en Flutter:**

Abre `sumly_app/lib/config/api_config.dart` y verifica:
```dart
static const String baseUrl = 'http://TU_IP_AQUI:5000/api';
```

**IMPORTANTE:** La IP debe ser la misma en:
- El backend (donde corre)
- La configuración de Flutter
- Tu teléfono/emulador debe estar en la MISMA red WiFi

---

### **PASO 3: Prueba el Backend Manualmente**

Abre el navegador o Postman:

**Prueba 1 - Health Check:**
```
http://192.168.18.54:5000/api/
```
Debería responder: `{ "message": "SUMLY API is running" }`

**Prueba 2 - Login:**
```
POST http://192.168.18.54:5000/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "Test123!"
}
```

**Prueba 3 - Listar Resúmenes:**
```
GET http://192.168.18.54:5000/api/summaries
Authorization: Bearer [tu_token_aqui]
```

---

### **PASO 4: Revisa Errores en Flutter**

Cuando ejecutas `flutter run`, busca estos errores:

#### **Error 1: SocketException / Connection refused**
```
SocketException: Failed to connect to /192.168.18.54:5000
```

**Solución:**
1. Verifica que el backend esté corriendo
2. Verifica que la IP sea correcta
3. Asegúrate de estar en la misma red WiFi
4. En Android, verifica que `android:usesCleartextTraffic="true"` esté en AndroidManifest (ya lo pusimos)

#### **Error 2: TimeoutException**
```
TimeoutException after 30 seconds
```

**Solución:**
1. El backend puede estar muy lento
2. Verifica tu conexión a internet
3. Si usas MongoDB Atlas, verifica que no esté en modo "pause"

#### **Error 3: 404 Not Found**
```
Response status: 404
```

**Solución:**
- La ruta está mal escrita
- El endpoint no existe en el backend
- Verifica que el backend tenga todas las rutas en `src/routes/`

#### **Error 4: 500 Internal Server Error**
```
Response status: 500
```

**Solución:**
- Error en el backend
- Revisa la consola del backend para ver el error específico
- Puede ser error de Gemini API, MongoDB, etc.

---

## 🔍 DIAGNÓSTICO POR PANTALLA

### **Dashboard - No carga estadísticas**

**Síntomas:**
- La pantalla se queda en blanco
- Loading infinito
- Error de conexión

**Solución:**
1. Verifica que `/api/documents` funcione
2. Verifica que `/api/summaries` funcione
3. Revisa la consola de Flutter para ver el error exacto

**Prueba manual:**
```bash
# En el backend
cd sumly_backend
npm start

# Deberías ver el log cuando la app intenta cargar
```

---

### **Generar Resumen - No se genera**

**Síntomas:**
- La pantalla de procesamiento se queda en 0%
- Error después de unos segundos
- "Error al iniciar generación"

**Causas posibles:**

#### 1. **Gemini API Key inválida**
Verifica en `sumly_backend/.env`:
```
GEMINI_API_KEY=AIzaSyD7wSqYAv4P3wy1S8JVbxQrwY152OfnOyc
```

**Prueba la API key:**
```bash
curl -X POST \
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyD7wSqYAv4P3wy1S8JVbxQrwY152OfnOyc' \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hola"}]}]}'
```

Si da error 404, la API key es inválida o el modelo no existe.

#### 2. **Documento no tiene texto extraído**
- Verifica que el documento tenga `content` en MongoDB
- Si es PDF, verifica que `pdf-parse` esté instalado

#### 3. **Error en el modelo de Gemini**
Verifica en `sumly_backend/src/controllers/summary.controller.js`:
```javascript
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
```

Si el modelo cambió o fue deprecado, actualiza a la versión actual.

---

### **Ver Resúmenes - Lista vacía o error**

**Síntomas:**
- La lista aparece vacía aunque debería tener resúmenes
- Error al cargar
- "No hay resúmenes aún" cuando sí hay

**Solución:**

1. **Verifica en MongoDB:**
```javascript
// Conéctate a MongoDB Atlas
// Ve a "Browse Collections"
// Busca la colección "summaries"
// Deberías ver documentos ahí
```

2. **Verifica el endpoint:**
```
GET http://192.168.18.54:5000/api/summaries
Authorization: Bearer [token]
```

3. **Verifica que el token sea válido:**
- El token expira después de cierto tiempo
- Cierra sesión y vuelve a iniciar sesión

---

## 🛠️ SOLUCIONES RÁPIDAS

### **Solución 1: Reiniciar Todo**

```bash
# 1. Para el backend
# Ctrl+C en la terminal del backend

# 2. Para la app Flutter
# Ctrl+C en la terminal de Flutter

# 3. Inicia el backend
cd sumly_backend
npm start

# 4. Espera a ver "Servidor corriendo"

# 5. Inicia Flutter
cd ../sumly_app
flutter run

# 6. Espera a que compile y abra
```

---

### **Solución 2: Limpiar Caché de Flutter**

```bash
cd sumly_app
flutter clean
flutter pub get
flutter run
```

---

### **Solución 3: Reinstalar dependencias del Backend**

```bash
cd sumly_backend
rm -rf node_modules
npm install
npm start
```

---

### **Solución 4: Verificar MongoDB**

1. Ve a https://cloud.mongodb.com/
2. Inicia sesión
3. Ve a tu cluster
4. Verifica que no esté "Paused"
5. Ve a "Network Access" y verifica que tu IP esté permitida (o usa 0.0.0.0/0 para desarrollo)

---

### **Solución 5: Usar ngrok (si nada funciona)**

Si las soluciones anteriores no funcionan, usa ngrok:

```bash
# 1. Instala ngrok
# https://ngrok.com/download

# 2. Inicia ngrok
ngrok http 5000

# 3. Copia la URL (ejemplo: https://abc123.ngrok-free.app)

# 4. Actualiza en Flutter
# sumly_app/lib/config/api_config.dart
static const String baseUrl = 'https://abc123.ngrok-free.app/api';

# 5. Reinicia la app
flutter run
```

---

## 📝 LOG DE ERRORES COMUNES

### Error: "CORS policy"
**Causa:** El backend bloquea peticiones del frontend
**Solución:** Ya está configurado CORS en el backend, no debería pasar

### Error: "Invalid token"
**Causa:** Token expirado o inválido
**Solución:** Cierra sesión y vuelve a iniciar sesión

### Error: "Network error"
**Causa:** Backend no está corriendo o IP incorrecta
**Solución:** Ver PASO 1 y PASO 2 arriba

### Error: "Model not found: gemini-2.5-flash"
**Causa:** El modelo de Gemini fue deprecado
**Solución:** Actualizar a la versión actual (consulta documentación de Gemini)

---

## 🎯 CHECKLIST FINAL

Marca cada item cuando lo hayas verificado:

- [ ] Backend está corriendo (`npm start`)
- [ ] MongoDB está conectado (ves mensaje de conexión exitosa)
- [ ] La IP en `api_config.dart` es correcta
- [ ] Tu teléfono/emulador está en la misma red WiFi
- [ ] El navegador puede acceder a `http://IP:5000/api/`
- [ ] `flutter clean && flutter pub get` ejecutado
- [ ] `flutter run` sin errores de compilación
- [ ] AndroidManifest tiene `usesCleartextTraffic="true"`
- [ ] El archivo `.env` tiene GEMINI_API_KEY válida
- [ ] MongoDB Atlas permite conexiones desde tu IP

---

## 📞 SI NADA FUNCIONA

**Comparte:**
1. El error EXACTO que ves en la consola de Flutter
2. El error que ves en la consola del backend (si hay)
3. La pantalla donde ocurre el error
4. Screenshot del error (si es visual)

**Formato:**
```
Pantalla: [nombre]
Error en Flutter: [copiar y pegar]
Error en Backend: [copiar y pegar]
```

Con esa información podré darte una solución precisa.

---

## 🚀 PRÓXIMOS PASOS

Una vez que todo funcione:

1. ✅ Prueba generar un resumen
2. ✅ Prueba ver la lista de resúmenes
3. ✅ Prueba el modo oscuro en todas las pantallas
4. ✅ Prueba el audio (si está implementado)
5. ✅ Prueba favoritos
6. ✅ Prueba editar perfil

**¡Avísame qué error específico ves y lo arreglo inmediatamente!** 🔧
