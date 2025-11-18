import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String? devCode; // Solo para desarrollo

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.devCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // En desarrollo, mostrar el código en un snackbar
    if (widget.devCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CÓDIGO DE DESARROLLO: ${widget.devCode}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 10),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que las contraseñas coincidan
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success']) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Contraseña reseteada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la pantalla de login
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al resetear contraseña'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    Colors.indigo.shade400,
                    Colors.purple.shade300,
                    Colors.pink.shade200,
                  ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.vpn_key,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Resetear\nContraseña',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'Ingresa el código que enviamos a ${widget.email} y tu nueva contraseña.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Code Field
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Código de 6 dígitos',
                              labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.pin_outlined,
                                color: isDarkMode ? Colors.purple[300] : Colors.indigo.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa el código';
                              }
                              if (value.length != 6) {
                                return 'El código debe tener 6 dígitos';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // New Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nueva Contraseña',
                              labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: isDarkMode ? Colors.purple[300] : Colors.indigo.shade400,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nueva contraseña';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirmar Contraseña',
                              labelStyle: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: isDarkMode ? Colors.purple[300] : Colors.indigo.shade400,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor confirma tu contraseña';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Reset Button
                        Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [
                                      const Color(0xFF6B46C1),
                                      const Color(0xFF553C9A),
                                    ]
                                  : [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDarkMode ? Colors.white : Colors.indigo.shade600,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Resetear Contraseña',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.indigo.shade600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
