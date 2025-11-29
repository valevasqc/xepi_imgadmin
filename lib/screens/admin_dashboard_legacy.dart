import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _renameCategoryController =
      TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('images');
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _categories = [];
  String? _selectedCategory;
  XFile? _selectedCoverImage;
  List<XFile> _selectedProductImages = [];
  bool _isUploadingCover = false;
  bool _isUploadingProduct = false;
  List<MapEntry<String, String>> _orderedImages = [];
  String? _coverImageUrl;
  final Map<String, String> _imageBarcodes = {}; // Maps imageUrl to barcode
  final Map<String, TextEditingController> _barcodeControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _barcodeControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadBarcodesForCategory(String category) async {
    // Load existing barcodes from Firestore where images array contains URLs from this category
    _imageBarcodes.clear();
    _barcodeControllers.forEach((key, controller) => controller.dispose());
    _barcodeControllers.clear();

    try {
      final querySnapshot = await _firestore.collection('products').get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final primaryImageUrl = data['primaryImageUrl'] as String?;
        final barcode = data['barcode'] as String?;

        if (primaryImageUrl != null && barcode != null) {
          // Map this image URL to its barcode for display
          _imageBarcodes[primaryImageUrl] = barcode;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading barcodes from Firestore: $e');
      // Continue even if error - controllers will be created in build
    }
  }

  TextEditingController _getOrCreateController(
      String imageKey, String imageUrl) {
    if (!_barcodeControllers.containsKey(imageKey)) {
      _barcodeControllers[imageKey] = TextEditingController(
        text: _imageBarcodes[imageUrl] ?? '',
      );
    }
    return _barcodeControllers[imageKey]!;
  }

  bool _allImagesHaveBarcodes() {
    if (_orderedImages.isEmpty) return true;
    for (var entry in _orderedImages) {
      if (!_imageBarcodes.containsKey(entry.value)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveBarcode(String imageKey, String imageUrl) async {
    debugPrint('=== SAVE BARCODE TO FIRESTORE ===');
    debugPrint('imageKey: $imageKey');
    debugPrint('imageUrl: $imageUrl');

    final controller = _barcodeControllers[imageKey];

    if (controller == null) {
      debugPrint('ERROR: Controller is null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: No se pudo encontrar el campo de texto')),
        );
      }
      return;
    }

    final barcode = controller.text.trim();
    debugPrint('barcode value: "$barcode"');

    if (barcode.isEmpty) {
      debugPrint('ERROR: Barcode is empty!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('El código de barras no puede estar vacío')),
        );
      }
      return;
    }

    debugPrint('Attempting to save to Firestore...');
    try {
      // Create/update product document in Firestore - minimal schema
      // Only barcode and primaryImageUrl. Everything else filled by Python later.
      await _firestore.collection('products').doc(barcode).set({
        'barcode': barcode,
        'primaryImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Firestore save successful!');

      setState(() {
        _imageBarcodes[imageUrl] = barcode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✓ Código de barras "$barcode" guardado en Firestore!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('Success message shown');
    } catch (e) {
      debugPrint('ERROR saving to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
            'Estás seguro que quieres eliminar "$category" y todas sus imágenes?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete product images
        final firebase_storage.ListResult productResult =
            await _storage.ref().child('products/$category').listAll();
        for (var item in productResult.items) {
          await item.delete();
        }

        // Delete cover image if exists
        final firebase_storage.ListResult coverResult =
            await _storage.ref().child('covers/$category').listAll();
        for (var item in coverResult.items) {
          await item.delete();
        }

        await _databaseRef.child(category).remove();
        if (_selectedCategory == category) {
          setState(() {
            _selectedCategory = null;
            _orderedImages.clear();
            _coverImageUrl = null;
          });
        }
        await _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada con éxito!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando categoría: $e')),
        );
      }
    }
  }

  Future<void> _renameCategory(String oldName, String newName) async {
    if (newName.trim().isEmpty || newName == oldName) return;

    try {
      final snapshot = await _databaseRef.child(oldName).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;

        // Move data in Realtime Database
        await _databaseRef.child(newName).set(data);
        await _databaseRef.child(oldName).remove();

        // Rename folders in Firebase Storage
        // Products
        final productResult =
            await _storage.ref().child('products/$oldName').listAll();
        for (var item in productResult.items) {
          final newPath = 'products/$newName/${item.name}';
          final data = await item.getData();
          if (data != null) {
            await _storage.ref().child(newPath).putData(data);
            await item.delete();
          }
        }

        // Covers
        final coverResult =
            await _storage.ref().child('covers/$oldName').listAll();
        for (var item in coverResult.items) {
          final newPath = 'covers/$newName/${item.name}';
          final data = await item.getData();
          if (data != null) {
            await _storage.ref().child(newPath).putData(data);
            await item.delete();
          }
        }

        if (_selectedCategory == oldName) {
          setState(() {
            _selectedCategory = newName;
          });
          _fetchImagesForCategory(newName);
        }
        await _fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría renombrada con éxito!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error renombrando categoría: $e')),
      );
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await _databaseRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _categories = data.keys.cast<String>().toList();
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories.first;
            _fetchImagesForCategory(_selectedCategory!);
          } else if (_selectedCategory != null &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = null;
            _orderedImages = [];
            _coverImageUrl = null;
          } else if (_selectedCategory != null) {
            _fetchImagesForCategory(_selectedCategory!);
          }
        });
      } else {
        setState(() {
          _categories = [];
          _selectedCategory = null;
          _orderedImages = [];
          _coverImageUrl = null;
        });
      }
    } else {
      setState(() {
        _categories = [];
        _selectedCategory = null;
        _orderedImages = [];
        _coverImageUrl = null;
      });
    }
  }

  Future<void> _fetchImagesForCategory(String category) async {
    final snapshot = await _databaseRef.child(category).get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map<dynamic, dynamic>) {
        final List<MapEntry<String, String>> fetchedImages = [];
        String? fetchedCoverImageUrl;

        data.forEach((key, value) {
          if (key == 'coverImage') {
            fetchedCoverImageUrl = value.toString();
          } else if (key == 'products') {
            if (value is Map<dynamic, dynamic>) {
              value.forEach((productKey, productValue) {
                if (productKey != '__placeholder__' && productKey != '_empty') {
                  fetchedImages.add(
                      MapEntry(productKey.toString(), productValue.toString()));
                }
              });
            } else if (value is List) {
              for (int i = 0; i < value.length; i++) {
                if (value[i] != null) {
                  fetchedImages
                      .add(MapEntry(i.toString(), value[i].toString()));
                }
              }
            }
          } else if (key != 'coverImage') {
            fetchedImages.add(MapEntry(key.toString(), value.toString()));
          }
        });

        fetchedImages.sort((a, b) {
          final aNum = int.tryParse(a.key) ?? 999999;
          final bNum = int.tryParse(b.key) ?? 999999;
          return aNum.compareTo(bNum);
        });

        setState(() {
          _orderedImages = fetchedImages;
          _coverImageUrl = fetchedCoverImageUrl;
        });

        // Load barcodes for this category
        await _loadBarcodesForCategory(category);
      } else {
        setState(() {
          _orderedImages = [];
          _coverImageUrl = null;
        });
      }
    } else {
      setState(() {
        _orderedImages = [];
        _coverImageUrl = null;
      });
    }
  }

  Future<void> _addCategory() async {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isNotEmpty) {
      await _databaseRef.child(categoryName).set({
        'products': {'__placeholder__': 'keep'}
      });
      _newCategoryController.clear();
      await _fetchCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría creada')),
      );
    }
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedCoverImage = image;
    });
  }

  Future<void> _pickProductImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    setState(() {
      _selectedProductImages = images;
    });
  }

  void _removeSelectedProductImage(int index) {
    setState(() {
      _selectedProductImages.removeAt(index);
    });
  }

  Future<void> _uploadCoverImage() async {
    if (_selectedCategory == null || _selectedCoverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor seleccionar una categoría y una imagen.')),
      );
      return;
    }

    setState(() {
      _isUploadingCover = true;
    });

    try {
      final String fileName =
          'cover_${DateTime.now().millisecondsSinceEpoch}_${_selectedCoverImage!.name}';
      final firebase_storage.Reference ref = _storage
          .ref()
          .child('covers')
          .child(_selectedCategory!)
          .child(fileName);

      await ref.putData(
        await _selectedCoverImage!.readAsBytes(),
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );
      final String downloadURL = await ref.getDownloadURL();

      await _databaseRef
          .child(_selectedCategory!)
          .child('coverImage')
          .set(downloadURL);

      setState(() {
        _selectedCoverImage = null;
        _isUploadingCover = false;
      });

      await _fetchImagesForCategory(_selectedCategory!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida exitosamente!')),
      );
    } catch (e) {
      setState(() {
        _isUploadingCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e')),
      );
    }
  }

  Future<void> _uploadProductImages() async {
    if (_selectedCategory == null || _selectedProductImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor seleccionar una categoría e imágenes.')),
      );
      return;
    }

    setState(() {
      _isUploadingProduct = true;
    });

    try {
      final snapshot =
          await _databaseRef.child(_selectedCategory!).child('products').get();
      int startIndex = 0;
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map<dynamic, dynamic>) {
          startIndex = data.keys
              .where((key) => key != '__placeholder__' && key != '_empty')
              .length;
        } else if (data is List) {
          startIndex = data.length;
        }
      }

      int successCount = 0;
      for (var image in _selectedProductImages) {
        final String fileName =
            'product_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final firebase_storage.Reference ref = _storage
            .ref()
            .child('products')
            .child(_selectedCategory!)
            .child(fileName);

        await ref.putData(
          await image.readAsBytes(),
          firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
        );
        final String downloadURL = await ref.getDownloadURL();

        final newImageKey = (startIndex + successCount).toString();
        await _databaseRef
            .child(_selectedCategory!)
            .child('products')
            .child(newImageKey)
            .set(downloadURL);

        successCount++;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final updatedSnapshot =
          await _databaseRef.child(_selectedCategory!).child('products').get();
      if (updatedSnapshot.exists) {
        final data = updatedSnapshot.value;
        if (data is Map<dynamic, dynamic>) {
          if (data.containsKey('__placeholder__')) {
            await _databaseRef
                .child(_selectedCategory!)
                .child('products')
                .child('__placeholder__')
                .remove();
          }
          if (data.containsKey('_empty')) {
            await _databaseRef
                .child(_selectedCategory!)
                .child('products')
                .child('_empty')
                .remove();
          }
        }
      }

      setState(() {
        _selectedProductImages = [];
        _isUploadingProduct = false;
      });

      await _fetchImagesForCategory(_selectedCategory!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$successCount imagen(es) subida(s) exitosamente!')),
      );
    } catch (e) {
      setState(() {
        _isUploadingProduct = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imágenes: $e')),
      );
    }
  }

  Future<void> _deleteImage(String imageKey, String imageUrl,
      {bool isCoverImage = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Imagen'),
        content: const Text('Estás seguro que quieres eliminar esta imagen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (imageKey != '__placeholder__') {
          final firebase_storage.Reference ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        }

        if (isCoverImage) {
          await _databaseRef
              .child(_selectedCategory!)
              .child('coverImage')
              .remove();
          setState(() {
            _coverImageUrl = null;
          });
        } else {
          await _databaseRef
              .child(_selectedCategory!)
              .child('products')
              .child(imageKey)
              .remove();

          // Also delete from Firestore if it has a barcode
          final barcode = _imageBarcodes[imageUrl];
          if (barcode != null) {
            await _firestore.collection('products').doc(barcode).delete();
          }

          setState(() {
            _orderedImages.removeWhere((entry) => entry.key == imageKey);
            _barcodeControllers[imageKey]?.dispose();
            _barcodeControllers.remove(imageKey);
            _imageBarcodes.remove(imageUrl);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada con éxito!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando imagen: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xepi Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories Panel
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categorías',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return ListTile(
                              title: Text(category),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _fetchImagesForCategory(category);
                                });
                              },
                              selected: _selectedCategory == category,
                              selectedTileColor:
                                  Colors.blueGrey.withOpacity(0.2),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      _renameCategoryController.text = category;
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title:
                                              const Text('Renombrar Categoría'),
                                          content: TextField(
                                            controller:
                                                _renameCategoryController,
                                            decoration: const InputDecoration(
                                                labelText: 'Nuevo Nombre'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _renameCategory(
                                                    category,
                                                    _renameCategoryController
                                                        .text
                                                        .trim());
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Renombrar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteCategory(category),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(
                            labelText: 'Nombre de nueva Categoría'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addCategory,
                        child: const Text('Agregar Categoría'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Images Panel with Barcode Input
            Expanded(
              flex: 5,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoría: ${_selectedCategory ?? 'Seleccionar Categoría'}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      // Make the content scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Upload Controls Row (side by side) - ORIGINAL LAYOUT
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cover Image Upload
                                  Expanded(
                                    child: Card(
                                      elevation: 2,
                                      color: Colors.blue.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Imagen de Portada',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 15),
                                            // Cover Image Preview
                                            if (_coverImageUrl != null)
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 250,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300,
                                                          width: 1),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        _coverImageUrl!,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                            Icons
                                                                .delete_forever,
                                                            color:
                                                                Colors.white),
                                                        onPressed: () =>
                                                            _deleteImage(
                                                                'coverImage',
                                                                _coverImageUrl!,
                                                                isCoverImage:
                                                                    true),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Container(
                                                height: 250,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                      width: 2),
                                                ),
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .add_photo_alternate_outlined,
                                                          size: 64,
                                                          color: Colors.grey),
                                                      SizedBox(height: 8),
                                                      Text(
                                                          'Sin imagen de portada',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 15),
                                            if (_selectedCoverImage != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15.0),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.blue,
                                                          size: 24),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          _selectedCoverImage!
                                                              .name,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (_selectedCoverImage == null)
                                              SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                  onPressed: _isUploadingCover
                                                      ? null
                                                      : () => _pickCoverImage(),
                                                  icon: const Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 24),
                                                  label: const Text(
                                                    'Seleccionar Imagen',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue.shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              )
                                            else
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 48,
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed:
                                                            _isUploadingCover
                                                                ? null
                                                                : () =>
                                                                    setState(
                                                                        () {
                                                                      _selectedCoverImage =
                                                                          null;
                                                                    }),
                                                        icon: const Icon(
                                                            Icons.close),
                                                        label: const Text(
                                                            'Cancelar'),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    flex: 2,
                                                    child: SizedBox(
                                                      height: 48,
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: _isUploadingCover
                                                            ? null
                                                            : _uploadCoverImage,
                                                        icon: _isUploadingCover
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons
                                                                    .cloud_upload,
                                                                size: 24),
                                                        label: Text(
                                                          _isUploadingCover
                                                              ? 'Subiendo...'
                                                              : 'Subir Portada',
                                                          style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
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
                                  const SizedBox(width: 16),
                                  // Product Image Upload
                                  Expanded(
                                    child: Card(
                                      elevation: 2,
                                      color: Colors.green.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                    'Imágenes de Productos',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    '${_orderedImages.length}',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                            // Multi-image selection area
                                            if (_selectedProductImages.isEmpty)
                                              GestureDetector(
                                                onTap: _isUploadingProduct
                                                    ? null
                                                    : _pickProductImages,
                                                child: Container(
                                                  height: 250,
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: Colors
                                                            .green.shade300,
                                                        width: 2),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .add_photo_alternate_outlined,
                                                          size: 64,
                                                          color: Colors
                                                              .green.shade400),
                                                      const SizedBox(
                                                          height: 16),
                                                      Text(
                                                          'Seleccionar múltiples imágenes',
                                                          style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .green
                                                                  .shade700)),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Haz clic aquí para seleccionar\nvarias imágenes a la vez',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.grey
                                                                  .shade600)),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                height: 250,
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          Colors.green.shade300,
                                                      width: 2),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          '${_selectedProductImages.length} imagen(es) seleccionada(s)',
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14),
                                                        ),
                                                        TextButton.icon(
                                                          onPressed:
                                                              _isUploadingProduct
                                                                  ? null
                                                                  : () =>
                                                                      setState(
                                                                          () {
                                                                        _selectedProductImages =
                                                                            [];
                                                                      }),
                                                          icon: const Icon(
                                                              Icons.clear_all,
                                                              size: 18),
                                                          label: const Text(
                                                              'Limpiar',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Expanded(
                                                      child: GridView.builder(
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          crossAxisSpacing: 8,
                                                          mainAxisSpacing: 8,
                                                          childAspectRatio: 1,
                                                        ),
                                                        itemCount:
                                                            _selectedProductImages
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300),
                                                            ),
                                                            child: Stack(
                                                              children: [
                                                                Center(
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child: Text(
                                                                      _selectedProductImages[
                                                                              index]
                                                                          .name,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              9),
                                                                      maxLines:
                                                                          4,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Positioned(
                                                                  top: 0,
                                                                  right: 0,
                                                                  child:
                                                                      IconButton(
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .close,
                                                                        size:
                                                                            14),
                                                                    onPressed: () =>
                                                                        _removeSelectedProductImage(
                                                                            index),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                      minWidth:
                                                                          24,
                                                                      minHeight:
                                                                          24,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(height: 15),
                                            if (_selectedProductImages.isEmpty)
                                              SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                  onPressed: _isUploadingProduct
                                                      ? null
                                                      : _pickProductImages,
                                                  icon: const Icon(
                                                      Icons.collections,
                                                      size: 24),
                                                  label: const Text(
                                                    'Seleccionar Múltiples Imágenes',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green.shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                              )
                                            else
                                              SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton.icon(
                                                  onPressed: _isUploadingProduct
                                                      ? null
                                                      : _uploadProductImages,
                                                  icon: _isUploadingProduct
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.cloud_upload,
                                                          size: 24),
                                                  label: Text(
                                                    _isUploadingProduct
                                                        ? 'Subiendo ${_selectedProductImages.length} imagen(es)...'
                                                        : 'Subir ${_selectedProductImages.length} Imagen(es)',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
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
                              const SizedBox(height: 30),
                              const Divider(thickness: 2),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Imágenes de Productos:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text('Total: ${_orderedImages.length}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Conditional warning banner
                              if (_orderedImages.isNotEmpty &&
                                  !_allImagesHaveBarcodes())
                                Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Colors.orange.shade700),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Algunas imágenes no tienen códigos de barras asignados. Asigna códigos para vincular con los datos del Excel.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_orderedImages.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.image_not_supported_outlined,
                                            size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text(
                                          'No existen imágenes para esta categoría',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                // ReorderableGrid with barcode inputs
                                ReorderableGridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: _orderedImages.length,
                                  onReorder: (oldIndex, newIndex) async {
                                    if (_selectedCategory == null) return;

                                    setState(() {
                                      final item =
                                          _orderedImages.removeAt(oldIndex);
                                      _orderedImages.insert(newIndex, item);
                                    });

                                    // Update Firebase with new order
                                    final updates = <String, dynamic>{};
                                    for (int i = 0;
                                        i < _orderedImages.length;
                                        i++) {
                                      updates['$i'] = _orderedImages[i].value;
                                    }

                                    try {
                                      await _databaseRef
                                          .child(_selectedCategory!)
                                          .child('products')
                                          .set(updates);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error al reordenar: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      // Revert on error
                                      await _fetchImagesForCategory(
                                          _selectedCategory!);
                                    }
                                  },
                                  itemBuilder: (context, index) {
                                    final entry = _orderedImages[index];
                                    // Get or create controller on-demand
                                    final controller = _getOrCreateController(
                                        entry.key, entry.value);
                                    final hasBarcode =
                                        _imageBarcodes.containsKey(entry.value);

                                    return Card(
                                      key: ValueKey(entry.key),
                                      elevation: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Image preview
                                          Expanded(
                                            flex: 3,
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                          top: Radius.circular(
                                                              4)),
                                                  child: Image.network(
                                                    entry.value,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        Container(
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                          Icons.error,
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                                // Status indicator
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: hasBarcode
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          hasBarcode
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons.pending,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          hasBarcode
                                                              ? 'Código asignado'
                                                              : 'Sin código',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // Delete button
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                          size: 18),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                              minWidth: 32,
                                                              minHeight: 32),
                                                      onPressed: () =>
                                                          _deleteImage(
                                                              entry.key,
                                                              entry.value),
                                                    ),
                                                  ),
                                                ),
                                                // Drag indicator
                                                Positioned(
                                                  bottom: 8,
                                                  left: 8,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .blue.shade700
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: const Icon(
                                                      Icons.drag_indicator,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Barcode input section
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const Text(
                                                    'Código de Barras:',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Show barcode or input field based on status
                                                  if (hasBarcode &&
                                                      controller
                                                          .text.isNotEmpty)
                                                    // Display mode: Show barcode with edit button
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .green.shade50,
                                                        border: Border.all(
                                                            color: Colors
                                                                .green.shade300,
                                                            width: 1.5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              controller.text,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              // Force rebuild to show edit mode
                                                              setState(() {
                                                                _imageBarcodes
                                                                    .remove(entry
                                                                        .value);
                                                              });
                                                            },
                                                            icon: const Icon(
                                                                Icons.edit,
                                                                size: 16),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                                    minWidth:
                                                                        28,
                                                                    minHeight:
                                                                        28),
                                                            style: IconButton
                                                                .styleFrom(
                                                              foregroundColor:
                                                                  Colors.blue
                                                                      .shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else
                                                    // Edit mode: Show input field and save button
                                                    Column(
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              controller,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                'Ej: 1203023000012',
                                                            hintStyle: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey
                                                                    .shade400),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        8),
                                                            isDense: true,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        ElevatedButton.icon(
                                                          onPressed: () =>
                                                              _saveBarcode(
                                                                  entry.key,
                                                                  entry.value),
                                                          icon: const Icon(
                                                              Icons.save,
                                                              size: 14),
                                                          label: const Text(
                                                            'Guardar',
                                                            style: TextStyle(
                                                                fontSize: 11),
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.blue,
                                                            foregroundColor:
                                                                Colors.white,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        8),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
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
    );
  }
}
