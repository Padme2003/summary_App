import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Política de Privacidad',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'En Sumly, nos comprometemos a proteger su privacidad y sus datos personales. Esta Política de Privacidad explica cómo recopilamos, usamos, almacenamos y protegemos su información.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              title: '1. Información que Recopilamos',
              content: 'Recopilamos la siguiente información cuando utiliza Sumly:\n\n• Información de Cuenta:\n  - Nombre\n  - Correo electrónico\n  - Contraseña (encriptada)\n  - Foto de perfil (opcional)\n\n• Contenido del Usuario:\n  - Documentos que sube\n  - Resúmenes generados\n  - Audiolibros creados\n  - Historial de actividad\n\n• Información de Uso:\n  - Preferencias de configuración\n  - Estadísticas de uso\n  - Registros de errores\n  - Información del dispositivo',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '2. Cómo Usamos su Información',
              content: 'Utilizamos su información para:\n\n• Proporcionar y mejorar el servicio de Sumly\n• Procesar sus documentos y generar resúmenes\n• Crear versiones de audio de sus documentos\n• Mantener la seguridad de su cuenta\n• Enviar notificaciones sobre el estado de procesamiento\n• Personalizar su experiencia\n• Analizar el uso de la aplicación para mejoras\n• Responder a sus consultas y brindar soporte',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '3. Procesamiento de Documentos',
              content: 'Cuando sube un documento a Sumly:\n\n• Los documentos se almacenan de forma segura en nuestros servidores\n• Utilizamos Google Gemini AI para analizar y generar resúmenes\n• El contenido se procesa únicamente para proporcionar el servicio\n• No compartimos sus documentos con terceros para otros fines\n• Puede eliminar sus documentos en cualquier momento\n\nImportante: Si bien tomamos medidas de seguridad, evite subir información extremadamente sensible o confidencial.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '4. Compartir Información',
              content: 'No vendemos ni alquilamos su información personal. Solo compartimos datos en estas situaciones:\n\n• Con Proveedores de Servicios:\n  - Google Gemini AI (para generación de resúmenes)\n  - Servicios de almacenamiento en la nube\n  - Servicios de análisis (datos anonimizados)\n\n• Por Requisitos Legales:\n  - Cuando lo exija la ley\n  - Para proteger nuestros derechos legales\n  - En caso de investigaciones legales\n\n• Con su Consentimiento:\n  - Cuando use la función de compartir\n  - Al conectar servicios de terceros',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '5. Almacenamiento y Seguridad',
              content: 'Implementamos medidas de seguridad para proteger sus datos:\n\n• Encriptación:\n  - Contraseñas encriptadas con bcrypt\n  - Conexiones HTTPS/TLS\n  - Almacenamiento encriptado\n\n• Control de Acceso:\n  - Autenticación mediante tokens JWT\n  - Acceso limitado a datos personales\n  - Auditorías de seguridad regulares\n\n• Respaldo:\n  - Copias de seguridad automáticas\n  - Redundancia de datos',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '6. Retención de Datos',
              content: 'Conservamos su información mientras:\n\n• Su cuenta permanezca activa\n• Sea necesario para proporcionar el servicio\n• Lo requieran obligaciones legales\n\nCuando elimina su cuenta:\n• Sus datos personales se eliminan dentro de 30 días\n• Los documentos y resúmenes se eliminan permanentemente\n• Algunos datos pueden conservarse para cumplir con requisitos legales',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '7. Sus Derechos',
              content: 'Usted tiene derecho a:\n\n• Acceder: Solicitar una copia de sus datos personales\n• Rectificar: Corregir información inexacta\n• Eliminar: Solicitar la eliminación de sus datos\n• Portabilidad: Obtener sus datos en formato estructurado\n• Oposición: Oponerse a ciertos usos de sus datos\n• Restricción: Solicitar limitación del procesamiento\n\nPara ejercer estos derechos, contáctenos en support@sumly.app',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '8. Cookies y Tecnologías Similares',
              content: 'Sumly utiliza:\n\n• Tokens de Sesión: Para mantener su sesión activa\n• Preferencias Locales: Para recordar configuraciones\n• Análisis: Para entender cómo se usa la aplicación\n\nPuede controlar estas preferencias desde la configuración de la aplicación.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '9. Privacidad de Menores',
              content: 'Sumly no está dirigido a menores de 13 años. No recopilamos intencionalmente información de niños. Si descubrimos que hemos recopilado datos de un menor, los eliminaremos inmediatamente.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '10. Transferencias Internacionales',
              content: 'Sus datos pueden ser transferidos y procesados en servidores ubicados fuera de su país de residencia. Implementamos salvaguardias apropiadas para proteger sus datos en estas transferencias.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '11. Cambios a esta Política',
              content: 'Podemos actualizar esta Política de Privacidad ocasionalmente. Le notificaremos sobre cambios significativos mediante:\n\n• Notificación en la aplicación\n• Correo electrónico\n• Banner en el inicio de sesión\n\nLa fecha de "Última actualización" al inicio indica cuándo se modificó por última vez.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '12. Contacto',
              content: 'Si tiene preguntas, inquietudes o solicitudes sobre esta Política de Privacidad o el manejo de sus datos personales:\n\n• Email: support@sumly.app\n• WhatsApp: +593 984173150\n\nResponderemos a su solicitud dentro de 30 días.',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.gold : AppColors.brown).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: isDark ? AppColors.gold : AppColors.brown,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Su privacidad es importante para nosotros. Trabajamos continuamente para mejorar la seguridad y protección de sus datos.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                '© ${DateTime.now().year} Sumly. Todos los derechos reservados.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
