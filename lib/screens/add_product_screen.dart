import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
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
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceOverrideController = TextEditingController();
  final _warehouseStockController = TextEditingController(text: '0');
  final _storeStockController = TextEditingController(text: '0');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _selectedCategoryId;
  String? _selectedCategoryCode;
  String? _selectedSubcategory;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  
  List<Map<String, dynamic>> _categories = [];
  List<String> _availableSubcategories = [];
  List<String> _allTemas = [];
  List<String> _selectedTemas = [];
  List<String> _uploadedImages = [];
  int _selectedImageIndex = 0;
  
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
            'code': data['code'] ?? '',
            'name': data['name'] ?? '',
            'subcategories': (data['subcategories'] as List?)?.cast<String>() ?? [],
            'defaultPrice': data['defaultPrice'],
          };
        }).toList();
        _categories.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onCategoryChanged(String? categoryId) {
    if (categoryId == null) return;
    
    final category = _categories.firstWhere((c) => c['id'] == categoryId);
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryCode = category['code'];
      _availableSubcategories = (category['subcategories'] as List).cast<String>();
      _selectedSubcategory = null; // Reset subcategory
    });
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
    _widthController.dispose();
    _heightController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _priceOverrideController.dispose();
    _warehouseStockController.dispose();
    _storeStockController.dispose();
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
                                                child: Text(category['name'] as String),
                                              );
                                            }).toList(),
                                            onChanged: _onCategoryChanged,
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
                              if (_availableSubcategories.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingM),
                                DropdownButtonFormField<String>(
                                  value: _selectedSubcategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Subcategoría',
                                  ),
                                  items: _availableSubcategories.map((sub) {
                                    return DropdownMenuItem<String>(
                                      value: sub,
                                      child: Text(sub),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSubcategory = value;
                                    });
                                  },
                                ),
                              ],
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
                                child: TextFormField(
                                  controller: _warehouseStockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Stock Bodega',
                                    hintText: '0',
                                    prefixIcon: Icon(Icons.warehouse_rounded),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Debe ser un número';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingL),
                              Expanded(
                                child: TextFormField(
                                  controller: _storeStockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Stock Tienda',
                                    hintText: '0',
                                    prefixIcon: Icon(Icons.store_rounded),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requerido';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Debe ser un número';
                                    }
                                    return null;
                                  },
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
                                          },
                                          fieldViewBuilder: (context, controller,
                                              focusNode, onFieldSubmitted) {
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
                                      controller: _widthController,
                                      decoration: const InputDecoration(
                                        labelText: 'Ancho',
                                        hintText: 'Ej: 20',
                                        suffixText: 'cms',
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingM),
                                    child: Text('x',
                                        style: AppTheme.heading2
                                            .copyWith(color: AppTheme.mediumGray)),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Alto',
                                        hintText: 'Ej: 30',
                                        suffixText: 'cms',
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _colorController,
                                      decoration: const InputDecoration(
                                        labelText: 'Color',
                                        hintText: 'Ej: Dorado, Plateado',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingL),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceOverrideController,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio Override',
                                        hintText: 'Opcional',
                                        prefixText: 'Q ',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                    ),
                                  ),
                                ],
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
                          title: 'IMÁGENES (Opcional)',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Upload button
                              OutlinedButton.icon(
                                onPressed: _isUploading ? null : _pickAndUploadImages,
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_photo_alternate_rounded),
                                label: Text(_isUploading ? 'Subiendo...' : 'Agregar Imágenes'),
                              ),
                              if (_uploadedImages.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingL),
                                // Image preview
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundGray,
                                    borderRadius: AppTheme.borderRadiusMedium,
                                    border: Border.all(color: AppTheme.lightGray),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: AppTheme.borderRadiusMedium,
                                    child: Image.network(
                                      _uploadedImages[_selectedImageIndex],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                // Thumbnails
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _uploadedImages.length,
                                    itemBuilder: (context, index) {
                                      final isSelected = index == _selectedImageIndex;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImageIndex = index;
                                          });
                                        },
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          margin: const EdgeInsets.only(right: AppTheme.spacingS),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSelected ? AppTheme.blue : AppTheme.lightGray,
                                              width: isSelected ? 3 : 1,
                                            ),
                                            borderRadius: AppTheme.borderRadiusSmall,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: AppTheme.borderRadiusSmall,
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  _uploadedImages[index],
                                                  fit: BoxFit.cover,
                                                  width: 80,
                                                  height: 80,
                                                ),
                                                if (index == 0)
                                                  Positioned(
                                                    top: 2,
                                                    right: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.yellow,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Text(
                                                        '⭐',
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
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

  Future<void> _pickAndUploadImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Pick multiple images
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Subiendo ${images.length} imagen(es)...',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                ),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Use temporary barcode for upload path
      final barcode = _barcodeController.text.trim().isNotEmpty
          ? _barcodeController.text.trim()
          : 'temp_${DateTime.now().millisecondsSinceEpoch}';

      final List<String> uploadedUrls = [];

      for (final image in images) {
        final bytes = await image.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${barcode}_${timestamp}_${image.name}';
        final ref = _storage.ref().child('products/$barcode/$fileName');

        // Upload with retry
        int retries = 0;
        bool uploadSuccess = false;
        String? downloadUrl;

        while (retries < 3 && !uploadSuccess) {
          try {
            await ref.putData(
              bytes,
              firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
            );
            downloadUrl = await ref.getDownloadURL();
            uploadedUrls.add(downloadUrl);
            uploadSuccess = true;
          } catch (e) {
            retries++;
            if (retries >= 3) {
              throw Exception('Error después de 3 intentos: $e');
            }
            await Future.delayed(Duration(seconds: retries));
          }
        }
      }

      setState(() {
        _uploadedImages.addAll(uploadedUrls);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  '${images.length} imagen(es) subida(s) exitosamente',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading images: $e');
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al subir imágenes: $e',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

      // Get category name
      final category = _categories.firstWhere((c) => c['id'] == _selectedCategoryId);
      final categoryName = category['name'] as String;
      
      // Build size string
      String? sizeString;
      if (_widthController.text.isNotEmpty && _heightController.text.isNotEmpty) {
        sizeString = '${_widthController.text} x ${_heightController.text} cms';
      } else if (_widthController.text.isNotEmpty) {
        sizeString = '${_widthController.text} cms';
      } else if (_heightController.text.isNotEmpty) {
        sizeString = '${_heightController.text} cms';
      }

      // Create product document
      final productData = {
        'barcode': barcode,
        'name': _nameController.text.trim(),
        'warehouseCode': _warehouseCodeController.text.trim(),
        'categoryId': _selectedCategoryId,
        'categoryCode': _selectedCategoryCode,
        'categoryName': categoryName,
        'subcategory': _selectedSubcategory,
        'stockWarehouse': int.parse(_warehouseStockController.text),
        'stockStore': int.parse(_storeStockController.text),
        'size': sizeString,
        'width': _widthController.text.isNotEmpty ? int.tryParse(_widthController.text) : null,
        'height': _heightController.text.isNotEmpty ? int.tryParse(_heightController.text) : null,
        'color': _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        'priceOverride': _priceOverrideController.text.trim().isNotEmpty
            ? double.tryParse(_priceOverrideController.text.trim())
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'temas': _selectedTemas.isNotEmpty ? _selectedTemas : [],
        'images': _uploadedImages,
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
