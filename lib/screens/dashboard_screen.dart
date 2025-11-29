import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacingXL),
            _buildFinancialSummary(),
            const SizedBox(height: AppTheme.spacingL),
            _buildAlertsAndOrders(),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInventorySummary()),
                const SizedBox(width: AppTheme.spacingL),
                Expanded(child: _buildSalesInsights()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Dashboard', style: AppTheme.heading1),
        const Spacer(),
        Text(_getGreeting(),
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.mediumGray)),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Widget _buildFinancialSummary() {
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
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppTheme.blue, size: 28),
              const SizedBox(width: AppTheme.spacingM),
              Text('RESUMEN FINANCIERO', style: AppTheme.heading3),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Ver Detalles →'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                  child: _buildFinancialCard(
                      'Efectivo Pendiente',
                      'Q2,450',
                      '🔴',
                      AppTheme.danger,
                      'Tienda: Q850\nMensajero: Q1,600')),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                  child: _buildFinancialCard('Ventas Hoy', 'Q1,250', '',
                      AppTheme.blue, '12 pedidos\n8 tienda • 4 entrega')),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                  child: _buildFinancialCard('Ventas del Mes', 'Q38,450', '',
                      AppTheme.success, '145 pedidos\nPromedio: Q265')),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.danger, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                    Text('Depósitos Pendientes:',
                        style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.danger)),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text('• Depósito tienda (7 días) - Q850',
                    style: AppTheme.bodySmall),
                Text('• Depósito mensajero (3 días) - Q1,600',
                    style: AppTheme.bodySmall),
                Text('• Forza pendiente (2 pedidos) - Q450',
                    style: AppTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Registrar Depósito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assessment_rounded),
                  label: const Text('Reportes Financieros'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
      String label, String value, String emoji, Color color, String details) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Text(value, style: AppTheme.heading2.copyWith(color: color)),
              if (emoji.isNotEmpty) ...[
                const SizedBox(width: AppTheme.spacingS),
                Text(emoji, style: const TextStyle(fontSize: 20)),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(details, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildAlertsAndOrders() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAlerts()),
        const SizedBox(width: AppTheme.spacingL),
        Expanded(child: _buildPendingOrders()),
      ],
    );
  }

  Widget _buildAlerts() {
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
              const Icon(Icons.warning_rounded,
                  color: AppTheme.danger, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('ALERTAS URGENTES', style: AppTheme.heading3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('3',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildAlertItem('🔴 Stock Crítico', 'Carrusel Rosado',
              'B:1 T:0 (necesita 10+)', AppTheme.danger, 'Ordenar Ahora'),
          const SizedBox(height: AppTheme.spacingM),
          _buildAlertItem('🔴 Pago Atrasado', 'Pedido #1230 (5 días)',
              'Cliente: Ana García', AppTheme.danger, 'Contactar'),
          const SizedBox(height: AppTheme.spacingM),
          _buildAlertItem('🔴 Depósito Atrasado', 'Última depósito: 7 días',
              'Monto: Q850', AppTheme.danger, 'Registrar'),
          const SizedBox(height: AppTheme.spacingL),
          TextButton(
            onPressed: () {},
            child: const Text('Ver Todas las Alertas →'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, String detail,
      Color color, String action) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTheme.bodySmall),
                Text(detail,
                    style:
                        AppTheme.caption.copyWith(color: AppTheme.mediumGray)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrders() {
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
                  color: AppTheme.blue, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('PEDIDOS PENDIENTES', style: AppTheme.heading3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('5',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildOrderItem('#1234', 'María López', 'Q285', 'Listo',
              AppTheme.success, 'Marcar Enviado'),
          const SizedBox(height: AppTheme.spacingM),
          _buildOrderItem('#1233', 'Juan Pérez', 'Q99', 'Preparando',
              AppTheme.yellow, 'Marcar Listo'),
          const SizedBox(height: AppTheme.spacingM),
          _buildOrderItem('#1232', 'Rosa Méndez', 'Q450', 'Pend. Pago',
              AppTheme.danger, 'Confirmar Pago'),
          const SizedBox(height: AppTheme.spacingL),
          TextButton(
            onPressed: () {},
            child: const Text('Ver Todos los Pedidos →'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String id, String customer, String amount,
      String status, Color statusColor, String action) {
    return Container(
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
                    Text(id,
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status,
                          style: AppTheme.caption.copyWith(
                              color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Text(customer, style: AppTheme.bodySmall),
                Text(amount,
                    style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600, color: AppTheme.blue)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
            ),
            child: Text(action, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySummary() {
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
              const Icon(Icons.inventory_2_rounded,
                  color: AppTheme.orange, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('INVENTARIO', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildInventoryStat('Total Productos', '612', null),
          _buildInventoryStat('En Stock', '534 (87%)', AppTheme.success),
          _buildInventoryStat('🔴 Stock Bajo', '12', AppTheme.danger),
          _buildInventoryStat('🟡 Stock Medio', '45', AppTheme.yellow),
          _buildInventoryStat('✅ Stock Bueno', '477', AppTheme.success),
          const Divider(height: AppTheme.spacingXL),
          Text('Valor Inventario: Q125,000',
              style: AppTheme.heading3.copyWith(color: AppTheme.blue)),
          const SizedBox(height: AppTheme.spacingS),
          Text('└─ Bodega: Q98,000 (78%)', style: AppTheme.bodySmall),
          Text('└─ Tienda: Q27,000 (22%)', style: AppTheme.bodySmall),
          const Divider(height: AppTheme.spacingXL),
          Text('Actividad Reciente:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          Text('• Recepción: 45 items (21 Oct)', style: AppTheme.bodySmall),
          Text('• Traslado B→T: 7 items (hace 2h)', style: AppTheme.bodySmall),
          Text('• Venta: Tobogán -1 (hace 30m)', style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.inbox_rounded, size: 18),
                  label: const Text('Recibir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Trasladar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStat(String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
          Text(value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.darkGray,
              )),
        ],
      ),
    );
  }

  Widget _buildSalesInsights() {
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
              Text('VENTAS', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text('Esta Semana: Q8,450 (+15%)',
              style: AppTheme.heading3.copyWith(color: AppTheme.success)),
          const SizedBox(height: AppTheme.spacingL),
          _buildSalesBar('Lun', 1200, 1650),
          _buildSalesBar('Mar', 1050, 1650),
          _buildSalesBar('Mié', 1450, 1650),
          _buildSalesBar('Jue', 1150, 1650),
          _buildSalesBar('Vie', 1300, 1650),
          _buildSalesBar('Sáb', 1650, 1650, isHighlight: true),
          _buildSalesBar('Dom', 0, 1650, isClosed: true),
          const Divider(height: AppTheme.spacingXL),
          Text('Top Ventas (Semana):',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          Text('1. Cuadro Coca Cola 20x30 - 12 unid',
              style: AppTheme.bodySmall),
          Text('2. Tobogán Amarillo - 8 unid', style: AppTheme.bodySmall),
          Text('3. Carrusel Rosado - 7 unid', style: AppTheme.bodySmall),
          const Divider(height: AppTheme.spacingXL),
          Text('Canales de Venta:',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppTheme.spacingS),
          _buildSalesChannel('Tienda', '65%', AppTheme.blue),
          _buildSalesChannel('WhatsApp', '25%', AppTheme.success),
          _buildSalesChannel('Facebook', '10%', AppTheme.orange),
          const SizedBox(height: AppTheme.spacingL),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.assessment_rounded),
            label: const Text('Reporte Detallado'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesBar(String day, int amount, int max,
      {bool isHighlight = false, bool isClosed = false}) {
    final percentage = isClosed ? 0.0 : (amount / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(day, style: AppTheme.caption),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppTheme.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isClosed
                      ? AppTheme.lightGray
                      : (isHighlight ? AppTheme.success : AppTheme.blue),
                ),
                minHeight: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          SizedBox(
            width: 60,
            child: Text(
              isClosed ? 'Cerrado' : 'Q$amount',
              style: AppTheme.caption.copyWith(
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (isHighlight) const Text(' ⭐', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSalesChannel(String channel, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(child: Text(channel, style: AppTheme.bodySmall)),
          Text(percentage,
              style: AppTheme.bodySmall
                  .copyWith(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
