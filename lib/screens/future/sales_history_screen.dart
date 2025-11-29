import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(color: AppTheme.white, boxShadow: AppTheme.subtleShadow),
            child: Row(
              children: [
                Text('Historial de Ventas', style: AppTheme.heading1),
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
          ),
          Expanded(
            child: SingleChildScrollView(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Ventas Hoy', '12', AppTheme.blue)),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _buildStatCard('Total Hoy', 'Q1,450', AppTheme.success)),
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
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
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
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.success, size: 28),
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
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment,
                        style: AppTheme.caption.copyWith(color: AppTheme.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text('$date • $time', style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    const Icon(Icons.store_rounded, size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(location, style: AppTheme.bodyMedium),
                    const SizedBox(width: AppTheme.spacingL),
                    Text('$items items • Q$total', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
