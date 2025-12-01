import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

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
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Pedido #1234', style: AppTheme.heading1),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  child: const Text('Cancelar Pedido'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  child: const Text('Cambiar Estado'),
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
                        _buildInfoCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildItemsCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: AppTheme.spacingL),
                        _buildTimelineCard(),
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

  Widget _buildInfoCard() {
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
          Text('Información del Cliente', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildInfoRow(Icons.person_outline_rounded, 'Cliente', 'María López'),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.phone_rounded, 'Teléfono', '5555-1234'),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.location_on_outlined, 'Dirección', 'Zona 10, Ciudad de Guatemala'),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.local_shipping_rounded, 'Entrega', 'Forza'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.mediumGray),
        const SizedBox(width: AppTheme.spacingM),
        Text('$label:', style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
        const SizedBox(width: AppTheme.spacingS),
        Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemsCard() {
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
          Text('Productos', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildOrderItem('Pollo Entero', 2, 95, 190),
          const Divider(height: AppTheme.spacingL),
          _buildOrderItem('Crema 500ml', 1, 95, 95),
          const Divider(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTheme.heading3),
              Text('Q285', style: AppTheme.heading2.copyWith(color: AppTheme.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, int quantity, int price, int total) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: const Icon(Icons.shopping_basket_rounded, color: AppTheme.mediumGray),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text('Q$price c/u', style: AppTheme.bodySmall),
            ],
          ),
        ),
        Text('x$quantity', style: AppTheme.bodyMedium),
        const SizedBox(width: AppTheme.spacingL),
        Text('Q$total', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text('Estado Actual', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: AppTheme.borderRadiusMedium,
            ),
            child: Column(
              children: [
                const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppTheme.danger),
                const SizedBox(height: AppTheme.spacingM),
                Text('Pendiente', style: AppTheme.heading2.copyWith(color: AppTheme.danger)),
                const SizedBox(height: AppTheme.spacingS),
                Text('En espera de confirmación', style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
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
          Text('Historial', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildTimelineItem('Pedido creado', '21 Oct, 2:30 PM', true),
          _buildTimelineItem('En preparación', '21 Oct, 3:00 PM', false),
          _buildTimelineItem('Listo para entrega', '21 Oct, 4:00 PM', false),
          _buildTimelineItem('Entregado', '21 Oct, 5:00 PM', false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String time, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.blue : AppTheme.lightGray,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodyMedium.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppTheme.darkGray : AppTheme.mediumGray,
                )),
                Text(time, style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
