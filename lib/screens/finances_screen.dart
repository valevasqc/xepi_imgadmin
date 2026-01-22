import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/expenses_service.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real data from Firestore
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _deposits = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  double _totalSales = 0;
  double _totalExpenses = 0;
  double _pendingCash = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load sales, expenses, deposits, and categories in parallel
      final results = await Future.wait([
        _firestore
            .collection('sales')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get(),
        ExpensesService.fetchExpenses(),
        _firestore
            .collection('deposits')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get(),
        ExpensesService.fetchCategories(),
      ]);

      final salesSnapshot = results[0] as QuerySnapshot;
      final depositsSnapshot = results[2] as QuerySnapshot;

      setState(() {
        _sales = salesSnapshot.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList();
        _expenses = results[1] as List<Map<String, dynamic>>;
        _deposits = depositsSnapshot.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList();
        _categories = results[3] as List<Map<String, dynamic>>;

        // Calculate totals
        _totalSales = _sales.fold<double>(
            0, (sum, s) => sum + ((s['total'] as num?)?.toDouble() ?? 0));
        _totalExpenses = _expenses.fold<double>(
            0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));

        // Calculate pending cash (efectivo sales without depositId)
        _pendingCash = _sales
            .where((s) =>
                s['paymentMethod'] == 'efectivo' && s['depositId'] == null)
            .fold<double>(
                0, (sum, s) => sum + ((s['total'] as num?)?.toDouble() ?? 0));

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                    child: Text('Error cargando datos: $e',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.white))),
              ],
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                const Icon(Icons.account_balance_wallet_rounded,
                    color: AppTheme.blue, size: 32),
                const SizedBox(width: AppTheme.spacingM),
                Text('Finanzas', style: AppTheme.heading1),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Exportar Reporte'),
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
                children: [
                  // Sales & Expenses Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSalesSummary()),
                      const SizedBox(width: AppTheme.spacingL),
                      Expanded(child: _buildExpensesSummary()),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Recent Sales & Deposits
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildRecentSales(),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                      Expanded(
                        child: _buildRecentDepositsWidget(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Expenses List
                  _buildExpensesTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SALES SUMMARY ==========
  Widget _buildSalesSummary() {
    final profit = _totalSales - _totalExpenses;

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
              const Icon(Icons.trending_up_rounded,
                  color: AppTheme.success, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('Ventas', style: AppTheme.heading2),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildStatRow('Total Ventas', _totalSales, AppTheme.success),
          const SizedBox(height: AppTheme.spacingM),
          _buildStatRow('Efectivo Pendiente', _pendingCash,
              _pendingCash > 2000 ? AppTheme.danger : AppTheme.warning),
          const Divider(height: AppTheme.spacingXL),
          _buildStatRow('Ganancia Estimada', profit, AppTheme.blue),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Ventas - Gastos (sin COGS)',
            style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text('Q${value.toStringAsFixed(2)}',
            style: AppTheme.heading3.copyWith(color: color)),
      ],
    );
  }

  // ========== EXPENSES SUMMARY ==========
  Widget _buildExpensesSummary() {
    final operationalExpenses = _expenses
        .where((e) => e['categoryType'] == 'operativo')
        .fold<double>(
            0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));
    final nonOperationalExpenses = _expenses
        .where((e) => e['categoryType'] == 'no_operativo')
        .fold<double>(
            0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));

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
                  color: AppTheme.danger, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('Gastos', style: AppTheme.heading2),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddExpenseDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildStatRow(
              'Gastos Operativos', operationalExpenses, AppTheme.orange),
          const SizedBox(height: AppTheme.spacingM),
          _buildStatRow(
              'Gastos No Operativos', nonOperationalExpenses, AppTheme.danger),
          const Divider(height: AppTheme.spacingXL),
          _buildStatRow('Total Gastos', _totalExpenses, AppTheme.danger),
        ],
      ),
    );
  }

  // ========== RECENT SALES ==========
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
              const Icon(Icons.point_of_sale_rounded,
                  color: AppTheme.blue, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Ventas Recientes', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ..._sales
              .take(5)
              .map((sale) => Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: AppTheme.success, size: 20),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                      sale['saleType'] == 'kiosko'
                                          ? 'Tienda'
                                          : 'Delivery',
                                      style: AppTheme.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingS,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPaymentColor(
                                              sale['paymentMethod'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sale['paymentMethod'] ?? '',
                                      style: AppTheme.caption.copyWith(
                                        color: _getPaymentColor(
                                            sale['paymentMethod']),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(_formatTimestamp(sale['createdAt']),
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.mediumGray)),
                            ],
                          ),
                        ),
                        Text(
                            'Q${((sale['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success)),
                      ],
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  Color _getPaymentColor(String? method) {
    switch (method) {
      case 'efectivo':
        return AppTheme.success;
      case 'transferencia':
        return AppTheme.blue;
      case 'tarjeta':
        return AppTheme.orange;
      default:
        return AppTheme.mediumGray;
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  // ========== RECENT DEPOSITS ==========
  Widget _buildRecentDepositsWidget() {
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
              const Icon(Icons.account_balance_rounded,
                  color: AppTheme.blue, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Depósitos', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ..._deposits
              .take(5)
              .map((deposit) => Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_rounded,
                              color: AppTheme.blue, size: 20),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(deposit['source'] ?? 'N/A',
                                  style: AppTheme.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_formatTimestamp(deposit['createdAt']),
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.mediumGray)),
                            ],
                          ),
                        ),
                        Text(
                            'Q${((deposit['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.blue)),
                      ],
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  // ========== EXPENSES TABLE ==========
  Widget _buildExpensesTable() {
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
              Text('Detalle de Gastos', style: AppTheme.heading3),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCategoryManagementDialog(),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Gestionar Categorías'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ..._expenses
              .map((expense) => Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingS,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (expense['categoryType'] ==
                                                  'operativo'
                                              ? AppTheme.blue
                                              : AppTheme.orange)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      expense['category'] ?? 'Sin categoría',
                                      style: AppTheme.caption.copyWith(
                                        color: expense['categoryType'] ==
                                                'operativo'
                                            ? AppTheme.blue
                                            : AppTheme.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text(_formatTimestamp(expense['createdAt']),
                                      style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.mediumGray)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(expense['description'] ?? '',
                                  style: AppTheme.bodyMedium),
                            ],
                          ),
                        ),
                        Text(
                            'Q${((expense['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.danger)),
                      ],
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  // ========== DIALOGS ==========
  void _showAddExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedCategory;
    String categoryType = 'operativo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Gasto'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat['name'] as String,
                            child: Text(cat['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedCategory = v;
                      final cat = _categories.firstWhere((c) => c['name'] == v,
                          orElse: () => {});
                      categoryType = cat['type'] ?? 'operativo';
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Monto', prefixText: 'Q'),
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.spacingL),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Subir recibo - próximamente'))),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Subir Recibo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (selectedCategory == null ||
                    amountCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Complete todos los campos')));
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                await ExpensesService.addExpense(
                  amount: amount,
                  category: selectedCategory!,
                  categoryType: categoryType,
                  description: descCtrl.text.trim(),
                  createdBy: AuthService.currentUser?.uid ?? 'admin',
                  status: 'approved', // Admin adds directly as approved
                );
                await _loadData();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.white),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                              child: Text('Gasto registrado',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.white))),
                        ],
                      ),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category_rounded,
                      color: AppTheme.blue, size: 28),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Gestionar Categorías', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              FilledButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar Categoría'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    return ListTile(
                      title: Text(cat['name'] as String),
                      subtitle: Text(cat['type'] == 'operativo'
                          ? 'Operativo'
                          : 'No Operativo'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            onPressed: () => _showEditCategoryDialog(cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                size: 18, color: AppTheme.danger),
                            onPressed: () => _deleteCategoryInDialog(cat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    String type = 'operativo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Categoría'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: AppTheme.spacingM),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                        value: 'operativo', child: Text('Operativo')),
                    DropdownMenuItem(
                        value: 'no_operativo', child: Text('No Operativo')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? 'operativo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await ExpensesService.addCategory(nameCtrl.text.trim(), type);
                  await _loadData();
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> cat) {
    final nameCtrl = TextEditingController(text: cat['name'] as String);
    String type = cat['type'] as String;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Categoría'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: AppTheme.spacingM),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                        value: 'operativo', child: Text('Operativo')),
                    DropdownMenuItem(
                        value: 'no_operativo', child: Text('No Operativo')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? 'operativo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                await ExpensesService.updateCategory(cat['id'] as String,
                    name: nameCtrl.text.trim(), type: type);
                await _loadData();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategoryInDialog(Map<String, dynamic> cat) async {
    await ExpensesService.deleteCategory(cat['id'] as String);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.white),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
                child: Text('Categoría eliminada',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white))),
          ],
        ),
        backgroundColor: AppTheme.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
