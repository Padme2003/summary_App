# 🚀 GUÍA COMPLETA: Desplegar Backend en Railway

## 🎯 OBJETIVO

Hacer que tu app funcione **desde cualquier red de internet** sin necesidad de tener tu PC encendida.

### ANTES (Arquitectura Local):
```
📱 App → http://192.168.18.54:5000 → 💻 Tu PC (debe estar encendida)
❌ Solo funciona en tu WiFi de casa
❌ PC debe estar encendida 24/7
❌ No puedes probar fuera de casa
```

### DESPUÉS (Arquitectura en la Nube):
```
📱 App → https://sumly-backend.railway.app → ☁️ Railway → ☁️ MongoDB → 🤖 Gemini
✅ Funciona desde CUALQUIER WiFi
✅ Funciona con datos móviles
✅ PC puede estar apagada
✅ Disponible 24/7
```

---

## 📋 CHECKLIST PREVIO

Antes de comenzar, verifica que tengas:

- [ ] Cuenta de GitHub (ya la tienes)
- [ ] Código pusheado a GitHub en esta rama
- [ ] Cuenta de MongoDB Atlas con la base de datos creada
- [ ] API Key de Gemini funcionando

---

## 🚀 PASO 1: Crear Cuenta en Railway

1. Ve a: **https://railway.app**
2. Click en **"Login"** o **"Start a New Project"**
3. Selecciona **"Login with GitHub"**
4. Autoriza a Railway a acceder a tus repositorios

💡 **Railway es GRATIS hasta $5/mes** de uso. Tu app usará aproximadamente $2-3/mes.

---

## 📦 PASO 2: Crear Nuevo Proyecto

1. En Railway, click en **"New Project"**
2. Selecciona **"Deploy from GitHub repo"**
3. Busca y selecciona **`summary_App`** (tu repositorio)
4. Railway te preguntará qué servicio desplegar

⚠️ **IMPORTANTE:** Si Railway no muestra tus repositorios, click en "Configure GitHub App" y dale acceso a `summary_App`.

---

## ⚙️ PASO 3: Configurar el Servicio

Railway detectará automáticamente que es un proyecto Node.js. Ahora necesitas configurar:

### 3.1. Root Directory

Railway puede no detectar que el backend está en `sumly_backend/`. Necesitas configurarlo:

1. En tu proyecto de Railway, click en el servicio desplegado
2. Ve a **"Settings"**
3. Busca **"Root Directory"**
4. Pon: `sumly_backend`
5. Click en **"Update"**

### 3.2. Build & Deploy

Railway detectará **automáticamente** el `Dockerfile` que creamos y lo usará para construir la imagen. Esto arregla el problema de `pdf-parse`.

Si quieres verificar, en **"Settings"** → **"Build"** deberías ver:
- **Builder**: Docker (si detectó el Dockerfile) o Nixpacks (usará railway.json)

Ambos funcionan, pero **Docker es mejor** para nuestro caso porque instala las dependencias nativas que `pdf-parse` necesita.

---

## 🔐 PASO 4: Configurar Variables de Entorno

Esto es **CRÍTICO**. Sin estas variables, el backend no funcionará.

1. En tu proyecto de Railway, ve a **"Variables"**
2. Click en **"+ New Variable"**
3. Agrega **UNA POR UNA** las siguientes variables:

```
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb+srv://jppmoposita:Josselyn2003@cluster0.njfp3my.mongodb.net/sumly_db?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=sumly_secret_key_2025_change_in_production
GEMINI_API_KEY=AIzaSyD7wSqYAv4P3wy1S8JVbxQrwY152OfnOyc
```

### ⚠️ IMPORTANTE:
- **NO pongas espacios** alrededor del `=`
- **Copia y pega** exactamente como está
- Verifica que `MONGODB_URI` sea la correcta (con tu usuario y password)
- Después cambia `JWT_SECRET` por algo más seguro si quieres

4. Click en **"Add"** para cada variable

---

## 🔍 PASO 5: Verificar MongoDB Atlas

Antes de que Railway pueda conectarse a MongoDB, necesitas permitir conexiones desde cualquier IP:

1. Ve a **https://cloud.mongodb.com/**
2. Inicia sesión
3. Ve a tu cluster → **"Network Access"** (en el menú izquierdo)
4. Click en **"Add IP Address"**
5. Selecciona **"Allow Access from Anywhere"**
6. Confirma que se agregue `0.0.0.0/0`
7. Click en **"Confirm"**

⏰ **Espera 2-3 minutos** para que MongoDB actualice la lista de IPs permitidas.

