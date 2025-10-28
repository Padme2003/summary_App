# SUMLY - Aplicación de Resúmenes IA y Audiolibros

SUMLY es una aplicación móvil desarrollada con Flutter y Node.js que permite a los usuarios cargar documentos (PDF, TXT, DOC, DOCX) y generar:
- **Resúmenes inteligentes** usando IA (Google Gemini)
- **Audiolibros completos** con conversión texto a voz

## Características

- Autenticación de usuarios (registro/login)
- Carga de archivos PDF, TXT, DOC, DOCX
- Ingreso de texto manual
- Generación de resúmenes con IA
- Conversión de texto a audio
- Biblioteca personal de contenidos
- Favoritos y seguimiento de progreso
- Reproductor de audio integrado

## Tecnologías

### Backend
- Node.js + Express
- MongoDB + Mongoose
- JWT para autenticación
- Multer para carga de archivos
- pdf-parse para extracción de texto
- Google Gemini AI para resúmenes

### Frontend
- Flutter
- Provider para gestión de estado
- HTTP para comunicación con API
- audioplayers para reproducción
- shared_preferences para almacenamiento local

## Estructura del Proyecto

```
summary_App/
├── sumly_backend/          # Backend Node.js
│   ├── src/
│   │   ├── config/         # Configuración (DB, env)
│   │   ├── models/         # Modelos de datos
│   │   ├── controllers/    # Controladores
│   │   ├── routes/         # Rutas API
│   │   ├── middlewares/    # Middlewares
│   │   ├── services/       # Servicios (AI, PDF, TTS)
│   │   └── server.js       # Servidor principal
│   ├── uploads/            # Archivos subidos
│   ├── .env               # Variables de entorno
│   └── package.json
│
└── sumly_app/             # Frontend Flutter
    ├── lib/
    │   ├── main.dart
    │   ├── models/        # Modelos de datos
    │   ├── providers/     # Gestión de estado
    │   ├── screens/       # Pantallas UI
    │   ├── services/      # Servicios API
    │   ├── widgets/       # Widgets reutilizables
    │   └── utils/         # Utilidades
    └── pubspec.yaml
```

## Instalación

### Requisitos Previos

