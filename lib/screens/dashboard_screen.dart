import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/future/deposits_screen.dart';
import 'package:xepi_imgadmin/screens/future/sales_history_screen.dart';
import 'package:xepi_imgadmin/screens/future/shipment_history_screen.dart';
import 'package:xepi_imgadmin/screens/finances_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: 'Q', decimalDigits: 2);

  // Data caches
  double _dailySales = 0;
  double _monthlySales = 0;
  int _dailySalesCount = 0;
  int _monthlySalesCount = 0;
  double _monthlyExpenses = 0;
  Map<String, double> _pendingCashBySource = {};
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _recentExpenses = [];
  int _pendingShipments = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Load all data in parallel
      await Future.wait([
        _loadSalesData(startOfDay, startOfMonth),
        _loadExpensesData(startOfMonth),
        _loadPendingCash(),
        _loadRecentActivity(),
        _loadPendingShipments(),
      ]);

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  Future<void> _loadSalesData(
      DateTime startOfDay, DateTime startOfMonth) async {
    // Fetch recent sales and filter in memory to avoid composite indexes
    final salesSnap = await FirebaseFirestore.instance
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .limit(100) // Last 100 sales should cover the month
        .get();

    double dailyTotal = 0;
    double monthlyTotal = 0;
    int dailyCount = 0;
    int monthlyCount = 0;

    for (var doc in salesSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final total = (data['total'] as num?)?.toDouble() ?? 0;

      if (createdAt != null) {
        // Only count sales from this month
        if (createdAt.isAfter(startOfMonth)) {
          monthlyTotal += total;
          monthlyCount++;

          if (createdAt.isAfter(startOfDay)) {
            dailyTotal += total;
            dailyCount++;
          }
        }
      }
    }

    _dailySales = dailyTotal;
    _monthlySales = monthlyTotal;
    _dailySalesCount = dailyCount;
    _monthlySalesCount = monthlyCount;
  }

  Future<void> _loadExpensesData(DateTime startOfMonth) async {
    // Fetch recent expenses and filter in memory
    final expensesSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    double total = 0;
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final status = data['status'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      // Only count approved expenses from this month
      if (createdAt != null &&
          createdAt.isAfter(startOfMonth) &&
          status == 'approved') {
        total += amount;
      }
    }

    _monthlyExpenses = total;
  }

  Future<void> _loadPendingCash() async {
    final pendingSnap =
        await FirebaseFirestore.instance.collection('pendingCash').get();

    final Map<String, double> pending = {};
    for (var doc in pendingSnap.docs) {
      final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      // Only include sources with pending amounts > 0
      if (amount > 0) {
        pending[doc.id] = amount;
      }
    }

    _pendingCashBySource = pending;
  }

  Future<void> _loadRecentActivity() async {
    // Recent sales (last 5)
    final recentSalesSnap = await FirebaseFirestore.instance
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    _recentSales =
        recentSalesSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    // Recent expenses (last 5)
    final recentExpensesSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    _recentExpenses =
        recentExpensesSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> _loadPendingShipments() async {
    final shipmentsSnap = await FirebaseFirestore.instance
        .collection('shipments')
        .where('status', isEqualTo: 'pending')
        .get();

    _pendingShipments = shipmentsSnap.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Header with Quick Actions
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                Text('Dashboard', style: AppTheme.heading1),
                const Spacer(),
                _buildQuickActions(),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFinancialOverview(),
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildPendingCashCards(),
                          const SizedBox(height: AppTheme.spacingXL),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildRecentSales()),
                              const SizedBox(width: AppTheme.spacingXL),
                              Expanded(child: _buildRecentExpenses()),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingXL),
                          _buildPendingShipments(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: AppTheme.spacingM,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to Register Sale screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registrar Venta - Próximamente')),
            );
          },
          icon: const Icon(Icons.point_of_sale_rounded, size: 20),
          label: const Text('Registrar Venta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.blue,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FinancesScreen()),
            );
          },
          icon: const Icon(Icons.receipt_long_rounded, size: 20),
          label: const Text('Agregar Gasto'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navigate to Receive Shipment screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ver Recepciones en menú Inventario')),
            );
          },
          icon: const Icon(Icons.inventory_2_rounded, size: 20),
          label: const Text('Recibir Envío'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOverview() {
    final monthlyProfit = _monthlySales - _monthlyExpenses;
    final profitColor = monthlyProfit >= 0 ? AppTheme.success : AppTheme.danger;

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
          Text('RESUMEN FINANCIERO', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ventas Hoy',
                  _currencyFormat.format(_dailySales),
                  '$_dailySalesCount pedidos',
                  AppTheme.blue,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Ventas del Mes',
                  _currencyFormat.format(_monthlySales),
                  '$_monthlySalesCount pedidos',
                  AppTheme.success,
                  Icons.assessment_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Gastos del Mes',
                  _currencyFormat.format(_monthlyExpenses),
                  'Aprobados',
                  AppTheme.danger,
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Ganancia Neta',
                  _currencyFormat.format(monthlyProfit),
                  monthlyProfit >= 0 ? 'Positivo' : 'Negativo',
                  profitColor,
                  Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  label,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(value, style: AppTheme.heading3.copyWith(color: color)),
          Text(subtitle, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildPendingCashCards() {
    if (_pendingCashBySource.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('EFECTIVO PENDIENTE DEPÓSITO', style: AppTheme.heading3),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DepositsScreen()),
                );
              },
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Registrar Depósito'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Wrap(
          spacing: AppTheme.spacingM,
          runSpacing: AppTheme.spacingM,
          children: _pendingCashBySource.entries.map((entry) {
            return _buildPendingCashCard(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPendingCashCard(String source, double amount) {
    String sourceName;
    IconData icon;
    Color color;

    switch (source) {
      case 'store':
        sourceName = 'Tienda';
        icon = Icons.store_rounded;
        color = AppTheme.blue;
        break;
      case 'mensajero':
        sourceName = 'Mensajero';
        icon = Icons.delivery_dining_rounded;
        color = AppTheme.orange;
        break;
      case 'forza':
        sourceName = 'Forza';
        icon = Icons.local_shipping_rounded;
        color = AppTheme.yellow;
        break;
      default:
        sourceName = source;
        icon = Icons.account_balance_wallet_rounded;
        color = AppTheme.mediumGray;
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text(sourceName, style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _currencyFormat.format(amount),
            style: AppTheme.heading2.copyWith(color: color),
          ),
          Text('Pendiente depósito', style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildRecentSales() {
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
              const Icon(Icons.shopping_cart_rounded,
                  color: AppTheme.blue, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('VENTAS RECIENTES', style: AppTheme.heading3),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalesHistoryScreen()),
                  );
                },
                child: const Text('Ver Todas →'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_recentSales.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Text(
                  'No hay ventas recientes',
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
                ),
              ),
            )
          else
            ..._recentSales.map((sale) => _buildSaleItem(sale)),
        ],
      ),
    );
  }

  Widget _buildSaleItem(Map<String, dynamic> sale) {
    final total = (sale['total'] as num?)?.toDouble() ?? 0;
    final customerName = sale['customerName'] as String? ?? 'Cliente';
    final saleType = sale['saleType'] as String? ?? 'kiosko';
    final createdAt = (sale['createdAt'] as Timestamp?)?.toDate();
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Icon(
            saleType == 'delivery'
                ? Icons.delivery_dining_rounded
                : Icons.store_rounded,
            color: AppTheme.blue,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(timeAgo, style: AppTheme.caption),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(total),
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses() {
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
              const Icon(Icons.receipt_long_rounded,
                  color: AppTheme.danger, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('GASTOS RECIENTES', style: AppTheme.heading3),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FinancesScreen()),
                  );
                },
                child: const Text('Ver Todos →'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_recentExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Text(
                  'No hay gastos recientes',
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
                ),
              ),
            )
          else
            ..._recentExpenses.map((expense) => _buildExpenseItem(expense)),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final category = expense['category'] as String? ?? 'Sin categoría';
    final description = expense['description'] as String? ?? '';
    final status = expense['status'] as String? ?? 'pending_approval';
    final createdAt = (expense['createdAt'] as Timestamp?)?.toDate();
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : '';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = AppTheme.success;
        break;
      case 'rejected':
        statusColor = AppTheme.danger;
        break;
      default:
        statusColor = AppTheme.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_rounded, color: statusColor),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: AppTheme.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(timeAgo, style: AppTheme.caption),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingShipments() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              color: AppTheme.orange, size: 32),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENVÍOS PENDIENTES', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  _pendingShipments == 0
                      ? 'No hay envíos pendientes'
                      : '$_pendingShipments ${_pendingShipments == 1 ? 'envío pendiente' : 'envíos pendientes'}',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (_pendingShipments > 0)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ShipmentHistoryScreen()),
                );
              },
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Ver Envíos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Justo ahora';
    }
  }
}
