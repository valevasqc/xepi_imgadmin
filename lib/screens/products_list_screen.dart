import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/product_detail_screen.dart';
import 'package:xepi_imgadmin/screens/add_product_screen.dart';

enum ViewMode { cards, table, list }

/// Products list screen with search, filters, and multiple view modes
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  ViewMode _viewMode = ViewMode.cards;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedSubcategory;
  String? _selectedLocation;
  String? _selectedStockStatus;
  bool _showFilters = false; // Collapsible filters

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isHeaderExpanded = true;

  // Cache categories for price lookup
  Map<String, Map<String, dynamic>> _categoriesCache = {};
  List<String> _primaryCategories = []; // For filter dropdown
  List<String> _subcategories = []; // Subcategories for selected category

  // Pagination
  static const int _pageSize = 50; // Products per page
  int _currentPage = 1;
  int _totalProducts = 0;
  List<Map<String, dynamic>> _allLoadedProducts =
      []; // Cache all loaded products

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAllProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Collapse header when scrolling down
    if (_scrollController.offset > 50 && _isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = false;
        _showFilters = false; // Close filters when collapsing
      });
    } else if (_scrollController.offset <= 10 && !_isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = true;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      setState(() {
        _categoriesCache = {for (var doc in snapshot.docs) doc.id: doc.data()};

        // Extract unique primary categories
        final primarySet = <String>{};
        for (var category in _categoriesCache.values) {
          final primary = category['primaryCategory'];
          if (primary != null) {
            primarySet.add(primary);
          }
        }
        _primaryCategories = primarySet.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  void _updateSubcategories(String? primaryCategory) {
    if (primaryCategory == null) {
      setState(() {
        _subcategories = [];
        _selectedSubcategory = null;
      });
      return;
    }

    // Find all subcategories for the selected primary category
    final subcategorySet = <String>{};
    for (var category in _categoriesCache.values) {
      if (category['primaryCategory'] == primaryCategory) {
        final subcategory = category['subcategoryName'];
        if (subcategory != null && subcategory.toString().isNotEmpty) {
          subcategorySet.add(subcategory);
        }
      }
    }

    setState(() {
      _subcategories = subcategorySet.toList()..sort();
      _selectedSubcategory = null; // Reset subcategory when category changes
    });
  }

  double? _getProductPrice(Map<String, dynamic> product) {
    final priceOverride = product['priceOverride'];
    if (priceOverride != null) return priceOverride.toDouble();

    final categoryCode = product['categoryCode'];
    if (categoryCode != null && _categoriesCache.containsKey(categoryCode)) {
      final category = _categoriesCache[categoryCode];
      final defaultPrice = category?['defaultPrice'];
      if (defaultPrice != null) return defaultPrice.toDouble();
    }

    return null; // No price available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Compact Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical:
                  _isHeaderExpanded ? AppTheme.spacingL : AppTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(
              children: [
                // Main row - always visible
                Row(
                  children: [
                    // Title (hide when collapsed)
                    if (_isHeaderExpanded) ...[
                      Text(
                        'Productos',
                        style: AppTheme.heading2,
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                    ],

                    // Search Bar (compact)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _currentPage = 1;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _currentPage = 1;
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppTheme.spacingM),

                    // Filter Button with badge
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_alt_rounded
                            : Icons.filter_alt_outlined,
                        size: 20,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Filtros'),
                          if (_hasActiveFilters()) ...[
                            const SizedBox(width: AppTheme.spacingS),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_getActiveFiltersCount()}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS + 2,
                        ),
                        backgroundColor: _showFilters
                            ? AppTheme.blue.withOpacity(0.1)
                            : null,
                        side: BorderSide(
                          color:
                              _showFilters ? AppTheme.blue : AppTheme.lightGray,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppTheme.spacingM),

                    // View Mode Selector (compact icons only when collapsed)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewModeButton(
                            icon: Icons.grid_view_rounded,
                            mode: ViewMode.cards,
                            tooltip: 'Tarjetas',
                          ),
                          _buildViewModeButton(
                            icon: Icons.table_rows_rounded,
                            mode: ViewMode.table,
                            tooltip: 'Tabla',
                          ),
                          _buildViewModeButton(
                            icon: Icons.view_list_rounded,
                            mode: ViewMode.list,
                            tooltip: 'Lista',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppTheme.spacingM),

                    // Add Product Button (icon only when collapsed)
                    if (_isHeaderExpanded)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddProductScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Agregar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS + 2,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddProductScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Agregar Producto',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.blue,
                          foregroundColor: AppTheme.white,
                        ),
                      ),
                  ],
                ),

                // Collapsible Filters Panel
                if (_showFilters) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    child: Wrap(
                      spacing: AppTheme.spacingM,
                      runSpacing: AppTheme.spacingM,
                      children: [
                        // Category Filter
                        SizedBox(
                          width: 240,
                          child: _buildFilterDropdown(
                            hint: 'Categoría',
                            value: _selectedCategory,
                            items: [
                              'Todas',
                              ..._primaryCategories,
                            ],
                            onChanged: (value) {
                              final selectedCat =
                                  value == 'Todas' ? null : value;
                              setState(() {
                                _selectedCategory = selectedCat;
                                _currentPage = 1;
                              });
                              _updateSubcategories(selectedCat);
                            },
                          ),
                        ),

                        // Subcategory Filter (only show if category selected)
                        if (_selectedCategory != null)
                          SizedBox(
                            width: 180,
                            child: _buildFilterDropdown(
                              hint: 'Subcategoría',
                              value: _selectedSubcategory,
                              items: [
                                'Todas',
                                ..._subcategories,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubcategory =
                                      value == 'Todas' ? null : value;
                                  _currentPage = 1;
                                });
                              },
                            ),
                          ),

                        // Location Filter
                        SizedBox(
                          width: 160,
                          child: _buildFilterDropdown(
                            hint: 'Ubicación',
                            value: _selectedLocation,
                            items: ['Todas', 'Bodega', 'Kiosco'],
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation =
                                    value == 'Todas' ? null : value;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),

                        // Stock Status Filter
                        SizedBox(
                          width: 180,
                          child: _buildFilterDropdown(
                            hint: 'Stock',
                            value: _selectedStockStatus,
                            items: [
                              'Todos',
                              'En Stock',
                              'Stock Bajo',
                              'Sin Stock'
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStockStatus =
                                    value == 'Todos' ? null : value;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),

                        // Clear Filters Button
                        if (_hasActiveFilters())
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedSubcategory = null;
                                _selectedLocation = null;
                                _selectedStockStatus = null;
                                _subcategories = [];
                                _currentPage = 1;
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded, size: 18),
                            label: const Text('Limpiar filtros'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.danger,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content Area with Scroll
          Expanded(
            child: _allLoadedProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final pageProducts = _getCurrentPageProducts();
                      final totalPages = _getTotalPages();

                      if (pageProducts.isEmpty) {
                        return _buildEmptyState();
                      }

                      final filteredCount =
                          _filterProducts(_allLoadedProducts).length;

                      return Column(
                        children: [
                          // Compact Stats Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingL,
                              vertical: AppTheme.spacingS,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.white,
                              border: Border(
                                bottom: BorderSide(color: AppTheme.lightGray),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildCompactStat(
                                  Icons.inventory_2_rounded,
                                  '$filteredCount',
                                  AppTheme.blue,
                                ),
                                const SizedBox(width: AppTheme.spacingL),
                                _buildCompactStat(
                                  Icons.check_circle_rounded,
                                  '${_getInStockCount(pageProducts)}',
                                  AppTheme.success,
                                ),
                                const SizedBox(width: AppTheme.spacingL),
                                _buildCompactStat(
                                  Icons.warning_rounded,
                                  '${_getLowStockCount(pageProducts)}',
                                  AppTheme.warning,
                                ),
                              ],
                            ),
                          ),

                          // Products Content with ScrollController
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: _buildContent(pageProducts),
                            ),
                          ),

                          // Compact Page Navigation
                          _buildCompactPageNavigation(totalPages),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required ViewMode mode,
    required String tooltip,
  }) {
    final isSelected = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        borderRadius: AppTheme.borderRadiusSmall,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white : Colors.transparent,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppTheme.blue : AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> products) {
    switch (_viewMode) {
      case ViewMode.cards:
        return _buildCardsView(products);
      case ViewMode.table:
        return _buildTableView(products);
      case ViewMode.list:
        return _buildListView(products);
    }
  }

  Widget _buildCardsView(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cards per row
        childAspectRatio: 0.7, // More compact cards
        crossAxisSpacing: AppTheme.spacingS,
        mainAxisSpacing: AppTheme.spacingS,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildCompactPageNavigation(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.lightGray),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button (compact)
          IconButton(
            onPressed:
                _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            tooltip: 'Anterior',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),

          const SizedBox(width: AppTheme.spacingS),

          // Page Numbers (compact)
          ..._buildPageNumbers(totalPages),

          const SizedBox(width: AppTheme.spacingS),

          // Next Button (compact)
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _changePage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            tooltip: 'Siguiente',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),

          const SizedBox(width: AppTheme.spacingM),

          // Page indicator text
          Text(
            'Página $_currentPage de $totalPages',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> pageButtons = [];

    // Show first page
    if (_currentPage > 3) {
      pageButtons.add(_buildPageButton(1));
      if (_currentPage > 4) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
    }

    // Show pages around current page
    final int start = (_currentPage - 2).clamp(1, totalPages);
    final int end = (_currentPage + 2).clamp(1, totalPages);

    for (int i = start; i <= end; i++) {
      pageButtons.add(_buildPageButton(i));
    }

    // Show last page
    if (_currentPage < totalPages - 2) {
      if (_currentPage < totalPages - 3) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
      pageButtons.add(_buildPageButton(totalPages));
    }

    return pageButtons;
  }

  Widget _buildPageButton(int pageNumber) {
    final isCurrentPage = pageNumber == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: isCurrentPage
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$pageNumber',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : TextButton(
              onPressed: () => _changePage(pageNumber),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '$pageNumber',
                style: AppTheme.bodySmall,
              ),
            ),
    );
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    // Scroll to top when changing pages
    // Optional: Add scroll controller to scroll to top
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
    final storeStock = (product['stockStore'] ?? 0) as int;
    final totalStock = warehouseStock + storeStock;
    final stockStatus = _getStockStatus(totalStock);

    // Get product name or fallback to warehouse code
    final productName =
        (product['nombre'] ?? product['warehouseCode'] ?? 'Sin nombre')
            .toString();

    // Get price (with category fallback)
    final price = _getProductPrice(product);
    final priceText =
        price != null ? 'Q${price.toStringAsFixed(0)}' : 'Sin precio';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(productId: product['id']),
            ),
          );
          // Reload products to show updated main images
          _loadAllProducts();
        },
        borderRadius: AppTheme.borderRadiusMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: () {
                    final images =
                        (product['images'] as List?)?.cast<String>() ?? [];
                    if (images.isEmpty) {
                      return const Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 40,
                          color: AppTheme.lightGray,
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        images[0],
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 40,
                              color: AppTheme.danger,
                            ),
                          );
                        },
                      ),
                    );
                  }(),
                ),
              ),

              // Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        productName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Price & Stock Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              priceText,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (totalStock > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: stockStatus['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$totalStock',
                                style: TextStyle(
                                  color: stockStatus['color'],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          if (totalStock == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Agotado',
                                style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Location Stock (only show if has stock)
                      if (warehouseStock > 0 || storeStock > 0)
                        Row(
                          children: [
                            if (warehouseStock > 0) ...[
                              const Icon(Icons.warehouse_rounded,
                                  size: 12, color: AppTheme.mediumGray),
                              const SizedBox(width: 4),
                              Text(
                                '$warehouseStock',
                                style: AppTheme.caption.copyWith(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (storeStock > 0) ...[
                              const Icon(Icons.store_rounded,
                                  size: 12, color: AppTheme.mediumGray),
                              const SizedBox(width: 4),
                              Text(
                                '$storeStock',
                                style: AppTheme.caption.copyWith(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.cardShadow,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppTheme.backgroundGray,
          ),
          columns: [
            DataColumn(label: Text('Imagen', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Nombre', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Código', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Categoría', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Precio', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Bodega', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Tienda', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Estado', style: AppTheme.bodyMedium)),
            DataColumn(label: Text('Acciones', style: AppTheme.bodyMedium)),
          ],
          rows: products.map((product) {
            final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
            final storeStock = (product['stockStore'] ?? 0) as int;
            final totalStock = warehouseStock + storeStock;
            final stockStatus = _getStockStatus(totalStock);

            final productName =
                (product['nombre'] ?? product['warehouseCode'] ?? 'Sin nombre')
                    .toString();
            final price = _getProductPrice(product);
            final priceText =
                price != null ? 'Q${price.toStringAsFixed(0)}' : 'Sin precio';
            final categoryCode = (product['categoryCode'] ?? '').toString();

            return DataRow(
              cells: [
                DataCell(
                  () {
                    final images =
                        (product['images'] as List?)?.cast<String>() ?? [];
                    if (images.isEmpty) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: AppTheme.borderRadiusSmall,
                        ),
                        child: const Icon(
                          Icons.image_rounded,
                          size: 20,
                          color: AppTheme.lightGray,
                        ),
                      );
                    }
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      child: ClipRRect(
                        borderRadius: AppTheme.borderRadiusSmall,
                        child: Image.network(
                          images[0],
                          fit: BoxFit.cover,
                          cacheWidth: 80,
                          cacheHeight: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.backgroundGray,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                size: 20,
                                color: AppTheme.danger,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }(),
                ),
                DataCell(Text(productName, style: AppTheme.bodyMedium)),
                DataCell(Text(product['warehouseCode'] ?? '',
                    style: AppTheme.bodySmall)),
                DataCell(Text(categoryCode, style: AppTheme.bodySmall)),
                DataCell(Text(priceText, style: AppTheme.bodyMedium)),
                DataCell(Text('$warehouseStock', style: AppTheme.bodyMedium)),
                DataCell(Text('$storeStock', style: AppTheme.bodyMedium)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stockStatus['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stockStatus['label'],
                      style: AppTheme.caption.copyWith(
                        color: stockStatus['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    iconSize: 20,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(productId: product['id']),
                        ),
                      );
                      // Reload products to show updated main images
                      _loadAllProducts();
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> products) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
        final storeStock = (product['stockStore'] ?? 0) as int;
        final totalStock = warehouseStock + storeStock;
        final stockStatus = _getStockStatus(totalStock);

        final productName =
            (product['nombre'] ?? product['warehouseCode'] ?? 'Sin nombre')
                .toString();
        final barcode = (product['barcode'] ?? product['id'] ?? '').toString();
        final warehouseCode = (product['warehouseCode'] ?? '').toString();
        final categoryCode = (product['categoryCode'] ?? '').toString();
        final price = _getProductPrice(product);
        final priceText =
            price != null ? 'Q${price.toStringAsFixed(0)}' : 'Sin precio';

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.borderRadiusMedium,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(productId: product['id']),
                  ),
                );
                // Reload products to show updated main images
                _loadAllProducts();
              },
              borderRadius: AppTheme.borderRadiusMedium,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    // Image
                    () {
                      final images =
                          (product['images'] as List?)?.cast<String>() ?? [];
                      if (images.isEmpty) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGray,
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.image_rounded,
                            size: 30,
                            color: AppTheme.lightGray,
                          ),
                        );
                      }
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: AppTheme.borderRadiusSmall,
                        ),
                        child: ClipRRect(
                          borderRadius: AppTheme.borderRadiusSmall,
                          child: Image.network(
                            images[0],
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                            cacheHeight: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.backgroundGray,
                                child: const Icon(
                                  Icons.broken_image_rounded,
                                  size: 30,
                                  color: AppTheme.danger,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }(),

                    const SizedBox(width: AppTheme.spacingM),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: AppTheme.heading4,
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            '$barcode • $warehouseCode',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            categoryCode,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceText,
                          style: AppTheme.heading4.copyWith(
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockStatus['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Total: $totalStock',
                            style: AppTheme.caption.copyWith(
                              color: stockStatus['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: AppTheme.spacingM),

                    // Arrow
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.mediumGray,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 64,
            color: AppTheme.lightGray,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No se encontraron productos',
            style: AppTheme.heading3.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Intenta ajustar los filtros o agregar nuevos productos',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  /// Load all products (we'll paginate client-side for simplicity)
  Future<void> _loadAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('warehouseCode')
          .get();

      setState(() {
        _allLoadedProducts = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _totalProducts = _allLoadedProducts.length;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  List<Map<String, dynamic>> _getCurrentPageProducts() {
    final filtered = _filterProducts(_allLoadedProducts);
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= filtered.length) return [];
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int _getTotalPages() {
    final filtered = _filterProducts(_allLoadedProducts);
    return (filtered.length / _pageSize).ceil();
  }

  /// Apply client-side filters (search, stock status, location, category)
  List<Map<String, dynamic>> _filterProducts(
      List<Map<String, dynamic>> products) {
    return products.where((product) {
      // Category filter (check if product's category matches selected primary category)
      if (_selectedCategory != null && _selectedCategory != 'Todas') {
        final categoryCode = product['categoryCode'];
        if (categoryCode != null &&
            _categoriesCache.containsKey(categoryCode)) {
          final category = _categoriesCache[categoryCode];
          final primaryCategory = category?['primaryCategory'];
          if (primaryCategory != _selectedCategory) {
            return false;
          }
        } else {
          return false; // Exclude products without valid category
        }
      }

      // Subcategory filter
      if (_selectedSubcategory != null && _selectedSubcategory != 'Todas') {
        final productSubcategory = product['subcategory'];
        if (productSubcategory != _selectedSubcategory) {
          return false;
        }
      }

      // Search filter (client-side - check barcode, name, warehouse code)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final barcode = (product['barcode'] ?? '').toString().toLowerCase();
        final name = (product['nombre'] ?? '').toString().toLowerCase();
        final code = (product['warehouseCode'] ?? '').toString().toLowerCase();

        if (!barcode.contains(query) &&
            !name.contains(query) &&
            !code.contains(query)) {
          return false;
        }
      }

      // Stock status filter (client-side calculation)
      if (_selectedStockStatus != null && _selectedStockStatus != 'Todos') {
        final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
        final storeStock = (product['stockStore'] ?? 0) as int;
        final totalStock = warehouseStock + storeStock;
        final status = _getStockStatus(totalStock)['label'];

        if (status != _selectedStockStatus) {
          return false;
        }
      }

      // Location filter (client-side)
      if (_selectedLocation != null && _selectedLocation != 'Todas') {
        final warehouseStock = (product['stockWarehouse'] ?? 0) as int;
        final storeStock = (product['stockStore'] ?? 0) as int;

        if (_selectedLocation == 'Bodega' && warehouseStock == 0) {
          return false;
        }
        if (_selectedLocation == 'Kiosco' && storeStock == 0) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Map<String, dynamic> _getStockStatus(int stock) {
    if (stock == 0) {
      return {'label': 'Sin Stock', 'color': AppTheme.danger};
    } else if (stock < 3) {
      return {'label': 'Stock Bajo', 'color': AppTheme.warning};
    } else {
      return {'label': 'En Stock', 'color': AppTheme.success};
    }
  }

  int _getInStockCount(List<Map<String, dynamic>> products) {
    return products.where((p) {
      final warehouseStock = (p['stockWarehouse'] ?? 0) as int;
      final storeStock = (p['stockStore'] ?? 0) as int;
      final total = warehouseStock + storeStock;
      return total > 0;
    }).length;
  }

  int _getLowStockCount(List<Map<String, dynamic>> products) {
    return products.where((p) {
      final warehouseStock = (p['stockWarehouse'] ?? 0) as int;
      final storeStock = (p['stockStore'] ?? 0) as int;
      final total = warehouseStock + storeStock;
      return total > 0 && total < 10;
    }).length;
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedSubcategory != null ||
        _selectedLocation != null ||
        _selectedStockStatus != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedSubcategory != null) count++;
    if (_selectedLocation != null) count++;
    if (_selectedStockStatus != null) count++;
    return count;
  }

  Widget _buildCompactStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
