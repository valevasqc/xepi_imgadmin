import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/dashboard_screen.dart';
import 'package:xepi_imgadmin/screens/products_list_screen.dart';
import 'package:xepi_imgadmin/screens/categories_list_screen.dart';
import 'package:xepi_imgadmin/screens/finances_screen.dart';
import 'package:xepi_imgadmin/screens/settings_screen.dart';
import 'package:xepi_imgadmin/screens/future/orders_list_screen.dart';
import 'package:xepi_imgadmin/screens/future/shipment_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/movement_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/register_sale_screen.dart';
import 'package:xepi_imgadmin/screens/future/reports_screen.dart';

/// Main layout with collapsible sidebar navigation
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isExpanded = true;
  int _selectedIndex = 0;

  final List<NavigationItem> _navItems = [
    // Phase 1 - Fully functional
    NavigationItem(
      icon: Icons.home_rounded,
      label: 'Inicio',
      page: const DashboardScreen(),
      isPhase2: false,
    ),
    NavigationItem(
      icon: Icons.inventory_2_rounded,
      label: 'Productos',
      page: const ProductsListScreen(),
      isPhase2: false,
    ),
    NavigationItem(
      icon: Icons.folder_rounded,
      label: 'Categorías',
      page: const CategoriesListScreen(),
      isPhase2: false,
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Finanzas',
      page: const FinancesScreen(),
      isPhase2: false,
    ),

    // Divider
    NavigationItem(
      icon: Icons.lock_outline_rounded,
      label: 'PHASE 2 - UI ONLY',
      page: const SizedBox.shrink(),
      isDivider: true,
      isPhase2: true,
    ),

    // Phase 2 - UI only
    NavigationItem(
      icon: Icons.receipt_long_rounded,
      label: 'Pedidos',
      page: const OrdersListScreen(),
      isPhase2: true,
    ),
    NavigationItem(
      icon: Icons.local_shipping_rounded,
      label: 'Recepciones',
      page: const ShipmentHistoryScreen(),
      isPhase2: true,
    ),
    NavigationItem(
      icon: Icons.swap_horiz_rounded,
      label: 'Movimientos',
      page: const MovementHistoryScreen(),
      isPhase2: true,
    ),
    NavigationItem(
      icon: Icons.point_of_sale_rounded,
      label: 'Registrar Venta',
      page: const RegisterSaleScreen(),
      isPhase2: true,
    ),
    NavigationItem(
      icon: Icons.assessment_rounded,
      label: 'Reportes',
      page: const ReportsScreen(),
      isPhase2: true,
    ),

    // Settings at bottom
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'Configuración',
      page: const SettingsScreen(),
      isPhase2: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Collapsible Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 240 : 72,
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(
              children: [
                // Logo/Brand Area
                Container(
                  height: 72,
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        _isExpanded ? AppTheme.spacingL : AppTheme.spacingM,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.orange, AppTheme.yellow],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppTheme.borderRadiusSmall,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppTheme.white,
                          size: 24,
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            'XEPI Admin',
                            style: AppTheme.heading4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppTheme.lightGray),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingM,
                    ),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;

                      // Divider item
                      if (item.isDivider) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM),
                          child: _isExpanded
                              ? Column(
                                  children: [
                                    const Divider(color: AppTheme.lightGray),
                                    const SizedBox(height: AppTheme.spacingS),
                                    Row(
                                      children: [
                                        const SizedBox(
                                            width: AppTheme.spacingM),
                                        const Icon(Icons.lock_outline_rounded,
                                            size: 14,
                                            color: AppTheme.mediumGray),
                                        const SizedBox(
                                            width: AppTheme.spacingS),
                                        Text(
                                          'PHASE 2',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.mediumGray,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.spacingS),
                                  ],
                                )
                              : const Divider(color: AppTheme.lightGray),
                        );
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingS),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });

                              // Show snackbar for Phase 2 items
                              if (item.isPhase2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded,
                                            color: AppTheme.white),
                                        const SizedBox(
                                            width: AppTheme.spacingM),
                                        Expanded(
                                          child: Text(
                                            'Phase 2: Solo UI disponible. Funcionalidad próximamente.',
                                            style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.white),
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
                            },
                            borderRadius: AppTheme.borderRadiusSmall,
                            child: Container(
                              height: 48,
                              padding: EdgeInsets.symmetric(
                                horizontal: _isExpanded ? AppTheme.spacingM : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (item.isPhase2
                                        ? AppTheme.orange.withOpacity(0.1)
                                        : AppTheme.blue.withOpacity(0.1))
                                    : Colors.transparent,
                                borderRadius: AppTheme.borderRadiusSmall,
                              ),
                              child: Row(
                                children: [
                                  if (!_isExpanded)
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            item.icon,
                                            color: isSelected
                                                ? (item.isPhase2
                                                    ? AppTheme.orange
                                                    : AppTheme.blue)
                                                : AppTheme.mediumGray,
                                            size: 24,
                                          ),
                                          if (item.isPhase2)
                                            Positioned(
                                              top: 2,
                                              right: 16,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.lock_rounded,
                                                  size: 8,
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    Icon(
                                      item.icon,
                                      color: isSelected
                                          ? (item.isPhase2
                                              ? AppTheme.orange
                                              : AppTheme.blue)
                                          : AppTheme.mediumGray,
                                      size: 24,
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: isSelected
                                              ? (item.isPhase2
                                                  ? AppTheme.orange
                                                  : AppTheme.blue)
                                              : AppTheme.darkGray,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (item.isPhase2)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          size: 12,
                                          color: AppTheme.orange,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Toggle Button
                const Divider(height: 1, color: AppTheme.lightGray),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: Icon(
                      _isExpanded
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _navItems[_selectedIndex].isDivider
                ? const DashboardScreen()
                : _navItems[_selectedIndex].page,
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;
  final bool isPhase2;
  final bool isDivider;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
    this.isPhase2 = false,
    this.isDivider = false,
  });
}
