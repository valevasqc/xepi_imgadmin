import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class ReceiveShipmentScreen extends StatelessWidget {
  const ReceiveShipmentScreen({super.key});

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
                Text('Recibir Mercadería', style: AppTheme.heading1),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  child: const Text('Confirmar Recepción'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildScanCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildProductsList(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(child: _buildSummaryCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppTheme.blue),
          const SizedBox(height: AppTheme.spacingL),
          Text('Escanear Código de Barras', style: AppTheme.heading2),
          const SizedBox(height: AppTheme.spacingM),
          Text('Presiona el botón para activar el escáner', style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Activar Escáner'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
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
          Text('Productos Escaneados', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildScannedProduct('Pollo Entero', 'SKU-001', 10),
          const SizedBox(height: AppTheme.spacingM),
          _buildScannedProduct('Crema 500ml', 'SKU-045', 24),
        ],
      ),
    );
  }

  Widget _buildScannedProduct(String name, String sku, int quantity) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.blue),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(sku, style: AppTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            onPressed: () {},
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusSmall,
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: Text('$quantity', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
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
          Text('Resumen de Recepción', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Destino', 'Bodega Principal'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Fecha', '21 Oct 2025'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Hora', '2:30 PM'),
          const Divider(height: AppTheme.spacingXL),
          _buildSummaryRow('Total Productos', '2'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Total Unidades', '34', highlight: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.blue : AppTheme.darkGray,
          ),
        ),
      ],
    );
  }
}
