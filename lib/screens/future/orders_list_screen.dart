import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

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
                Text('Pedidos', style: AppTheme.heading1),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función próximamente')),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo Pedido'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildFilterDropdown('Todos')),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(child: _buildFilterDropdown('Fecha')),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(child: _buildFilterDropdown('Cliente')),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildStatusTabs(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildOrderCard(
                    orderNumber: '#1234',
                    customer: 'María López',
                    phone: '5555-1234',
                    items: 3,
                    total: 285,
                    delivery: 'Forza',
                    status: 'Pendiente',
                    statusColor: AppTheme.danger,
                    date: '21 Oct, 2:30 PM',
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildOrderCard(
                    orderNumber: '#1233',
                    customer: 'Juan Pérez',
                    phone: '5555-5678',
                    items: 1,
                    total: 99,
                    delivery: 'Messenger',
                    status: 'Listo',
                    statusColor: AppTheme.success,
                    date: '21 Oct, 11:15 AM',
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

  Widget _buildStatusTabs() {
    return Row(
      children: [
        _buildTab('Pendiente', true),
        const SizedBox(width: AppTheme.spacingS),
        _buildTab('Preparando', false),
        const SizedBox(width: AppTheme.spacingS),
        _buildTab('Listo', false),
        const SizedBox(width: AppTheme.spacingS),
        _buildTab('Completado', false),
      ],
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.blue : AppTheme.white,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          color: isSelected ? AppTheme.white : AppTheme.darkGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderNumber,
    required String customer,
    required String phone,
    required int items,
    required int total,
    required String delivery,
    required String status,
    required Color statusColor,
    required String date,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(orderNumber, style: AppTheme.heading3),
                    const SizedBox(width: AppTheme.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: AppTheme.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(date, style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(customer, style: AppTheme.bodyMedium),
                    const SizedBox(width: AppTheme.spacingL),
                    const Icon(Icons.phone_rounded, size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(phone, style: AppTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Text('$items items • Q$total', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppTheme.spacingL),
                    const Icon(Icons.local_shipping_rounded, size: 16, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(delivery, style: AppTheme.bodySmall),
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
