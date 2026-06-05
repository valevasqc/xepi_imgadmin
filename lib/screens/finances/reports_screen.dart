import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/reports_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum DatePreset { today, thisWeek, thisMonth, thisYear, custom }

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportsService _reportsService = ReportsService();

  // Date range filters
  DatePreset _selectedPreset = DatePreset.thisMonth;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Other filters
  String? _selectedCategoryCode;
  String? _selectedProductBarcode;
  String? _selectedPaymentMethod;
  String? _selectedSaleType;
  String? _selectedExpenseType;

  // Data
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  Map<String, dynamic>? _salesAnalytics;
  Map<String, dynamic>? _expensesAnalytics;
  Map<String, double>? _pendingCash;
  Map<String, double>? _revenueByAccount;
  Map<String, dynamic>? _expensesByAccount;
  bool _isLoading = true;
  bool _isExporting = false;

  // Pagination
  int _expensesPage = 0;
  int _productsPage = 0;
  final int _rowsPerPage = 10;

  // Sorting
  String _productsSortColumn = 'revenue';
  bool _productsSortAscending = false;
  String _expensesSortColumn = 'createdAt';
  bool _expensesSortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDates();
    _loadData();
  }

  void _initializeDates() {
    final now = DateTime.now();
    switch (_selectedPreset) {
      case DatePreset.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisWeek:
        final weekday = now.weekday;
        _startDate = now.subtract(Duration(days: weekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisMonth:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.thisYear:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DatePreset.custom:
        // Keep current dates
        break;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load sales
      final sales = await _reportsService.getSales(
        startDate: _startDate,
        endDate: _endDate,
        categoryCode: _selectedCategoryCode,
        productBarcode: _selectedProductBarcode,
        paymentMethod: _selectedPaymentMethod,
        saleType: _selectedSaleType,
      );

      // Load expenses
      final expenses = await _reportsService.getExpenses(
        startDate: _startDate,
        endDate: _endDate,
        categoryType: _selectedExpenseType,
      );

      // Load categories
      final categories = await _reportsService.getCategories();

      // Load bank accounts
      final bankAccounts = await _reportsService.getBankAccounts();

      // Load pending cash
      final pendingCash = await _reportsService.getPendingCash();

      // Calculate analytics
      final salesAnalytics = _reportsService.calculateSalesAnalytics(sales);
      final expensesAnalytics = _reportsService.calculateExpensesAnalytics(expenses);
      final revenueByAccount = _reportsService.calculateRevenueByAccount(sales, bankAccounts);
      final expensesByAccount = _reportsService.calculateExpensesByPaymentSource(expenses, bankAccounts);

      setState(() {
        _expenses = expenses;
        _categories = categories;
        _bankAccounts = bankAccounts;
        _salesAnalytics = salesAnalytics;
        _expensesAnalytics = expensesAnalytics;
        _pendingCash = pendingCash;
        _revenueByAccount = revenueByAccount;
        _expensesByAccount = expensesByAccount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text('Error al cargar datos: $e',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.white)),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportSalesDataCSV() async {
    if (_salesAnalytics == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      final topProducts = _salesAnalytics!['topProducts'] as List<Map<String, dynamic>>;
      final salesByPaymentMethod = _salesAnalytics!['salesByPaymentMethod'] as Map<String, int>;
      final salesBySaleType = _salesAnalytics!['salesBySaleType'] as Map<String, int>;
      
      // Create CSV header and rows
      List<List<dynamic>> rows = [
        ['Reporte de Ventas - XEPI'],
        ['Período:', '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'],
        [],
        ['RESUMEN GENERAL'],
        ['Total Ingresos', 'Q${NumberFormat('#,##0.00').format(_salesAnalytics!['totalRevenue'])}'],
        ['Total Ventas', '${_salesAnalytics!['totalSalesCount']}'],
        ['Productos Vendidos', '${_salesAnalytics!['totalProductsSold']}'],
        ['Ticket Promedio', 'Q${NumberFormat('#,##0.00').format(_salesAnalytics!['avgTicket'])}'],
        [],
        ['PRODUCTOS MÁS VENDIDOS'],
        ['Producto', 'Cantidad', 'Ingresos'],
      ];
      
      for (var product in topProducts.take(20)) {
        rows.add([
          product['name'],
          product['quantity'],
          'Q${NumberFormat('#,##0.00').format(product['revenue'])}',
        ]);
      }
      
      rows.addAll([
        [],
        ['VENTAS POR MÉTODO DE PAGO'],
        ['Método', 'Cantidad'],
      ]);
      
      salesByPaymentMethod.forEach((method, count) {
        final label = method == 'efectivo' ? 'Efectivo' 
          : method == 'transferencia' ? 'Transferencia' 
          : method == 'tarjeta' ? 'Tarjeta' 
          : method;
        rows.add([label, count]);
      });
      
      rows.addAll([
        [],
        ['VENTAS POR TIPO'],
        ['Tipo', 'Cantidad'],
      ]);
      
      salesBySaleType.forEach((type, count) {
        final label = type == 'kiosko' ? 'Kiosko' : 'Delivery';
        rows.add([label, count]);
      });
      
      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);
      
      // Download file
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'ventas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportExpensesDataCSV() async {
    if (_expensesAnalytics == null || _expenses.isEmpty) return;
    
    setState(() => _isExporting = true);
    
    try {
      final expensesByCategory = _expensesAnalytics!['expensesByCategory'] as Map<String, double>;
      final expensesByType = _expensesAnalytics!['expensesByType'] as Map<String, double>;
      
      List<List<dynamic>> rows = [
        ['Reporte de Gastos - XEPI'],
        ['Período:', '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'],
        [],
        ['RESUMEN GENERAL'],
        ['Total Gastos', 'Q${NumberFormat('#,##0.00').format(_expensesAnalytics!['totalExpenses'])}'],
        ['Gastos Operativos', 'Q${NumberFormat('#,##0.00').format(expensesByType['operativo'] ?? 0)}'],
        ['Gastos No Operativos', 'Q${NumberFormat('#,##0.00').format(expensesByType['no_operativo'] ?? 0)}'],
        [],
        ['DETALLE DE GASTOS'],
        ['Fecha', 'Categoría', 'Descripción', 'Monto', 'Método de Pago', 'Estado'],
      ];
      
      final dateFormat = DateFormat('dd/MM/yyyy');
      for (var expense in _expenses) {
        final createdAt = (expense['createdAt'] as Timestamp?)?.toDate();
        final paymentSource = expense['paymentSource'] as String?;
        String paymentMethod = 'Efectivo';
        
        if (paymentSource != null && paymentSource != 'efectivo') {
          final account = _bankAccounts.firstWhere(
            (acc) => acc['id'] == paymentSource,
            orElse: () => {'accountName': 'Cuenta bancaria'},
          );
          paymentMethod = account['accountName'] as String? ?? 'Cuenta bancaria';
        }
        
        rows.add([
          createdAt != null ? dateFormat.format(createdAt) : '',
          expense['category'],
          expense['description'],
          'Q${NumberFormat('#,##0.00').format(expense['amount'])}',
          paymentMethod,
          expense['status'] == 'approved' ? 'Aprobado' 
            : expense['status'] == 'rejected' ? 'Rechazado' 
            : 'Pendiente',
        ]);
      }
      
      rows.addAll([
        [],
        ['GASTOS POR CATEGORÍA'],
        ['Categoría', 'Monto Total'],
      ]);
      
      final sortedCategories = expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var entry in sortedCategories) {
        rows.add([
          entry.key,
          'Q${NumberFormat('#,##0.00').format(entry.value)}',
        ]);
      }
      
      String csv = const ListToCsvConverter().convert(rows);
      
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'gastos_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportProductsDataCSV() async {
    if (_salesAnalytics == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      final topProducts = _salesAnalytics!['topProducts'] as List<Map<String, dynamic>>;
      
      List<List<dynamic>> rows = [
        ['Reporte de Productos - XEPI'],
        ['Período:', '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'],
        [],
        ['PRODUCTOS MÁS VENDIDOS'],
        ['Producto', 'Cantidad Vendida', 'Ingresos'],
      ];
      
      for (var product in topProducts) {
        rows.add([
          product['name'],
          product['quantity'],
          'Q${NumberFormat('#,##0.00').format(product['revenue'])}',
        ]);
      }
      
      String csv = const ListToCsvConverter().convert(rows);
      
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'productos_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportFinancialsCSV() async {
    if (_salesAnalytics == null || _expensesAnalytics == null) return;
    
    setState(() => _isExporting = true);
    
    try {
      final totalRevenue = _salesAnalytics!['totalRevenue'] as double;
      final totalExpenses = _expensesAnalytics!['totalExpenses'] as double;
      final netProfit = totalRevenue - totalExpenses;
      
      List<List<dynamic>> rows = [
        ['Reporte Financiero - XEPI'],
        ['Período:', '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'],
        [],
        ['RESUMEN FINANCIERO'],
        ['Concepto', 'Monto'],
        ['Ingresos Totales', 'Q${NumberFormat('#,##0.00').format(totalRevenue)}'],
        ['Gastos Totales', 'Q${NumberFormat('#,##0.00').format(totalExpenses)}'],
        ['Ganancia Neta', 'Q${NumberFormat('#,##0.00').format(netProfit)}'],
      ];
      
      if (_pendingCash != null) {
        final totalPending = _pendingCash!.values.reduce((a, b) => a + b);
        rows.addAll([
          [],
          ['EFECTIVO PENDIENTE POR DEPOSITAR'],
          ['Fuente', 'Monto'],
        ]);
        
        _pendingCash!.forEach((source, amount) {
          final label = source == 'store' ? 'Tienda'
            : source == 'mensajero' ? 'Mensajero'
            : source == 'forza' ? 'Forza'
            : source;
          rows.add([label, 'Q${NumberFormat('#,##0.00').format(amount)}']);
        });
        
        rows.add(['Total Pendiente', 'Q${NumberFormat('#,##0.00').format(totalPending)}']);
      }
      
      if (_revenueByAccount != null && _revenueByAccount!.isNotEmpty) {
        rows.addAll([
          [],
          ['INGRESOS POR CUENTA BANCARIA'],
          ['Cuenta', 'Monto'],
        ]);
        
        _revenueByAccount!.forEach((accountId, amount) {
          rows.add([
            _getAccountName(accountId),
            'Q${NumberFormat('#,##0.00').format(amount)}',
          ]);
        });
      }
      
      if (_expensesByAccount != null && _expensesByAccount!.isNotEmpty) {
        rows.addAll([
          [],
          ['GASTOS POR CUENTA BANCARIA'],
          ['Cuenta', 'Monto'],
        ]);
        
        _expensesByAccount!.forEach((accountId, amount) {
          rows.add([
            _getAccountName(accountId),
            'Q${NumberFormat('#,##0.00').format(amount)}',
          ]);
        });
      }
      
      String csv = const ListToCsvConverter().convert(rows);
      
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'finanzas_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado exitosamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
                color: AppTheme.white, boxShadow: AppTheme.subtleShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Reportes', style: AppTheme.heading1),
                    const Spacer(),
                    _buildDateRangeSelector(),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.blue,
                  unselectedLabelColor: AppTheme.mediumGray,
                  indicatorColor: AppTheme.blue,
                  labelStyle:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Ventas'),
                    Tab(text: 'Productos'),
                    Tab(text: 'Finanzas'),
                    Tab(text: 'Gastos'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesAnalyticsTab(),
                      _buildProductPerformanceTab(),
                      _buildFinancialSummaryTab(),
                      _buildExpensesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Date Range Selector Widget
  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        _buildPresetButton('Hoy', DatePreset.today),
        const SizedBox(width: AppTheme.spacingS),
        _buildPresetButton('Esta Semana', DatePreset.thisWeek),
        const SizedBox(width: AppTheme.spacingS),
        _buildPresetButton('Este Mes', DatePreset.thisMonth),
        const SizedBox(width: AppTheme.spacingS),
        _buildPresetButton('Este Año', DatePreset.thisYear),
        const SizedBox(width: AppTheme.spacingS),
        OutlinedButton.icon(
          onPressed: _showCustomDatePicker,
          icon: const Icon(Icons.calendar_today_rounded, size: 16),
          label: Text(
            _selectedPreset == DatePreset.custom
                ? '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}'
                : 'Personalizado',
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor:
                _selectedPreset == DatePreset.custom ? AppTheme.blue : null,
            foregroundColor:
                _selectedPreset == DatePreset.custom ? AppTheme.white : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, DatePreset preset) {
    final isSelected = _selectedPreset == preset;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPreset = preset;
          _initializeDates();
        });
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.blue : AppTheme.white,
        foregroundColor: isSelected ? AppTheme.white : AppTheme.darkGray,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.blue : AppTheme.lightGray,
        ),
      ),
      child: Text(label),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = DatePreset.custom;
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _loadData();
    }
  }

  // Sales Analytics Tab
  Widget _buildSalesAnalyticsTab() {
    if (_salesAnalytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: AppTheme.mediumGray),
            const SizedBox(height: AppTheme.spacingL),
            Text('No hay datos disponibles', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacingS),
            Text('Selecciona un rango de fechas diferente', 
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
          ],
        ),
      );
    }

    final analytics = _salesAnalytics!;
    final totalRevenue = analytics['totalRevenue'] as double;
    final totalSalesCount = analytics['totalSalesCount'] as int;
    final totalProductsSold = analytics['totalProductsSold'] as int;
    final avgTicket = analytics['avgTicket'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Análisis de Ventas', style: AppTheme.heading2),
              IconButton(
                onPressed: _isExporting ? null : _exportSalesDataCSV,
                icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
                tooltip: 'Exportar CSV',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Filters Row
          _buildFiltersRow(),
          const SizedBox(height: AppTheme.spacingL),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Ventas',
                  'Q${NumberFormat('#,##0.00').format(totalRevenue)}',
                  AppTheme.blue,
                  Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildMetricCard(
                  'Cantidad',
                  '$totalSalesCount',
                  AppTheme.orange,
                  Icons.shopping_cart_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildMetricCard(
                  'Productos Vendidos',
                  '$totalProductsSold',
                  AppTheme.success,
                  Icons.inventory_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildMetricCard(
                  'Ticket Promedio',
                  'Q${NumberFormat('#,##0.00').format(avgTicket)}',
                  AppTheme.yellow,
                  Icons.receipt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildSalesTrendChart(analytics['dailySales'] as Map<String, double>),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCategoryBarChart(analytics['salesByCategory'] as Map<String, double>),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  children: [
                    _buildPaymentMethodPieChart(analytics['salesByPaymentMethod'] as Map<String, int>),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildSaleTypePieChart(analytics['salesBySaleType'] as Map<String, int>),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryFilter(),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildPaymentMethodFilter(),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildSaleTypeFilter(),
        ),
        const SizedBox(width: AppTheme.spacingM),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _selectedCategoryCode = null;
              _selectedProductBarcode = null;
              _selectedPaymentMethod = null;
              _selectedSaleType = null;
            });
            _loadData();
          },
          icon: const Icon(Icons.clear_rounded),
          label: const Text('Limpiar Filtros'),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryCode,
          hint: Text('Todas las categorías', style: AppTheme.bodyMedium),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todas las categorías'),
            ),
            ..._categories.map((cat) => DropdownMenuItem<String>(
              value: cat['code'],
              child: Text(cat['name']),
            )),
          ],
          onChanged: (value) {
            setState(() => _selectedCategoryCode = value);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPaymentMethod,
          hint: Text('Todos los pagos', style: AppTheme.bodyMedium),
          isExpanded: true,
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Todos los pagos')),
            DropdownMenuItem<String>(value: 'efectivo', child: Text('Efectivo')),
            DropdownMenuItem<String>(value: 'transferencia', child: Text('Transferencia')),
            DropdownMenuItem<String>(value: 'tarjeta', child: Text('Tarjeta')),
          ],
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildSaleTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSaleType,
          hint: Text('Todos los tipos', style: AppTheme.bodyMedium),
          isExpanded: true,
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Todos los tipos')),
            DropdownMenuItem<String>(value: 'kiosko', child: Text('Kiosko')),
            DropdownMenuItem<String>(value: 'delivery', child: Text('Delivery')),
          ],
          onChanged: (value) {
            setState(() => _selectedSaleType = value);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
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
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
          const SizedBox(height: AppTheme.spacingS),
          Text(value, style: AppTheme.heading2.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart(Map<String, double> dailySales) {
    if (dailySales.isEmpty) {
      return _buildEmptyChart('Tendencia de Ventas', 'No hay ventas en este período');
    }

    final sortedDates = dailySales.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailySales[sortedDates[i]]!));
    }

    final maxY = dailySales.values.reduce((a, b) => a > b ? a : b);

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
          Text('Tendencia de Ventas', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Q${NumberFormat.compact().format(value)}',
                          style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) return const SizedBox();
                        final date = DateTime.parse(sortedDates[value.toInt()]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.blue.withValues(alpha: 0.1),
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

  Widget _buildCategoryBarChart(Map<String, double> salesByCategory) {
    if (salesByCategory.isEmpty) {
      return _buildEmptyChart('Ventas por Categoría', 'No hay datos de categorías');
    }

    final sortedEntries = salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(10).toList();

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
          Text('Top 10 Categorías', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topEntries.first.value * 1.2,
                barGroups: topEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AppTheme.blue,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Q${NumberFormat.compact().format(value)}',
                          style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= topEntries.length) return const SizedBox();
                        // Get category name from code
                        final categoryCode = topEntries[value.toInt()].key;
                        final category = _categories.firstWhere(
                          (c) => c['code'] == categoryCode,
                          orElse: () => {'name': categoryCode},
                        );
                        final name = category['name'] as String;
                        // Show only subcategory name (after dash)
                        final shortName = name.contains('-') 
                          ? name.split('-').last.trim() 
                          : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortName.length > 10 ? '${shortName.substring(0, 10)}...' : shortName,
                            style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPieChart(Map<String, int> salesByPaymentMethod) {
    if (salesByPaymentMethod.isEmpty) {
      return _buildEmptyChart('Métodos de Pago', 'No hay datos de pagos');
    }

    final total = salesByPaymentMethod.values.reduce((a, b) => a + b);
    final colors = {
      'efectivo': AppTheme.success,
      'transferencia': AppTheme.blue,
      'tarjeta': AppTheme.orange,
    };

    final sections = salesByPaymentMethod.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[entry.key] ?? AppTheme.mediumGray,
        radius: 60,
        titleStyle: AppTheme.bodySmall.copyWith(
          color: AppTheme.white,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

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
          Text('Métodos de Pago', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...salesByPaymentMethod.entries.map((entry) {
            final label = entry.key == 'efectivo' ? 'Efectivo'
              : entry.key == 'transferencia' ? 'Transferencia'
              : entry.key == 'tarjeta' ? 'Tarjeta'
              : entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[entry.key] ?? AppTheme.mediumGray,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(label, style: AppTheme.bodySmall),
                  const Spacer(),
                  Text('${entry.value}', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSaleTypePieChart(Map<String, int> salesBySaleType) {
    if (salesBySaleType.isEmpty) {
      return _buildEmptyChart('Tipos de Venta', 'No hay datos de tipos');
    }

    final total = salesBySaleType.values.reduce((a, b) => a + b);
    final colors = {
      'kiosko': AppTheme.blue,
      'delivery': AppTheme.orange,
    };

    final sections = salesBySaleType.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[entry.key] ?? AppTheme.mediumGray,
        radius: 60,
        titleStyle: AppTheme.bodySmall.copyWith(
          color: AppTheme.white,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

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
          Text('Tipos de Venta', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...salesBySaleType.entries.map((entry) {
            final label = entry.key == 'kiosko' ? 'Kiosko'
              : entry.key == 'delivery' ? 'Delivery'
              : entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[entry.key] ?? AppTheme.mediumGray,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(label, style: AppTheme.bodySmall),
                  const Spacer(),
                  Text('${entry.value}', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, String message) {
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
          Text(title, style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 48, color: AppTheme.mediumGray),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(message, style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product Performance Tab
  Widget _buildProductPerformanceTab() {
    if (_salesAnalytics == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final topProducts = _salesAnalytics!['topProducts'] as List<Map<String, dynamic>>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rendimiento de Productos', style: AppTheme.heading2),
              IconButton(
                onPressed: _isExporting ? null : _exportProductsDataCSV,
                icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
                tooltip: 'Exportar CSV',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildBestSellersTable(topProducts),
        ],
      ),
    );
  }

  Widget _buildBestSellersTable(List<Map<String, dynamic>> products) {
    // Sort products
    final sortedProducts = List<Map<String, dynamic>>.from(products);
    sortedProducts.sort((a, b) {
      final aValue = a[_productsSortColumn];
      final bValue = b[_productsSortColumn];
      final comparison = _productsSortAscending 
        ? Comparable.compare(aValue, bValue)
        : Comparable.compare(bValue, aValue);
      return comparison;
    });

    // Paginate
    final startIndex = _productsPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, sortedProducts.length);
    final paginatedProducts = sortedProducts.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Text('Rendimiento de Productos', style: AppTheme.heading3),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _productsSortColumn == 'name' ? 0
                : _productsSortColumn == 'quantity' ? 1
                : 2,
              sortAscending: _productsSortAscending,
              columns: [
                DataColumn(
                  label: const Text('Producto'),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _productsSortColumn = 'name';
                      _productsSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Unidades Vendidas'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _productsSortColumn = 'quantity';
                      _productsSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Ingresos'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _productsSortColumn = 'revenue';
                      _productsSortAscending = ascending;
                    });
                  },
                ),
              ],
              rows: paginatedProducts.map((product) {
                return DataRow(cells: [
                  DataCell(Text(product['name'] ?? 'Sin nombre')),
                  DataCell(Text('${product['quantity']}')),
                  DataCell(Text('Q${NumberFormat('#,##0.00').format(product['revenue'])}')),
                ]);
              }).toList(),
            ),
          ),
          // Pagination controls
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Mostrando ${startIndex + 1}-$endIndex de ${sortedProducts.length}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
                const SizedBox(width: AppTheme.spacingM),
                IconButton(
                  onPressed: _productsPage > 0 ? () {
                    setState(() => _productsPage--);
                  } : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: endIndex < sortedProducts.length ? () {
                    setState(() => _productsPage++);
                  } : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Financial Summary Tab
  Widget _buildFinancialSummaryTab() {
    if (_salesAnalytics == null || _expensesAnalytics == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final totalRevenue = _salesAnalytics!['totalRevenue'] as double;
    final totalExpenses = _expensesAnalytics!['totalExpenses'] as double;
    final netProfit = totalRevenue - totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resumen Financiero', style: AppTheme.heading2),
              IconButton(
                onPressed: _isExporting ? null : _exportFinancialsCSV,
                icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
                tooltip: 'Exportar CSV',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Ingresos Totales',
                  'Q${NumberFormat('#,##0.00').format(totalRevenue)}',
                  AppTheme.success,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildMetricCard(
                  'Gastos Totales',
                  'Q${NumberFormat('#,##0.00').format(totalExpenses)}',
                  AppTheme.danger,
                  Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildMetricCard(
                  'Ganancia Neta',
                  'Q${NumberFormat('#,##0.00').format(netProfit)}',
                  netProfit >= 0 ? AppTheme.blue : AppTheme.danger,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_pendingCash != null) _buildPendingCashCard(),
          if (_revenueByAccount != null && _expensesByAccount != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            _buildBankAccountBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCashCard() {
    final pendingCash = _pendingCash!;
    final totalPending = pendingCash.values.reduce((a, b) => a + b);

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
              Text('Efectivo Pendiente', style: AppTheme.heading3),
              const Spacer(),
              Text(
                'Q${NumberFormat('#,##0.00').format(totalPending)}',
                style: AppTheme.heading2.copyWith(
                  color: totalPending > 0 ? AppTheme.warning : AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...pendingCash.entries.map((entry) {
            final label = entry.key == 'store' ? 'Tienda'
              : entry.key == 'mensajero' ? 'Mensajero'
              : entry.key == 'forza' ? 'Forza'
              : entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppTheme.spacingS),
                        LinearProgressIndicator(
                          value: totalPending > 0 ? (entry.value / totalPending) : 0,
                          backgroundColor: AppTheme.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            entry.value > 1000 ? AppTheme.danger : AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Text(
                    'Q${NumberFormat('#,##0.00').format(entry.value)}',
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBankAccountBreakdown() {
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
          Text('Movimientos por Cuenta', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue by account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresos',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    ...(_revenueByAccount!.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((entry) {
                      final accountName = _getAccountName(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountName,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  LinearProgressIndicator(
                                    value: _revenueByAccount!.values.reduce((a, b) => a + b) > 0
                                        ? (entry.value / _revenueByAccount!.values.reduce((a, b) => a + b))
                                        : 0,
                                    backgroundColor: AppTheme.lightGray,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Text(
                              'Q${NumberFormat('#,##0.00').format(entry.value)}',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingXL),
              // Expenses by payment source
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    ...(_expensesByAccount!.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((entry) {
                      final accountName = _getAccountName(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountName,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  LinearProgressIndicator(
                                    value: _expensesByAccount!.values.reduce((a, b) => a + b) > 0
                                        ? (entry.value / _expensesByAccount!.values.reduce((a, b) => a + b))
                                        : 0,
                                    backgroundColor: AppTheme.lightGray,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.danger),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingL),
                            Text(
                              'Q${NumberFormat('#,##0.00').format(entry.value)}',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAccountName(String accountId) {
    if (accountId == 'efectivo') {
      return 'Efectivo';
    }
    
    final account = _bankAccounts.firstWhere(
      (acc) => acc['id'] == accountId,
      orElse: () => {'accountName': 'Cuenta desconocida'},
    );
    
    return account['accountName'] as String? ?? 'Cuenta desconocida';
  }

  // Expenses Tab
  Widget _buildExpensesTab() {
    if (_expensesAnalytics == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final analytics = _expensesAnalytics!;
    final totalExpenses = analytics['totalExpenses'] as double;
    final expensesByType = analytics['expensesByType'] as Map<String, double>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          // Header with Export Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Análisis de Gastos', style: AppTheme.heading2),
              IconButton(
                onPressed: _isExporting ? null : _exportExpensesDataCSV,
                icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
                tooltip: 'Exportar CSV',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                  foregroundColor: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Filter and summary
          Row(
            children: [
              Expanded(
                child: _buildExpenseTypeFilter(),
              ),
              const Spacer(),
              _buildMetricCard(
                'Total Gastos',
                'Q${NumberFormat('#,##0.00').format(totalExpenses)}',
                AppTheme.danger,
                Icons.receipt_long_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Charts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildExpenseTypePieChart(expensesByType),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: _buildExpensesTrendChart(analytics['dailyExpenses'] as Map<String, double>),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Expenses table
          _buildExpensesTable(),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExpenseType,
          hint: Text('Todos los tipos', style: AppTheme.bodyMedium),
          isExpanded: true,
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Todos los tipos')),
            DropdownMenuItem<String>(value: 'operativo', child: Text('Operativo')),
            DropdownMenuItem<String>(value: 'no_operativo', child: Text('No Operativo')),
          ],
          onChanged: (value) {
            setState(() => _selectedExpenseType = value);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildExpenseTypePieChart(Map<String, double> expensesByType) {
    if (expensesByType.isEmpty || expensesByType.values.every((v) => v == 0)) {
      return _buildEmptyChart('Gastos por Tipo', 'No hay gastos registrados');
    }

    final total = expensesByType.values.reduce((a, b) => a + b);
    final colors = {
      'operativo': AppTheme.blue,
      'no_operativo': AppTheme.orange,
    };

    final sections = expensesByType.entries.where((e) => e.value > 0).map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[entry.key] ?? AppTheme.mediumGray,
        radius: 60,
        titleStyle: AppTheme.bodySmall.copyWith(
          color: AppTheme.white,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

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
          Text('Gastos por Tipo', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...expensesByType.entries.where((e) => e.value > 0).map((entry) {
            final label = entry.key == 'operativo' ? 'Operativo' : 'No Operativo';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[entry.key] ?? AppTheme.mediumGray,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(label, style: AppTheme.bodySmall),
                  const Spacer(),
                  Text(
                    'Q${NumberFormat('#,##0.00').format(entry.value)}',
                    style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpensesTrendChart(Map<String, double> dailyExpenses) {
    if (dailyExpenses.isEmpty) {
      return _buildEmptyChart('Tendencia de Gastos', 'No hay gastos en este período');
    }

    final sortedDates = dailyExpenses.keys.toList()..sort();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyExpenses[sortedDates[i]]!));
    }

    final maxY = dailyExpenses.values.reduce((a, b) => a > b ? a : b);

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
          Text('Tendencia de Gastos', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Q${NumberFormat.compact().format(value)}',
                          style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) return const SizedBox();
                        final date = DateTime.parse(sortedDates[value.toInt()]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.danger,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.danger.withValues(alpha: 0.1),
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

  Widget _buildExpensesTable() {
    // Sort expenses
    final sortedExpenses = List<Map<String, dynamic>>.from(_expenses);
    sortedExpenses.sort((a, b) {
      dynamic aValue, bValue;
      
      if (_expensesSortColumn == 'createdAt') {
        aValue = (a['createdAt'] as Timestamp).toDate();
        bValue = (b['createdAt'] as Timestamp).toDate();
      } else if (_expensesSortColumn == 'amount') {
        aValue = a['amount'];
        bValue = b['amount'];
      } else {
        aValue = a[_expensesSortColumn] ?? '';
        bValue = b[_expensesSortColumn] ?? '';
      }
      
      final comparison = _expensesSortAscending 
        ? Comparable.compare(aValue, bValue)
        : Comparable.compare(bValue, aValue);
      return comparison;
    });

    // Paginate
    final startIndex = _expensesPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, sortedExpenses.length);
    final paginatedExpenses = sortedExpenses.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Text('Historial de Gastos', style: AppTheme.heading3),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _expensesSortColumn == 'createdAt' ? 0
                : _expensesSortColumn == 'category' ? 1
                : _expensesSortColumn == 'description' ? 2
                : 3,
              sortAscending: _expensesSortAscending,
              columns: [
                DataColumn(
                  label: const Text('Fecha'),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _expensesSortColumn = 'createdAt';
                      _expensesSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Categoría'),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _expensesSortColumn = 'category';
                      _expensesSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Descripción'),
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _expensesSortColumn = 'description';
                      _expensesSortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Monto'),
                  numeric: true,
                  onSort: (columnIndex, ascending) {
                    setState(() {
                      _expensesSortColumn = 'amount';
                      _expensesSortAscending = ascending;
                    });
                  },
                ),
              ],
              rows: paginatedExpenses.map((expense) {
                final createdAt = (expense['createdAt'] as Timestamp?)?.toDate();
                return DataRow(cells: [
                  DataCell(Text(createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt) : '-')),
                  DataCell(Text(expense['category'] ?? 'Sin categoría')),
                  DataCell(Text(expense['description'] ?? 'Sin descripción')),
                  DataCell(Text('Q${NumberFormat('#,##0.00').format(expense['amount'] ?? 0)}')),
                ]);
              }).toList(),
            ),
          ),
          // Pagination controls
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Mostrando ${startIndex + 1}-$endIndex de ${sortedExpenses.length}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
                const SizedBox(width: AppTheme.spacingM),
                IconButton(
                  onPressed: _expensesPage > 0 ? () {
                    setState(() => _expensesPage--);
                  } : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: endIndex < sortedExpenses.length ? () {
                    setState(() => _expensesPage++);
                  } : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
