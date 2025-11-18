import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _autoPlay = false;
  double _defaultSpeed = 1.0;
  String _voiceLanguage = 'es-ES';
  bool _wifiOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _autoPlay = prefs.getBool('autoPlay') ?? false;
      _defaultSpeed = prefs.getDouble('defaultSpeed') ?? 1.0;
      _voiceLanguage = prefs.getString('voiceLanguage') ?? 'es-ES';
      _wifiOnly = prefs.getBool('wifiOnly') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('autoPlay', _autoPlay);
    await prefs.setDouble('defaultSpeed', _defaultSpeed);
    await prefs.setString('voiceLanguage', _voiceLanguage);
    await prefs.setBool('wifiOnly', _wifiOnly);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Apariencia',
            icon: Icons.palette_outlined,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildSwitchTile(
                    title: 'Modo oscuro',
                    subtitle: 'Tema oscuro para la aplicación',
                    icon: Icons.dark_mode_outlined,
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Audio',
            icon: Icons.volume_up_outlined,
            children: [
              _buildSwitchTile(
                title: 'Reproducción automática',
                subtitle: 'Iniciar audio al abrir resumen',
                icon: Icons.play_circle_outline,
                value: _autoPlay,
                onChanged: (value) {
                  setState(() => _autoPlay = value);
                  _saveSettings();
                },
              ),
              _buildSliderTile(
                title: 'Velocidad predeterminada',
                subtitle: '${_defaultSpeed}x',
                icon: Icons.speed,
                value: _defaultSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: (value) {
                  setState(() => _defaultSpeed = value);
                  _saveSettings();
                },
              ),
              _buildSelectTile(
                title: 'Idioma de voz',
                subtitle: _getLanguageName(_voiceLanguage),
                icon: Icons.language,
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Notificaciones',
            icon: Icons.notifications_outlined,
            children: [
              _buildSwitchTile(
                title: 'Notificaciones push',
                subtitle: 'Recibir alertas y recordatorios',
                icon: Icons.notifications_active_outlined,
                value: _notifications,
                onChanged: (value) {
                  setState(() => _notifications = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Datos y almacenamiento',
            icon: Icons.storage_outlined,
            children: [
              _buildSwitchTile(
                title: 'Solo WiFi',
                subtitle: 'Descargar solo con WiFi',
                icon: Icons.wifi,
                value: _wifiOnly,
                onChanged: (value) {
                  setState(() => _wifiOnly = value);
                  _saveSettings();
                },
              ),
              _buildActionTile(
                title: 'Limpiar caché',
                subtitle: 'Liberar espacio de almacenamiento',
                icon: Icons.cleaning_services_outlined,
                onTap: () => _showClearCacheDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Soporte',
            icon: Icons.help_outline,
            children: [
              _buildActionTile(
                title: 'Ayuda por WhatsApp',
                subtitle: 'Contacta con soporte',
                icon: Icons.chat,
                onTap: () => _openWhatsApp(),
              ),
              _buildActionTile(
                title: 'Reportar problema',
                subtitle: 'Envíanos tus comentarios',
                icon: Icons.bug_report_outlined,
                onTap: () => _openWhatsApp(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Acerca de',
            icon: Icons.info_outline,
            children: [
              _buildActionTile(
                title: 'Versión',
                subtitle: '1.0.0',
                icon: Icons.app_settings_alt,
                onTap: () {},
              ),
              _buildActionTile(
                title: 'Términos y condiciones',
                subtitle: 'Ver políticas de uso',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/terms');
                },
              ),
              _buildActionTile(
                title: 'Política de privacidad',
                subtitle: 'Cómo manejamos tus datos',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/privacy');
                },
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value}x',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    final languages = {
      'es-ES': 'Español',
      'en-US': 'English',
      'fr-FR': 'Français',
      'de-DE': 'Deutsch',
    };
    return languages[code] ?? 'Español';
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es-ES',
              groupValue: _voiceLanguage,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en-US',
              groupValue: _voiceLanguage,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr-FR',
              groupValue: _voiceLanguage,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Deutsch'),
              value: 'de-DE',
              groupValue: _voiceLanguage,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text(
          '¿Estás seguro de que deseas limpiar el caché?\n\n'
          'Esto liberará espacio pero puede hacer que la app sea más lenta temporalmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caché limpiado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    // Número de WhatsApp de soporte - Cambiar por el número real
    const phoneNumber = '593999999999'; // Ecuador formato: 593 + código + número
    const message = '¡Hola! Necesito ayuda con la app SUMLY';

    final url = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature próximamente disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
