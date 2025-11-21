# 🚀 QUICK START: Desplegar SUMLY a la Nube

## 🔴 PROBLEMA QUE ESTO SOLUCIONA

**Tu app NO funciona si:**
- ❌ Tu PC no está encendida
- ❌ Tu teléfono no está en tu WiFi de casa
- ❌ El backend no está corriendo

**Después de este deployment:**
- ✅ La app funciona desde CUALQUIER WiFi
- ✅ Funciona con datos móviles
- ✅ Tu PC puede estar apagada
- ✅ Backend disponible 24/7

---

## 📋 PASOS RÁPIDOS (15 minutos)

### **1. Obtener los cambios**

```bash
cd /home/user/summary_App
git pull
```

### **2. Crear cuenta en Railway**

1. Ve a: https://railway.app
2. Click en "Start a New Project"
3. Login con tu cuenta de GitHub

### **3. Crear proyecto en Railway**

1. Click en "New Project"
2. Selecciona "Deploy from GitHub repo"
3. Autoriza Railway a acceder a tu GitHub
4. Selecciona el repositorio: `summary_App`
5. Railway detectará automáticamente Node.js
6. Espera 3-5 minutos mientras se despliega

### **4. Configurar Variables de Entorno**

En Railway, ve a tu proyecto → Tab "Variables" → Agregar estas variables:

```
PORT=5000
MONGODB_URI=mongodb+srv://jppmoposita:Josselyn2003@cluster0.njfp3my.mongodb.net/sumly_db?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=sumly_secret_key_2025_change_in_production
GEMINI_API_KEY=AIzaSyD7wSqYAv4P3wy1S8JVbxQrwY152OfnOyc
NODE_ENV=production
```

Después de agregar las variables, Railway hará un **re-deploy automático** (espera 2-3 minutos).

### **5. Configurar MongoDB Atlas**

1. Ve a: https://cloud.mongodb.com/
2. Login con tu cuenta
3. Ve a "Network Access" (menú izquierdo)
4. Click en "Add IP Address"
5. Selecciona **"Allow access from anywhere"** (0.0.0.0/0)
6. Click "Confirm"

⚠️ **Esto es NECESARIO** para que Railway pueda conectarse a MongoDB.

### **6. Obtener URL de Railway**

1. En Railway, ve a tu proyecto
2. Click en el tab "Settings"
3. En "Domains", verás algo como:
   ```
   https://sumly-backend-production.up.railway.app
   ```
4. **COPIA ESTA URL** (la necesitarás en el siguiente paso)

### **7. Actualizar Flutter con la URL de Railway**

Abre el archivo:
```
sumly_app/lib/config/api_config.dart
```

Busca la línea:
```dart
static const String baseUrl = 'http://192.168.18.54:5000/api';
```

Cámbiala por tu URL de Railway:
```dart
static const String baseUrl = 'https://sumly-backend-production.up.railway.app/api';
```

⚠️ **IMPORTANTE:** Reemplaza `sumly-backend-production.up.railway.app` con TU URL real de Railway.

### **8. Rebuild de la App Flutter**

```bash
cd sumly_app
flutter clean
flutter pub get
flutter run
```

---

## ✅ VERIFICAR QUE TODO FUNCIONE

### **Prueba 1: Verificar Backend en Navegador**

Abre en tu navegador:
```
https://TU-URL-DE-RAILWAY.up.railway.app/
```

Deberías ver:
```json
{
  "message": "API de SUMLY funcionando correctamente",
  "version": "1.0.0",
  "endpoints": { ... }
}
```

### **Prueba 2: Verificar Logs en Railway**

1. Ve a Railway → Tu proyecto
2. Click en el tab "Deployments"
3. Click en el deployment más reciente
4. Deberías ver:
   ```
   ✓ Servidor corriendo en http://0.0.0.0:5000
   ✓ MongoDB conectado exitosamente
   ```

### **Prueba 3: Probar la App**

1. Abre la app en tu teléfono
2. Login con tu cuenta
3. Intenta generar un resumen
4. Verifica que se carguen los resúmenes

**Si funciona:** ¡Felicidades! 🎉 Tu app ya está en la nube.

**Si NO funciona:** Ve a la sección de **Troubleshooting** abajo.

---

## 🔧 TROUBLESHOOTING

### **Error: "Application failed to respond"**

**Causa:** El backend no está iniciando correctamente.

**Solución:**
1. Ve a Railway → Deployments → Logs
2. Busca el error específico
3. Verifica que todas las variables de entorno estén configuradas

