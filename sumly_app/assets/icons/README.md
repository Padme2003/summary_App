# 📱 Íconos de la App Sumly

## 🎨 Cómo cambiar el ícono de la aplicación

### Paso 1: Preparar tu imagen

1. **Crea o descarga tu ícono:**
   - Tamaño recomendado: **1024x1024 píxeles** (mínimo 512x512)
   - Formato: **PNG** con fondo transparente o de color
   - Diseño: Simple, reconocible, que represente "Sumly"
   - Sugerencias:
     - Un libro con un rayo (lectura rápida)
     - Letras "S" estilizada
     - Documento con estrella
     - Cerebro + libro

2. **Nombra tu imagen:**
   - Guárdala como: `icon.png`
   - Colócala en esta carpeta: `sumly_app/assets/icons/icon.png`

### Paso 2: Generar los íconos para Android e iOS

Una vez que tengas tu `icon.png` en esta carpeta, ejecuta:

```bash
# 1. Ir a la carpeta de la app
cd sumly_app

# 2. Instalar dependencias (si no lo has hecho)
flutter pub get

# 3. Generar los íconos
flutter pub run flutter_launcher_icons
```

Esto creará automáticamente:
- ✅ Todos los tamaños de ícono para Android
- ✅ Todos los tamaños de ícono para iOS
- ✅ Íconos adaptativos para Android

### Paso 3: Compilar la app

```bash
# Para Android
flutter build apk

# Para iOS
flutter build ios
```

## 🎨 Ideas de diseño para Sumly

### Opción 1: Minimalista
- Fondo azul/morado degradado
- Ícono de libro blanco simple
- Letra "S" destacada

### Opción 2: Moderno
- Fondo sólido (color de tu marca)
- Ícono de ondas de audio + documento
- Estilo flat design

### Opción 3: Profesional
- Fondo oscuro (azul marino o negro)
- Documento dorado/amarillo brillante
- Efecto de brillo o estrella

## 🌐 Herramientas recomendadas para crear íconos:

### Online (gratis):
1. **Canva** - https://www.canva.com
   - Plantillas de íconos de apps
   - Fácil de usar

2. **Figma** - https://www.figma.com
   - Profesional
   - Muchas plantillas gratis

3. **Icon Generator** - https://icon.kitchen
   - Genera íconos automáticamente
   - Muy rápido

### Desktop:
- **GIMP** (gratis) - Editor de imágenes
- **Inkscape** (gratis) - Editor vectorial
- **Adobe Illustrator** (pago) - Profesional

## ⚠️ Importante:

- **NO uses imágenes con copyright**
- **Asegúrate de tener derechos sobre el diseño**
- **Prueba el ícono en diferentes fondos** (claro y oscuro)
- **Verifica que se vea bien en tamaño pequeño**

## 📝 Ejemplo de configuración actual:

El archivo `pubspec.yaml` está configurado para buscar:
- Ícono: `assets/icons/icon.png`
- Color de fondo adaptativo (Android): `#1a1a2e` (azul oscuro)

## 🆘 ¿Necesitas ayuda?

Si no tienes un ícono diseñado, puedes:
1. Usar un generador automático (icon.kitchen)
2. Contratar un diseñador en Fiverr ($5-20)
3. Usar IA como DALL-E o Midjourney

---

**¡Tu ícono es la primera impresión de tu app! Hazlo memorable.** 🚀
