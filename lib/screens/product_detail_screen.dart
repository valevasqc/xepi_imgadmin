import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Product detail screen with image gallery and full product information
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  bool _isLoadingInitialData = true;
  final Set<String> _preloadedImages = {}; // Track preloaded images

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _temasController;
  late TextEditingController _colorController;
  late TextEditingController _notesController;
  late TextEditingController _priceOverrideController;
  late TextEditingController _warehouseCodeController;
  late TextEditingController _categoryCodeController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  // Stock adjustment controllers
  late TextEditingController _warehouseStockAdjustmentController;
  late TextEditingController _storeStockAdjustmentController;

  // Category data cache
  Map<String, dynamic>? _categoryData;
  List<Map<String, dynamic>> _allCategories = [];
  List<String> _availableSubcategories = [];
  bool _categoriesLoaded = false;

  // Selected category/subcategory
  String? _selectedPrimaryCategory;
  String? _selectedSubcategory;
  String _selectedSizeUnit = 'cms';

  // Temas chips
  List<String> _temas = [];
  List<String> _allAvailableTemas = []; // All temas used across all products
  bool _temasLoaded = false;

  bool _isInitialized = false;

  // Original values for change detection
  Map<String, dynamic>? _originalProduct;

  // ValueNotifier for unsaved changes indicator
  final ValueNotifier<bool> _hasChanges = ValueNotifier<bool>(false);

  // Debounce timer for change detection
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load categories and temas once on init
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAllCategories(),
      _loadAllAvailableTemas(),
    ]);
    if (mounted) {
      setState(() {
        _isLoadingInitialData = false;
      });
    }
  }

  @override
  void dispose() {
    // Cancel debounce timer
    _debounceTimer?.cancel();

    // Remove listeners before disposing controllers
    _nameController.removeListener(_checkForChanges);
    _colorController.removeListener(_checkForChanges);
    _notesController.removeListener(_checkForChanges);
    _priceOverrideController.removeListener(_checkForChanges);
    _warehouseCodeController.removeListener(_checkForChanges);
    _categoryCodeController.removeListener(_checkForChanges);
    _widthController.removeListener(_checkForChanges);
    _heightController.removeListener(_checkForChanges);
    _warehouseStockAdjustmentController.removeListener(_checkForChanges);
    _storeStockAdjustmentController.removeListener(_checkForChanges);

    _hasChanges.dispose();
    _nameController.dispose();
    _temasController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    _priceOverrideController.dispose();
    _warehouseCodeController.dispose();
    _categoryCodeController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _warehouseStockAdjustmentController.dispose();
    _storeStockAdjustmentController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    if (!mounted) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer (debounce 300ms)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _hasChanges.value = _hasUnsavedChanges();
      }
    });
  }

  void _initializeControllers(Map<String, dynamic> product) {
    if (_isInitialized) return;

    // Store original product data for change detection
    _originalProduct = Map<String, dynamic>.from(product);

    _nameController = TextEditingController(text: product['name'] ?? '');
    _nameController.addListener(_checkForChanges);

    _temasController = TextEditingController(
      text: (product['temas'] as List?)?.join(', ') ?? '',
    );

    _colorController = TextEditingController(text: product['color'] ?? '');
    _colorController.addListener(_checkForChanges);

    _notesController = TextEditingController(text: product['notes'] ?? '');
    _notesController.addListener(_checkForChanges);

    _priceOverrideController = TextEditingController(
      text: product['priceOverride']?.toString() ?? '',
    );
    _priceOverrideController.addListener(_checkForChanges);

    _warehouseCodeController = TextEditingController(
      text: product['warehouseCode'] ?? '',
    );
    _warehouseCodeController.addListener(_checkForChanges);

    _categoryCodeController = TextEditingController(
      text: product['categoryCode'] ?? '',
    );
    _categoryCodeController.addListener(_checkForChanges);

    // Parse size if exists
    final sizeFormatted = product['sizeFormatted'] as String?;
    if (sizeFormatted != null && sizeFormatted.contains('x')) {
      final parts = sizeFormatted.split('x');
      if (parts.length >= 2) {
        _widthController = TextEditingController(text: parts[0].trim());
        _widthController.addListener(_checkForChanges);

        _heightController = TextEditingController(
            text: parts[1].trim().replaceAll(RegExp(r'[^\d.]'), ''));
        _heightController.addListener(_checkForChanges);

        // Extract unit if present
        if (sizeFormatted.contains('cms')) {
          _selectedSizeUnit = 'cms';
        } else if (sizeFormatted.contains('pulgadas') ||
            sizeFormatted.contains('"')) {
          _selectedSizeUnit = 'pulgadas';
        }
      }
    } else {
      _widthController = TextEditingController();
      _widthController.addListener(_checkForChanges);

      _heightController = TextEditingController();
      _heightController.addListener(_checkForChanges);
    }

    // Initialize temas
    _temas = (product['temas'] as List?)?.cast<String>() ?? [];

    // Initialize category selections
    _selectedPrimaryCategory = product['primaryCategory'];
    _selectedSubcategory = product['subcategory'];

    // Initialize stock adjustment controllers
    _warehouseStockAdjustmentController = TextEditingController(text: '0');
    _warehouseStockAdjustmentController.addListener(_checkForChanges);

    _storeStockAdjustmentController = TextEditingController(text: '0');
    _storeStockAdjustmentController.addListener(_checkForChanges);

    _isInitialized = true;
  }

  Future<void> _loadCategoryData(String? categoryCode) async {
    if (categoryCode == null || categoryCode.isEmpty) return;

    try {
      final doc =
          await _firestore.collection('categories').doc(categoryCode).get();
      if (doc.exists) {
        setState(() {
          _categoryData = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading category: $e');
    }
  }

  Future<void> _loadAllCategories() async {
    if (_categoriesLoaded) return;

    try {
      final snapshot = await _firestore.collection('categories').get();
      setState(() {
        _allCategories = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _categoriesLoaded = true;
      });
      _updateAvailableSubcategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load all unique temas from temas collection
  /// Optimized: Uses dedicated temas collection instead of scanning all products
  Future<void> _loadAllAvailableTemas() async {
    if (_temasLoaded) return;

    try {
      // Load from temas collection
      final snapshot = await _firestore.collection('temas').get();

      if (snapshot.docs.isEmpty) {
        // First time: migrate from products collection
        await _migrateTemasToCollection();
        // Reload after migration
        final newSnapshot = await _firestore.collection('temas').get();
        setState(() {
          _allAvailableTemas = newSnapshot.docs.map((doc) => doc.id).toList()
            ..sort();
          _temasLoaded = true;
        });
      } else {
        setState(() {
          _allAvailableTemas = snapshot.docs.map((doc) => doc.id).toList()
            ..sort();
          _temasLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading temas: $e');
      // Set as loaded even on error to prevent infinite retries
      setState(() {
        _temasLoaded = true;
      });
    }
  }

  /// Migrate existing temas from products to temas collection (one-time)
  Future<void> _migrateTemasToCollection() async {
    try {
      debugPrint('Migrating temas to collection...');

      // Get all unique temas from products
      final snapshot = await _firestore
          .collection('products')
          .where('temas', isNotEqualTo: null)
          .get();

      final Set<String> uniqueTemas = {};
      final Map<String, int> temaCount = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['temas'] != null && data['temas'] is List) {
          final temas = List<String>.from(data['temas']);
          for (var tema in temas) {
            uniqueTemas.add(tema);
            temaCount[tema] = (temaCount[tema] ?? 0) + 1;
          }
        }
      }

      // Create batch to write all temas
      final batch = _firestore.batch();
      for (var tema in uniqueTemas) {
        final temaRef = _firestore.collection('temas').doc(tema);
        batch.set(temaRef, {
          'name': tema,
          'productCount': temaCount[tema] ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsed': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Migration complete: ${uniqueTemas.length} temas created');
    } catch (e) {
      debugPrint('Error migrating temas: $e');
    }
  }

  void _updateAvailableSubcategories() {
    if (_selectedPrimaryCategory == null) {
      setState(() {
        _availableSubcategories = [];
      });
      return;
    }

    final subcats = _allCategories
        .where((cat) => cat['primaryCategory'] == _selectedPrimaryCategory)
        .map((cat) => cat['subcategoryName'] as String)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _availableSubcategories = subcats;
      // Reset subcategory if it's not in the new list
      if (_selectedSubcategory != null &&
          !subcats.contains(_selectedSubcategory)) {
        _selectedSubcategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('products').doc(widget.productId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Producto no encontrado')),
            body: const Center(
              child: Text('Este producto no existe'),
            ),
          );
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;
        final images = (product['images'] as List?)?.cast<String>() ?? [];
        final isActive = product['isActive'] ?? true;

        // Initialize controllers once
        _initializeControllers(product);

        // Load category data if not loaded (async, doesn't block UI)
        if (_categoryData == null && product['categoryCode'] != null) {
          _loadCategoryData(product['categoryCode']);
        }

        // Show loading indicator while initial data loads
        if (_isLoadingInitialData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return _buildProductDetail(product, images, isActive);
      },
    );
  }

  Widget _buildProductDetail(
      Map<String, dynamic> product, List<String> images, bool isActive) {
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
                        product['name'] ??
                            '${product['primaryCategory']} ${product['subcategory'] ?? ''}',
                        style: AppTheme.heading2,
                      ),
                      Row(
                        children: [
                          Text(
                            'Código Barra: ${product['barcode'] ?? widget.productId}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Container(
                            height: 16,
                            width: 1,
                            color: AppTheme.lightGray,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Text(
                            'Código Bodega: ${product['warehouseCode'] ?? 'N/A'}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unsaved Changes Indicator
                ValueListenableBuilder<bool>(
                  valueListenable: _hasChanges,
                  builder: (context, hasChanges, child) {
                    if (!hasChanges) return const SizedBox.shrink();

                    return Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: AppTheme.warning, size: 18),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(
                              'Hay cambios sin guardar',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                      ],
                    );
                  },
                ),

                // Save Button
                ValueListenableBuilder<bool>(
                  valueListenable: _hasChanges,
                  builder: (context, hasChanges, child) {
                    return ElevatedButton.icon(
                      onPressed:
                          hasChanges ? () => _saveChanges(product) : null,
                      icon: const Icon(Icons.save_rounded),
                      label:
                          Text(hasChanges ? 'Guardar Cambios' : 'Sin Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasChanges ? AppTheme.blue : AppTheme.mediumGray,
                        foregroundColor: AppTheme.white,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppTheme.spacingL),

                // Active Toggle
                Row(
                  children: [
                    Text(
                      isActive ? 'Activo' : 'Inactivo',
                      style: AppTheme.bodyMedium.copyWith(
                        color:
                            isActive ? AppTheme.success : AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Switch(
                      value: isActive,
                      onChanged: (value) async {
                        await _firestore
                            .collection('products')
                            .doc(widget.productId)
                            .update({
                          'isActive': value,
                        });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: 3 columns (Image, Inventario, Precios)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Reduced spacing to 1% between columns
                      final spacing = constraints.maxWidth * 0.01;
                      // Calculate equal column widths with remaining space distributed
                      final totalSpacing =
                          spacing * 2; // Only 2 gaps between 3 columns
                      final columnWidth =
                          (constraints.maxWidth - totalSpacing) / 3;

                      return SizedBox(
                        height: 320, // Increased height to prevent overflow
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Column 1: Image Gallery
                            SizedBox(
                              width: columnWidth,
                              child: _buildImageGallery(images),
                            ),

                            SizedBox(width: spacing),

                            // Column 2: Inventario
                            SizedBox(
                              width: columnWidth,
                              child: _buildInventarioSection(product),
                            ),

                            SizedBox(width: spacing),

                            // Column 3: Precios
                            SizedBox(
                              width: columnWidth,
                              child: _buildPreciosSection(product),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Bottom: Full-width Información del Producto
                  _buildInformacionSection(product),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    final hasImages = images.isNotEmpty;

    // Preload all images to prevent white flash (only if not already preloaded)
    // Using post-frame callback to avoid building during build phase
    if (hasImages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var imageUrl in images) {
          if (!_preloadedImages.contains(imageUrl)) {
            precacheImage(NetworkImage(imageUrl), context).then((_) {
              _preloadedImages.add(imageUrl);
            }).catchError((e) {
              debugPrint('Error preloading image: $e');
            });
          }
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Main Image - takes most space
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: hasImages
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Image.network(
                          images[_selectedImageIndex],
                          key: ValueKey<String>(images[_selectedImageIndex]),
                          fit: BoxFit.contain,
                          cacheWidth: 800,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: AppTheme.danger,
                                  ),
                                  SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    'Error al cargar imagen',
                                    style: TextStyle(
                                      color: AppTheme.mediumGray,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_rounded,
                            size: 48,
                            color: AppTheme.lightGray,
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Sin imagen',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Thumbnails and Actions - compact bottom section
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                // Thumbnail Grid
                if (hasImages) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: AppTheme.spacingS,
                      mainAxisSpacing: AppTheme.spacingS,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return _buildThumbnail(index, images);
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Mantén presionada una imagen para establecerla como principal',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.mediumGray,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                if (hasImages) const SizedBox(height: AppTheme.spacingM),

                // Action Buttons - compact
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _uploadImages,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_rounded,
                                size: 16),
                        label: Text(
                          _isUploading ? 'Subiendo...' : 'Agregar',
                          style: AppTheme.bodySmall,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: AppTheme.spacingS,
                          ),
                        ),
                      ),
                    ),
                    if (hasImages) ...[
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteSelectedImage(images),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: Text('Eliminar', style: AppTheme.bodySmall),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: AppTheme.spacingS,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(int index, List<String> images) {
    final isSelected = _selectedImageIndex == index;
    final isMainImage = index == 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageIndex = index;
        });
      },
      onLongPress: () async {
        if (index == 0) return; // Already main image

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Establecer como principal'),
            content: const Text(
              '¿Deseas establecer esta imagen como la imagen principal del producto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await _setMainImage(index, images);
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: AppTheme.borderRadiusSmall,
              border: Border.all(
                color: isSelected ? AppTheme.blue : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppTheme.borderRadiusSmall,
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                cacheWidth: 150, // Small cache for thumbnails
                cacheHeight: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image_rounded,
                    color: AppTheme.danger,
                    size: 20,
                  );
                },
              ),
            ),
          ),
          // Main image indicator
          if (isMainImage)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.subtleShadow,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: AppTheme.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build Inventario Section (Column 2)
  Widget _buildInventarioSection(Map<String, dynamic> product) {
    final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
    final storeStock = (product['stockStore'] ?? 0) as int;
    final totalStock = warehouseStock + storeStock;

    return _buildSection(
      title: 'INVENTARIO',
      child: Column(
        children: [
          // Total Stock Display - compact horizontal layout
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: totalStock == 0
                  ? AppTheme.danger.withOpacity(0.1)
                  : totalStock < 3
                      ? AppTheme.warning.withOpacity(0.1)
                      : totalStock < 10
                          ? Colors.orange.withOpacity(0.1)
                          : AppTheme.success.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
              border: Border.all(
                color: totalStock == 0
                    ? AppTheme.danger
                    : totalStock < 3
                        ? AppTheme.warning
                        : totalStock < 10
                            ? Colors.orange
                            : AppTheme.success,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Stock Total:',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.mediumGray,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  '$totalStock',
                  style: AppTheme.heading3.copyWith(
                    color: totalStock == 0
                        ? AppTheme.danger
                        : totalStock < 3
                            ? AppTheme.warning
                            : totalStock < 10
                                ? Colors.orange
                                : AppTheme.success,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Icon(
                  totalStock == 0
                      ? Icons.warning_rounded
                      : Icons.inventory_2_rounded,
                  size: 18,
                  color: totalStock == 0
                      ? AppTheme.danger
                      : totalStock < 3
                          ? AppTheme.warning
                          : totalStock < 10
                              ? Colors.orange
                              : AppTheme.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Location Breakdown
          Row(
            children: [
              Expanded(
                child: _buildStockCard(
                  label: 'Bodega',
                  value: warehouseStock,
                  icon: Icons.warehouse_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildStockCard(
                  label: 'Kiosco',
                  value: storeStock,
                  icon: Icons.store_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Stock Adjustment Controls - compact
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajustar Stock',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _buildStockAdjuster(
                        'Bodega',
                        _warehouseStockAdjustmentController,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: _buildStockAdjuster(
                        'Kiosco',
                        _storeStockAdjustmentController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Precios Section (Column 3)
  Widget _buildPreciosSection(Map<String, dynamic> product) {
    return _buildSection(
      title: 'PRECIOS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Price Display - compact
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.blue.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money_rounded,
                  size: 24,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio Actual',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Q${_getCurrentPrice(product)}',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (product['priceOverride'] == null && _categoryData != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXS),
              child: Text(
                'Precio de Categoría',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.mediumGray,
                  fontSize: 10,
                ),
              ),
            ),

          const SizedBox(height: AppTheme.spacingM),

          // Price Override Input - compact
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio Personalizado',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceOverrideController,
                      decoration: InputDecoration(
                        hintText: _categoryData != null
                            ? 'Q${_categoryData!['defaultPrice'] ?? '0.00'} (por defecto)'
                            : 'Vacío = precio de categoría',
                        prefixText: 'Q',
                        suffixIcon: product['priceOverride'] != null
                            ? IconButton(
                                icon:
                                    const Icon(Icons.restore_rounded, size: 18),
                                tooltip: 'Usar precio de categoría',
                                onPressed: () {
                                  setState(() {
                                    _priceOverrideController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Información Section (Full width bottom)
  Widget _buildInformacionSection(Map<String, dynamic> product) {
    return Column(
      children: [
        _buildSection(
          title: 'INFORMACIÓN DEL PRODUCTO',
          child: Column(
            children: [
              // Product Name (editable)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre del Producto',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre descriptivo del producto',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Category Dropdowns (editable)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categoría Principal',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        DropdownButtonFormField<String>(
                          initialValue: _categoriesLoaded &&
                                  _allCategories.any((cat) =>
                                      cat['primaryCategory'] ==
                                      _selectedPrimaryCategory)
                              ? _selectedPrimaryCategory
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: _categoriesLoaded
                                ? 'Seleccionar categoría'
                                : 'Cargando categorías...',
                          ),
                          items: _categoriesLoaded
                              ? (_allCategories
                                      .map((cat) =>
                                          cat['primaryCategory'] as String)
                                      .toSet()
                                      .toList()
                                    ..sort())
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList()
                              : [],
                          onChanged: _categoriesLoaded
                              ? (value) {
                                  setState(() {
                                    _selectedPrimaryCategory = value;
                                    _updateAvailableSubcategories();
                                  });
                                  _checkForChanges();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subcategoría',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        DropdownButtonFormField<String>(
                          initialValue: _availableSubcategories
                                  .contains(_selectedSubcategory)
                              ? _selectedSubcategory
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: _selectedPrimaryCategory == null
                                ? 'Primero selecciona categoría'
                                : 'Seleccionar subcategoría',
                          ),
                          items: _availableSubcategories.isEmpty
                              ? []
                              : _availableSubcategories
                                  .map((subcat) => DropdownMenuItem(
                                        value: subcat,
                                        child: Text(subcat,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                          onChanged: _selectedPrimaryCategory == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedSubcategory = value;
                                  });
                                  _checkForChanges();
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingM),

              // Codes (editable)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de Bodega',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        TextField(
                          controller: _warehouseCodeController,
                          decoration: const InputDecoration(
                            hintText: 'CUA-01',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de Categoría',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        TextField(
                          controller: _categoryCodeController,
                          decoration: const InputDecoration(
                            hintText: 'CUA-2030',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Color and Tamaño side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        TextField(
                          controller: _colorController,
                          decoration: const InputDecoration(
                            hintText: 'Amarillo, Azul, etc.',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppTheme.spacingM),

                  // Size (Tamaño)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tamaño',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _widthController,
                                decoration: const InputDecoration(
                                  hintText: 'Ancho',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Text('x', style: AppTheme.heading3),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: TextField(
                                controller: _heightController,
                                decoration: const InputDecoration(
                                  hintText: 'Alto',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSizeUnit,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingM,
                                    vertical: AppTheme.spacingM,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'cms', child: Text('cms')),
                                  DropdownMenuItem(
                                      value: 'pulgadas',
                                      child: Text('pulgadas')),
                                  DropdownMenuItem(
                                      value: 'm', child: Text('m')),
                                  DropdownMenuItem(
                                      value: 'mm', child: Text('mm')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSizeUnit = value!;
                                  });
                                  _checkForChanges();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Temas (Google Sheets style chip selector)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temas',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  !_temasLoaded
                      ? Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Text(
                                'Cargando temas disponibles...',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: AppTheme.spacingS,
                          runSpacing: AppTheme.spacingS,
                          children: [
                            // Show all available temas from all products
                            ..._allAvailableTemas.map((tema) {
                              final isSelected = _temas.contains(tema);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilterChip(
                                    label: Text(tema),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _temas.add(tema);
                                        } else {
                                          _temas.remove(tema);
                                        }
                                      });
                                      _checkForChanges();
                                    },
                                    backgroundColor: AppTheme.white,
                                    selectedColor:
                                        AppTheme.blue.withOpacity(0.1),
                                    checkmarkColor: AppTheme.blue,
                                    labelStyle: AppTheme.bodySmall.copyWith(
                                      color: isSelected
                                          ? AppTheme.blue
                                          : AppTheme.darkGray,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide.none,
                                    ),
                                    showCheckmark: true,
                                  ),
                                  const SizedBox(width: 2),
                                  InkWell(
                                    onTap: () => _showEditTemaDialog(tema),
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            // Circular add button for new temas
                            IconButton.filled(
                              onPressed: () => _showAddTemaDialog(),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              iconSize: 20,
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.blue.withOpacity(0.1),
                                foregroundColor: AppTheme.blue,
                                minimumSize: const Size(32, 32),
                                padding: EdgeInsets.zero,
                              ),
                              tooltip: 'Agregar nuevo tema',
                            ),
                          ],
                        ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingL),

              // Notes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notas',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Notas adicionales sobre el producto...',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasUnsavedChanges() {
    if (!_isInitialized || _originalProduct == null) return false;

    // Check stock adjustments
    final warehouseAdjustment =
        int.tryParse(_warehouseStockAdjustmentController.text) ?? 0;
    final storeAdjustment =
        int.tryParse(_storeStockAdjustmentController.text) ?? 0;
    if (warehouseAdjustment != 0 || storeAdjustment != 0) {
      return true;
    }

    // Check text fields
    if (_nameController.text != (_originalProduct!['name'] ?? '')) return true;
    if (_colorController.text != (_originalProduct!['color'] ?? '')) {
      return true;
    }
    if (_notesController.text != (_originalProduct!['notes'] ?? '')) {
      return true;
    }
    if (_priceOverrideController.text !=
        (_originalProduct!['priceOverride']?.toString() ?? '')) {
      return true;
    }
    if (_warehouseCodeController.text !=
        (_originalProduct!['warehouseCode'] ?? '')) {
      return true;
    }
    if (_categoryCodeController.text !=
        (_originalProduct!['categoryCode'] ?? '')) {
      return true;
    }

    // Check temas
    final originalTemas =
        (_originalProduct!['temas'] as List?)?.cast<String>() ?? [];
    if (_temas.length != originalTemas.length) return true;
    for (var tema in _temas) {
      if (!originalTemas.contains(tema)) return true;
    }

    // Check category/subcategory
    if (_selectedPrimaryCategory != _originalProduct!['primaryCategory']) {
      return true;
    }
    if (_selectedSubcategory != _originalProduct!['subcategory']) return true;

    // Check size fields
    final originalSize = _originalProduct!['sizeFormatted'] as String?;
    if (originalSize != null && originalSize.contains('x')) {
      final parts = originalSize.split('x');
      if (parts.length >= 2) {
        final origWidth = parts[0].trim();
        final origHeight = parts[1].trim().replaceAll(RegExp(r'[^\d.]'), '');
        if (_widthController.text != origWidth ||
            _heightController.text != origHeight) {
          return true;
        }
      }
    } else if (_widthController.text.isNotEmpty ||
        _heightController.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Set selected image as main image by reordering images array
  Future<void> _setMainImage(int index, List<String> currentImages) async {
    if (index == 0) return; // Already main image

    try {
      // Create new array with selected image first
      final List<String> reorderedImages = List.from(currentImages);
      final selectedImage = reorderedImages.removeAt(index);
      reorderedImages.insert(0, selectedImage);

      // Update Firestore
      await _firestore.collection('products').doc(widget.productId).update({
        'images': reorderedImages,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update selected index to point to new position (first)
      setState(() {
        _selectedImageIndex = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Imagen principal actualizada',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al actualizar imagen principal: $e',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Delete the currently selected image
  Future<void> _deleteSelectedImage(List<String> currentImages) async {
    if (currentImages.isEmpty) return;

    final selectedImage = currentImages[_selectedImageIndex];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from Storage
      try {
        final firebase_storage.Reference ref =
            _storage.refFromURL(selectedImage);
        await ref.delete();
      } catch (e) {
        debugPrint('Error deleting from Storage (may not exist): $e');
        // Continue anyway - remove from Firestore even if Storage delete fails
      }

      // Remove from Firestore images array
      final updatedImages = List<String>.from(currentImages);
      updatedImages.removeAt(_selectedImageIndex);

      await _firestore.collection('products').doc(widget.productId).update({
        'images': updatedImages,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update selected index (move to previous image or 0)
      setState(() {
        if (_selectedImageIndex > 0) {
          _selectedImageIndex--;
        } else {
          _selectedImageIndex = 0;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Imagen eliminada exitosamente',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Error al eliminar imagen: $e',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Upload images from computer to Firebase Storage
  Future<void> _uploadImages() async {
    try {
      // Show immediate feedback that file picker is opening
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
                Expanded(
                  child: Text(
                    'Abriendo selector de archivos...',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Pick multiple images
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      // Get current product data for barcode
      final productDoc =
          await _firestore.collection('products').doc(widget.productId).get();
      final productData = productDoc.data();
      final barcode = productData?['barcode'] ?? widget.productId;

      // Upload each image with retry logic
      final List<String> uploadedUrls = [];
      for (var file in pickedFiles) {
        final fileName =
            '${barcode}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final firebase_storage.Reference ref =
            _storage.ref().child('products').child(barcode).child(fileName);

        // Read file bytes and upload with retry
        final bytes = await file.readAsBytes();

        // Retry upload up to 3 times on failure
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
              throw Exception(
                  'Error al subir ${file.name} después de 3 intentos: $e');
            }
            await Future.delayed(
                Duration(seconds: retries)); // Exponential backoff
          }
        }
      }

      // Update Firestore document with new image URLs
      final currentImages =
          (productData?['images'] as List?)?.cast<String>() ?? [];
      final updatedImages = [...currentImages, ...uploadedUrls];

      await _firestore.collection('products').doc(widget.productId).update({
        'images': updatedImages,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    '${uploadedUrls.length} imagen${uploadedUrls.length > 1 ? 'es' : ''} subida${uploadedUrls.length > 1 ? 's' : ''} exitosamente',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges(Map<String, dynamic> currentProduct) async {
    try {
      final updates = <String, dynamic>{};

      // Update name
      if (_nameController.text != (currentProduct['name'] ?? '')) {
        updates['name'] = _nameController.text.trim();
      }

      // Update temas (from chips list)
      final currentTemas =
          (currentProduct['temas'] as List?)?.cast<String>() ?? [];
      if (_temas.toString() != currentTemas.toString()) {
        updates['temas'] = _temas;
      }

      // Update category and subcategory
      if (_selectedPrimaryCategory != currentProduct['primaryCategory']) {
        updates['primaryCategory'] = _selectedPrimaryCategory;
      }
      if (_selectedSubcategory != currentProduct['subcategory']) {
        updates['subcategory'] = _selectedSubcategory;
      }

      // Update warehouse code
      if (_warehouseCodeController.text.trim() !=
          (currentProduct['warehouseCode'] ?? '')) {
        updates['warehouseCode'] = _warehouseCodeController.text.trim();
      }

      // Update category code
      if (_categoryCodeController.text.trim() !=
          (currentProduct['categoryCode'] ?? '')) {
        updates['categoryCode'] = _categoryCodeController.text.trim();
      }

      // Update size
      final width = _widthController.text.trim();
      final height = _heightController.text.trim();
      if (width.isNotEmpty && height.isNotEmpty) {
        final newSizeFormatted = '$width x $height $_selectedSizeUnit';
        if (newSizeFormatted != currentProduct['sizeFormatted']) {
          updates['sizeFormatted'] = newSizeFormatted;
          updates['size'] = '$width x $height'; // Keep raw size too
        }
      }

      // Update color
      if (_colorController.text != (currentProduct['color'] ?? '')) {
        updates['color'] = _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim();
      }

      // Update notes
      if (_notesController.text != (currentProduct['notes'] ?? '')) {
        updates['notes'] = _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim();
      }

      // Update price override
      final priceText = _priceOverrideController.text.trim();
      if (priceText.isEmpty) {
        // Clear override if empty
        if (currentProduct['priceOverride'] != null) {
          updates['priceOverride'] = null;
        }
      } else {
        final newPrice = double.tryParse(priceText);
        if (newPrice != null &&
            newPrice != (currentProduct['priceOverride'] ?? 0)) {
          updates['priceOverride'] = newPrice;
        }
      }

      // Apply stock adjustments
      final warehouseAdjustment =
          int.tryParse(_warehouseStockAdjustmentController.text) ?? 0;
      final storeAdjustment =
          int.tryParse(_storeStockAdjustmentController.text) ?? 0;

      if (warehouseAdjustment != 0) {
        final currentWarehouse = (currentProduct['stockWarehouse'] ?? 0) as int;
        updates['stockWarehouse'] = currentWarehouse + warehouseAdjustment;
      }
      if (storeAdjustment != 0) {
        final currentStore = (currentProduct['stockStore'] ?? 0) as int;
        updates['stockStore'] = currentStore + storeAdjustment;
      }

      // Only update if there are changes
      if (updates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Text('No hay cambios para guardar'),
              ],
            ),
            backgroundColor: AppTheme.blue,
          ),
        );
        return;
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      // Save to Firestore
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .update(updates);

      // Reset stock adjustments and update original product
      setState(() {
        _warehouseStockAdjustmentController.text = '0';
        _storeStockAdjustmentController.text = '0';

        // Update original product with new values
        _originalProduct = Map<String, dynamic>.from(currentProduct);
        _originalProduct!.addAll(updates);
      });

      // Reset the change indicator
      _hasChanges.value = false;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Cambios guardados exitosamente${updates.containsKey('stockWarehouse') || updates.containsKey('stockStore') ? ' (stock actualizado)' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(child: Text('Error al guardar: $e')),
              ],
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
            style: AppTheme.bodySmall.copyWith(
              letterSpacing: 1.0,
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }

  Widget _buildStockCard({
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.mediumGray,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.mediumGray,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: AppTheme.heading3.copyWith(
                    color: value > 0 ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockAdjuster(
    String label,
    TextEditingController controller,
  ) {
    final currentAdjustment = int.tryParse(controller.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.mediumGray,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            IconButton(
              onPressed: () {
                final newValue = currentAdjustment - 1;
                controller.text = newValue.toString();
              },
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AppTheme.danger,
              tooltip: 'Restar 1',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingM,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusSmall,
                    borderSide: BorderSide(
                      color: currentAdjustment != 0
                          ? AppTheme.blue
                          : AppTheme.lightGray,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusSmall,
                    borderSide: BorderSide(
                      color: currentAdjustment != 0
                          ? AppTheme.blue
                          : AppTheme.lightGray,
                    ),
                  ),
                  filled: true,
                  fillColor: currentAdjustment != 0
                      ? AppTheme.blue.withOpacity(0.1)
                      : AppTheme.white,
                ),
                style: AppTheme.heading3.copyWith(
                  color: currentAdjustment != 0
                      ? AppTheme.blue
                      : AppTheme.mediumGray,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final newValue = currentAdjustment + 1;
                controller.text = newValue.toString();
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AppTheme.success,
              tooltip: 'Sumar 1',
            ),
          ],
        ),
        if (currentAdjustment != 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                controller.text = '0';
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Resetear'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  String _getCurrentPrice(Map<String, dynamic> product) {
    final priceOverride = product['priceOverride'];
    if (priceOverride != null) {
      return priceOverride.toStringAsFixed(2);
    }

    if (_categoryData != null && _categoryData!['defaultPrice'] != null) {
      return _categoryData!['defaultPrice'].toStringAsFixed(2);
    }

    return '0.00';
  }

  void _showAddTemaDialog() {
    final temaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar Tema',
          style: AppTheme.heading3,
        ),
        content: TextField(
          controller: temaController,
          decoration: const InputDecoration(
            hintText: 'Nombre del tema (ej: Coca Cola)',
            labelText: 'Tema',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTema = temaController.text.trim();
              if (newTema.isNotEmpty && !_temas.contains(newTema)) {
                // Add to local product temas
                setState(() {
                  _temas.add(newTema);
                });

                // Add to temas collection if it doesn't exist
                try {
                  final temaRef = _firestore.collection('temas').doc(newTema);
                  final temaDoc = await temaRef.get();

                  if (!temaDoc.exists) {
                    await temaRef.set({
                      'name': newTema,
                      'productCount': 1,
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastUsed': FieldValue.serverTimestamp(),
                    });
                    // Add to local list
                    setState(() {
                      if (!_allAvailableTemas.contains(newTema)) {
                        _allAvailableTemas.add(newTema);
                        _allAvailableTemas.sort();
                      }
                    });
                  } else {
                    // Increment product count and update lastUsed
                    await temaRef.update({
                      'productCount': FieldValue.increment(1),
                      'lastUsed': FieldValue.serverTimestamp(),
                    });
                    // Add to local list if not present
                    setState(() {
                      if (!_allAvailableTemas.contains(newTema)) {
                        _allAvailableTemas.add(newTema);
                        _allAvailableTemas.sort();
                      }
                    });
                  }
                } catch (e) {
                  debugPrint('Error adding tema to collection: $e');
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditTemaDialog(String oldTema) {
    final temaController = TextEditingController(text: oldTema);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Tema',
          style: AppTheme.heading3,
        ),
        content: TextField(
          controller: temaController,
          decoration: const InputDecoration(
            hintText: 'Nombre del tema',
            labelText: 'Tema',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          // Delete button (left side)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteTemaDialog(oldTema);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.danger,
            ),
          ),
          const Spacer(),
          // Cancel and Save buttons (right side)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTema = temaController.text.trim();
              if (newTema.isNotEmpty && newTema != oldTema) {
                _renameTemaInAllProducts(oldTema, newTema);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTemaDialog(String tema) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar Tema?',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Se eliminará "$tema" de todos los productos que lo usen. Esta acción no se puede deshacer.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteTemaFromAllProducts(tema);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameTemaInAllProducts(String oldTema, String newTema) async {
    try {
      // Show loading indicator
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
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Renombrando "$oldTema" a "$newTema"...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Get all products with this tema
      final snapshot = await _firestore
          .collection('products')
          .where('temas', arrayContains: oldTema)
          .get();

      // Update each product
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final temas = List<String>.from(data['temas'] ?? []);

        // Replace old tema with new tema
        final index = temas.indexOf(oldTema);
        if (index != -1) {
          temas[index] = newTema;
          batch.update(doc.reference, {'temas': temas});
        }
      }

      // Commit all updates
      await batch.commit();

      // Update temas collection
      try {
        final oldTemaRef = _firestore.collection('temas').doc(oldTema);
        final newTemaRef = _firestore.collection('temas').doc(newTema);

        // Get old tema data
        final oldTemaDoc = await oldTemaRef.get();
        if (oldTemaDoc.exists) {
          final oldData = oldTemaDoc.data()!;
          // Create new tema doc
          await newTemaRef.set({
            'name': newTema,
            'productCount': oldData['productCount'] ?? 0,
            'createdAt': oldData['createdAt'] ?? FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
          });
          // Delete old tema doc
          await oldTemaRef.delete();
        }
      } catch (e) {
        debugPrint('Error updating temas collection: $e');
      }

      // Update local state
      setState(() {
        // Update current product temas
        final index = _temas.indexOf(oldTema);
        if (index != -1) {
          _temas[index] = newTema;
        }

        // Update global temas list
        final globalIndex = _allAvailableTemas.indexOf(oldTema);
        if (globalIndex != -1) {
          _allAvailableTemas[globalIndex] = newTema;
          _allAvailableTemas.sort();
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Tema renombrado en ${snapshot.docs.length} producto(s)',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error renaming tema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text('Error al renombrar tema'),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteTemaFromAllProducts(String tema) async {
    try {
      // Show loading indicator
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
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Eliminando "$tema"...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Get all products with this tema
      final snapshot = await _firestore
          .collection('products')
          .where('temas', arrayContains: tema)
          .get();

      // Update each product
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'temas': FieldValue.arrayRemove([tema])
        });
      }

      // Commit all updates
      await batch.commit();

      // Delete from temas collection
      try {
        final temaRef = _firestore.collection('temas').doc(tema);
        await temaRef.delete();
      } catch (e) {
        debugPrint('Error deleting tema from collection: $e');
      }

      // Update local state
      setState(() {
        _temas.remove(tema);
        _allAvailableTemas.remove(tema);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Tema eliminado de ${snapshot.docs.length} producto(s)',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting tema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text('Error al eliminar tema'),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Eliminar Producto?',
          style: AppTheme.heading3,
        ),
        content: Text(
          'Esta acción no se puede deshacer. ¿Estás seguro de que deseas eliminar este producto?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete product
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado'),
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
