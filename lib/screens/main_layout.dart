import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';
import 'package:xepi_imgadmin/screens/dashboard_screen.dart';
import 'package:xepi_imgadmin/screens/products_list_screen.dart';
import 'package:xepi_imgadmin/screens/categories_list_screen.dart';
import 'package:xepi_imgadmin/screens/finances_screen.dart';
import 'package:xepi_imgadmin/screens/settings_screen.dart';
import 'package:xepi_imgadmin/screens/future/orders_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/shipment_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/movement_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/sales_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/deposits_screen.dart';
import 'package:xepi_imgadmin/screens/future/reports_screen.dart';

/// Main layout with collapsible sidebar navigation with grouped dropdowns
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isExpanded = true;
  String _selectedPageKey = 'dashboard';
  final Map<String, bool> _expandedGroups = {
    'catalog': true,
    'inventory': false,
    'operations': false,
    'finance': false,
  };

  // Navigation groups structure
  final List<NavigationGroup> _navGroups = [
    NavigationGroup(
      label: 'Inicio',
      icon: Icons.home_rounded,
      key: 'dashboard',
      items: [
        NavigationItem(
          key: 'dashboard',
          icon: Icons.home_rounded,
          label: 'Inicio',
          page: const DashboardScreen(),
        ),
      ],
      isSingleItem: true,
    ),
    NavigationGroup(
      label: 'Catálogo',
      icon: Icons.inventory_rounded,
      key: 'catalog',
      items: [
        NavigationItem(
          key: 'products',
          icon: Icons.inventory_2_rounded,
          label: 'Productos',
          page: const ProductsListScreen(),
        ),
        NavigationItem(
          key: 'categories',
          icon: Icons.folder_rounded,
          label: 'Categorías',
          page: const CategoriesListScreen(),
        ),
      ],
    ),
    NavigationGroup(
      label: 'Inventario',
      icon: Icons.warehouse_rounded,
      key: 'inventory',
      items: [
        NavigationItem(
          key: 'shipments',
          icon: Icons.local_shipping_rounded,
          label: 'Recepciones',
          page: const ShipmentHistoryScreen(),
        ),
        NavigationItem(
          key: 'movements',
          icon: Icons.swap_horiz_rounded,
          label: 'Movimientos',
          page: const MovementHistoryScreen(),
        ),
      ],
    ),
    NavigationGroup(
      label: 'Ventas',
      icon: Icons.store_rounded,
      key: 'operations',
      items: [
        NavigationItem(
          key: 'orders',
          icon: Icons.receipt_long_rounded,
          label: 'Envíos',
          page: const OrdersHistoryScreen(),
        ),
        NavigationItem(
          key: 'sales',
          icon: Icons.point_of_sale_rounded,
          label: 'Ventas',
          page: const SalesHistoryScreen(),
        ),
      ],
    ),
    NavigationGroup(
      label: 'Finanzas',
      icon: Icons.account_balance_wallet_rounded,
      key: 'finance',
      items: [
        NavigationItem(
          key: 'finances',
          icon: Icons.account_balance_wallet_rounded,
          label: 'Resumen',
          page: const FinancesScreen(),
        ),
        NavigationItem(
          key: 'deposits',
          icon: Icons.account_balance_rounded,
          label: 'Depósitos',
          page: const DepositsScreen(),
        ),
        NavigationItem(
          key: 'reports',
          icon: Icons.assessment_rounded,
          label: 'Reportes',
          page: const ReportsScreen(),
          isPhase2: true,
        ),
      ],
      requiresSuperuser: true,
    ),
    NavigationGroup(
      label: 'Configuración',
      icon: Icons.settings_rounded,
      key: 'settings',
      items: [
        NavigationItem(
          key: 'settings',
          icon: Icons.settings_rounded,
          label: 'Configuración',
          page: const SettingsScreen(),
        ),
      ],
      isSingleItem: true,
    ),
  ];

  // Get visible groups based on user role
  List<NavigationGroup> get _visibleNavGroups {
    if (AuthService.isSuperuser) {
      return _navGroups;
    } else {
      // Employee sees only Catalog group
      return _navGroups.where((group) => !group.requiresSuperuser).toList();
    }
  }

  Widget _getCurrentPage() {
    for (var group in _navGroups) {
      for (var item in group.items) {
        if (item.key == _selectedPageKey) {
          return item.page;
        }
      }
    }
    return const DashboardScreen();
  }

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

                // Navigation Groups
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingM,
                    ),
                    itemCount: _visibleNavGroups.length,
                    itemBuilder: (context, index) {
                      final group = _visibleNavGroups[index];
                      final isExpanded = _expandedGroups[group.key] ?? false;

                      // Single item groups (no dropdown)
                      if (group.isSingleItem) {
                        final item = group.items.first;
                        final isSelected = _selectedPageKey == item.key;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacingS),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPageKey = item.key;
                                });
                              },
                              borderRadius: AppTheme.borderRadiusSmall,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingM,
                                  vertical: AppTheme.spacingM,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.blue.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: AppTheme.borderRadiusSmall,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 20,
                                      color: isSelected
                                          ? AppTheme.blue
                                          : AppTheme.mediumGray,
                                    ),
                                    if (_isExpanded) ...[
                                      const SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: isSelected
                                                ? AppTheme.blue
                                                : AppTheme.darkGray,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Group with dropdown
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingXS),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _expandedGroups[group.key] = !isExpanded;
                                  });
                                },
                                borderRadius: AppTheme.borderRadiusSmall,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingM,
                                    vertical: AppTheme.spacingM,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        group.icon,
                                        size: 20,
                                        color: AppTheme.mediumGray,
                                      ),
                                      if (_isExpanded) ...[
                                        const SizedBox(
                                            width: AppTheme.spacingM),
                                        Expanded(
                                          child: Text(
                                            group.label,
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.darkGray,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          size: 20,
                                          color: AppTheme.mediumGray,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isExpanded && _isExpanded)
                            ...group.items.map((item) {
                              final isSelected = _selectedPageKey == item.key;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: AppTheme.spacingL,
                                  bottom: AppTheme.spacingXS,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPageKey = item.key;
                                      });

                                      if (item.isPhase2) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                    Icons.info_outline_rounded,
                                                    color: AppTheme.white),
                                                const SizedBox(
                                                    width: AppTheme.spacingM),
                                                Expanded(
                                                  child: Text(
                                                    'Funcionalidad en desarrollo - solo UI',
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                            color:
                                                                AppTheme.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppTheme.blue,
                                            behavior: SnackBarBehavior.floating,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: AppTheme.borderRadiusSmall,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingM,
                                        vertical: AppTheme.spacingS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.blue
                                                .withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius:
                                            AppTheme.borderRadiusSmall,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 18,
                                            color: isSelected
                                                ? AppTheme.blue
                                                : AppTheme.mediumGray,
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spacingM),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              style:
                                                  AppTheme.bodyMedium.copyWith(
                                                color: isSelected
                                                    ? AppTheme.blue
                                                    : AppTheme.darkGray,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (item.isPhase2)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.warning
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'UI',
                                                style:
                                                    AppTheme.caption.copyWith(
                                                  color: AppTheme.warning,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
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
            child: _getCurrentPage(),
          ),
        ],
      ),
    );
  }
}

class NavigationGroup {
  final String label;
  final IconData icon;
  final String key;
  final List<NavigationItem> items;
  final bool isSingleItem;
  final bool requiresSuperuser;

  NavigationGroup({
    required this.label,
    required this.icon,
    required this.key,
    required this.items,
    this.isSingleItem = false,
    this.requiresSuperuser = false,
  });
}

class NavigationItem {
  final String key;
  final IconData icon;
  final String label;
  final Widget page;
  final bool isPhase2;

  NavigationItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.page,
    this.isPhase2 = false,
  });
}
