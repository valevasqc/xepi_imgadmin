import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Reusable product search dialog
/// Used across Recepciones, Movimientos, and Ventas screens
class ProductSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductSelected;
  final String?
      stockSourceFilter; // 'store' or 'warehouse' - filters products with stock
  final bool showPrices; // Show price information in results
  final bool showStock; // Show stock information in results

  const ProductSearchDialog({
    super.key,
    required this.onProductSelected,
    this.stockSourceFilter,
    this.showPrices = false,
    this.showStock = false,
  });

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      setState(() {
        _allProducts = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data()};
        }).toList();
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final barcode = (product['barcode'] ?? '').toString().toLowerCase();
        final name = (product['name'] ?? '').toString().toLowerCase();
        final warehouseCode =
            (product['warehouseCode'] ?? '').toString().toLowerCase();

        return barcode.contains(lowerQuery) ||
            name.contains(lowerQuery) ||
            warehouseCode.contains(lowerQuery);
      }).toList();
    });
  }

  String _getStockInfo(Map<String, dynamic> product) {
    if (!widget.showStock) return '';

    if (widget.stockSourceFilter != null) {
      final stockField =
          widget.stockSourceFilter == 'store' ? 'stockStore' : 'stockWarehouse';
      final stock = product[stockField] ?? 0;
      return 'Stock: $stock';
    } else {
      final stockWarehouse = product['stockWarehouse'] ?? 0;
      final stockStore = product['stockStore'] ?? 0;
      return 'B: $stockWarehouse, T: $stockStore';
    }
  }

  String _getPriceInfo(Map<String, dynamic> product) {
    if (!widget.showPrices) return '';

    final priceOverride = product['priceOverride'];
    if (priceOverride != null) {
      return 'Q${priceOverride.toStringAsFixed(2)}';
    }
    return 'Precio por categoría';
  }

  bool _hasStock(Map<String, dynamic> product) {
    if (widget.stockSourceFilter == null) return true;

    final stockField =
        widget.stockSourceFilter == 'store' ? 'stockStore' : 'stockWarehouse';
    final stock = product[stockField] ?? 0;
    return stock > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.blue),
                const SizedBox(width: AppTheme.spacingM),
                Text('Buscar Producto', style: AppTheme.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por código, nombre o código de bodega...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron productos',
                            style: AppTheme.bodyMedium
                                .copyWith(color: AppTheme.mediumGray),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final name = product['name'] ?? '';
                            final warehouseCode =
                                product['warehouseCode'] ?? '';
                            final barcode = product['barcode'] ?? '';
                            final hasStock = _hasStock(product);

                            // Build subtitle with stock and price info
                            final subtitleParts = <String>[barcode];
                            if (widget.showStock) {
                              subtitleParts.add(_getStockInfo(product));
                            }
                            if (widget.showPrices) {
                              subtitleParts.add(_getPriceInfo(product));
                            }
                            final subtitle = subtitleParts.join(' • ');

                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: hasStock
                                      ? AppTheme.blue.withValues(alpha: 0.1)
                                      : AppTheme.lightGray,
                                  borderRadius: AppTheme.borderRadiusSmall,
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: hasStock
                                      ? AppTheme.blue
                                      : AppTheme.mediumGray,
                                ),
                              ),
                              title: Text(
                                name.isNotEmpty
                                    ? name
                                    : warehouseCode.isNotEmpty
                                        ? warehouseCode
                                        : barcode,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: hasStock
                                      ? AppTheme.darkGray
                                      : AppTheme.mediumGray,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: AppTheme.bodySmall,
                              ),
                              trailing: hasStock
                                  ? const Icon(Icons.add_circle_rounded,
                                      color: AppTheme.blue)
                                  : null,
                              enabled: hasStock,
                              onTap: hasStock
                                  ? () {
                                      widget.onProductSelected(product);
                                      Navigator.pop(context);
                                    }
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
