import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';
import 'package:xepi_imgadmin/screens/add_product_screen.dart';
import 'package:xepi_imgadmin/widgets/product_search_dialog.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';

class ReceiveShipmentScreen extends StatefulWidget {
  final String? shipmentId; // If editing existing shipment

  const ReceiveShipmentScreen({super.key, this.shipmentId});

  @override
  State<ReceiveShipmentScreen> createState() => _ReceiveShipmentScreenState();
}

class _ReceiveShipmentScreenState extends State<ReceiveShipmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  Map<String, Map<String, dynamic>> _scannedItems =
      {}; // barcode -> {product data + quantity}
  bool _isLoading = false;
  bool _isSaving = false;
  String? _shipmentId;
  String _shipmentStatus = 'in-progress';

  @override
  void initState() {
    super.initState();
    _shipmentId = widget.shipmentId;
    if (_shipmentId != null) {
      _loadExistingShipment();
    } else {
      _createNewShipment();
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
                color: AppTheme.white, boxShadow: AppTheme.subtleShadow),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _handleBack(context),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  widget.shipmentId != null
                      ? 'Editar Recepción'
                      : 'Recibir Mercadería',
                  style: AppTheme.heading1,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _handleBack(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                if (_shipmentStatus != 'completed')
                  ElevatedButton.icon(
                    onPressed: _scannedItems.isEmpty || _isSaving
                        ? null
                        : _completeShipment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                        _isSaving ? 'Guardando...' : 'Confirmar Recepción'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildScanCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildProductsList(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(child: _buildSummaryCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded,
              size: 64, color: AppTheme.blue),
          const SizedBox(height: AppTheme.spacingL),
          Text('Escanear Código de Barras', style: AppTheme.heading2),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Escanea con lector USB o escribe manualmente',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras',
                    hintText: 'Escanea o escribe el código',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                  onSubmitted: (barcode) {
                    if (barcode.trim().isNotEmpty) {
                      _handleBarcodeScanned(barcode.trim());
                      _barcodeController.clear();
                      _barcodeFocusNode.requestFocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              OutlinedButton.icon(
                onPressed: _showSearchDialog,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buscar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadExcel,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Cargar Excel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scannedItems.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Limpiar Todo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_scannedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: AppTheme.lightGray),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No hay productos escaneados',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Escanea códigos de barras para comenzar',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.lightGray),
            ),
          ],
        ),
      );
    }

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
              Text('Productos Escaneados', style: AppTheme.heading3),
              const Spacer(),
              Text(
                '${_scannedItems.length} productos',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ..._scannedItems.entries.map((entry) {
            final barcode = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: _buildScannedProduct(barcode, item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScannedProduct(String barcode, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: item['images'] != null && (item['images'] as List).isNotEmpty
                ? ClipRRect(
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Image.network(
                      item['images'][0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.blue),
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined, color: AppTheme.blue),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.isNotEmpty == true
                      ? item['name']
                      : (item['warehouseCode'] ?? 'Sin nombre'),
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  barcode,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppTheme.danger),
            onPressed: () => _decrementQuantity(barcode),
            tooltip: 'Reducir cantidad',
          ),
          InkWell(
            onTap: () => _editQuantity(barcode, item['quantity']),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Text(
                '${item['quantity']}',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.success),
            onPressed: () => _incrementQuantity(barcode),
            tooltip: 'Aumentar cantidad',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger),
            onPressed: () => _removeItem(barcode),
            tooltip: 'Eliminar producto',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalProducts = _scannedItems.length;
    final totalUnits = _scannedItems.values.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

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
          Text('Resumen de Recepción', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Destino', 'Bodega Principal'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(
            'Fecha',
            '${DateTime.now().day} ${DateFormatter.getMonthName(DateTime.now().month)} ${DateTime.now().year}',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(
            'Hora',
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          ),
          const Divider(height: AppTheme.spacingXL),
          _buildSummaryRow('Total Productos', '$totalProducts'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Total Unidades', '$totalUnits', highlight: true),
          if (_shipmentStatus == 'completed') ...[
            const Divider(height: AppTheme.spacingXL),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 20),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Recepción completada',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.blue : AppTheme.darkGray,
          ),
        ),
      ],
    );
  }
  // ==================== BUSINESS LOGIC ====================

  Future<void> _createNewShipment() async {
    try {
      final userId = AuthService.currentUser?.uid ?? 'unknown';
      final userName = AuthService.currentUser?.email ?? 'Usuario';

      final docRef = await _firestore.collection('shipments').add({
        'status': 'in-progress',
        'date': FieldValue.serverTimestamp(),
        'receivedBy': userId,
        'receivedByName': userName,
        'items': [],
        'totalItems': 0,
        'totalProducts': 0,
        'completedAt': null,
        'cancelledAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': null,
      });

      setState(() {
        _shipmentId = docRef.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _loadExistingShipment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await _firestore.collection('shipments').doc(_shipmentId).get();

      if (!doc.exists) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recepción no encontrada'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final data = doc.data()!;
      final items = data['items'] as List<dynamic>;

      setState(() {
        _shipmentStatus = data['status'] as String;
        _scannedItems = {};

        for (var item in items) {
          _scannedItems[item['barcode']] = {
            'name': item['productName'],
            'quantity': item['quantity'],
            'categoryCode': item['categoryCode'],
            'images': item['images'],
          };
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    if (_scannedItems.containsKey(barcode)) {
      setState(() {
        _scannedItems[barcode]!['quantity'] += 1;
      });
      await _updateShipmentInFirestore();
      return;
    }

    try {
      final productDoc =
          await _firestore.collection('products').doc(barcode).get();

      if (productDoc.exists) {
        final productData = productDoc.data()!;
        setState(() {
          _scannedItems[barcode] = {
            'name': productData['name'] ?? '',
            'warehouseCode': productData['warehouseCode'] ?? '',
            'quantity': 1,
            'categoryCode': productData['categoryCode'],
            'images': productData['images'] ?? [],
          };
        });
        await _updateShipmentInFirestore();
      } else {
        _promptCreateProduct(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar producto: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _promptCreateProduct(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Producto no encontrado'),
        content: Text('El código de barras $barcode no existe en el sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddProductScreen(prefilledBarcode: barcode),
                ),
              );

              if (result == true) {
                await _handleBarcodeScanned(barcode);
              }
            },
            child: const Text('Crear Producto'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ProductSearchDialog(
        onProductSelected: (productData) {
          final barcode = productData['barcode'] as String;
          setState(() {
            if (_scannedItems.containsKey(barcode)) {
              _scannedItems[barcode]!['quantity'] += 1;
            } else {
              _scannedItems[barcode] = {
                'name': productData['name'] ?? '',
                'warehouseCode': productData['warehouseCode'] ?? '',
                'quantity': 1,
                'categoryCode': productData['categoryCode'],
                'images': productData['images'] ?? [],
              };
            }
          });
          _updateShipmentInFirestore();
          _barcodeFocusNode.requestFocus();
        },
      ),
    );
  }

  void _incrementQuantity(String barcode) {
    setState(() {
      _scannedItems[barcode]!['quantity'] += 1;
    });
    _updateShipmentInFirestore();
  }

  void _decrementQuantity(String barcode) {
    final currentQty = _scannedItems[barcode]!['quantity'] as int;
    if (currentQty > 1) {
      setState(() {
        _scannedItems[barcode]!['quantity'] -= 1;
      });
      _updateShipmentInFirestore();
    } else {
      _removeItem(barcode);
    }
  }

  void _removeItem(String barcode) {
    setState(() {
      _scannedItems.remove(barcode);
    });
    _updateShipmentInFirestore();
  }

  Future<void> _editQuantity(String barcode, int currentQty) async {
    final controller = TextEditingController(text: currentQty.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text.trim());
              if (qty != null && qty > 0) {
                Navigator.pop(context, qty);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _scannedItems[barcode]!['quantity'] = result;
      });
      await _updateShipmentInFirestore();
    }
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar todo'),
        content: const Text(
            '¿Estás seguro de eliminar todos los productos escaneados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scannedItems.clear();
              });
              _updateShipmentInFirestore();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result == null) return;

      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cargar Excel'),
          content: const Text('¿Cómo deseas importar los datos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, 'merge'),
              child: const Text('Combinar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'replace'),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );

      if (action == null) return;

      if (action == 'replace') {
        setState(() {
          _scannedItems.clear();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Función de Excel próximamente (parseo de archivo pendiente)'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar Excel: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _updateShipmentInFirestore() async {
    if (_shipmentId == null) return;

    try {
      final now = Timestamp.now();
      final items = _scannedItems.entries.map((entry) {
        return {
          'barcode': entry.key,
          'productName': entry.value['name'],
          'warehouseCode': entry.value['warehouseCode'],
          'categoryCode': entry.value['categoryCode'],
          'quantity': entry.value['quantity'],
          'images': entry.value['images'],
          'addedAt': now,
        };
      }).toList();

      final totalUnits = _scannedItems.values.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

      await _firestore.collection('shipments').doc(_shipmentId).update({
        'items': items,
        'totalProducts': _scannedItems.length,
        'totalItems': totalUnits,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating shipment: $e');
    }
  }

  Future<void> _completeShipment() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final batch = _firestore.batch();
      final now = Timestamp.now();

      // Prepare items data
      final items = _scannedItems.entries.map((entry) {
        return {
          'barcode': entry.key,
          'productName': entry.value['name'],
          'warehouseCode': entry.value['warehouseCode'],
          'categoryCode': entry.value['categoryCode'],
          'quantity': entry.value['quantity'],
          'images': entry.value['images'],
          'addedAt': now,
        };
      }).toList();

      final totalUnits = _scannedItems.values.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

      // Update products stock
      for (var entry in _scannedItems.entries) {
        final barcode = entry.key;
        final quantity = entry.value['quantity'] as int;

        final productRef = _firestore.collection('products').doc(barcode);
        batch.update(productRef, {
          'stockWarehouse': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update shipment with items and status
      final shipmentRef = _firestore.collection('shipments').doc(_shipmentId);
      batch.update(shipmentRef, {
        'items': items,
        'totalProducts': _scannedItems.length,
        'totalItems': totalUnits,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción completada exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleBack(BuildContext context) async {
    if (_scannedItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: const Text(
            'Tienes productos escaneados. La recepción quedará guardada como borrador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }
}