### **Error: "MongoDB connection failed"**

**Causa:** Railway no puede conectarse a MongoDB Atlas.

**Solución:**
1. Ve a MongoDB Atlas → Network Access
2. Asegúrate de que 0.0.0.0/0 esté permitido
3. Espera 2-3 minutos (puede tardar en aplicarse)
4. Re-deploy en Railway (Settings → Restart)

### **Error: "Cannot connect to server" en la app**

**Causa:** La URL en `api_config.dart` está mal o el backend no está corriendo.

**Solución:**
1. Verifica que la URL en `api_config.dart` sea correcta
2. Verifica que el backend esté corriendo en Railway
3. Prueba la URL en el navegador (Prueba 1)
4. Ejecuta `flutter clean && flutter pub get && flutter run`

### **Error: CORS**

**Causa:** El backend está bloqueando peticiones desde la app.

**Solución:**
El backend ya está configurado con CORS abierto, pero si sigue dando error:
1. Ve a Railway → Variables
2. Verifica que `NODE_ENV=production`
3. Re-deploy (Settings → Restart)

### **La app carga lento (15-30 segundos)**

**Causa:** Render FREE se "duerme" después de 15 min sin uso.

**Solución:**
- Si usaste Render: Es normal, la primera petición tarda
- Si usaste Railway: NO debería pasar, verifica los logs

---

## 💰 COSTOS

### **Railway (RECOMENDADO)**
- ✅ Gratis hasta $5 de uso mensual
- ✅ No se duerme
- ✅ Muy rápido
- ⚠️ Después de $5/mes, cobran por uso

**Uso estimado para tu app:**
- ~$0.50-$2/mes (muy bajo uso)
- ~$3-$4/mes (uso normal)

### **Render (ALTERNATIVA GRATIS)**
- ✅ 100% gratis
- ⚠️ Se duerme después de 15 min sin uso
- ⚠️ Primera petición tarda 30-60 segundos

### **MongoDB Atlas**
- ✅ Gratis hasta 512MB de almacenamiento
- ✅ Suficiente para miles de resúmenes

### **Gemini API**
- ✅ Gratis hasta 60 requests/minuto
- ✅ Suficiente para uso normal

---

## 📊 MONITOREO

### **Ver Logs en Tiempo Real:**

En Railway:
1. Ve a tu proyecto
2. Click en "Deployments"
3. Click en el deployment activo
4. Verás logs en tiempo real

### **Ver Uso y Costos:**

En Railway:
1. Ve a "Account" (arriba derecha)
2. Click en "Usage"
3. Verás cuánto has usado del crédito gratis

---

## 🎯 RESUMEN

**Lo que hiciste:**
1. ✅ Preparaste el backend para la nube (railway.json, package.json)
2. ✅ Desplegaste a Railway
3. ✅ Configuraste variables de entorno
4. ✅ Permitiste acceso a MongoDB desde Railway
5. ✅ Actualizaste Flutter con la URL de Railway
6. ✅ Verificaste que todo funcione

**Lo que ganaste:**
- ✅ App funciona desde cualquier lugar
- ✅ No necesitas PC encendida
- ✅ Backend disponible 24/7
- ✅ Escalable para más usuarios
- ✅ Logs y monitoreo incluidos

---

## 📚 DOCUMENTOS DE REFERENCIA

- **SOLUCION_BACKEND_CLOUD.md** → Guía detallada con más opciones
- **DIAGNOSTICO_Y_ARREGLOS.md** → Troubleshooting completo
- **RESUMEN_COMPLETO_FINAL.md** → Todas las mejoras de dark mode

---

## ❓ PREGUNTAS FRECUENTES

**P: ¿Necesito pagar algo?**
R: No, Railway da $5 gratis/mes. Tu app probablemente use $1-3/mes.

**P: ¿Y si se me acaba el crédito gratis?**
R: Railway te avisará y puedes migrar a Render (100% gratis) o agregar tarjeta.

**P: ¿Puedo usar mi propio dominio?**
R: Sí, Railway permite agregar dominios personalizados (ej: api.sumlyapp.com).

**P: ¿Y si quiero cambiar algo del backend?**
R: Solo haz push a GitHub, Railway re-desplegará automáticamente.

**P: ¿Funciona con iOS?**
R: Sí, funciona igual en Android e iOS.

---

**¿Dudas? ¡Pregúntame en qué paso estás y te ayudo!** 🚀
