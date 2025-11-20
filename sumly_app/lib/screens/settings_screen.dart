import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../models/models.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DocumentService _documentService = DocumentService();

  User? _user;
  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  // Settings
  bool _notifications = true;
  bool _autoPlay = false;
  double _defaultSpeed = 1.0;
  String _voiceLanguage = 'es-ES';
  bool _wifiOnly = false;
  String _summaryLength = 'medium';
  String _audioLanguage = 'es-ES';
  double _readingSpeed = 1.0;
  String _fontSize = 'medium';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    try {
      final userResult = await _authService.getProfile();
      final docsResult = await _documentService.getDocuments();

      if (mounted) {
        setState(() {
          if (userResult['success'] == true) {
            _user = userResult['user'];
          }
          if (docsResult['success'] == true) {
            _documents = docsResult['documents'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _autoPlay = prefs.getBool('autoPlay') ?? false;
      _defaultSpeed = prefs.getDouble('defaultSpeed') ?? 1.0;
      _voiceLanguage = prefs.getString('voiceLanguage') ?? 'es-ES';
      _wifiOnly = prefs.getBool('wifiOnly') ?? false;
      _summaryLength = prefs.getString('summaryLength') ?? 'medium';
      _audioLanguage = prefs.getString('audioLanguage') ?? 'es-ES';
      _readingSpeed = prefs.getDouble('readingSpeed') ?? 1.0;
      _fontSize = prefs.getString('fontSize') ?? 'medium';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('autoPlay', _autoPlay);
    await prefs.setDouble('defaultSpeed', _defaultSpeed);
    await prefs.setString('voiceLanguage', _voiceLanguage);
    await prefs.setBool('wifiOnly', _wifiOnly);
    await prefs.setString('summaryLength', _summaryLength);
    await prefs.setString('audioLanguage', _audioLanguage);
    await prefs.setDouble('readingSpeed', _readingSpeed);
    await prefs.setString('fontSize', _fontSize);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(isDark),
                  const SizedBox(height: 48),
                  
                  // CUENTA
                  _buildSection(
                    title: 'CUENTA',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    children: [
                      _buildActionTile(
                        title: 'Editar perfil',
                        subtitle: 'Cambia tu nombre y foto',
                        icon: Icons.edit_rounded,
                        onTap: _showEditProfileDialog,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        title: 'Cambiar contraseña',
                        subtitle: 'Actualiza tu contraseña',
                        icon: Icons.lock_outline_rounded,
                        onTap: _showChangePasswordDialog,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        title: 'Eliminar cuenta',
                        subtitle: 'Borrar permanentemente',
                        icon: Icons.delete_forever_rounded,
                        iconColor: AppColors.error,
                        onTap: _showDeleteAccountDialog,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // PREFERENCIAS DE RESUMEN
                  _buildSection(
                    title: 'PREFERENCIAS DE RESUMEN',
                    icon: Icons.tune_rounded,
                    isDark: isDark,
                    children: [
                      _buildSelectTile(
                        title: 'Longitud del resumen',
                        subtitle: _getSummaryLengthName(_summaryLength),
                        icon: Icons.format_size_rounded,
                        onTap: () => _showSummaryLengthDialog(),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSelectTile(
                        title: 'Idioma de audio',
                        subtitle: _getLanguageName(_audioLanguage),
                        icon: Icons.language_rounded,
                        onTap: () => _showLanguageDialog(),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSliderTile(
                        title: 'Velocidad de lectura',
                        subtitle: '${_readingSpeed}x',
                        icon: Icons.speed_rounded,
                        value: _readingSpeed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        onChanged: (value) {
                          setState(() => _readingSpeed = value);
                          _saveSettings();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // APARIENCIA
                  _buildSection(
                    title: 'APARIENCIA',
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
                      _buildDivider(isDark),
                      _buildSelectTile(
                        title: 'Tamaño de fuente',
                        subtitle: _getFontSizeName(_fontSize),
                        icon: Icons.text_fields_rounded,
                        onTap: () => _showFontSizeDialog(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // NOTIFICACIONES
                  _buildSection(
                    title: 'NOTIFICACIONES',
                    icon: Icons.notifications_outlined,
                    isDark: isDark,
                    children: [
                      _buildSwitchTile(
                        title: 'Resumen completado',
                        subtitle: 'Notificar cuando esté listo',
                        icon: Icons.notifications_active_outlined,
                        value: _notifications,
                        onChanged: (value) {
                          setState(() => _notifications = value);
                          _saveSettings();
                        },
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        title: 'Nuevas funcionalidades',
                        subtitle: 'Avisar sobre actualizaciones',
                        icon: Icons.new_releases_outlined,
                        value: _autoPlay,
                        onChanged: (value) {
                          setState(() => _autoPlay = value);
                          _saveSettings();
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // SUSCRIPCIÓN
                  _buildSection(
                    title: 'SUSCRIPCIÓN',
                    icon: Icons.workspace_premium_rounded,
                    isDark: isDark,
                    children: [
                      _buildSubscriptionCard(isDark),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // AYUDA Y SOPORTE
                  _buildSection(
                    title: 'AYUDA Y SOPORTE',
                    icon: Icons.help_outline_rounded,
                    isDark: isDark,
                    children: [
                      _buildActionTile(
                        title: 'WhatsApp Support',
                        subtitle: 'Contacta con soporte',
                        icon: Icons.chat_rounded,
                        onTap: () => _openWhatsApp(),
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        title: 'Términos y condiciones',
                        subtitle: 'Ver políticas de uso',
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/terms');
                        },
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        title: 'Política de privacidad',
                        subtitle: 'Cómo manejamos tus datos',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/privacy');
                        },
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _buildActionTile(
                        title: 'Versión de la app',
                        subtitle: '1.0.0',
                        icon: Icons.info_outline_rounded,
                        onTap: () {},
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // CERRAR SESIÓN
                  _buildLogoutButton(isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Configuración',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.darkAccent : AppColors.lightAccent,
            isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.black : AppColors.white,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: isDark ? AppColors.black : AppColors.white,
                    backgroundImage: _user?.avatar != null && _user!.avatar!.isNotEmpty
                        ? (_user!.avatar!.startsWith('data:')
                            ? MemoryImage(base64Decode(_user!.avatar!.split(',')[1]))
                            : NetworkImage(_user!.avatar!) as ImageProvider)
                        : null,
                    child: _user?.avatar == null || _user!.avatar!.isEmpty
                        ? Text(
                            (_user?.name ?? 'U').substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.black : AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.name ?? 'Usuario',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.black : AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: (isDark ? AppColors.black : AppColors.white).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.black : AppColors.white).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_documents.length} documentos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppColors.black : AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
              (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
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
      trailing: Transform.scale(
        scale: 1.1,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
        ),
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
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
                  (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value}x',
            onChanged: onChanged,
            activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.2),
              (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
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
        Icons.chevron_right_rounded,
        size: 24,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (iconColor ?? (isDark ? AppColors.darkAccent : AppColors.lightAccent)).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isDark ? AppColors.darkAccent : AppColors.lightAccent),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
        Icons.chevron_right_rounded,
        size: 24,
        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    );
  }

  Widget _buildSubscriptionCard(bool isDark) {
    final plan = _user?.role == 'pro' ? 'Pro' : 'Free';
    final docsThisMonth = _documents.where((doc) {
      final now = DateTime.now();
      return doc.createdAt.year == now.year && doc.createdAt.month == now.month;
    }).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Actual',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              if (plan == 'Free')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppColors.darkAccent : AppColors.lightAccent,
                        isDark ? AppColors.darkAccent2 : AppColors.lightAccent2,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (plan == 'Free') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.1),
                    (isDark ? AppColors.darkAccent2 : AppColors.lightAccent2).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Has usado $docsThisMonth de 10 documentos este mes',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showLogoutDialog,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  String _getSummaryLengthName(String length) {
    final lengths = {
      'short': 'Corto (1-2 páginas)',
      'medium': 'Medio (3-5 páginas)',
      'long': 'Largo (6-10 páginas)',
    };
    return lengths[length] ?? 'Medio';
  }

  String _getFontSizeName(String size) {
    final sizes = {
      'small': 'Pequeño',
      'medium': 'Mediano',
      'large': 'Grande',
    };
    return sizes[size] ?? 'Mediano';
  }

  Future<void> _changeProfilePhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Cambiar foto de perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
              title: Text(
                'Tomar foto',
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              ),
              title: Text(
                'Elegir de galería',
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_user?.avatar != null && _user!.avatar!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: AppColors.error),
                title: Text('Eliminar foto', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        final result = await _authService.updateProfile(avatar: base64Image);

        if (mounted) {
          if (result['success'] == true) {
            setState(() {
              _user = result['user'];
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Foto de perfil actualizada'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Error al actualizar foto'),
                backgroundColor: AppColors.error,
              ),
            );
          }
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

  Future<void> _removeProfilePhoto() async {
    try {
      final result = await _authService.updateProfile(avatar: '');

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _user = result['user'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto de perfil eliminada'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
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

  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Editar Perfil',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.darkAccent : AppColors.lightAccent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(color: isDark ? AppColors.darkAccent : AppColors.lightAccent),
                ),
              );

              final result = await _authService.updateProfile(
                name: nameController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context);

                if (result['success'] == true) {
                  setState(() {
                    _user = result['user'];
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Perfil actualizado'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Error al actualizar'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cambiar Contraseña',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                labelStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                labelStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Las contraseñas no coinciden'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final result = await _authService.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Operación completada'),
                    backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Eliminar cuenta',
          style: TextStyle(color: AppColors.error),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar tu cuenta permanentemente?\n\nEsta acción no se puede deshacer.',
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
              // Implement delete account logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Función en desarrollo'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showSummaryLengthDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Longitud del resumen',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['short', 'medium', 'long'].map((length) {
            return RadioListTile<String>(
              title: Text(
                _getSummaryLengthName(length),
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              value: length,
              groupValue: _summaryLength,
              onChanged: (value) {
                setState(() => _summaryLength = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Seleccionar idioma',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['es-ES', 'en-US', 'fr-FR', 'de-DE'].map((lang) {
            return RadioListTile<String>(
              title: Text(
                _getLanguageName(lang),
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              value: lang,
              groupValue: _audioLanguage,
              onChanged: (value) {
                setState(() => _audioLanguage = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Tamaño de fuente',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['small', 'medium', 'large'].map((size) {
            return RadioListTile<String>(
              title: Text(
                _getFontSizeName(size),
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              activeColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              value: size,
              groupValue: _fontSize,
              onChanged: (value) {
                setState(() => _fontSize = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
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
      // Intentar abrir directamente sin verificar primero (mejor compatibilidad)
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo abrir WhatsApp. Asegúrate de tener WhatsApp instalado.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al intentar abrir WhatsApp. Asegúrate de tener la aplicación instalada.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await _authService.logout();

              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