1. **Node.js** (v16 o superior)
2. **MongoDB** (local o Atlas)
3. **Flutter** (3.9.2 o superior)
4. **Google Gemini API Key** (gratis en https://makersuite.google.com/app/apikey)

### Backend

1. Navegar al directorio del backend:
```bash
cd sumly_backend
```

2. Instalar dependencias:
```bash
npm install
```

3. Configurar variables de entorno:
   - Edita el archivo `.env` con tus credenciales:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/sumly_db  # o tu URI de MongoDB Atlas
JWT_SECRET=tu_clave_secreta_aqui
GEMINI_API_KEY=tu_api_key_de_gemini_aqui
```

4. Asegurarse de que MongoDB esté corriendo:
```bash
# Si tienes MongoDB local:
mongod

# Si usas MongoDB Atlas, no es necesario
```

5. Iniciar el servidor:
```bash
# Desarrollo (con auto-reload):
npm run dev

# Producción:
npm start
```

El servidor estará disponible en `http://localhost:3000`

### Frontend

1. Navegar al directorio de la app:
```bash
cd sumly_app
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Configurar la URL del backend:
   - Edita `lib/services/api_config.dart`:
```dart
class ApiConfig {
  // Para Android Emulator:
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Para iOS Simulator:
  // static const String baseUrl = 'http://localhost:3000/api';

  // Para dispositivo físico (usa tu IP local):
  // static const String baseUrl = 'http://192.168.1.X:3000/api';
}
```

4. Ejecutar la aplicación:
```bash
# Ver dispositivos disponibles:
flutter devices

# Ejecutar en dispositivo/emulador:
flutter run

# O específicamente:
flutter run -d chrome        # Para web
flutter run -d android       # Para Android
flutter run -d ios          # Para iOS
```

## Uso

### 1. Registrarse / Iniciar Sesión
- Abre la app y crea una cuenta nueva
- O inicia sesión si ya tienes una cuenta

### 2. Subir Contenido
- Toca el botón "Nuevo Contenido"
- Selecciona entre:
  - **Resumen IA**: Genera un resumen de 3-5 páginas
  - **Audiolibro**: Convierte todo el contenido a audio
- Elige cómo proporcionar el contenido:
  - Subir archivo (PDF, TXT, DOC, DOCX)
  - Pegar texto directamente

### 3. Procesar
- Toca "Generar Resumen" o "Crear Audiolibro"
- Espera mientras la IA procesa el contenido
- El documento aparecerá en tu biblioteca

### 4. Reproducir y Gestionar
- Ve a "Mi Biblioteca" para ver todos tus documentos
- Toca cualquier documento para reproducir el audio
- Marca favoritos, elimina o comparte contenido

## API Endpoints

### Autenticación
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión
- `GET /api/auth/me` - Obtener usuario actual

### Documentos
- `GET /api/documents` - Listar documentos del usuario
- `GET /api/documents/:id` - Obtener un documento
- `POST /api/documents/upload` - Subir documento
- `PUT /api/documents/:id` - Actualizar documento
- `DELETE /api/documents/:id` - Eliminar documento

## Configuración de Servicios

### Google Gemini AI

1. Ve a https://makersuite.google.com/app/apikey
2. Crea un nuevo API key
3. Copia la clave y pégala en `.env`:
```
GEMINI_API_KEY=tu_clave_aqui
```

### Text-to-Speech (Opcional)

Por defecto, el TTS está en modo demo. Para producción, puedes integrar:
- **Google Cloud Text-to-Speech**: https://cloud.google.com/text-to-speech
- **AWS Polly**: https://aws.amazon.com/polly/
- **Azure Cognitive Services**: https://azure.microsoft.com/en-us/services/cognitive-services/text-to-speech/

Edita `sumly_backend/src/services/ttsService.js` para integrar el servicio que prefieras.

## Desarrollo

### Estructura de Código

#### Backend
- **Models**: Define esquemas de MongoDB
- **Controllers**: Lógica de negocio
- **Routes**: Define endpoints API
- **Services**: Servicios externos (AI, PDF, TTS)
- **Middlewares**: Autenticación, validación

#### Frontend
- **Screens**: Pantallas completas de UI
- **Providers**: Gestión de estado global
- **Services**: Comunicación con API
- **Models**: Clases de datos
- **Widgets**: Componentes reutilizables

### Scripts Útiles

Backend:
```bash
npm start          # Iniciar servidor
npm run dev        # Desarrollo con nodemon
```

Frontend:
```bash
flutter run        # Ejecutar app
flutter build apk  # Compilar APK Android
flutter build ios  # Compilar iOS
flutter test       # Ejecutar tests
```

## Troubleshooting

### Backend no se conecta a MongoDB
- Verifica que MongoDB esté corriendo: `mongod --version`
- Verifica la URI en `.env`
- Si usas Atlas, verifica que tu IP esté en la whitelist

### Flutter no puede conectarse al backend
- Verifica que el servidor esté corriendo en `http://localhost:3000`
- Para Android Emulator, usa `http://10.0.2.2:3000`
- Para dispositivo físico, usa tu IP local (ej: `http://192.168.1.10:3000`)

### Error de Gemini API
- Verifica que tu API key sea válida
- Verifica que tengas cuota disponible en Google AI Studio
- El servicio funcionará en modo demo sin la clave (no generará resúmenes reales)

## Roadmap

- [ ] Integración de TTS real (Google/AWS/Azure)
- [ ] Soporte para más formatos de archivo
- [ ] Compartir resúmenes con otros usuarios
- [ ] Modo offline
- [ ] Temas claro/oscuro
- [ ] Multi-idioma
- [ ] Export a PDF/EPUB

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

MIT License - ver archivo LICENSE para más detalles

## Autor

Pamela Moposita

## Soporte

Para problemas o preguntas, abre un issue en el repositorio.

---

Hecho con ❤️ y Flutter
