import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/expenses_service.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  List<Map<String, dynamic>> _expenses = [];
  String _filterType = 'todos';
  String _filterStatus = 'todos';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loading = true);
    try {
      final items = await ExpensesService.fetchExpenses(
          type: _filterType, status: _filterStatus);
      setState(() {
        _expenses = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.white),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                  child: Text('Error cargando gastos: $e',
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.white))),
            ],
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _expenses;
    final total = expenses.fold<double>(
        0, (sum, e) => sum + ((e['amount'] as num).toDouble()));

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
                color: AppTheme.white, boxShadow: AppTheme.subtleShadow),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.danger, size: 32),
                const SizedBox(width: AppTheme.spacingM),
                Text('Gastos', style: AppTheme.heading1),
                const Spacer(),
                DropdownButton<String>(
                  value: _filterType,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'operativo', child: Text('Operativos')),
                    DropdownMenuItem(
                        value: 'no_operativo', child: Text('No Operativos')),
                  ],
                  onChanged: (v) async {
                    setState(() => _filterType = v ?? 'todos');
                    await _loadExpenses();
                  },
                ),
                const SizedBox(width: AppTheme.spacingM),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'pending_approval', child: Text('Pendientes')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Aprobados')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rechazados')),
                  ],
                  onChanged: (v) async {
                    setState(() => _filterStatus = v ?? 'todos');
                    await _loadExpenses();
                  },
                ),
                const SizedBox(width: AppTheme.spacingM),
                OutlinedButton.icon(
                  onPressed: () => _showSubmitExpenseDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar Gasto'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      children: [
                        Container(
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
                                  Expanded(
                                    child: Text('Listado de gastos',
                                        style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Text('Total: Q${total.toStringAsFixed(2)}',
                                      style: AppTheme.bodyMedium
                                          .copyWith(color: AppTheme.danger)),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              ...expenses.map(_buildExpenseRow),
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

  Widget _buildExpenseRow(Map<String, dynamic> e) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall),
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
                          horizontal: AppTheme.spacingS, vertical: 2),
                      decoration: BoxDecoration(
                        color: (e['type'] == 'operativo'
                                ? AppTheme.blue
                                : AppTheme.orange)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e['category'] as String,
                        style: AppTheme.caption.copyWith(
                          color: e['type'] == 'operativo'
                              ? AppTheme.blue
                              : AppTheme.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      _fmtTimestamp(e['createdAt']),
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(e['description'] as String, style: AppTheme.bodyMedium),
              ],
            ),
          ),
          Text('Q${(e['amount'] as double).toStringAsFixed(2)}',
              style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.danger, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppTheme.spacingM),
          IconButton(
            tooltip: 'Ver recibo',
            icon: const Icon(Icons.receipt_rounded),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recibo próximamente'))),
          ),
        ],
      ),
    );
  }

  String _fmtTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
    }
    return '';
  }

  String _monthName(int m) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[m - 1];
  }

  void _showSubmitExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Suministros de tienda';
    String type = 'operativo';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Gasto'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: const [
                  DropdownMenuItem(
                      value: 'Suministros de tienda',
                      child: Text('Suministros de tienda')),
                  DropdownMenuItem(
                      value: 'Inventarios', child: Text('Inventarios')),
                  DropdownMenuItem(value: 'Renta', child: Text('Renta')),
                  DropdownMenuItem(
                      value: 'Publicidad y marketing',
                      child: Text('Publicidad y marketing')),
                  DropdownMenuItem(
                      value: 'No operativos', child: Text('No operativos')),
                ],
                onChanged: (v) => category = v ?? 'Suministros de tienda',
              ),
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
                onChanged: (v) => type = v ?? 'operativo',
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Monto', prefixText: 'Q'),
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
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              await ExpensesService.addExpense(
                amount: amount,
                category: category,
                categoryType: type,
                description: descCtrl.text.trim(),
                createdBy: AuthService.currentUser?.uid ?? 'unknown',
              );
              if (context.mounted) Navigator.pop(context);
              await _loadExpenses();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.white),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                          child: Text('Gasto registrado (pendiente)',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.white))),
                    ],
                  ),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
