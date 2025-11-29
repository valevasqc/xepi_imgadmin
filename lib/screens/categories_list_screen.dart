import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/category_detail_screen.dart';

/// Categories list screen with grouped category cards
class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  // Mock data - replace with Firestore data
  final Map<String, List<Map<String, dynamic>>> _mockCategories = {
    'Cuadros de Latón': [
      {
        'id': 'cat_1',
        'name': '20x30 cms',
        'code': 'CUA-2030',
        'price': 35,
        'itemCount': 124,
        'primaryCategory': 'Cuadros de Latón',
      },
      {
        'id': 'cat_2',
        'name': '30x40 cms',
        'code': 'CUA-3040',
        'price': 59,
        'itemCount': 87,
        'primaryCategory': 'Cuadros de Latón',
      },
      {
        'id': 'cat_3',
        'name': 'Círculos 30 cms',
        'code': 'CUA-C30',
        'price': 85,
        'itemCount': 43,
        'primaryCategory': 'Cuadros de Latón',
      },
    ],
    'Juguetes Educativos': [
      {
        'id': 'cat_4',
        'name': 'Principal',
        'code': 'JUG-MAIN',
        'price': 0, // Varies
        'itemCount': 23,
        'primaryCategory': 'Juguetes Educativos',
      },
    ],
  };

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
                  onPressed: () {
                    // TODO: Add new category
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar Categoría'),
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
                children: _mockCategories.entries.map((entry) {
                  return _buildCategoryGroup(
                    primaryCategory: entry.key,
                    categories: entry.value,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Category Header
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
          child: Text(
            primaryCategory.toUpperCase(),
            style: AppTheme.heading3.copyWith(
              letterSpacing: 1.5,
              color: AppTheme.mediumGray,
            ),
          ),
        ),

        // Category Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(
                categoryId: category['id'],
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
              // Image/Icon Area
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.folder_rounded,
                      size: 64,
                      color: AppTheme.blue.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // Info Area
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: AppTheme.heading3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        category['code'],
                        style: AppTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category['price'] > 0
                                ? 'Q${category['price']}'
                                : 'Varía',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 4,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
