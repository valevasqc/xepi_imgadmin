import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Text('Reportes', style: AppTheme.heading1),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función próximamente')),
                      ),
                      icon: const Icon(Icons.file_download_rounded),
                      label: const Text('Exportar Todo'),
                    ),
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
                    Tab(text: 'Análisis y Estadísticas'),
                    Tab(text: 'Historial de Ventas'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildSalesHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterDropdown('Este mes')),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(child: _buildFilterDropdown('Todas las ubicaciones')),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildSalesChart(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildTopProducts(),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCategoryBreakdown(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterDropdown('Hoy')),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(child: _buildFilterDropdown('Tienda Zona 10')),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(child: _buildFilterDropdown('Todos los pagos')),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función próximamente')),
                ),
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Exportar'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildStatsRow(),
          const SizedBox(height: AppTheme.spacingL),
          _buildSaleCard(
            id: '#VEN-234',
            date: '21 Oct 2025',
            time: '2:30 PM',
            location: 'Tienda Zona 10',
            items: 3,
            total: 285,
            payment: 'Efectivo',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildSaleCard(
            id: '#VEN-233',
            date: '21 Oct 2025',
            time: '1:15 PM',
            location: 'Tienda Zona 10',
            items: 1,
            total: 99,
            payment: 'Transferencia',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          Text(label, style: AppTheme.bodyMedium),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.mediumGray),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
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
              Text('Ventas del Mes', style: AppTheme.heading3),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_rounded, size: 16),
                label: const Text('Exportar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS),
                ),
              ),
            ],
          ),
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
                  const Icon(Icons.bar_chart_rounded,
                      size: 64, color: AppTheme.blue),
                  const SizedBox(height: AppTheme.spacingM),
                  Text('Gráfico de Ventas', style: AppTheme.heading3),
                  const SizedBox(height: AppTheme.spacingS),
                  Text('Visualización de datos próximamente',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
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
          Text('Productos Más Vendidos', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildTopProductItem(1, 'Pollo Entero', 245, 'Q23,275'),
          const SizedBox(height: AppTheme.spacingM),
          _buildTopProductItem(2, 'Crema 500ml', 189, 'Q17,955'),
          const SizedBox(height: AppTheme.spacingM),
          _buildTopProductItem(3, 'Queso Fresco', 156, 'Q15,600'),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(int rank, String name, int units, String total) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rank == 1
                ? AppTheme.orange.withValues(alpha: 0.1)
                : rank == 2
                    ? AppTheme.mediumGray.withValues(alpha: 0.1)
                    : AppTheme.yellow.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: rank == 1
                    ? AppTheme.orange
                    : rank == 2
                        ? AppTheme.mediumGray
                        : AppTheme.yellow,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('$units unidades vendidas', style: AppTheme.bodySmall),
            ],
          ),
        ),
        Text(total,
            style: AppTheme.bodyMedium
                .copyWith(fontWeight: FontWeight.w700, color: AppTheme.blue)),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
          Text('Resumen del Mes', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Total Ventas', 'Q156,890', AppTheme.blue),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Total Pedidos', '1,234', AppTheme.orange),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Productos Vendidos', '4,567', AppTheme.success),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Ticket Promedio', 'Q127', AppTheme.yellow),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
        const SizedBox(height: AppTheme.spacingS),
        Text(value, style: AppTheme.heading2.copyWith(color: color)),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
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
          Text('Ventas por Categoría', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildCategoryItem('Lácteos', 45, AppTheme.blue),
          const SizedBox(height: AppTheme.spacingM),
          _buildCategoryItem('Carnes', 35, AppTheme.orange),
          const SizedBox(height: AppTheme.spacingM),
          _buildCategoryItem('Otros', 20, AppTheme.yellow),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category,
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text('$percentage%',
                style: AppTheme.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Ventas Hoy', '12', AppTheme.blue)),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
            child: _buildStatCard('Total Hoy', 'Q1,450', AppTheme.success)),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _buildStatCard('Promedio', 'Q121', AppTheme.orange)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
          Text(label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
          const SizedBox(height: AppTheme.spacingS),
          Text(value, style: AppTheme.heading1.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildSaleCard({
    required String id,
    required String date,
    required String time,
    required String location,
    required int items,
    required int total,
    required String payment,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: AppTheme.success, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(id, style: AppTheme.heading3),
                    const SizedBox(width: AppTheme.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment,
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text('$date • $time', style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    const Icon(Icons.store_rounded,
                        size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(location, style: AppTheme.bodyMedium),
                    const SizedBox(width: AppTheme.spacingL),
                    Text('$items items • Q$total',
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
        ],
      ),
    );
  }
}
