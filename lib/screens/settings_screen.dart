import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Settings screen with WhatsApp configuration and user profile
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController(text: '+502 5555-5555');
  final _nameController = TextEditingController(text: 'Administrador');
  final _emailController = TextEditingController(text: 'admin@xepi.com');

  @override
  void dispose() {
    _whatsappController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                Text(
                  'Configuración',
                  style: AppTheme.heading1,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        _buildSection(
                          title: 'PERFIL DE USUARIO',
                          icon: Icons.person_rounded,
                          child: Column(
                            children: [
                              // Avatar
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.blue,
                                            AppTheme.orange
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'AD',
                                          style: AppTheme.heading1.copyWith(
                                            color: AppTheme.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: AppTheme.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingXL),

                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingM),

                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Correo Electrónico',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: AppTheme.spacingL),

                              OutlinedButton.icon(
                                onPressed: () {
                                  _showChangePasswordDialog();
                                },
                                icon: const Icon(Icons.lock_outline_rounded),
                                label: const Text('Cambiar Contraseña'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // WhatsApp Configuration
                        _buildSection(
                          title: 'WHATSAPP',
                          icon: Icons.chat_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Número de WhatsApp para pedidos de clientes',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              TextFormField(
                                controller: _whatsappController,
                                decoration: const InputDecoration(
                                  labelText: 'Número de WhatsApp',
                                  hintText: '+502 1234-5678',
                                  prefixIcon: Icon(Icons.phone_rounded),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El número es requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.blue.withOpacity(0.1),
                                  borderRadius: AppTheme.borderRadiusSmall,
                                  border: Border.all(
                                    color: AppTheme.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: Text(
                                        'Este número será usado en la aplicación de clientes para enviar pedidos',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // App Information
                        _buildSection(
                          title: 'INFORMACIÓN DE LA APP',
                          icon: Icons.info_rounded,
                          child: Column(
                            children: [
                              _buildInfoRow('Versión', '1.0.0'),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildInfoRow(
                                  'Última Actualización', '23 Oct 2025'),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildInfoRow('Productos Totales', '612'),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildInfoRow('Categorías', '4'),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // TODO: Save settings
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Configuración guardada'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Guardar Cambios'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.all(AppTheme.spacingL),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Logout Button
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showLogoutDialog();
                                },
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Cerrar Sesión'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side:
                                      const BorderSide(color: AppTheme.danger),
                                  padding:
                                      const EdgeInsets.all(AppTheme.spacingL),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withOpacity(0.1),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                title,
                style: AppTheme.heading4.copyWith(
                  letterSpacing: 1.2,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cambiar Contraseña',
          style: AppTheme.heading3,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña Actual',
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Change password
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contraseña actualizada'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Cerrar Sesión?',
          style: AppTheme.heading3,
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Logout and navigate to login
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
