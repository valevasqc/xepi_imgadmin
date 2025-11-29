import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _selectedCategory;
  String? _selectedCategoryId;
  int _warehouseStock = 0;
  int _storeStock = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  
  List<Map<String, dynamic>> _categories = [];
  List<String> _allTemas = [];
  List<String> _selectedTemas = [];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTemas();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await _firestore.collection('categories').get();
      setState(() {
        _categories = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'defaultPrice': data['defaultPrice'],
          };
        }).toList();
        _categories.sort((a, b) => a['name'].compareTo(b['name']));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadTemas() async {
    try {
      final snapshot = await _firestore.collection('temas').get();
      setState(() {
        _allTemas = snapshot.docs.map((doc) => doc.id).toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading temas: $e');
    }
  }

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
                                    child: _isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : DropdownButtonFormField<String>(
                                            value: _selectedCategoryId,
                                            decoration: const InputDecoration(
                                              labelText: 'Categoría',
                                            ),
                                            items: _categories.map((category) {
                                              return DropdownMenuItem<String>(
                                                value: category['id'],
                                                child: Text(category['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedCategoryId = value;
                                                _selectedCategory = _categories
                                                    .firstWhere((c) =>
                                                        c['id'] == value)['name'];
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Autocomplete<String>(
                                          optionsBuilder:
                                              (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<String>.empty();
                                            }
                                            return _allTemas.where((String option) {
                                              return option
                                                  .toLowerCase()
                                                  .contains(textEditingValue.text
                                                      .toLowerCase());
                                            });
                                          },
                                          onSelected: (String selection) {
                                            if (!_selectedTemas.contains(selection)) {
                                              setState(() {
                                                _selectedTemas.add(selection);
                                              });
                                            }
                                            _temaController.clear();
                                          },
                                          fieldViewBuilder: (context, controller,
                                              focusNode, onFieldSubmitted) {
                                            _temaController.text = controller.text;
                                            return TextFormField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              decoration: InputDecoration(
                                                labelText: 'Temas',
                                                hintText:
                                                    'Escribe para buscar o agregar',
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.add_rounded),
                                                  onPressed: () {
                                                    final newTema =
                                                        controller.text.trim();
                                                    if (newTema.isNotEmpty &&
                                                        !_selectedTemas
                                                            .contains(newTema)) {
                                                      setState(() {
                                                        _selectedTemas.add(newTema);
                                                        if (!_allTemas
                                                            .contains(newTema)) {
                                                          _allTemas.add(newTema);
                                                          _allTemas.sort();
                                                        }
                                                      });
                                                      controller.clear();
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedTemas.isNotEmpty) ...{
                                    const SizedBox(height: AppTheme.spacingM),
                                    Wrap(
                                      spacing: AppTheme.spacingS,
                                      runSpacing: AppTheme.spacingS,
                                      children: _selectedTemas
                                          .map((tema) => Chip(
                                                label: Text(tema),
                                                deleteIcon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                ),
                                                onDeleted: () {
                                                  setState(() {
                                                    _selectedTemas.remove(tema);
                                                  });
                                                },
                                              ))
                                          .toList(),
                                    ),
                                  },
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Row(
                                children: [
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
                              onPressed: _isSaving ? null : _saveProduct,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppTheme.white),
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(
                                  _isSaving ? 'Guardando...' : 'Guardar Producto'),
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final barcode = _barcodeController.text.trim();
      
      // Check if barcode already exists
      final existingProduct = await _firestore
          .collection('products')
          .doc(barcode)
          .get();
      
      if (existingProduct.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.white),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Ya existe un producto con el código $barcode',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Create product document
      final productData = {
        'barcode': barcode,
        'name': _nameController.text.trim(),
        'warehouseCode': _warehouseCodeController.text.trim(),
        'categoryId': _selectedCategoryId,
        'categoryName': _selectedCategory,
        'stockWarehouse': _warehouseStock,
        'stockStore': _storeStock,
        'size': _sizeController.text.trim().isNotEmpty
            ? _sizeController.text.trim()
            : null,
        'color': _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'temas': _selectedTemas.isNotEmpty ? _selectedTemas : [],
        'images': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore.collection('products').doc(barcode).set(productData);
      
      // Update temas collection for new temas
      final batch = _firestore.batch();
      for (final tema in _selectedTemas) {
        final temaRef = _firestore.collection('temas').doc(tema);
        final temaDoc = await temaRef.get();
        
        if (!temaDoc.exists) {
          batch.set(temaRef, {
            'name': tema,
            'productCount': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
          });
        } else {
          batch.update(temaRef, {
            'productCount': FieldValue.increment(1),
            'lastUsed': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Producto guardado exitosamente',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al guardar producto: $e',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
