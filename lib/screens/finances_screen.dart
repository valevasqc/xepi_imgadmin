import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  // Mock data for pending cash
  final double _storeCash = 850.0;
  final int _storeDays = 7;
  final double _mensajeroCash = 1600.0;
  final int _mensajeroDays = 3;
  final double _forzaCash = 420.0;
  final int _forzaDays = 2;

  double get _totalPending => _storeCash + _mensajeroCash + _forzaCash;
  bool get _isOverLimit => _totalPending > 2000;

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
                  // CASH FLOW OVERVIEW
                  _buildCashFlowOverview(),

                  const SizedBox(height: AppTheme.spacingXL),

                  // DEPOSIT MANAGEMENT + PAYMENT ANALYSIS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildDepositManagement(),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                      Expanded(
                        flex: 2,
                        child: _buildPaymentMethodAnalysis(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // EXPENSE TRACKING + PROFIT/LOSS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildExpenseTracking(),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                      Expanded(
                        flex: 2,
                        child: _buildProfitLossSummary(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== CASH FLOW OVERVIEW ==========
  Widget _buildCashFlowOverview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
        border:
            _isOverLimit ? Border.all(color: AppTheme.danger, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isOverLimit
                    ? Icons.warning_rounded
                    : Icons.trending_up_rounded,
                color: _isOverLimit ? AppTheme.danger : AppTheme.success,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text('Resumen de Efectivo', style: AppTheme.heading2),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showRecordDepositDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar Depósito'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Pending Cash Alert
          if (_isOverLimit)
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.danger),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      '⚠️ Efectivo pendiente excede Q2,000. Se recomienda realizar depósito.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Pending Cash Cards
          Row(
            children: [
              Expanded(
                child: _buildPendingCashCard(
                  'Caja Tienda',
                  _storeCash,
                  _storeDays,
                  Icons.store_rounded,
                  AppTheme.blue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildPendingCashCard(
                  'Mensajero',
                  _mensajeroCash,
                  _mensajeroDays,
                  Icons.delivery_dining_rounded,
                  AppTheme.orange,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildPendingCashCard(
                  'Forza',
                  _forzaCash,
                  _forzaDays,
                  Icons.moped_rounded,
                  AppTheme.yellow,
                ),
              ),
            ],
          ),

          const Divider(height: AppTheme.spacingXL * 2),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Total Pendiente',
                  'Q${_totalPending.toStringAsFixed(2)}',
                  _isOverLimit ? AppTheme.danger : AppTheme.darkGray,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: _buildQuickStat(
                  'Cobros Hoy',
                  'Q1,245',
                  AppTheme.success,
                  Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: _buildQuickStat(
                  'Depósitos Esta Semana',
                  'Q8,450',
                  AppTheme.blue,
                  Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCashCard(
      String label, double amount, int days, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Q${amount.toStringAsFixed(2)}',
            style: AppTheme.heading2.copyWith(color: color),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '$days días sin depositar',
            style: AppTheme.bodySmall.copyWith(
              color: days > 5 ? AppTheme.danger : AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
              const SizedBox(height: 4),
              Text(value, style: AppTheme.heading3.copyWith(color: color)),
            ],
          ),
        ),
      ],
    );
  }

  // ========== DEPOSIT MANAGEMENT ==========
  Widget _buildDepositManagement() {
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
              Text('Depósitos Recientes', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Recent Deposits List
          ..._buildRecentDeposits(),

          const SizedBox(height: AppTheme.spacingL),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ver historial completo - próximamente')),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver Historial Completo'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentDeposits() {
    final deposits = [
      {
        'date': '23 Oct 2025',
        'source': 'Caja Tienda',
        'amount': 1500.0,
        'bank': 'BAM'
      },
      {
        'date': '21 Oct 2025',
        'source': 'Mensajero',
        'amount': 2300.0,
        'bank': 'Banrural'
      },
      {
        'date': '20 Oct 2025',
        'source': 'Forza',
        'amount': 680.0,
        'bank': 'BAM'
      },
      {
        'date': '18 Oct 2025',
        'source': 'Caja Tienda',
        'amount': 1850.0,
        'bank': 'G&T'
      },
      {
        'date': '17 Oct 2025',
        'source': 'Mensajero',
        'amount': 1920.0,
        'bank': 'Banrural'
      },
    ];

    return deposits.map((deposit) {
      return Container(
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
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded,
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
                        deposit['source'] as String,
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text('→', style: AppTheme.bodySmall),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        deposit['bank'] as String,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                  Text(
                    deposit['date'] as String,
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
            Text(
              'Q${(deposit['amount'] as double).toStringAsFixed(2)}',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver boleta - próximamente')),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              tooltip: 'Ver boleta',
            ),
          ],
        ),
      );
    }).toList();
  }

  // ========== PAYMENT METHOD ANALYSIS ==========
  Widget _buildPaymentMethodAnalysis() {
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
              const Icon(Icons.pie_chart_rounded,
                  color: AppTheme.orange, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Análisis de Pagos', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Store Payment Methods
          Text('Tienda:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Tarjeta', 65, AppTheme.blue),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Efectivo', 35, AppTheme.success),

          const Divider(height: AppTheme.spacingXL),

          // Delivery Payment Methods
          Text('Entregas:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Pre-pagado', 72, AppTheme.orange),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Contra Entrega', 28, AppTheme.yellow),

          const Divider(height: AppTheme.spacingXL),

          // Sales Channels
          Text('Canales de Venta:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Tienda', 65, AppTheme.blue),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('WhatsApp', 25, AppTheme.success),
          const SizedBox(height: AppTheme.spacingS),
          _buildPaymentBar('Facebook', 10, AppTheme.orange),

          const SizedBox(height: AppTheme.spacingL),

          // Placeholder for pie chart
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pie_chart_outline_rounded,
                      size: 48, color: AppTheme.mediumGray),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Gráfica circular',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.mediumGray),
                  ),
                  Text(
                    'próximamente',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodySmall),
            Text('$percentage%',
                style:
                    AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppTheme.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ========== EXPENSE TRACKING ==========
  Widget _buildExpenseTracking() {
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
              const Icon(Icons.receipt_rounded,
                  color: AppTheme.danger, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Gastos', style: AppTheme.heading3),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showRecordExpenseDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar Gasto'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Recent Expenses
          ..._buildRecentExpenses(),

          const SizedBox(height: AppTheme.spacingL),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ver todos los gastos - próximamente')),
            ),
            icon: const Icon(Icons.list_rounded),
            label: const Text('Ver Todos los Gastos'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentExpenses() {
    final expenses = [
      {
        'date': '23 Oct',
        'category': 'Proveedor',
        'description': 'Compra inventario',
        'amount': 4500.0
      },
      {
        'date': '20 Oct',
        'category': 'Salarios',
        'description': 'Pago quincenal',
        'amount': 6800.0
      },
      {
        'date': '15 Oct',
        'category': 'Alquiler',
        'description': 'Renta local',
        'amount': 3500.0
      },
      {
        'date': '12 Oct',
        'category': 'Servicios',
        'description': 'Luz y agua',
        'amount': 850.0
      },
      {
        'date': '10 Oct',
        'category': 'Marketing',
        'description': 'Anuncios Facebook',
        'amount': 500.0
      },
    ];

    return expenses.map((expense) {
      return Container(
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
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.trending_down_rounded,
                  color: AppTheme.danger, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expense['category'] as String,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        expense['date'] as String,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense['description'] as String,
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              'Q${(expense['amount'] as double).toStringAsFixed(2)}',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver recibo - próximamente')),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              tooltip: 'Ver recibo',
            ),
          ],
        ),
      );
    }).toList();
  }

  // ========== PROFIT/LOSS SUMMARY ==========
  Widget _buildProfitLossSummary() {
    const revenue = 45680.0;
    const expenses = 28350.0;
    const profit = revenue - expenses;
    const margin = (profit / revenue * 100);
    const lastMonthProfit = 15200.0;
    const growth = ((profit - lastMonthProfit) / lastMonthProfit * 100);

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
                  color: AppTheme.success, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('Ganancias', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          Text(
            'Este Mes',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Total Revenue
          _buildFinancialRow(
            'Ingresos Totales',
            revenue,
            AppTheme.blue,
            Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Total Expenses
          _buildFinancialRow(
            'Gastos Totales',
            expenses,
            AppTheme.danger,
            Icons.arrow_downward_rounded,
          ),

          const Divider(height: AppTheme.spacingXL),

          // Net Profit
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ganancia Neta',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Q${profit.toStringAsFixed(2)}',
                  style: AppTheme.heading1.copyWith(color: AppTheme.success),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Margen: ${margin.toStringAsFixed(1)}%',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Comparison to last month
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: growth > 0
                  ? AppTheme.success.withOpacity(0.05)
                  : AppTheme.danger.withOpacity(0.05),
              borderRadius: AppTheme.borderRadiusSmall,
              border: Border.all(
                color: growth > 0
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.danger.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  growth > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: growth > 0 ? AppTheme.success : AppTheme.danger,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    growth > 0
                        ? '${growth.toStringAsFixed(1)}% más que el mes pasado'
                        : '${growth.abs().toStringAsFixed(1)}% menos que el mes pasado',
                    style: AppTheme.bodySmall.copyWith(
                      color: growth > 0 ? AppTheme.success : AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // View Detailed Report Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Reporte detallado - próximamente')),
              ),
              icon: const Icon(Icons.assessment_rounded),
              label: const Text('Ver Reporte Detallado'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
      String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium,
          ),
        ),
        Text(
          'Q${amount.toStringAsFixed(2)}',
          style: AppTheme.heading3.copyWith(color: color),
        ),
      ],
    );
  }

  // ========== DIALOGS ==========
  void _showRecordDepositDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Depósito'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Origen del efectivo',
                  prefixIcon: Icon(Icons.source_rounded),
                ),
                items: ['Caja Tienda', 'Mensajero', 'Forza']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Q',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Banco',
                  prefixIcon: Icon(Icons.account_balance_rounded),
                ),
                items: ['BAM', 'Banrural', 'G&T Continental', 'Industrial']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: AppTheme.spacingL),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subir foto - próximamente')),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Subir Boleta de Depósito'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Depósito registrado - próximamente')),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _showRecordExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Gasto'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: [
                  'Alquiler',
                  'Salarios',
                  'Proveedor',
                  'Servicios',
                  'Marketing',
                  'Otros'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Q',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  prefixIcon: Icon(Icons.payment_rounded),
                ),
                items: ['Efectivo', 'Transferencia', 'Cheque', 'Tarjeta']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: AppTheme.spacingL),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subir foto - próximamente')),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Subir Recibo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Gasto registrado - próximamente')),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