---

## 🎬 PASO 6: Desplegar

1. Railway debería iniciar el deployment automáticamente
2. Si no, en tu servicio click en **"Deploy"** o **"Redeploy"**

### Monitorear el Build:

1. En Railway, ve a **"Deployments"**
2. Click en el deployment más reciente
3. Ve a **"Build Logs"**

Deberías ver algo como:
```
Building with Dockerfile...
Installing system dependencies...
Installing Node.js dependencies...
Build completed successfully
```

⏰ **El build tomará 3-5 minutos** la primera vez (porque está instalando dependencias del sistema para pdf-parse).

---

## ✅ PASO 7: Obtener URL de Railway

Una vez que el deployment diga **"Success"** o tenga un ✅:

1. En tu servicio, ve a **"Settings"**
2. Busca **"Domains"**
3. Click en **"Generate Domain"**
4. Railway te dará una URL como:
   ```
   https://sumly-backend-production.up.railway.app
   ```
   O simplemente:
   ```
   https://web-production-xxxx.up.railway.app
   ```

5. **COPIA esta URL** - la necesitarás para Flutter

---

## 🧪 PASO 8: Probar el Backend

Antes de actualizar Flutter, verifica que el backend funcione:

### Prueba 1: Health Check

Abre en tu navegador:
```
https://TU-URL-DE-RAILWAY.up.railway.app/api/
```

**Respuesta esperada:**
```json
{
  "message": "SUMLY API is running"
}
```

Si ves esto, ¡el backend funciona! 🎉

### Prueba 2: Ver los Logs

En Railway, ve a **"Deployments"** → Click en el deployment → **"View Logs"**

Deberías ver:
```
🚀 Servidor corriendo en puerto 5000
✅ MongoDB conectado exitosamente
```

---

## 📱 PASO 9: Actualizar Flutter

Ahora que el backend funciona en la nube, actualiza Flutter para que se conecte a Railway en lugar de tu PC local.

### 9.1. Actualizar api_config.dart

Busca el archivo:
```
sumly_app/lib/config/api_config.dart
```

Cambia la URL base:

```dart
class ApiConfig {
  // ANTES (LOCAL - YA NO SE USA):
  // static const String baseUrl = 'http://192.168.18.54:5000/api';

  // DESPUÉS (RAILWAY - USA ESTO):
  static const String baseUrl = 'https://TU-URL-DE-RAILWAY.up.railway.app/api';

  // ⚠️ IMPORTANTE: Reemplaza TU-URL-DE-RAILWAY por la URL real que Railway te dio
  // Ejemplo: 'https://web-production-a1b2.up.railway.app/api'

  // ... resto del código no lo toques
}
```

### 9.2. Rebuild la App

```bash
cd sumly_app
flutter clean
flutter pub get
flutter run
```

---

## 🎉 PASO 10: Probar la App

Ahora tu app debería funcionar completamente:

### Pruebas a Realizar:

1. **Login/Register** - Debe funcionar
2. **Subir PDF** - Debe procesar correctamente
3. **Generar Resumen** - Debe llamar a Gemini
4. **Ver Resúmenes** - Debe cargar desde MongoDB
5. **Desconéctate de tu WiFi** y usa datos móviles - ¡debe seguir funcionando!
6. **Apaga tu PC** - la app debe seguir funcionando

---

## 🔧 TROUBLESHOOTING

### ❌ Error: "Build Failed"

**Síntoma:** Railway muestra "Build Failed" en rojo

**Soluciones:**
1. Verifica que **Root Directory** sea `sumly_backend`
2. Revisa los **Build Logs** para ver el error específico
3. Verifica que `Dockerfile` y `package.json` estén en `sumly_backend/`

### ❌ Error: "Application Error" o "Service Crashed"

**Síntoma:** La URL de Railway muestra "Application Error" o el servicio se reinicia constantemente

**Soluciones:**
1. Ve a **"Deployments"** → **"View Logs"**
2. Busca el error específico
3. Los errores más comunes:
   - **"MongoDB connection failed"**: Verifica MongoDB Atlas Network Access
   - **"Port already in use"**: Verifica que `PORT=5000` esté en las variables
   - **"Cannot find module"**: Falta instalar dependencias (raro con Docker)

### ❌ Error: "Cannot connect to MongoDB"

**Síntoma:** Logs muestran "MongoDB connection error"

