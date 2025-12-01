import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/category_detail_screen.dart';

/// Categories list screen with grouped category cards
class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print('🔍 Loading categories from Firestore...');

      // Load primary categories
      final primarySnapshot = await _firestore
          .collection('categories')
          .orderBy('displayOrder')
          .get();

      print('📦 Found ${primarySnapshot.docs.length} primary categories');

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var primaryDoc in primarySnapshot.docs) {
        final primaryData = primaryDoc.data();
        final primaryName = primaryDoc.id;
        final primaryCoverImage = primaryData['coverImageUrl'];

        print('Processing primary category: $primaryName');

        // Load subcategories from subcollection
        final subSnapshot = await primaryDoc.reference
            .collection('subcategories')
            .orderBy('displayOrder')
            .get();

        print('  → Found ${subSnapshot.docs.length} subcategories');

        grouped[primaryName] = [];
        final hasOnlyOneSubcategory = subSnapshot.docs.length == 1;

        for (var subDoc in subSnapshot.docs) {
          final subData = subDoc.data();
          final code = subData['code'] as String;

          // Count products in this category
          final productCount = await _firestore
              .collection('products')
              .where('categoryCode', isEqualTo: code)
              .count()
              .get();

          print('    → $code: ${productCount.count} products');

          // If only 1 subcategory, use primary cover as default
          final subcategoryCoverUrl = subData['coverImageUrl'];
          final effectiveCoverUrl =
              hasOnlyOneSubcategory && subcategoryCoverUrl == null
                  ? primaryCoverImage
                  : subcategoryCoverUrl;

          final categoryData = {
            'id': subDoc.id, // Subcategory code
            'parentId': primaryDoc.id, // Primary category name
            'code': code,
            'name': subData['name'] as String,
            'primaryCategory': primaryName,
            'primaryCoverImageUrl': primaryCoverImage, // Fallback image
            'subcategoryName': subData['subcategoryName'],
            'defaultPrice': subData['defaultPrice'] ?? 0,
            'itemCount': productCount.count ?? 0,
            'coverImageUrl':
                effectiveCoverUrl, // Use primary if only 1 subcategory
          };

          grouped[primaryName]!.add(categoryData);
        }
      }

      print('✅ Grouped into ${grouped.length} primary categories');

      setState(() {
        _groupedCategories = grouped;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading categories: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: $e'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadPrimaryCategoryImage(String primaryCategoryName) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Upload to Storage: categories/{primaryName}/cover.jpg
      final ref = _storage
          .ref()
          .child('categories')
          .child(primaryCategoryName)
          .child('cover.jpg');

      final bytes = await image.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await _firestore
          .collection('categories')
          .doc(primaryCategoryName)
          .update({'coverImageUrl': downloadUrl});

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.white),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  'Imagen de categoría actualizada',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload categories to show new image
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _showAddPrimaryCategoryDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Categoría Principal'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Cuadros de latón',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: CUA',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final name = nameController.text.trim();
      final code = codeController.text.trim().toUpperCase();

      if (name.isEmpty || code.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nombre y código son requeridos'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Get max displayOrder
      final existingCategories = await _firestore
          .collection('categories')
          .orderBy('displayOrder', descending: true)
          .limit(1)
          .get();

      final maxOrder = existingCategories.docs.isEmpty
          ? 0
          : (existingCategories.docs.first.data()['displayOrder'] ?? 0) as int;

      await _firestore.collection('categories').doc(name).set({
        'name': name,
        'primaryCode': code,
        'coverImageUrl': null,
        'isActive': true,
        'displayOrder': maxOrder + 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría principal creada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _showAddSubcategoryDialog(String primaryCategory) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Subcategoría a $primaryCategory'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: 20x30 cms',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: LAT-2030',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio predeterminado',
                  hintText: '0 = sin precio',
                  border: OutlineInputBorder(),
                  prefixText: 'Q',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final name = nameController.text.trim();
      final code = codeController.text.trim().toUpperCase();
      final price = double.tryParse(priceController.text.trim()) ?? 0;

      if (name.isEmpty || code.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nombre y código son requeridos'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Get max displayOrder in subcollection
      final existingSubcategories = await _firestore
          .collection('categories')
          .doc(primaryCategory)
          .collection('subcategories')
          .orderBy('displayOrder', descending: true)
          .limit(1)
          .get();

      final maxOrder = existingSubcategories.docs.isEmpty
          ? 0
          : (existingSubcategories.docs.first.data()['displayOrder'] ?? 0)
              as int;

      await _firestore
          .collection('categories')
          .doc(primaryCategory)
          .collection('subcategories')
          .doc(code)
          .set({
        'code': code,
        'name': name,
        'subcategoryName': null,
        'defaultPrice': price,
        'coverImageUrl': null,
        'bulkPricing': null,
        'hasSubcategories': false,
        'isActive': true,
        'displayOrder': maxOrder + 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subcategoría creada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deletePrimaryCategory(String primaryCategory) async {
    // Check if has subcategories
    final subSnapshot = await _firestore
        .collection('categories')
        .doc(primaryCategory)
        .collection('subcategories')
        .limit(1)
        .get();

    if (subSnapshot.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede eliminar: tiene subcategorías'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría Principal'),
        content: Text('¿Eliminar "$primaryCategory"?'),
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

    if (confirm != true) return;

    try {
      await _firestore.collection('categories').doc(primaryCategory).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubcategory(
      String parentId, String categoryId, String name) async {
    // Check if has products
    final productCount = await _firestore
        .collection('products')
        .where('categoryCode', isEqualTo: categoryId)
        .count()
        .get();

    if (productCount.count! > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No se puede eliminar: tiene ${productCount.count} productos'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Subcategoría'),
        content: Text('¿Eliminar "$name"?'),
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

    if (confirm != true) return;

    try {
      await _firestore
          .collection('categories')
          .doc(parentId)
          .collection('subcategories')
          .doc(categoryId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subcategoría eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      _loadCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _reorderPrimaryCategory(
      String primaryCategory, bool moveUp) async {
    try {
      // Get all primary categories sorted
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('displayOrder')
          .get();

      final categories = snapshot.docs;
      final currentIndex =
          categories.indexWhere((doc) => doc.id == primaryCategory);

      if (currentIndex == -1) return;
      if (moveUp && currentIndex == 0) return; // Already first
      if (!moveUp && currentIndex == categories.length - 1)
        return; // Already last

      final swapIndex = moveUp ? currentIndex - 1 : currentIndex + 1;

      // Swap display orders
      final batch = _firestore.batch();
      batch.update(categories[currentIndex].reference, {
        'displayOrder': categories[swapIndex].data()['displayOrder'],
      });
      batch.update(categories[swapIndex].reference, {
        'displayOrder': categories[currentIndex].data()['displayOrder'],
      });

      await batch.commit();
      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden actualizado'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
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
                  'Categorías',
                  style: AppTheme.heading1,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddPrimaryCategoryDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar Categoría Principal'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _groupedCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 64,
                              color: AppTheme.mediumGray.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Text(
                              'No hay categorías',
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _groupedCategories.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final categoryEntry = entry.value;
                            return _buildCategoryGroup(
                              primaryCategory: categoryEntry.key,
                              categories: categoryEntry.value,
                              isFirst: index == 0,
                              isLast: index == _groupedCategories.length - 1,
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup({
    required String primaryCategory,
    required List<Map<String, dynamic>> categories,
    required bool isFirst,
    required bool isLast,
  }) {
    // Get primary category cover image from first subcategory's data
    final primaryCoverImageUrl = categories.isNotEmpty
        ? categories[0]['primaryCoverImageUrl'] as String?
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Category Header with Image Preview and Edit Button
        Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.subtleShadow,
          ),
          child: Row(
            children: [
              // Primary Category Cover Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: AppTheme.borderRadiusSmall,
                  border: Border.all(
                    color: AppTheme.lightGray,
                    width: 2,
                  ),
                ),
                child: primaryCoverImageUrl != null
                    ? ClipRRect(
                        borderRadius: AppTheme.borderRadiusSmall,
                        child: Image.network(
                          primaryCoverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 32,
                                color: AppTheme.mediumGray,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.category_rounded,
                          size: 40,
                          color: AppTheme.mediumGray,
                        ),
                      ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryCategory.toUpperCase(),
                      style: AppTheme.heading3.copyWith(
                        letterSpacing: 1.5,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${categories.length} subcategorías',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _uploadPrimaryCategoryImage(primaryCategory),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(primaryCoverImageUrl != null ? 'Cambiar' : 'Subir'),
              ),
              const SizedBox(width: AppTheme.spacingS),
              OutlinedButton.icon(
                onPressed: () => _showAddSubcategoryDialog(primaryCategory),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
              ),
              const SizedBox(width: AppTheme.spacingS),
              // Reorder arrows
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: isFirst
                        ? null
                        : () => _reorderPrimaryCategory(primaryCategory, true),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Mover arriba',
                  ),
                  IconButton(
                    onPressed: isLast
                        ? null
                        : () => _reorderPrimaryCategory(primaryCategory, false),
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Mover abajo',
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingS),
              IconButton(
                onPressed: () => _deletePrimaryCategory(primaryCategory),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppTheme.danger,
                tooltip: 'Eliminar categoría',
              ),
            ],
          ),
        ),

        // Category Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio:
                0.72, // Balanced ratio for square image + compact info
            crossAxisSpacing: AppTheme.spacingL,
            mainAxisSpacing: AppTheme.spacingL,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        ),

        const SizedBox(height: AppTheme.spacingXXL),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final code = category['code'] as String;
    final name = category['name'] as String;
    final subcategoryName = category['subcategoryName'];
    final displayName =
        subcategoryName != null && subcategoryName.toString().isNotEmpty
            ? subcategoryName
            : name;

    // Use subcategory cover if available, otherwise use primary category cover
    final coverImageUrl =
        category['coverImageUrl'] ?? category['primaryCoverImageUrl'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(
                categoryId: category['id'], // Subcategory code
                parentId: category['parentId'], // Primary category name
              ),
            ),
          );
        },
        borderRadius: AppTheme.borderRadiusMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              // Image/Icon Area with Delete Button - Square
              AspectRatio(
                aspectRatio: 1, // Square image area
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: coverImageUrl != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                coverImageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.folder_rounded,
                                      size: 64,
                                      color:
                                          AppTheme.blue.withValues(alpha: 0.3),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.folder_rounded,
                                size: 64,
                                color: AppTheme.blue.withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: () => _deleteSubcategory(
                          category['parentId'],
                          category['id'],
                          displayName,
                        ),
                        icon: const Icon(Icons.delete_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.white.withValues(alpha: 0.9),
                          foregroundColor: AppTheme.danger,
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(28, 28),
                        ),
                        tooltip: 'Eliminar',
                      ),
                    ),
                  ],
                ),
              ),

              // Info Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['defaultPrice'] > 0
                              ? 'Q${category['defaultPrice']}'
                              : 'Varía',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${category['itemCount']} items',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
