import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/widgets/product_search_dialog.dart';
import 'package:xepi_imgadmin/services/bank_accounts_service.dart';

class RegisterSaleScreen extends StatefulWidget {
  final String? initialSaleType;
  
  const RegisterSaleScreen({super.key, this.initialSaleType});

  @override
  State<RegisterSaleScreen> createState() => _RegisterSaleScreenState();
}

class _RegisterSaleScreenState extends State<RegisterSaleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BankAccountsService _bankAccountsService = BankAccountsService();

  // Sale type
  late String _saleType; // 'kiosko' | 'delivery'
  String? _deliveryMethod; // 'mensajero' | 'forza'
  String _paymentMethod =
      'efectivo'; // 'efectivo' | 'transferencia' | 'tarjeta'
  String _deductFrom = 'store'; // 'store' | 'warehouse'
  String? _selectedBankAccount; // For transferencia/tarjeta

  // Bank accounts
  List<Map<String, dynamic>> _bankAccounts = [];

  // Cart items
  final Map<String, Map<String, dynamic>> _cartItems = {};
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  // Customer info
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _nitController =
      TextEditingController(text: 'CF');

  // Discount
  final TextEditingController _discountController =
      TextEditingController(text: '0');

  bool _isCreatingSale = false;

  @override
  void initState() {
    super.initState();
    _saleType = widget.initialSaleType ?? 'kiosko';
    _loadBankAccounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await _bankAccountsService.getActiveAccounts();
      setState(() {
        _bankAccounts = accounts;
      });
    } catch (e) {
      // Silent fail - defaults to empty list
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _nitController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // Check if item is eligible for bulk pricing (cuadros 20x30 or 15x30)
  bool _isBulkEligible(Map<String, dynamic> item) {
    final productData = item['productData'] as Map<String, dynamic>?;
    if (productData == null) return false;
    
    final categoryCode = productData['categoryCode'] as String?;
    // Cuadros 20x30 and 15x30 are eligible for bulk pricing
    return categoryCode == 'CUA-2030' || categoryCode == 'CUA-1530';
  }

  // Get total quantity of bulk-eligible items in cart
  int _getBulkEligibleQuantity() {
    return _cartItems.values.fold<int>(0, (sum, item) {
      if (_isBulkEligible(item)) {
        return sum + (item['quantity'] as int);
      }
      return sum;
    });
  }

  // Get effective unit price for an item (applying bulk pricing if applicable)
  double _getEffectiveUnitPrice(Map<String, dynamic> item) {
    final basePrice = item['unitPrice'] as double;
    
    // Check if item is bulk-eligible
    if (!_isBulkEligible(item)) {
      return basePrice;
    }

    // Get total quantity of bulk-eligible items
    final totalBulkQty = _getBulkEligibleQuantity();
    
    // Apply bulk pricing if >= 2 items
    if (totalBulkQty >= 2) {
      final productData = item['productData'] as Map<String, dynamic>;
      final categoryCode = productData['categoryCode'] as String;
      
      // Get bulk pricing from stored category data (should be loaded when item was added)
      final bulkPricing = productData['bulkPricing'] as Map<String, dynamic>?;
      
      if (bulkPricing != null) {
        // Apply appropriate tier
        if (totalBulkQty >= 5 && bulkPricing['qty5Plus'] != null) {
          return (bulkPricing['qty5Plus'] as num).toDouble();
        } else if (totalBulkQty >= 2 && bulkPricing['qty2'] != null) {
          return (bulkPricing['qty2'] as num).toDouble();
        }
      }
    }
    
    return basePrice;
  }

  double get _subtotal {
    return _cartItems.values.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final effectivePrice = _getEffectiveUnitPrice(item);
      return sum + (quantity * effectivePrice);
    });
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _total {
    return _subtotal - _discount;
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    if (barcode.trim().isEmpty) return;

    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();

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
      final name = productData['name'] ?? '';
      final warehouseCode = productData['warehouseCode'] ?? '';

      // Get price (override or category default) and bulk pricing
      double? price;
      Map<String, dynamic>? bulkPricing;
      final priceOverride = productData['priceOverride'];
      if (priceOverride != null) {
        price = priceOverride.toDouble();
      } else {
        final categoryCode = productData['categoryCode'];
        if (categoryCode != null) {
          final categoryDoc = await _getCategoryByCode(categoryCode);
          if (categoryDoc != null) {
            final defaultPrice = categoryDoc['defaultPrice'];
            if (defaultPrice != null) {
              price = defaultPrice.toDouble();
            }
            // Store bulk pricing if available (for cuadros 20x30 and 15x30)
            bulkPricing = categoryDoc['bulkPricing'] as Map<String, dynamic>?;
          }
        }
      }

      if (price == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto sin precio configurado'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // Check stock
      final stockField =
          _deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';
      final currentStock = productData[stockField] ?? 0;

      if (currentStock <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Producto sin stock en ${_deductFrom == 'store' ? 'tienda' : 'bodega'}'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      setState(() {
        if (_cartItems.containsKey(barcode)) {
          final currentQty = _cartItems[barcode]!['quantity'] as int;
          if (currentQty < currentStock) {
            _cartItems[barcode]!['quantity'] = currentQty + 1;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Stock insuficiente'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
        } else {
          // Enrich productData with bulkPricing if available
          final enrichedProductData = Map<String, dynamic>.from(productData);
          if (bulkPricing != null) {
            enrichedProductData['bulkPricing'] = bulkPricing;
          }
          
          _cartItems[barcode] = {
            'barcode': barcode,
            'name': name,
            'warehouseCode': warehouseCode,
            'quantity': 1,
            'unitPrice': price,
            'maxStock': currentStock,
            'productData': enrichedProductData,
          };
        }
      });
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

  Future<Map<String, dynamic>?> _getCategoryByCode(String code) async {
    // Search through all primary categories and their subcategories
    final primarySnapshot = await _firestore.collection('categories').get();

    for (var primaryDoc in primarySnapshot.docs) {
      final subSnapshot = await primaryDoc.reference
          .collection('subcategories')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (subSnapshot.docs.isNotEmpty) {
        return subSnapshot.docs.first.data();
      }
    }

    return null;
  }

  Future<void> _showSearchDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ProductSearchDialog(
        stockSourceFilter: _deductFrom == 'store' ? 'store' : 'warehouse',
        showStock: true,
        showPrices: true,
        onProductSelected: (productData) async {
          final barcode = productData['barcode'] as String;

          // Get price (override or category default) and bulk pricing
          double? price;
          Map<String, dynamic>? bulkPricing;
          final priceOverride = productData['priceOverride'];
          if (priceOverride != null) {
            price = priceOverride.toDouble();
          } else {
            // Try to get category default price
            final categoryCode = productData['categoryCode'];
            if (categoryCode != null) {
              final categoryDoc = await _getCategoryByCode(categoryCode);
              if (categoryDoc != null) {
                final defaultPrice = categoryDoc['defaultPrice'];
                if (defaultPrice != null) {
                  price = defaultPrice.toDouble();
                }
                // Store bulk pricing if available
                bulkPricing = categoryDoc['bulkPricing'] as Map<String, dynamic>?;
              }
            }
          }

          if (price == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto sin precio configurado'),
                backgroundColor: AppTheme.danger,
              ),
            );
            return;
          }

          final stockField =
              _deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';
          final currentStock = productData[stockField] ?? 0;

          if (currentStock <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Producto sin stock en ${_deductFrom == 'store' ? 'tienda' : 'bodega'}'),
                backgroundColor: AppTheme.danger,
              ),
            );
            return;
          }

          setState(() {
            if (_cartItems.containsKey(barcode)) {
              _cartItems[barcode]!['quantity']++;
            } else {
              // Enrich productData with bulkPricing if available
              final enrichedProductData = Map<String, dynamic>.from(productData);
              if (bulkPricing != null) {
                enrichedProductData['bulkPricing'] = bulkPricing;
              }
              
              _cartItems[barcode] = {
                'barcode': barcode,
                'name': productData['name'] ?? '',
                'warehouseCode': productData['warehouseCode'] ?? '',
                'quantity': 1,
                'unitPrice': price,
                'maxStock': currentStock,
                'productData': enrichedProductData,
              };
            }
          });
          _barcodeFocusNode.requestFocus();
        },
      ),
    );
  }

  void _updateQuantity(String barcode, String value, int currentQty, int maxStock) {
    final newQty = int.tryParse(value) ?? currentQty;
    if (newQty > 0 && newQty <= maxStock) {
      setState(() {
        _cartItems[barcode]!['quantity'] = newQty;
      });
    } else if (newQty > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock máximo: $maxStock'),
          backgroundColor: AppTheme.warning,
        ),
      );
      setState(() {
        _cartItems[barcode]!['quantity'] = maxStock;
      });
    } else {
      setState(() {
        _cartItems[barcode]!['quantity'] = 1;
      });
    }
  }

  Future<void> _createSale() async {
    // Validation
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (_saleType == 'delivery') {
      if (_customerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre del cliente es requerido para entregas'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      if (_customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teléfono del cliente es requerido para entregas'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      if (_deliveryAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección de entrega es requerida'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      if (_deliveryMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona método de entrega'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
    }

    if (_nitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIT es requerido'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Validate bank account for non-cash payments
    if ((_paymentMethod == 'transferencia' || _paymentMethod == 'tarjeta') &&
        _selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cuenta bancaria'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingSale = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final batch = _firestore.batch();
      final saleRef = _firestore.collection('sales').doc();

      // Prepare sale items
      final items = _cartItems.values.map((item) {
        return {
          'barcode': item['barcode'],
          'name': item['name'],
          'quantity': item['quantity'],
          'unitPrice': item['unitPrice'],
          'subtotal': (item['quantity'] as int) * (item['unitPrice'] as double),
        };
      }).toList();

      // Determine status and stock status
      final requiresApproval =
          _paymentMethod == 'transferencia' || _paymentMethod == 'tarjeta';
      final status = requiresApproval ? 'pending_approval' : 'approved';
      final stockStatus = _saleType == 'delivery' ? 'in_transit' : 'completed';

      // Create sale document
      final saleData = {
        'saleType': _saleType,
        'deliveryMethod': _saleType == 'delivery' ? _deliveryMethod : null,
        'paymentMethod': _paymentMethod,
        'destinationAccount': (_paymentMethod == 'transferencia' || _paymentMethod == 'tarjeta') 
            ? _selectedBankAccount 
            : null,
        'items': items,
        'subtotal': _subtotal,
        'discount': _discount,
        'total': _total,
        'nit': _nitController.text.trim(),
        'customerName': _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        'deliveryAddress': _saleType == 'delivery'
            ? _deliveryAddressController.text.trim()
            : null,
        'deductFrom': _deductFrom,
        'stockStatus': stockStatus,
        'paymentVerified': !requiresApproval, // Efectivo is auto-verified
        'status': status,
        'depositId': null,
        'deliveryStatus': _saleType == 'delivery' ? 'pending' : null,
        'pickedUpAt': null,
        'pickedUpBy': null,
        'deliveredAt': null,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(saleRef, saleData);

      // Track pending cash for efectivo sales (only for kiosko, deliveries add when delivered)
      if (_paymentMethod == 'efectivo' &&
          status == 'approved' &&
          _saleType == 'kiosko') {
        // Add to pending cash for store
        final pendingCashRef =
            _firestore.collection('pendingCash').doc('store');

        batch.set(
          pendingCashRef,
          {
            'source': 'store',
            'amount': FieldValue.increment(_total),
            'saleIds': FieldValue.arrayUnion([saleRef.id]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Update stock: if approved and completed, deduct now; if in_transit, track separately
      if (status == 'approved' && stockStatus == 'completed') {
        final stockField =
            _deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';

        for (var item in _cartItems.values) {
          final barcode = item['barcode'] as String;
          final quantity = item['quantity'] as int;
          final productRef = _firestore.collection('products').doc(barcode);

          batch.update(productRef, {
            stockField: FieldValue.increment(-quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      // If in_transit, we'll track in a separate field (Phase 2B)

      await batch.commit();

      if (mounted) {
        // Show success dialog with options
        final shouldStay = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Venta Registrada con Éxito',
                  style: AppTheme.heading3,
                ),
              ],
            ),
            content: Text(
              requiresApproval
                  ? 'Venta creada exitosamente. Está pendiente de aprobación de pago.'
                  : 'Venta registrada exitosamente.',
              style: AppTheme.bodyMedium,
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Regresar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar Nueva Venta'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                ),
              ),
            ],
          ),
        );

        if (shouldStay == true) {
          // Clear form for new sale
          setState(() {
            _cartItems.clear();
            _customerNameController.clear();
            _customerPhoneController.clear();
            _deliveryAddressController.clear();
            _nitController.text = 'CF';
            _discountController.text = '0';
            _saleType = widget.initialSaleType ?? 'kiosko';
            _deliveryMethod = null;
            _paymentMethod = 'efectivo';
            _deductFrom = 'store';
          });
          _barcodeFocusNode.requestFocus();
        } else {
          // Go back
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar venta: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSale = false;
        });
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundGray,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Registrar Venta', style: AppTheme.heading1),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _isCreatingSale
                      ? null
                      : () {
                          setState(() {
                            _cartItems.clear();
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                            _deliveryAddressController.clear();
                            _nitController.text = 'CF';
                            _discountController.text = '0';
                            _saleType = 'kiosko';
                            _deliveryMethod = null;
                            _paymentMethod = 'efectivo';
                            _deductFrom = 'store';
                          });
                          _barcodeFocusNode.requestFocus();
                        },
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Limpiar'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                FilledButton.icon(
                  onPressed: _isCreatingSale ? null : _createSale,
                  icon: _isCreatingSale
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                      _isCreatingSale ? 'Registrando...' : 'Registrar Venta'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Products
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildSaleTypeCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildScanCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildCartCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),

                  // Right column - Summary & customer info
                  Expanded(
                    child: Column(
                      children: [
                        _buildCustomerInfoCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildSummaryCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTypeCard() {
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
              const Icon(Icons.point_of_sale_rounded,
                  color: AppTheme.blue, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('Tipo de Venta', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildSaleTypeOption(
                  'kiosko',
                  'Kiosko',
                  Icons.store_rounded,
                  _saleType == 'kiosko',
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSaleTypeOption(
                  'delivery',
                  'Entrega',
                  Icons.local_shipping_rounded,
                  _saleType == 'delivery',
                ),
              ),
            ],
          ),
          if (_saleType == 'delivery') ...[
            const SizedBox(height: AppTheme.spacingL),
            const Divider(),
            const SizedBox(height: AppTheme.spacingL),
            Text('Método de Entrega',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildDeliveryMethodOption(
                    'mensajero',
                    'Mensajero',
                    _deliveryMethod == 'mensajero',
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildDeliveryMethodOption(
                    'forza',
                    'Forza',
                    _deliveryMethod == 'forza',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaleTypeOption(
      String value, String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _saleType = value;
          if (value == 'kiosko') {
            _deliveryMethod = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blue.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
          border: Border.all(
            color: isSelected ? AppTheme.blue : AppTheme.lightGray,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.blue : AppTheme.mediumGray,
                size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.blue : AppTheme.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodOption(
      String value, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _deliveryMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blue.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
          border: Border.all(
            color: isSelected ? AppTheme.blue : AppTheme.lightGray,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.blue : AppTheme.darkGray,
          ),
        ),
      ),
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
                  color: AppTheme.blue, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('Agregar Productos', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Escanear código de barras...',
                    prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                  ),
                  onSubmitted: _handleBarcodeScanned,
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
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Text('Descontar de:',
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
              const SizedBox(width: AppTheme.spacingM),
              _buildStockSourceOption('store', 'Tienda'),
              const SizedBox(width: AppTheme.spacingS),
              _buildStockSourceOption('warehouse', 'Bodega'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSourceOption(String value, String label) {
    final isSelected = _deductFrom == value;
    return GestureDetector(
      onTap: () async {
        // Validate cart items against new stock source
        final stockField = value == 'store' ? 'stockStore' : 'stockWarehouse';
        final List<String> insufficientStockItems = [];
        final Map<String, int> adjustedQuantities = {};

        for (var entry in _cartItems.entries) {
          final barcode = entry.key;
          final item = entry.value;
          final productData = item['productData'] as Map<String, dynamic>;
          final availableStock = productData[stockField] ?? 0;
          final currentQty = item['quantity'] as int;

          if (availableStock <= 0) {
            insufficientStockItems.add(item['name']);
          } else if (currentQty > availableStock) {
            adjustedQuantities[barcode] = availableStock;
          }
        }

        // Show warning if items have insufficient stock
        if (insufficientStockItems.isNotEmpty && mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stock Insuficiente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Los siguientes productos no tienen stock en ${value == 'store' ? 'tienda' : 'bodega'}:',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ...insufficientStockItems.map((name) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingXS),
                        child: Text('• $name',
                            style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.danger)),
                      )),
                  if (adjustedQuantities.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Algunos productos tendrán cantidades ajustadas al stock disponible.',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.warning),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _deductFrom = value;
                      // Remove items with no stock
                      for (var name in insufficientStockItems) {
                        _cartItems.removeWhere(
                            (key, item) => item['name'] == name);
                      }
                      // Adjust quantities for items with limited stock
                      for (var entry in adjustedQuantities.entries) {
                        if (_cartItems.containsKey(entry.key)) {
                          _cartItems[entry.key]!['quantity'] = entry.value;
                          _cartItems[entry.key]!['maxStock'] = entry.value;
                        }
                      }
                    });
                  },
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
        } else if (adjustedQuantities.isNotEmpty && mounted) {
          // Only quantity adjustments, no items removed
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ajuste de Cantidades'),
              content: Text(
                'Algunos productos tienen cantidades mayores al stock disponible en ${value == 'store' ? 'tienda' : 'bodega'}. Las cantidades serán ajustadas automáticamente.',
                style: AppTheme.bodySmall,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _deductFrom = value;
                      // Adjust quantities
                      for (var entry in adjustedQuantities.entries) {
                        if (_cartItems.containsKey(entry.key)) {
                          _cartItems[entry.key]!['quantity'] = entry.value;
                          _cartItems[entry.key]!['maxStock'] = entry.value;
                        }
                      }
                    });
                  },
                  child: const Text('Ajustar'),
                ),
              ],
            ),
          );
        } else {
          // No issues, just change the source
          setState(() {
            _deductFrom = value;
            // Update maxStock for all items
            for (var entry in _cartItems.entries) {
              final productData =
                  entry.value['productData'] as Map<String, dynamic>;
              final availableStock = productData[stockField] ?? 0;
              _cartItems[entry.key]!['maxStock'] = availableStock;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blue.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
          border: Border.all(
            color: isSelected ? AppTheme.blue : AppTheme.lightGray,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.blue : AppTheme.darkGray,
          ),
        ),
      ),
    );
  }

  Widget _buildCartCard() {
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
          Text('Productos en Carrito', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          if (_cartItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 64, color: AppTheme.lightGray),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No hay productos en el carrito',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_cartItems.values.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _buildCartItem(item),
                ))),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final barcode = item['barcode'] as String;
    final name = item['name'] as String;
    final warehouseCode = item['warehouseCode'] as String;
    final quantity = item['quantity'] as int;
    final baseUnitPrice = item['unitPrice'] as double;
    final effectiveUnitPrice = _getEffectiveUnitPrice(item);
    final maxStock = item['maxStock'] as int;
    final subtotal = quantity * effectiveUnitPrice;
    
    // Check if bulk pricing is applied
    final isBulkPriced = _isBulkEligible(item) && effectiveUnitPrice != baseUnitPrice;

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
                Text(name.isNotEmpty ? name : warehouseCode,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                if (isBulkPriced) ...[
                  Text('$barcode',
                      style: AppTheme.bodySmall),
                  Row(
                    children: [
                      Text(
                        'Q${baseUnitPrice.toStringAsFixed(2)}',
                        style: AppTheme.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        'Q${effectiveUnitPrice.toStringAsFixed(2)} c/u',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MAYOREO',
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 9,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text('$barcode • Q${effectiveUnitPrice.toStringAsFixed(2)} c/u',
                      style: AppTheme.bodySmall),
                Text('Subtotal: Q${subtotal.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppTheme.blue),
            onPressed: quantity > 1
                ? () {
                    setState(() {
                      _cartItems[barcode]!['quantity'] = quantity - 1;
                    });
                  }
                : null,
          ),
          SizedBox(
            width: 60,
            child: Builder(
              builder: (context) {
                final controller = TextEditingController(text: '$quantity')
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: '$quantity'.length),
                  );
                
                return TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingS,
                    ),
                  ),
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  onTapOutside: (event) {
                    _updateQuantity(barcode, controller.text, quantity, maxStock);
                    FocusScope.of(context).unfocus();
                  },
                  onEditingComplete: () {
                    _updateQuantity(barcode, controller.text, quantity, maxStock);
                    FocusScope.of(context).unfocus();
                  },
                  onSubmitted: (value) {
                    _updateQuantity(barcode, value, quantity, maxStock);
                  },
                );
              }
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.blue),
            onPressed: quantity < maxStock
                ? () {
                    setState(() {
                      _cartItems[barcode]!['quantity'] = quantity + 1;
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _cartItems.remove(barcode);
              });
            },
            color: AppTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
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
              const Icon(Icons.person_outline_rounded,
                  color: AppTheme.blue, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('Información del Cliente', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText:
                  _saleType == 'delivery' ? 'Nombre *' : 'Nombre (Opcional)',
              prefixIcon: const Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _customerPhoneController,
            decoration: InputDecoration(
              labelText: _saleType == 'delivery'
                  ? 'Teléfono *'
                  : 'Teléfono (Opcional)',
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          if (_saleType == 'delivery') ...[
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Entrega *',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
              maxLines: 2,
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _nitController,
            decoration: const InputDecoration(
              labelText: 'NIT *',
              prefixIcon: Icon(Icons.receipt_long_rounded),
              hintText: 'CF para Consumidor Final',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
          Text('Resumen de Venta', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Subtotal', 'Q${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Text('Descuento',
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
              const Spacer(),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    prefixText: 'Q',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingS,
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTheme.heading3),
              Text('Q${_total.toStringAsFixed(2)}',
                  style: AppTheme.heading1.copyWith(color: AppTheme.blue)),
            ],
          ),
          const Divider(height: AppTheme.spacingXL),
          Text('Método de Pago', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildPaymentMethod('efectivo', 'Efectivo', Icons.payments_rounded),
          const SizedBox(height: AppTheme.spacingM),
          _buildPaymentMethod('transferencia', 'Transferencia Bancaria',
              Icons.account_balance_rounded),
          if (_saleType == 'kiosko') ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildPaymentMethod(
                'tarjeta', 'Tarjeta (POS)', Icons.credit_card_rounded),
          ],
          // Bank account selector for non-cash payments
          if (_paymentMethod == 'transferencia' || _paymentMethod == 'tarjeta') ...[
            const SizedBox(height: AppTheme.spacingL),
            Text('Cuenta Bancaria', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.lightGray),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBankAccount,
                  hint: const Text('Selecciona cuenta bancaria'),
                  items: _bankAccounts.map<DropdownMenuItem<String>>((account) {
                    final accountName = account['accountName'] as String;
                    final bankName = account['bankName'] as String;
                    final last4 = account['last4Digits'] as String;
                    return DropdownMenuItem<String>(
                      value: account['id'],
                      child: Text('$accountName - $bankName (*$last4)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBankAccount = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
        Text(value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPaymentMethod(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
          // Reset bank account selection when switching to efectivo
          if (value == 'efectivo') {
            _selectedBankAccount = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.blue.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
          border: Border.all(
            color: isSelected ? AppTheme.blue : AppTheme.lightGray,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.blue : AppTheme.mediumGray,
                size: 20),
            const SizedBox(width: AppTheme.spacingM),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.blue : AppTheme.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
