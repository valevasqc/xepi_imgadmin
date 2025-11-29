import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class RegisterSaleScreen extends StatelessWidget {
  const RegisterSaleScreen({super.key});

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
                Text('Registrar Venta', style: AppTheme.heading1),
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
                  child: const Text('Registrar Venta'),
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
          const Icon(Icons.store_rounded, color: AppTheme.blue, size: 32),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubicación de Venta', style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
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
                Text('Escanea los productos vendidos', style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
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
          Text('Productos en Venta', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSaleProduct('Pollo Entero', 'SKU-001', 2, 95),
          const SizedBox(height: AppTheme.spacingM),
          _buildSaleProduct('Crema 500ml', 'SKU-045', 1, 95),
        ],
      ),
    );
  }

  Widget _buildSaleProduct(String name, String sku, int quantity, int price) {
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
            child: const Icon(Icons.shopping_basket_rounded, color: AppTheme.blue),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('$sku • Q$price c/u', style: AppTheme.bodySmall),
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
          Text('Resumen de Venta', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildSummaryRow('Subtotal', 'Q285'),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Descuento', 'Q0'),
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTheme.heading3),
              Text('Q285', style: AppTheme.heading1.copyWith(color: AppTheme.blue)),
            ],
          ),
          const Divider(height: AppTheme.spacingXL),
          Text('Método de Pago', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildPaymentMethod('Efectivo', Icons.payments_rounded, true),
          const SizedBox(height: AppTheme.spacingM),
          _buildPaymentMethod('Transferencia', Icons.account_balance_rounded, false),
          const SizedBox(height: AppTheme.spacingM),
          _buildPaymentMethod('Tarjeta', Icons.credit_card_rounded, false),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
        Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPaymentMethod(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.blue.withOpacity(0.1) : AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
          border: Border.all(color: isSelected ? AppTheme.blue : AppTheme.lightGray, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.blue : AppTheme.mediumGray, size: 20),
            const SizedBox(width: AppTheme.spacingM),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.blue : AppTheme.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
