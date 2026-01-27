import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';
import 'package:xepi_imgadmin/widgets/product_search_dialog.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';

class TransferStockScreen extends StatefulWidget {
  const TransferStockScreen({super.key});

  @override
  State<TransferStockScreen> createState() => _TransferStockScreenState();
}

class _TransferStockScreenState extends State<TransferStockScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  List<Map<String, dynamic>> _locations = [];
  String? _originLocationId;
  String? _destinationLocationId;
  final Map<String, Map<String, dynamic>> _scannedItems =
      {}; // barcode -> {product + quantity}
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      setState(() {
        _locations =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

        // Set default origin to warehouse
        final warehouse = _locations.firstWhere(
          (loc) => loc['id'] == 'warehouse',
          orElse: () => {},
        );
        if (warehouse.isNotEmpty) {
          _originLocationId = warehouse['id'] as String;
        } else if (_locations.isNotEmpty) {
          _originLocationId = _locations[0]['id'] as String;
        }

        // Set default destination to store
        final store = _locations.firstWhere(
          (loc) => loc['id'] == 'store',
          orElse: () => {},
        );
        if (store.isNotEmpty) {
          _destinationLocationId = store['id'] as String;
        } else if (_locations.length > 1) {
          _destinationLocationId = _locations[1]['id'] as String;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e')),
        );
      }
    }
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
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Trasladar Inventario', style: AppTheme.heading1),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: _scannedItems.isEmpty ||
                          _isSaving ||
                          !_canCreateMovement()
                      ? null
                      : _createMovement,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSaving ? 'Guardando...' : 'Crear Traslado'),
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
                        _buildLocationCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildScanCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        if (_scannedItems.isNotEmpty) _buildProductsList(),
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

  bool _canCreateMovement() {
    return _originLocationId != null &&
        _destinationLocationId != null &&
        _originLocationId != _destinationLocationId;
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Origen',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                _buildLocationDropdown(
                  value: _originLocationId,
                  onChanged: (value) {
                    setState(() {
                      _originLocationId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Icon(Icons.arrow_forward_rounded,
                color: AppTheme.blue, size: 32),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destino',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                _buildLocationDropdown(
                  value: _destinationLocationId,
                  onChanged: (value) {
                    setState(() {
                      _destinationLocationId = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.backgroundGray,
        border: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: AppTheme.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusSmall,
          borderSide: const BorderSide(color: AppTheme.lightGray),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
      ),
      icon:
          const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.mediumGray),
      items: _locations.map((location) {
        return DropdownMenuItem<String>(
          value: location['id'],
          child: Row(
            children: [
              Icon(
                location['type'] == 'warehouse'
                    ? Icons.warehouse_rounded
                    : Icons.store_rounded,
                size: 20,
                color: AppTheme.blue,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                location['name'] ?? location['id'],
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildScanCard() {
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
              const Icon(Icons.qr_code_scanner_rounded,
                  size: 48, color: AppTheme.blue),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Escanear Productos', style: AppTheme.heading3),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Escanea el código de barras para agregar productos',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Código de Barras',
                    hintText: 'Escanea o ingresa código',
                    prefixIcon: const Icon(Icons.qr_code_rounded),
                    border: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusSmall),
                    filled: true,
                    fillColor: AppTheme.backgroundGray,
                  ),
                  onSubmitted: (barcode) {
                    if (barcode.isNotEmpty) {
                      _handleBarcodeScanned(barcode);
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
        ],
      ),
    );
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();

    if (_originLocationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se ha seleccionado ubicación de origen'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    try {
      final productDoc =
          await _firestore.collection('products').doc(barcode).get();

      if (!productDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto no encontrado: $barcode'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        return;
      }

      final productData = productDoc.data()!;

      // Check stock availability at origin location
      if (_originLocationId != null) {
        final stockField = _locations.firstWhere(
          (loc) => loc['id'] == _originLocationId,
          orElse: () => {},
        )['stockField'] as String?;

        final availableStock = productData[stockField] ?? 0;

        if (availableStock <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Sin stock en origen: ${productData['name'] ?? productData['warehouseCode'] ?? barcode}'),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        if (_scannedItems.containsKey(barcode)) {
          _scannedItems[barcode]!['quantity']++;
        } else {
          _scannedItems[barcode] = {
            'barcode': barcode,
            'name': productData['name'] ?? '',
            'warehouseCode': productData['warehouseCode'] ?? '',
            'quantity': 1,
            'productData': productData,
          };
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Agregado: ${productData['name'] ?? productData['warehouseCode'] ?? barcode}'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 1),
          ),
        );
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

  void _showQuantityDialog(
      String barcode, int currentQuantity, int maxQuantity) async {
    // Fetch fresh stock data
    int actualMaxQuantity = maxQuantity;
    try {
      final productDoc =
          await _firestore.collection('products').doc(barcode).get();
      if (productDoc.exists && _originLocationId != null) {
        final stockField = _locations.firstWhere(
          (loc) => loc['id'] == _originLocationId,
          orElse: () => {},
        )['stockField'] as String?;

        if (stockField != null) {
          actualMaxQuantity = productDoc.data()![stockField] ?? 0;
          // Update the stored product data with fresh data
          setState(() {
            _scannedItems[barcode]!['productData'] = productDoc.data()!;
          });
        }
      }
    } catch (e) {
      // Use the passed maxQuantity if fetch fails
    }

    final controller = TextEditingController(text: currentQuantity.toString());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cantidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponible en origen: $actualMaxQuantity',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Cantidad a trasladar',
                hintText: 'Máximo: $actualMaxQuantity',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                final newQty = int.tryParse(value) ?? currentQuantity;
                if (newQty > 0 && newQty <= actualMaxQuantity) {
                  setState(() {
                    _scannedItems[barcode]!['quantity'] = newQty;
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? currentQuantity;
              if (newQty > 0 && newQty <= actualMaxQuantity) {
                setState(() {
                  _scannedItems[barcode]!['quantity'] = newQty;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Cantidad debe ser entre 1 y $actualMaxQuantity (stock disponible)'),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
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
          Text('Productos para Trasladar (${_scannedItems.length})',
              style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          ..._scannedItems.values.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: _buildTransferProduct(item),
              )),
        ],
      ),
    );
  }

  Widget _buildTransferProduct(Map<String, dynamic> item) {
    final barcode = item['barcode'];
    final name = item['name'];
    final warehouseCode = item['warehouseCode'];
    final quantity = item['quantity'] as int;
    final productData = item['productData'] as Map<String, dynamic>?;

    // Get available stock at origin
    final stockField = _originLocationId != null
        ? (_locations.firstWhere(
            (loc) => loc['id'] == _originLocationId,
            orElse: () => <String, dynamic>{},
          )['stockField'] as String?)
        : null;

    // Cast to int explicitly, defaulting to 0
    final totalAvailableStock = productData != null && stockField != null
        ? ((productData[stockField] is int)
            ? productData[stockField]
            : (productData[stockField] is double
                ? (productData[stockField] as double).toInt()
                : 0))
        : 0;

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
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.blue),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name : warehouseCode ?? barcode,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$barcode • Disponible: $totalAvailableStock',
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppTheme.blue),
            onPressed: quantity > 1
                ? () {
                    setState(() {
                      _scannedItems[barcode]!['quantity'] = quantity - 1;
                    });
                  }
                : null,
          ),
          GestureDetector(
            onTap: () =>
                _showQuantityDialog(barcode, quantity, totalAvailableStock),
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
                '$quantity',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.blue),
            onPressed: quantity < totalAvailableStock
                ? () {
                    setState(() {
                      _scannedItems[barcode]!['quantity'] = quantity + 1;
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _scannedItems.remove(barcode);
              });
            },
            color: AppTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final originLocation = _originLocationId != null
        ? _locations.firstWhere(
            (loc) => loc['id'] == _originLocationId,
            orElse: () => {'name': _originLocationId},
          )
        : null;

    final destinationLocation = _destinationLocationId != null
        ? _locations.firstWhere(
            (loc) => loc['id'] == _destinationLocationId,
            orElse: () => {'name': _destinationLocationId},
          )
        : null;

    final totalUnits = _scannedItems.values.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${now.day} ${DateFormatter.getMonthName(now.month)} ${now.year}';

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
          Text('Resumen de Traslado', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          if (originLocation != null)
            _buildSummaryRow(
              Icons.warehouse_outlined,
              'Origen',
              originLocation['name'] ?? _originLocationId ?? '',
            ),
          if (originLocation != null) const SizedBox(height: AppTheme.spacingM),
          if (destinationLocation != null)
            _buildSummaryRow(
              Icons.store_outlined,
              'Destino',
              destinationLocation['name'] ?? _destinationLocationId ?? '',
            ),
          if (destinationLocation != null)
            const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(Icons.calendar_today_rounded, 'Fecha', dateStr),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(Icons.access_time_rounded, 'Hora', timeStr),
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Productos',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
              Text(
                '${_scannedItems.length}',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Unidades',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
              Text(
                '$totalUnits',
                style: AppTheme.heading3.copyWith(color: AppTheme.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.mediumGray),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label:',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _createMovement() async {
    if (!_canCreateMovement() || _scannedItems.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Prepare items array
      final items = _scannedItems.values.map((item) {
        return {
          'barcode': item['barcode'],
          'name': item['name'],
          'warehouseCode': item['warehouseCode'],
          'quantity': item['quantity'],
        };
      }).toList();

      // Create movement document
      final movementData = {
        'originLocationId': _originLocationId,
        'destinationLocationId': _destinationLocationId,
        'items': items,
        'status': 'pending',
        'createdBy': user.email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('movements').add(movementData);

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Text('Traslado creado exitosamente'),
              ],
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _showSearchDialog() async {
    if (_originLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona ubicación de origen primero'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Get stock field for filtering
    final stockField = _locations.firstWhere(
      (loc) => loc['id'] == _originLocationId,
      orElse: () => {},
    )['stockField'] as String?;

    await showDialog(
      context: context,
      builder: (context) => ProductSearchDialog(
        stockSourceFilter: stockField == 'stockStore' ? 'store' : 'warehouse',
        showStock: true,
        onProductSelected: (productData) {
          final barcode = productData['barcode'] as String;
          setState(() {
            if (_scannedItems.containsKey(barcode)) {
              _scannedItems[barcode]!['quantity']++;
            } else {
              _scannedItems[barcode] = {
                'barcode': barcode,
                'name': productData['name'] ?? '',
                'warehouseCode': productData['warehouseCode'] ?? '',
                'quantity': 1,
                'productData': productData,
              };
            }
          });
          _barcodeFocusNode.requestFocus();
        },
      ),
    );
  }
}
