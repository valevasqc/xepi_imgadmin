import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Category detail screen for editing category information
class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isActive = true;

  // Mock data - replace with Firestore data
  final Map<String, dynamic> _mockCategory = {
    'id': 'cat_1',
    'name': '20x30 cms',
    'code': 'CUA-2030',
    'primaryCategory': 'Cuadros de Latón',
    'price': 35,
    'bulk2': 32, // Precio por 2 unidades
    'bulk4': 30, // Precio por 4 unidades
    'itemCount': 124,
    'displayOrder': 1,
  };

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mockCategory['name'],
                        style: AppTheme.heading2,
                      ),
                      Text(
                        _mockCategory['primaryCategory'],
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Active Toggle
                Row(
                  children: [
                    Text(
                      _isActive ? 'Activa' : 'Inactiva',
                      style: AppTheme.bodyMedium.copyWith(
                        color:
                            _isActive ? AppTheme.success : AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                        // TODO: Update Firestore
                      },
                      activeThumbColor: AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(width: AppTheme.spacingL),
                // Delete Button
                OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteDialog();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
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
                        // Image Section
                        _buildSection(
                          title: 'IMAGEN DE PORTADA',
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundGray,
                                borderRadius: AppTheme.borderRadiusMedium,
                                border: Border.all(
                                  color: AppTheme.lightGray,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 48,
                                    color: AppTheme.mediumGray,
                                  ),
                                  const SizedBox(height: AppTheme.spacingM),
                                  Text(
                                    'Agregar imagen de portada',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Upload image
                                    },
                                    icon: const Icon(Icons.upload_rounded),
                                    label: const Text('Subir Imagen'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Basic Information
                        _buildSection(
                          title: 'INFORMACIÓN BÁSICA',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _mockCategory['name'],
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre de la Categoría',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El nombre es requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingL),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _mockCategory['code'],
                                      decoration: const InputDecoration(
                                        labelText: 'Código',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El código es requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              TextFormField(
                                initialValue: _mockCategory['primaryCategory'],
                                decoration: const InputDecoration(
                                  labelText: 'Categoría Principal',
                                  hintText: 'Ej: Cuadros de Latón, Juguetes',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              TextFormField(
                                initialValue:
                                    '${_mockCategory['displayOrder']}',
                                decoration: const InputDecoration(
                                  labelText: 'Orden de Visualización',
                                  hintText: '1, 2, 3...',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Pricing Section
                        _buildSection(
                          title: 'PRECIOS',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todos los productos en esta categoría usarán estos precios por defecto',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              TextFormField(
                                initialValue: '${_mockCategory['price']}',
                                decoration: const InputDecoration(
                                  labelText: 'Precio Base',
                                  prefixText: 'Q',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El precio es requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              const Divider(color: AppTheme.lightGray),
                              const SizedBox(height: AppTheme.spacingM),
                              Text(
                                'Precios por Volumen (Opcional)',
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: '${_mockCategory['bulk2']}',
                                      decoration: const InputDecoration(
                                        labelText: 'Precio por 2 unidades',
                                        prefixText: 'Q',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingL),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: '${_mockCategory['bulk4']}',
                                      decoration: const InputDecoration(
                                        labelText: 'Precio por 4+ unidades',
                                        prefixText: 'Q',
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Stats Section
                        _buildSection(
                          title: 'ESTADÍSTICAS',
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGray,
                              borderRadius: AppTheme.borderRadiusMedium,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  label: 'Total de Productos',
                                  value: '${_mockCategory['itemCount']}',
                                  icon: Icons.inventory_2_rounded,
                                  color: AppTheme.blue,
                                ),
                                _buildStatItem(
                                  label: 'En Stock',
                                  value:
                                      '${(_mockCategory['itemCount'] * 0.87).toInt()}',
                                  icon: Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                ),
                                _buildStatItem(
                                  label: 'Stock Bajo',
                                  value:
                                      '${(_mockCategory['itemCount'] * 0.05).toInt()}',
                                  icon: Icons.warning_rounded,
                                  color: AppTheme.warning,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            ElevatedButton.icon(
                              onPressed: _saveCategory,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Guardar Cambios'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXL,
                                  vertical: AppTheme.spacingL,
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
          Text(
            title,
            style: AppTheme.heading4.copyWith(
              letterSpacing: 1.2,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          child,
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          value,
          style: AppTheme.heading2.copyWith(color: color),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: AppTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría guardada exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar Categoría?',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Esta acción no se puede deshacer. Los productos en esta categoría quedarán sin categoría.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete category
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Categoría eliminada'),
                  backgroundColor: AppTheme.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
