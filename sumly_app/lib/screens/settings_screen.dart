import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(color: isDark ? AppColors.gold : AppColors.brown),
        ),
      );
    }

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
          'Configuración',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
            isDark: isDark,
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
                    isDark: isDark,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Audio',
            icon: Icons.volume_up_outlined,
            isDark: isDark,
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
                isDark: isDark,
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
                isDark: isDark,
              ),
              _buildSelectTile(
                title: 'Idioma de voz',
                subtitle: _getLanguageName(_voiceLanguage),
                icon: Icons.language,
                onTap: () => _showLanguageDialog(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Notificaciones',
            icon: Icons.notifications_outlined,
            isDark: isDark,
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
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Datos y almacenamiento',
            icon: Icons.storage_outlined,
            isDark: isDark,
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
                isDark: isDark,
              ),
              _buildActionTile(
                title: 'Limpiar caché',
                subtitle: 'Liberar espacio de almacenamiento',
                icon: Icons.cleaning_services_outlined,
                onTap: () => _showClearCacheDialog(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Soporte',
            icon: Icons.help_outline,
            isDark: isDark,
            children: [
              _buildActionTile(
                title: 'Ayuda por WhatsApp',
                subtitle: 'Contacta con soporte',
                icon: Icons.chat,
                onTap: () => _openWhatsApp(),
                isDark: isDark,
              ),
              _buildActionTile(
                title: 'Reportar problema',
                subtitle: 'Envíanos tus comentarios',
                icon: Icons.bug_report_outlined,
                onTap: () => _openWhatsApp(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: 'Acerca de',
            icon: Icons.info_outline,
            isDark: isDark,
            children: [
              _buildActionTile(
                title: 'Versión',
                subtitle: '1.0.0',
                icon: Icons.app_settings_alt,
                onTap: () {},
                isDark: isDark,
              ),
              _buildActionTile(
                title: 'Términos y condiciones',
                subtitle: 'Ver políticas de uso',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/terms');
                },
                isDark: isDark,
              ),
              _buildActionTile(
                title: 'Política de privacidad',
                subtitle: 'Cómo manejamos tus datos',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.pushNamed(context, '/privacy');
                },
                isDark: isDark,
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
    required bool isDark,
  }) {
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
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: AppColors.cardShadow(isDark),
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
    required bool isDark,
  }) {
    final accentColor = isDark ? AppColors.gold : AppColors.brown;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: accentColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: accentColor,
      ),
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
    required bool isDark,
  }) {
    final accentColor = isDark ? AppColors.gold : AppColors.brown;

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
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: accentColor,
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
            activeColor: accentColor,
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
    required bool isDark,
  }) {
    final accentColor = isDark ? AppColors.gold : AppColors.brown;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: accentColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Seleccionar idioma',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Español', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              value: 'es-ES',
              groupValue: _voiceLanguage,
              activeColor: isDark ? AppColors.gold : AppColors.brown,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('English', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              value: 'en-US',
              groupValue: _voiceLanguage,
              activeColor: isDark ? AppColors.gold : AppColors.brown,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Français', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              value: 'fr-FR',
              groupValue: _voiceLanguage,
              activeColor: isDark ? AppColors.gold : AppColors.brown,
              onChanged: (value) {
                setState(() => _voiceLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Deutsch', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              value: 'de-DE',
              groupValue: _voiceLanguage,
              activeColor: isDark ? AppColors.gold : AppColors.brown,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Limpiar caché',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Text(
          '¿Estás seguro de que deseas limpiar el caché?\n\n'
          'Esto liberará espacio pero puede hacer que la app sea más lenta temporalmente.',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Caché limpiado exitosamente'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = '593984173150';
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
            SnackBar(
              content: const Text('No se pudo abrir WhatsApp'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
