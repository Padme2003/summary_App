# SUMLY - Aplicación de Resúmenes y Audiolibros con IA

Aplicación móvil desarrollada con Flutter para el frontend y Node.js/Express para el backend, que permite generar resúmenes inteligentes y convertir documentos a audiolibros utilizando IA (Google Gemini).

## Estructura del Proyecto

```
summary_App/
├── sumly_app/          # Frontend Flutter
└── sumly_backend/      # Backend Node.js
```

## Requisitos Previos

### Backend
- Node.js (v16 o superior)
- MongoDB (local o en la nube)
- Cuenta de Google Cloud con API Key de Gemini

### Frontend
- Flutter SDK (3.9.2 o superior)
- Android Studio / Xcode (según plataforma)
- Emulador o dispositivo físico

## Configuración del Backend

### 1. Instalar dependencias

```bash
cd sumly_backend
npm install
```

### 2. Configurar variables de entorno

Edita el archivo `.env` con tus credenciales:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/sumly
JWT_SECRET=sumly_secret_key_change_in_production_2024
GEMINI_API_KEY=tu_api_key_de_gemini_aqui
NODE_ENV=development
```

### 3. Iniciar MongoDB

Si usas MongoDB local:
```bash
mongod
```

O usa MongoDB Atlas para una base de datos en la nube.

### 4. Ejecutar el servidor

```bash
# Modo desarrollo (con auto-reload)
npm run dev

# Modo producción
npm start
```

El servidor estará corriendo en `http://localhost:3000`

### Endpoints disponibles

#### Autenticación
- `POST /api/auth/register` - Registrar nuevo usuario
- `POST /api/auth/login` - Iniciar sesión
- `GET /api/auth/me` - Obtener perfil del usuario (requiere token)

#### Documentos
- `POST /api/documents/upload` - Subir documento (requiere token)
- `GET /api/documents` - Obtener todos los documentos del usuario (requiere token)
- `GET /api/documents/:id` - Obtener un documento específico (requiere token)
- `DELETE /api/documents/:id` - Eliminar documento (requiere token)

#### Health Check
- `GET /api/health` - Verificar estado del servidor

## Configuración del Frontend

### 1. Instalar dependencias

```bash
cd sumly_app
flutter pub get
```

### 2. Configurar la URL del backend

Edita el archivo `lib/services/api_config.dart` y ajusta la URL según tu entorno:

```dart
class ApiConfig {
  // Para emulador Android
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Para iOS simulator
  // static const String baseUrl = 'http://localhost:3000/api';

  // Para dispositivo físico (usa tu IP local)
  // static const String baseUrl = 'http://192.168.1.X:3000/api';
}
```

### 3. Ejecutar la aplicación

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en el dispositivo/emulador
flutter run
```

## Funcionalidades Implementadas

### Backend
- ✅ Sistema de autenticación con JWT
- ✅ Registro e inicio de sesión de usuarios
- ✅ Encriptación de contraseñas con bcrypt
- ✅ Subida de archivos PDF y TXT
- ✅ Procesamiento de texto con Google Gemini AI
- ✅ Generación de resúmenes inteligentes
- ✅ División de contenido en capítulos (para audiolibros)
- ✅ CRUD completo de documentos
- ✅ Middleware de autenticación
- ✅ Manejo de errores global

### Frontend
- ✅ Interfaz de usuario moderna con Material Design 3
- ✅ Pantalla de splash animada
- ✅ Sistema de autenticación (login/registro)
- ✅ Navegación fluida entre pantallas
- ✅ Subida de archivos (PDF, TXT, DOC, DOCX)
- ✅ Opción de pegar texto directamente
- ✅ Selección de modo (Resumen IA o Audiolibro)
- ✅ Animaciones y transiciones suaves
- ✅ Manejo de estados de carga
- ✅ Validación de formularios
- ✅ Mensajes de error y éxito

## Flujo de Uso

1. **Registro/Login**: El usuario crea una cuenta o inicia sesión
2. **Home**: Pantalla principal con acceso a todas las funcionalidades
3. **Upload**: Subir un documento o pegar texto
4. **Selección de modo**: Elegir entre generar un resumen o un audiolibro
5. **Procesamiento**: El backend procesa el contenido con IA
6. **Resultado**: Ver el resumen o reproducir el audiolibro

## Tecnologías Utilizadas

### Backend
- Node.js + Express
- MongoDB + Mongoose
- JWT para autenticación
- Bcrypt para encriptación
- Multer para subida de archivos
- PDF-parse para leer PDFs
- Google Generative AI (Gemini)

### Frontend
- Flutter 3.9.2
- Material Design 3
- HTTP para peticiones
- SharedPreferences para almacenamiento local
- FilePicker para selección de archivos

## Notas Importantes

### Configuración de la API de Gemini

Para obtener una API Key de Google Gemini:
1. Visita [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Crea o selecciona un proyecto
3. Genera una nueva API Key
4. Copia la key al archivo `.env` del backend

### Configuración de red

- **Emulador Android**: Usa `10.0.2.2` para acceder a localhost
- **iOS Simulator**: Usa `localhost`
- **Dispositivo físico**: Usa la IP local de tu máquina (asegúrate de estar en la misma red)

### Seguridad

Para producción, asegúrate de:
- Cambiar el `JWT_SECRET` por uno más seguro
- Usar HTTPS en lugar de HTTP
- No exponer las API keys en el código
- Implementar rate limiting
- Agregar validaciones más robustas
- Configurar CORS apropiadamente

## Solución de Problemas

### Error de conexión en el frontend
1. Verifica que el backend esté corriendo
2. Confirma que la URL en `api_config.dart` sea correcta
3. Si usas un dispositivo físico, verifica que esté en la misma red

### Error de MongoDB
1. Asegúrate de que MongoDB esté corriendo
2. Verifica la cadena de conexión en `.env`
3. Comprueba que el puerto 27017 no esté ocupado

### Error de API de Gemini
1. Verifica que la API Key sea válida
2. Confirma que tengas créditos disponibles
3. Revisa los logs del servidor para más detalles

## Mejoras Futuras

- [ ] Implementar reproducción de audio real para audiolibros
- [ ] Agregar caché de resúmenes
- [ ] Implementar favoritos y biblioteca personal
- [ ] Agregar configuración de velocidad y voz para audio
- [ ] Soporte para más formatos de archivo (EPUB, etc.)
- [ ] Implementar búsqueda de documentos
- [ ] Agregar estadísticas de uso
- [ ] Modo oscuro
- [ ] Internacionalización (i18n)

## Contribución

Este es un proyecto educativo. Si encuentras algún problema o tienes sugerencias, no dudes en reportarlo.

## Licencia

MIT

---

Desarrollado con ❤️ usando Flutter y Node.js
