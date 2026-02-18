import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';

/// Category detail screen: manage cover image and reorder products
class CategoryDetailScreen extends StatefulWidget {
  final String categoryId; // Subcategory code (e.g., "LAT-2030")
  final String parentId; // Primary category name (e.g., "Cuadros de latón")

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.parentId,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _categoryData;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load category data from subcollection
      final categoryDoc = await _firestore
          .collection('categories')
          .doc(widget.parentId)
          .collection('subcategories')
          .doc(widget.categoryId)
          .get();

      if (!categoryDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Categoría no encontrada'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final categoryData = categoryDoc.data()!;
      final categoryCode = categoryData['code'] as String;

      // Load products for this category using categoryCode
      final productsSnapshot = await _firestore
          .collection('products')
          .where('categoryCode', isEqualTo: categoryCode)
          .orderBy('displayOrder')
          .get();

      setState(() {
        _categoryData = {
          'id': categoryDoc.id,
          ...categoryData,
        };
        _products = productsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categoría: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _isUploadingCover = true;
    });

    try {
      // Storage path: categories/{parentId}/subcategories/{categoryId}/cover.jpg
      final ref = _storage
          .ref()
          .child('categories')
          .child(widget.parentId)
          .child('subcategories')
          .child(widget.categoryId)
          .child('cover.jpg');

      await ref.putData(
        await image.readAsBytes(),
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Update subcategory document
      await _firestore
          .collection('categories')
          .doc(widget.parentId)
          .collection('subcategories')
          .doc(widget.categoryId)
          .update({
        'coverImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _categoryData!['coverImageUrl'] = downloadUrl;
        _isUploadingCover = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading cover image: $e');
      setState(() {
        _isUploadingCover = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteCoverImage() async {
    try {
      // Delete from Storage
      final ref = _storage
          .ref()
          .child('categories')
          .child(widget.categoryId)
          .child('cover.jpg');

      try {
        await ref.delete();
      } catch (e) {
        debugPrint('Storage file may not exist: $e');
      }

      // Update Firestore subcategory document
      await _firestore
          .collection('categories')
          .doc(widget.parentId)
          .collection('subcategories')
          .doc(widget.categoryId)
          .update({
        'coverImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _categoryData!.remove('coverImageUrl');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting cover image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar imagen: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = _products.removeAt(oldIndex);
      _products.insert(newIndex, item);
    });

    // Update displayOrder for all products in batch
    final batch = _firestore.batch();
    for (int i = 0; i < _products.length; i++) {
      final productRef =
          _firestore.collection('products').doc(_products[i]['id']);
      batch.update(productRef, {'displayOrder': i});
    }

    try {
      await batch.commit();
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
      debugPrint('Error updating order: $e');
      // Reload to restore order
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                              _categoryData!['name'] ?? 'Sin nombre',
                              style: AppTheme.heading2,
                            ),
                            Text(
                              '${_products.length} productos',
                              style: AppTheme.bodySmall,
                            ),
                          ],
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
                        // Category Info and Cover Image in Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Info Section (Left) - Takes more space
                            Expanded(
                              flex: 2,
                              child: _buildCategoryInfoSection(),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            // Cover Image Section (Right) - Smaller, square
                            Expanded(
                              flex: 1,
                              child: _buildCoverImageSection(),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Products Reorder Section
                        _buildProductsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryInfoSection() {
    final name = _categoryData!['name'] as String;
    final defaultPrice = _categoryData!['defaultPrice'] ?? 0;
    final code = _categoryData!['code'] as String;

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
              Text(
                'INFORMACIÓN DE CATEGORÍA',
                style: AppTheme.heading4.copyWith(
                  letterSpacing: 1.2,
                  color: AppTheme.mediumGray,
                ),
              ),
              const Spacer(),
              // Bulk pricing button (SUPERUSER ONLY)
              if (AuthService.isSuperuser) ...[
                OutlinedButton.icon(
                  onPressed: _editBulkPricing,
                  // TODO edit quantities too
                  icon: const Icon(Icons.local_offer_rounded, size: 18),
                  label: const Text('Precio por Mayor'),
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              OutlinedButton.icon(
                onPressed: _editCategoryInfo,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Code (read-only)
          Text(
            'Código',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            code,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Name
          Text(
            'Nombre',
            // TODO what does this modify ??
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            name,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Price
          Text(
            'Precio predeterminado',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            defaultPrice > 0 ? 'Q$defaultPrice' : 'Sin precio',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Active Status Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    _categoryData!['isActive'] == true
                        ? 'Activa (visible en cliente)'
                        : 'Inactiva (oculta)',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _categoryData!['isActive'] == true
                          ? AppTheme.success
                          : AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _categoryData!['isActive'] == true,
                onChanged: (value) async {
                  try {
                    await _firestore
                        .collection('categories')
                        .doc(widget.parentId)
                        .collection('subcategories')
                        .doc(widget.categoryId)
                        .update({'isActive': value});

                    setState(() {
                      _categoryData!['isActive'] = value;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? 'Categoría activada'
                              : 'Categoría desactivada'),
                          backgroundColor: AppTheme.success,
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
                },
                activeThumbColor: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editBulkPricing() async {
    final bulkPricing = _categoryData!['bulkPricing'] as Map<String, dynamic>?;
    final qty2Controller = TextEditingController(
      text: bulkPricing?['qty2']?.toString() ?? '',
    );
    final qty5PlusController = TextEditingController(
      text: bulkPricing?['qty5Plus']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precio por Mayor'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurar descuentos por cantidad',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Ejemplo: 20x30 → 1xQ35, 2xQ60 (Q30 c/u), 5+xQ25 c/u',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextField(
                controller: qty2Controller,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (2 unidades)',
                  hintText: '30',
                  border: OutlineInputBorder(),
                  prefixText: 'Q',
                  helperText: 'Dejar vacío si no aplica',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: qty5PlusController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (5+ unidades)',
                  hintText: '25',
                  border: OutlineInputBorder(),
                  prefixText: 'Q',
                  helperText: 'Dejar vacío si no aplica',
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
          if (bulkPricing != null)
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Eliminar'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null) {
      // Delete bulk pricing
      try {
        await _firestore
            .collection('categories')
            .doc(widget.parentId)
            .collection('subcategories')
            .doc(widget.categoryId)
            .update({'bulkPricing': FieldValue.delete()});

        setState(() {
          _categoryData!['bulkPricing'] = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Precio por mayor eliminado'),
              backgroundColor: AppTheme.success,
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
      return;
    }

    if (result != true) return;

    try {
      final qty2 = double.tryParse(qty2Controller.text.trim());
      final qty5Plus = double.tryParse(qty5PlusController.text.trim());

      Map<String, dynamic>? newBulkPricing;
      if (qty2 != null || qty5Plus != null) {
        newBulkPricing = {};
        if (qty2 != null) newBulkPricing['qty2'] = qty2;
        if (qty5Plus != null) newBulkPricing['qty5Plus'] = qty5Plus;
      }

      await _firestore
          .collection('categories')
          .doc(widget.parentId)
          .collection('subcategories')
          .doc(widget.categoryId)
          .update({
        'bulkPricing': newBulkPricing,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _categoryData!['bulkPricing'] = newBulkPricing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precio por mayor actualizado'),
            backgroundColor: AppTheme.success,
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

  Future<void> _editCategoryInfo() async {
    final nameController = TextEditingController(
        text: _categoryData!['subcategoryName'] as String? ??
            _categoryData!['name'] as String);
    final priceController = TextEditingController(
      text: (_categoryData!['defaultPrice'] ?? 0).toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Código: ${_categoryData!['code']}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Price field (SUPERUSER ONLY)
              if (AuthService.isSuperuser)
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio predeterminado',
                    border: OutlineInputBorder(),
                    prefixText: 'Q',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppTheme.mediumGray),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Precio: Q${_categoryData!['defaultPrice'] ?? 0} (solo administrador)',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final newName = nameController.text.trim();
      final newPrice = AuthService.isSuperuser
          ? (double.tryParse(priceController.text.trim()) ?? 0)
          : (_categoryData!['defaultPrice'] ?? 0);

      if (newName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El nombre no puede estar vacío'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final updateData = {
        'subcategoryName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only update price if superuser
      if (AuthService.isSuperuser) {
        updateData['defaultPrice'] = newPrice;
      }

      // Also update all products with this category
      final productsSnapshot = await _firestore
          .collection('products')
          .where('categoryCode', isEqualTo: _categoryData!['code'])
          .get();

      final batch = _firestore.batch();

      for (var doc in productsSnapshot.docs) {
        batch.update(doc.reference, {
          'subcategory': newName,
          'categoryName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update subcategory
      batch.update(
        _firestore
            .collection('categories')
            .doc(widget.parentId)
            .collection('subcategories')
            .doc(widget.categoryId),
        updateData,
      );

      await batch.commit();

      setState(() {
        _categoryData!['subcategoryName'] = newName;
        if (AuthService.isSuperuser) {
          _categoryData!['defaultPrice'] = newPrice;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría actualizada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Widget _buildCoverImageSection() {
    final coverImageUrl = _categoryData!['coverImageUrl'] as String?;

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
              Text(
                'IMAGEN DE PORTADA',
                style: AppTheme.heading4.copyWith(
                  letterSpacing: 1.2,
                  color: AppTheme.mediumGray,
                ),
              ),
              const Spacer(),
              if (coverImageUrl != null)
                OutlinedButton.icon(
                  onPressed: _deleteCoverImage,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AspectRatio(
            aspectRatio: 1, // Square container
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: AppTheme.borderRadiusMedium,
                border: Border.all(
                  color: AppTheme.lightGray,
                  width: 2,
                ),
              ),
              child: coverImageUrl != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppTheme.borderRadiusMedium,
                          child: Image.network(
                            coverImageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: AppTheme.danger,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: AppTheme.spacingM,
                          right: AppTheme.spacingM,
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingCover
                                ? null
                                : _pickAndUploadCoverImage,
                            icon: _isUploadingCover
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          AppTheme.white),
                                    ),
                                  )
                                : const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Cambiar'),
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                        const SizedBox(height: AppTheme.spacingM),
                        ElevatedButton.icon(
                          onPressed: _isUploadingCover
                              ? null
                              : _pickAndUploadCoverImage,
                          icon: _isUploadingCover
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(AppTheme.white),
                                  ),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: const Text('Subir Imagen'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
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
            'PRODUCTOS (${_products.length})',
            style: AppTheme.heading4.copyWith(
              letterSpacing: 1.2,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          // TODO take me to product detail screen when clicking on a product
          Text(
            'Arrastra para reordenar cómo aparecen en el sitio',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Text(
                  'No hay productos en esta categoría',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            )
          else
            ReorderableGridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppTheme.spacingM,
                mainAxisSpacing: AppTheme.spacingM,
              ),
              itemCount: _products.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final images = (product['images'] as List?)?.cast<String>() ?? [];
    final name = product['name'] ?? product['warehouseCode'] ?? 'Sin nombre';

    return Card(
      key: ValueKey(product['id']),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: images.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 32,
                        color: AppTheme.lightGray,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        images[0],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 32,
                              color: AppTheme.danger,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
