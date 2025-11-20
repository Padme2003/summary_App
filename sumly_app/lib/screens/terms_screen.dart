import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Términos y Condiciones',
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

            _buildSection(
              title: '1. Aceptación de los Términos',
              content: 'Al descargar, instalar o utilizar Sumly, usted acepta estar sujeto a estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '2. Descripción del Servicio',
              content: 'Sumly es una aplicación móvil que proporciona servicios de resumen automático de documentos y conversión de texto a audio utilizando tecnología de inteligencia artificial. La aplicación permite:\n\n• Subir documentos en formato PDF y texto\n• Generar resúmenes inteligentes de los documentos\n• Convertir documentos a formato de audio (audiolibros)\n• Gestionar una biblioteca personal de documentos y resúmenes',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '3. Registro y Cuenta de Usuario',
              content: 'Para utilizar Sumly, debe crear una cuenta proporcionando información precisa y completa. Usted es responsable de:\n\n• Mantener la confidencialidad de su contraseña\n• Todas las actividades que ocurran bajo su cuenta\n• Notificar inmediatamente cualquier uso no autorizado de su cuenta',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '4. Uso Aceptable',
              content: 'Usted acepta utilizar Sumly únicamente para fines legales y de acuerdo con estos términos. Está prohibido:\n\n• Subir contenido que viole derechos de autor o propiedad intelectual\n• Compartir contenido ilegal, difamatorio o inapropiado\n• Intentar acceder sin autorización a los sistemas de Sumly\n• Usar la aplicación para spam o actividades comerciales no autorizadas\n• Redistribuir o revender el servicio sin permiso',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '5. Contenido del Usuario',
              content: 'Usted retiene todos los derechos sobre el contenido que sube a Sumly. Al usar nuestro servicio, nos otorga una licencia limitada para:\n\n• Procesar y analizar sus documentos para generar resúmenes\n• Almacenar temporalmente sus archivos para proporcionar el servicio\n• Crear versiones de audio de sus documentos\n\nSus documentos son privados y no serán compartidos con terceros sin su consentimiento.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '6. Límites y Cuotas',
              content: 'Sumly puede establecer límites en el uso del servicio, incluyendo:\n\n• Número de documentos procesados por mes\n• Tamaño máximo de archivos\n• Cantidad de almacenamiento\n\nEstos límites pueden variar según el tipo de cuenta (gratuita o premium).',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '7. Precisión y Disponibilidad',
              content: 'Si bien nos esforzamos por proporcionar resúmenes precisos, Sumly utiliza inteligencia artificial que puede cometer errores. El servicio se proporciona "tal cual" y no garantizamos:\n\n• Precisión absoluta de los resúmenes generados\n• Disponibilidad ininterrumpida del servicio\n• Resultados específicos',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '8. Modificaciones al Servicio',
              content: 'Nos reservamos el derecho de modificar, suspender o discontinuar cualquier aspecto de Sumly en cualquier momento, con o sin previo aviso.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '9. Terminación',
              content: 'Podemos suspender o terminar su acceso a Sumly si:\n\n• Viola estos Términos y Condiciones\n• Usa el servicio de manera fraudulenta o ilegal\n• No paga las tarifas aplicables (para cuentas premium)\n\nUsted puede cancelar su cuenta en cualquier momento desde la configuración de la aplicación.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '10. Limitación de Responsabilidad',
              content: 'En la máxima medida permitida por la ley, Sumly no será responsable por:\n\n• Pérdida de datos o contenido\n• Daños indirectos o consecuentes\n• Interrupciones del servicio\n• Errores en los resúmenes generados',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '11. Propiedad Intelectual',
              content: 'Sumly y todos sus componentes (diseño, código, marca) son propiedad de sus creadores y están protegidos por leyes de propiedad intelectual. No puede copiar, modificar o distribuir la aplicación sin autorización.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '12. Cambios en los Términos',
              content: 'Podemos actualizar estos Términos y Condiciones ocasionalmente. Le notificaremos sobre cambios significativos mediante la aplicación o por correo electrónico. El uso continuado de Sumly después de los cambios constituye su aceptación de los nuevos términos.',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              title: '13. Contacto',
              content: 'Si tiene preguntas sobre estos Términos y Condiciones, puede contactarnos:\n\n• Email: support@sumly.app\n• WhatsApp: +593 984173150',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),

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
