#!/usr/bin/env node
/**
 * Script de configuración para Railway
 * Crea carpetas y archivos necesarios antes de iniciar el servidor
 */

const fs = require('fs');
const path = require('path');

console.log('🚀 Configurando entorno para Railway...');

// 1. Crear carpeta uploads/
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('✓ Carpeta uploads/ creada');
} else {
  console.log('✓ Carpeta uploads/ ya existe');
}

// 2. Crear carpeta credentials/
const credentialsDir = path.join(__dirname, '..', 'credentials');
if (!fs.existsSync(credentialsDir)) {
  fs.mkdirSync(credentialsDir, { recursive: true });
  console.log('✓ Carpeta credentials/ creada');
} else {
  console.log('✓ Carpeta credentials/ ya existe');
}

// 3. Crear archivo google-tts.json desde variable de entorno
const googleCredsPath = path.join(credentialsDir, 'google-tts.json');
const googleCredsEnv = process.env.GOOGLE_TTS_CREDENTIALS;

if (googleCredsEnv) {
  try {
    // Intentar parsear para validar que sea JSON válido
    const credsJson = JSON.parse(googleCredsEnv);
    fs.writeFileSync(googleCredsPath, JSON.stringify(credsJson, null, 2));
    console.log('✓ Credenciales de Google TTS configuradas');
  } catch (error) {
    console.warn('⚠️  GOOGLE_TTS_CREDENTIALS no es JSON válido');
    console.warn('⚠️  El servicio de Text-to-Speech NO estará disponible');
  }
} else {
  console.warn('⚠️  GOOGLE_TTS_CREDENTIALS no configurada');
  console.warn('⚠️  El servicio de Text-to-Speech NO estará disponible');

  // Crear un archivo vacío para evitar errores de "archivo no encontrado"
  fs.writeFileSync(googleCredsPath, JSON.stringify({
    "type": "service_account",
    "project_id": "disabled",
    "private_key_id": "disabled",
    "private_key": "disabled",
    "client_email": "disabled@disabled.iam.gserviceaccount.com",
    "client_id": "disabled",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "disabled",
    "universe_domain": "googleapis.com"
  }, null, 2));
  console.log('✓ Credenciales de Google TTS creadas (deshabilitadas)');
}

console.log('✅ Configuración completa, iniciando servidor...\n');
