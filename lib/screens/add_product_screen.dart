import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Add new product screen with barcode scanning
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _warehouseCodeController = TextEditingController();
  final _temaController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  int _warehouseStock = 0;
  int _storeStock = 0;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _warehouseCodeController.dispose();
    _temaController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _notesController.dispose();
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
                  'Agregar Nuevo Producto',
                  style: AppTheme.heading2,
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
                        // Barcode Section
                        _buildSection(
                          title: 'CÓDIGO DE BARRAS',
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _barcodeController,
                                  decoration: const InputDecoration(
                                    hintText: 'Escanear o ingresar código',
                                    prefixIcon: Icon(Icons.qr_code_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El código de barras es requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Open barcode scanner
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Función de escáner próximamente'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: const Text('Escanear'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Basic Information
                        _buildSection(
                          title: 'INFORMACIÓN BÁSICA',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Producto',
                                  hintText: 'Ej: Cuadro de Latón Paisaje',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El nombre es requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _warehouseCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Código de Bodega',
                                        hintText: 'Ej: COD-56',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El código es requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingL),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'Categoría',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Cuadros 20x30',
                                          child: Text('Cuadros 20x30 cms'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Cuadros 30x40',
                                          child: Text('Cuadros 30x40 cms'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Círculos',
                                          child: Text('Círculos 30 cms'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Juguetes',
                                          child: Text('Juguetes Educativos'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Selecciona una categoría';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Stock Section
                        _buildSection(
                          title: 'INVENTARIO INICIAL',
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStockInput(
                                  label: 'Bodega',
                                  value: _warehouseStock,
                                  onChanged: (value) {
                                    setState(() {
                                      _warehouseStock = value;
                                    });
                                  },
                                  icon: Icons.warehouse_rounded,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingL),
                              Expanded(
                                child: _buildStockInput(
                                  label: 'Tienda',
                                  value: _storeStock,
                                  onChanged: (value) {
                                    setState(() {
                                      _storeStock = value;
                                    });
                                  },
                                  icon: Icons.store_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Additional Details
                        _buildSection(
                          title: 'DETALLES ADICIONALES (Opcional)',
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _temaController,
                                      decoration: const InputDecoration(
                                        labelText: 'Tema',
                                        hintText: 'Ej: Paisaje, Abstracto',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingL),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sizeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Tamaño',
                                        hintText: 'Ej: 20x30 cms',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              TextFormField(
                                controller: _colorController,
                                decoration: const InputDecoration(
                                  labelText: 'Color',
                                  hintText: 'Ej: Dorado, Plateado',
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Notas',
                                  hintText:
                                      'Información adicional sobre el producto',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Images Section
                        _buildSection(
                          title: 'IMÁGENES',
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingXL),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGray,
                              borderRadius: AppTheme.borderRadiusMedium,
                              border: Border.all(
                                color: AppTheme.lightGray,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 48,
                                  color: AppTheme.mediumGray,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  'Agregar imágenes después de crear el producto',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.mediumGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingS),
                                Text(
                                  'Podrás subir imágenes en la página de detalles',
                                  style: AppTheme.bodySmall,
                                  textAlign: TextAlign.center,
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
                              onPressed: _saveProduct,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Guardar Producto'),
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

  Widget _buildStockInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.blue, size: 32),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (value > 0) onChanged(value - 1);
                },
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.darkGray,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: Text(
                  '$value',
                  style: AppTheme.heading2,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Go back after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }
}
