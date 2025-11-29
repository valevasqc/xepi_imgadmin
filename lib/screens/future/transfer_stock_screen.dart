import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class TransferStockScreen extends StatelessWidget {
  const TransferStockScreen({super.key});

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
                Text('Trasladar Inventario', style: AppTheme.heading1),
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
                  child: const Text('Confirmar Traslado'),
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
                        _buildLocationCard(),
                        const SizedBox(height: AppTheme.spacingL),
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

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Origen', style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                _buildLocationDropdown('Bodega Principal'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Icon(Icons.arrow_forward_rounded, color: AppTheme.blue, size: 32),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destino', style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                _buildLocationDropdown('Tienda Zona 10'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 20, color: AppTheme.blue),
          const SizedBox(width: AppTheme.spacingS),
          Text(label, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.mediumGray),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppTheme.blue),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Escanear Productos', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingS),
                Text('Activa el escáner para agregar productos al traslado', 
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Escanear'),
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
          Text('Productos para Trasladar', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildTransferProduct('Pollo Entero', 'SKU-001', 15, 25),
          const SizedBox(height: AppTheme.spacingM),
          _buildTransferProduct('Crema 500ml', 'SKU-045', 10, 50),
        ],
      ),
    );
  }

  Widget _buildTransferProduct(String name, String sku, int quantity, int available) {
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
                Text('$sku • Disponible: $available', style: AppTheme.bodySmall),
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
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {},
            color: AppTheme.danger,
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
          Text('Resumen de Traslado', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow(Icons.location_on_outlined, 'Origen', 'Bodega Principal'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(Icons.location_on_rounded, 'Destino', 'Tienda Zona 10'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(Icons.calendar_today_rounded, 'Fecha', '21 Oct 2025'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow(Icons.access_time_rounded, 'Hora', '2:30 PM'),
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Productos', style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
              Text('2', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Unidades', style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
              Text('25', style: AppTheme.heading3.copyWith(color: AppTheme.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.mediumGray),
        const SizedBox(width: AppTheme.spacingS),
        Text('$label:', style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
        const Spacer(),
        Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
