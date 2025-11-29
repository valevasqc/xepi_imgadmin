import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/future/receive_shipment_screen.dart';

class ShipmentHistoryScreen extends StatelessWidget {
  const ShipmentHistoryScreen({super.key});

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
                Text('Historial de Recepciones', style: AppTheme.heading1),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReceiveShipmentScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar Nueva Recepción'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
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
                      Expanded(child: _buildFilterDropdown('Bodega Principal')),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(child: _buildFilterDropdown('Todos')),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildShipmentCard(
                    id: '#REC-142',
                    date: '21 Oct 2025',
                    time: '2:30 PM',
                    location: 'Bodega Principal',
                    products: 15,
                    units: 230,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildShipmentCard(
                    id: '#REC-141',
                    date: '20 Oct 2025',
                    time: '9:15 AM',
                    location: 'Tienda Zona 10',
                    products: 8,
                    units: 95,
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

  Widget _buildShipmentCard({
    required String id,
    required String date,
    required String time,
    required String location,
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
              color: AppTheme.blue.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppTheme.blue, size: 28),
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
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Completado',
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
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(location, style: AppTheme.bodyMedium),
                    const SizedBox(width: AppTheme.spacingL),
                    Text('$products productos • $units unidades',
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
