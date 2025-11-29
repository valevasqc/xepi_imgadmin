import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/future/transfer_stock_screen.dart';

class MovementHistoryScreen extends StatelessWidget {
  const MovementHistoryScreen({super.key});

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
            child: Row(
              children: [
                Text('Historial de Movimientos', style: AppTheme.heading1),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransferStockScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo Traslado'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingM),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
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
                      Expanded(child: _buildFilterDropdown('Este mes')),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                          child: _buildFilterDropdown('Todas las ubicaciones')),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(child: _buildFilterDropdown('Todos los tipos')),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildMovementCard(
                    id: '#MOV-087',
                    type: 'Traslado',
                    from: 'Bodega Principal',
                    to: 'Tienda Zona 10',
                    date: '21 Oct 2025',
                    time: '2:30 PM',
                    products: 5,
                    units: 45,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildMovementCard(
                    id: '#MOV-086',
                    type: 'Recepción',
                    from: 'Proveedor XYZ',
                    to: 'Bodega Principal',
                    date: '20 Oct 2025',
                    time: '11:00 AM',
                    products: 12,
                    units: 150,
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

  Widget _buildMovementCard({
    required String id,
    required String type,
    required String from,
    required String to,
    required String date,
    required String time,
    required int products,
    required int units,
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
              color: AppTheme.orange.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: AppTheme.orange, size: 28),
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
                        color: AppTheme.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text('$date • $time', style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.mediumGray),
                          const SizedBox(width: AppTheme.spacingS),
                          Flexible(
                              child: Text(from, style: AppTheme.bodySmall)),
                        ],
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppTheme.mediumGray),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: AppTheme.mediumGray),
                          const SizedBox(width: AppTheme.spacingS),
                          Flexible(child: Text(to, style: AppTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text('$products productos • $units unidades',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
        ],
      ),
    );
  }
}
