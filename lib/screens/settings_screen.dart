import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';

/// Settings screen with WhatsApp configuration and user profile
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int _productCount = 0;
  int _categoryCount = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _loadData(user?.uid);
  }

  Future<void> _loadData(String? uid) async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('products').count().get(),
      db.collection('categories').count().get(),
      if (uid != null) db.collection('users').doc(uid).get(),
    ]);

    if (!mounted) return;
    setState(() {
      _productCount = (results[0] as AggregateQuerySnapshot).count ?? 0;
      _categoryCount = (results[1] as AggregateQuerySnapshot).count ?? 0;
      if (uid != null && results.length > 2) {
        final userDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;
        if (userDoc.exists) {
          _whatsappController.text =
              (userDoc.data()?['whatsapp'] as String?) ?? '';
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final futures = <Future>[
        if (_nameController.text.trim() != (user.displayName ?? ''))
          user.updateDisplayName(_nameController.text.trim()),
        FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'whatsapp': _whatsappController.text.trim()},
          SetOptions(merge: true),
        ),
      ];
      await Future.wait(futures);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppTheme.spacingM),
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
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text
                                                  .trim()
                                                  .split(' ')
                                                  .take(2)
                                                  .map((w) => w[0].toUpperCase())
                                                  .join()
                                              : '?',
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
                                  color: AppTheme.blue.withValues(alpha: 0.1),
                                  borderRadius: AppTheme.borderRadiusSmall,
                                  border: Border.all(
                                    color: AppTheme.blue.withValues(alpha: 0.3),
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
                              _buildInfoRow('Productos Totales', '$_productCount'),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildInfoRow('Categorías', '$_categoryCount'),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveSettings,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.white),
                                      )
                                    : const Icon(Icons.save_rounded),
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
                  color: AppTheme.blue.withValues(alpha: 0.1),
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
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Cambiar Contraseña', style: AppTheme.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Text(errorMsg!,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.danger)),
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Contraseña Actual'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nueva Contraseña'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final newPass = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (current.isEmpty || newPass.isEmpty) {
                  setDialogState(
                      () => errorMsg = 'Completa todos los campos');
                  return;
                }
                if (newPass != confirm) {
                  setDialogState(
                      () => errorMsg = 'Las contraseñas no coinciden');
                  return;
                }
                if (newPass.length < 6) {
                  setDialogState(() =>
                      errorMsg = 'Mínimo 6 caracteres');
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: current,
                  );
                  // Capture before async gap to avoid BuildContext-across-await lint.
                  final messenger = ScaffoldMessenger.of(context);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass);

                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña actualizada'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  final msg = e.code == 'wrong-password' ||
                          e.code == 'invalid-credential'
                      ? 'Contraseña actual incorrecta'
                      : 'Error: ${e.message}';
                  setDialogState(() => errorMsg = msg);
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    ).then((_) {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
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
            onPressed: () async {
              Navigator.pop(context);

              try {
                await AuthService.signOut();

                if (context.mounted) {
                  // Navigate back to login (main.dart will handle the redirect)
                  Navigator.of(context).pushReplacementNamed('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
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
