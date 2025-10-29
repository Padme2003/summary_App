# SUMLY Backend API

Backend completo para la aplicación SUMLY - Resúmenes inteligentes con IA y conversión a audio.

## 🚀 Características

- ✅ **Autenticación JWT** con registro y login
- ✅ **Gestión de documentos** (PDF, TXT, DOC, DOCX)
- ✅ **Resúmenes con IA** usando Google Gemini
- ✅ **Text-to-Speech** para convertir resúmenes a audio
- ✅ **Audiolibros** completos con capítulos navegables
- ✅ **Sistema de favoritos**
- ✅ **Base de datos MongoDB**
- ✅ **API RESTful** bien estructurada

## 📋 Requisitos

- Node.js v16 o superior
- MongoDB v5.0 o superior
- API Key de Google Gemini AI
- (Opcional) Credenciales de Google Cloud para TTS

## 🔧 Instalación

1. Instalar dependencias:
```bash
npm install
```

2. Configurar variables de entorno:
```bash
cp .env.example .env
```

3. Editar `.env` con tus credenciales:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/sumly_db
JWT_SECRET=tu_secreto_jwt_aqui
GEMINI_API_KEY=tu_api_key_de_gemini
NODE_ENV=development

# Opcional: Para Google Cloud TTS
GOOGLE_APPLICATION_CREDENTIALS=/ruta/a/tu/credenciales.json
```

4. Iniciar MongoDB:
```bash
# En Linux/Mac
mongod

# O usando Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

5. Iniciar servidor:
```bash
# Desarrollo con auto-reload
npm run dev

# Producción
npm start
```

## 🔑 Obtener API Keys

### Google Gemini AI (REQUERIDO)
1. Ve a https://makersuite.google.com/app/apikey
2. Inicia sesión con tu cuenta de Google
3. Crea una nueva API key
4. Copia y pega en `.env` como `GEMINI_API_KEY`

### Google Cloud Text-to-Speech (OPCIONAL)
Si no configuras esto, el sistema usará audio simulado para desarrollo.

Para producción, sigue estos pasos:
1. Ve a https://console.cloud.google.com/
2. Crea un nuevo proyecto
3. Habilita la API de Text-to-Speech
4. Crea credenciales de servicio (Service Account)
5. Descarga el archivo JSON de credenciales
6. Configura la variable `GOOGLE_APPLICATION_CREDENTIALS` en `.env`

## 📡 Endpoints de la API

### Autenticación
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión
- `GET /api/auth/me` - Obtener perfil actual
- `PUT /api/auth/profile` - Actualizar perfil
- `PUT /api/auth/change-password` - Cambiar contraseña

### Documentos
- `POST /api/documents/upload` - Subir archivo
- `POST /api/documents/text` - Subir texto
- `GET /api/documents` - Listar documentos
- `GET /api/documents/:id` - Obtener documento
- `PUT /api/documents/:id` - Actualizar documento
- `DELETE /api/documents/:id` - Eliminar documento

### Resúmenes
- `POST /api/summaries/generate` - Generar resumen con IA
- `GET /api/summaries` - Listar resúmenes
- `GET /api/summaries/:id` - Obtener resumen
- `PUT /api/summaries/:id` - Actualizar resumen
- `DELETE /api/summaries/:id` - Eliminar resumen

### Audiolibros
- `POST /api/audiobooks/generate` - Generar audiolibro
- `GET /api/audiobooks` - Listar audiolibros
- `GET /api/audiobooks/:id` - Obtener audiolibro
- `PUT /api/audiobooks/:id` - Actualizar audiolibro
- `PUT /api/audiobooks/:id/position` - Actualizar posición
- `DELETE /api/audiobooks/:id` - Eliminar audiolibro

## 🗂️ Estructura del Proyecto

```
sumly_backend/
├── src/
│   ├── config/
│   │   ├── database.js         # Conexión MongoDB
│   │   └── environment.js      # Variables de entorno
│   ├── models/
│   │   ├── User.js            # Modelo de usuario
│   │   ├── Document.js        # Modelo de documento
│   │   ├── Summary.js         # Modelo de resumen
│   │   └── Audiobook.js       # Modelo de audiolibro
│   ├── controllers/
│   │   ├── auth.controller.js      # Lógica de autenticación
│   │   ├── document.controller.js  # Lógica de documentos
│   │   ├── summary.controller.js   # Lógica de resúmenes
│   │   └── audiobook.controller.js # Lógica de audiolibros
│   ├── middleware/
│   │   ├── auth.middleware.js   # JWT y autorización
│   │   └── upload.middleware.js # Multer para archivos
│   ├── services/
│   │   └── tts.service.js       # Text-to-Speech
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   ├── document.routes.js
│   │   ├── summary.routes.js
│   │   └── audiobook.routes.js
│   └── server.js               # Punto de entrada
├── uploads/                    # Archivos subidos
│   ├── audio/                 # Archivos de audio generados
│   └── ...
├── .env                       # Variables de entorno
├── .env.example              # Ejemplo de variables
├── package.json
└── README.md
```

## 🧪 Ejemplos de Uso

### Registrar usuario
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "password123"
  }'
```

### Subir documento
```bash
curl -X POST http://localhost:5000/api/documents/upload \
  -H "Authorization: Bearer TU_TOKEN" \
  -F "file=@documento.pdf" \
  -F "title=Mi Documento"
```

### Generar resumen
```bash
curl -X POST http://localhost:5000/api/summaries/generate \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "documentId": "ID_DEL_DOCUMENTO"
  }'
```

### Generar audiolibro
```bash
curl -X POST http://localhost:5000/api/audiobooks/generate \
  -H "Authorization: Bearer TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "documentId": "ID_DEL_DOCUMENTO",
    "voice": "es-ES-Standard-A",
    "speed": 1.0
  }'
```

## 🔒 Seguridad

- Contraseñas encriptadas con bcrypt (10 rounds)
- JWT con expiración de 30 días
- Validación de tipos de archivo
- Límite de tamaño de archivo: 50MB
- CORS configurado
- Variables sensibles en `.env`

## 📝 Notas

- Los resúmenes se generan automáticamente con audio
- Los audiolibros se dividen en capítulos de ~5000 caracteres
- Los archivos de audio se guardan en `/uploads/audio/`
- El audio simulado se usa si no hay credenciales de TTS

## 🐛 Solución de Problemas

### Error de MongoDB
```bash
# Verificar que MongoDB está corriendo
ps aux | grep mongod

# O iniciar MongoDB
mongod --dbpath /ruta/a/tu/data
```

### Error de API Key
Verifica que tu API key de Gemini es válida:
```bash
# En tu archivo .env
GEMINI_API_KEY=AIza...
```

### Error de TTS
Si no tienes configurado Google Cloud TTS, el sistema usará audio simulado. Para producción, configura las credenciales.

## 📄 Licencia

MIT

## 👨‍💻 Autor

Pamela Moposita
