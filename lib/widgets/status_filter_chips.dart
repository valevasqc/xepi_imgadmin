import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Reusable filter chips for status filtering
/// Used in history screens (shipments, movements, orders, sales)
class StatusFilterChips extends StatelessWidget {
  final String selectedStatus;
  final List<StatusFilterOption> options;
  final ValueChanged<String> onStatusChanged;

  const StatusFilterChips({
    super.key,
    required this.selectedStatus,
    required this.options,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.spacingM,
      runSpacing: AppTheme.spacingS,
      children: options.map((option) {
        return _buildFilterChip(option);
      }).toList(),
    );
  }

  Widget _buildFilterChip(StatusFilterOption option) {
    final isSelected = selectedStatus == option.value;
    return FilterChip(
      label: Text(option.label),
      selected: isSelected,
      onSelected: (selected) {
        onStatusChanged(option.value);
      },
      selectedColor: AppTheme.blue.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.blue,
      backgroundColor: AppTheme.white,
      side: BorderSide(
        color: isSelected ? AppTheme.blue : AppTheme.lightGray,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.blue : AppTheme.darkGray,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      showCheckmark: true,
    );
  }
}

/// Option for status filter
class StatusFilterOption {
  final String label;
  final String value;

  const StatusFilterOption({
    required this.label,
    required this.value,
  });
}

/// Predefined filter options for different contexts

/// Shipment status filters
class ShipmentStatusFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const completed =
      StatusFilterOption(label: 'Completados', value: 'completed');
  static const inProgress =
      StatusFilterOption(label: 'En progreso', value: 'in-progress');
  static const cancelled =
      StatusFilterOption(label: 'Cancelados', value: 'cancelled');

  static const List<StatusFilterOption> options = [
    all,
    completed,
    inProgress,
    cancelled,
  ];
}

/// Movement status filters
class MovementStatusFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const pending =
      StatusFilterOption(label: 'Pendientes', value: 'pending');
  static const sent = StatusFilterOption(label: 'Enviados', value: 'sent');
  static const received =
      StatusFilterOption(label: 'Completados', value: 'received');
  static const cancelled =
      StatusFilterOption(label: 'Cancelados', value: 'cancelled');

  static const List<StatusFilterOption> options = [
    all,
    pending,
    sent,
    received,
    cancelled,
  ];
}

/// Order status filters (Future Phase 2B)
class OrderStatusFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const pending =
      StatusFilterOption(label: 'Pendientes', value: 'pending');
  static const preparing =
      StatusFilterOption(label: 'Preparando', value: 'preparing');
  static const ready = StatusFilterOption(label: 'Listos', value: 'ready');
  static const shipped =
      StatusFilterOption(label: 'Enviados', value: 'shipped');
  static const delivered =
      StatusFilterOption(label: 'Entregados', value: 'delivered');
  static const completed =
      StatusFilterOption(label: 'Completados', value: 'completed');
  static const cancelled =
      StatusFilterOption(label: 'Cancelados', value: 'cancelled');

  static const List<StatusFilterOption> options = [
    all,
    pending,
    preparing,
    ready,
    shipped,
    delivered,
    completed,
    cancelled,
  ];
}

/// Payment status filters (Future Phase 2B)
class PaymentStatusFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const pendingApproval =
      StatusFilterOption(label: 'Pendientes', value: 'pending_approval');
  static const approved =
      StatusFilterOption(label: 'Aprobados', value: 'approved');
  static const rejected =
      StatusFilterOption(label: 'Rechazados', value: 'rejected');

  static const List<StatusFilterOption> options = [
    all,
    pendingApproval,
    approved,
    rejected,
  ];
}

/// Sale type filters for sales
class SaleTypeFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const kiosko = StatusFilterOption(label: 'Kiosko', value: 'kiosko');
  static const delivery =
      StatusFilterOption(label: 'Envíos', value: 'delivery');

  static const List<StatusFilterOption> options = [
    all,
    kiosko,
    delivery,
  ];
}

/// Payment method filters for sales
class PaymentMethodFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const efectivo =
      StatusFilterOption(label: 'Efectivo', value: 'efectivo');
  static const transferencia =
      StatusFilterOption(label: 'Transferencia', value: 'transferencia');
  static const tarjeta = StatusFilterOption(label: 'Tarjeta', value: 'tarjeta');

  static const List<StatusFilterOption> options = [
    all,
    efectivo,
    transferencia,
    tarjeta,
  ];
}

/// Delivery status filters for sales
class DeliveryStatusFilters {
  static const all = StatusFilterOption(label: 'Todos', value: 'all');
  static const pending =
      StatusFilterOption(label: 'Pendientes', value: 'pending');
  static const pickedUp =
      StatusFilterOption(label: 'Recogidos', value: 'picked_up');
  static const delivered =
      StatusFilterOption(label: 'Entregados', value: 'delivered');
  static const completed =
      StatusFilterOption(label: 'Completados', value: 'completed');
  static const anulado =
      StatusFilterOption(label: 'Anulados', value: 'anulado');

  static const List<StatusFilterOption> options = [
    all,
    pending,
    pickedUp,
    delivered,
    completed,
    anulado,
  ];
}