**Soluciones:**
1. Verifica en MongoDB Atlas → **Network Access** → Debe tener `0.0.0.0/0`
2. Verifica que `MONGODB_URI` en Railway sea EXACTAMENTE igual a la que usabas localmente
3. Prueba la conexión manualmente copiando el URI en MongoDB Compass

### ❌ Flutter: "SocketException" o "Connection refused"

**Síntoma:** La app muestra error de conexión

**Soluciones:**
1. Verifica que `baseUrl` en Flutter tenga la URL **correcta** de Railway
2. Verifica que sea `https://` (con S) no `http://`
3. Verifica que termine en `/api`
4. Ejemplo correcto: `https://web-production-a1b2.up.railway.app/api`

### ❌ Railway: "Out of Memory"

**Síntoma:** El servicio se reinicia con error de memoria

**Soluciones:**
1. En Railway → **"Settings"** → Verifica el plan
2. El plan gratuito tiene 512MB de RAM (suficiente para tu app)
3. Si sigue pasando, optimiza el código o considera upgrade

---

## 💰 COSTOS DE RAILWAY

### Plan Gratuito:
- **$5 de crédito gratis** cada mes
- Se resetea el día 1 de cada mes
- Tu app usará aproximadamente **$2-3/mes**

### ¿Qué pasa si se acaba el crédito?
- Railway pausará tu servicio
- Puedes agregar una tarjeta de crédito para continuar
- O esperar al próximo mes para que se recarguen los $5

### Cómo Monitorear el Uso:
1. En Railway → **"Usage"**
2. Verás cuánto has usado del crédito mensual

---

## 📊 COMPARACIÓN: Local vs Railway

| Aspecto | Local (Antes) | Railway (Ahora) |
|---------|---------------|-----------------|
| **Funciona desde casa** | ✅ Solo WiFi local | ✅ Cualquier WiFi |
| **Funciona con datos móviles** | ❌ No | ✅ Sí |
| **PC debe estar encendida** | ❌ Sí | ✅ No |
| **Disponibilidad** | Solo cuando estás en casa | 24/7 |
| **Velocidad** | Rápida (local) | Rápida (nube) |
| **Costo** | $0 (electricidad de PC) | $2-3/mes |
| **Escalabilidad** | ❌ No | ✅ Sí |
| **Mantenimiento** | Tú (reiniciar PC, etc.) | Railway automático |

---

## ✅ CHECKLIST FINAL

Antes de dar por terminado, verifica que:

- [ ] Railway muestra el deployment como "Success" ✅
- [ ] La URL de Railway responde en `/api/` con el mensaje de salud
- [ ] MongoDB Atlas permite acceso desde 0.0.0.0/0
- [ ] Todas las variables de entorno están en Railway
- [ ] Flutter tiene la URL correcta de Railway en `api_config.dart`
- [ ] La app se reconstruyó (`flutter clean && flutter pub get`)
- [ ] Login/Register funciona
- [ ] Subir PDF funciona
- [ ] Generar resumen funciona
- [ ] La app funciona con datos móviles (desconectada del WiFi)
- [ ] La app funciona con tu PC apagada

---

## 🎯 RESULTADO FINAL

**AHORA TU APP:**
```
✅ Funciona desde CUALQUIER red WiFi
✅ Funciona con datos móviles (4G/5G)
✅ NO necesita que tu PC esté encendida
✅ NO necesita que estés en tu casa
✅ Está disponible 24/7
✅ Puede ser usada por otras personas
✅ Está lista para mostrar/publicar
```

---

## 🚀 PRÓXIMOS PASOS (OPCIONAL)

### A. Configurar Dominio Personalizado
En Railway puedes configurar tu propio dominio (ejemplo: `api.sumly.com`):
1. Compra un dominio en Namecheap, Google Domains, etc.
2. En Railway → Settings → Domains → Add Custom Domain
3. Configura los registros DNS según Railway te indique

### B. Configurar CI/CD Automático
Railway ya tiene CI/CD automático:
- Cada vez que hagas `git push` a GitHub
- Railway detectará los cambios
- Y redesplegarán automáticamente
- ¡No necesitas hacer nada más!

### C. Monitoreo y Logs
Railway provee:
- Logs en tiempo real
- Métricas de uso (CPU, RAM, Red)
- Alertas si algo falla

---

## 📞 ¿NECESITAS AYUDA?

Si tienes problemas:

1. **Revisa los logs** en Railway → Deployments → View Logs
2. **Revisa este troubleshooting** (arriba)
3. **Comparte el error específico** que estás viendo

---

**¡Felicidades! Tu backend ahora está en la nube y tu app funciona desde cualquier lugar del mundo! 🌍🎉**
