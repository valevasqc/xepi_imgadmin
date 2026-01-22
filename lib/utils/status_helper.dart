import 'package:flutter/material.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

/// Utility functions for status labels and colors across the app
class StatusHelper {
  // ========== Movement Status ==========

  /// Returns Spanish label for movement status
  static String getMovementStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'sent':
        return 'Enviado';
      case 'received':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  /// Returns color for movement status
  static Color getMovementStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'sent':
        return AppTheme.blue;
      case 'received':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.mediumGray;
    }
  }

  // ========== Shipment Status ==========

  /// Returns Spanish label for shipment status
  static String getShipmentStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'in-progress':
        return 'En progreso';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  /// Returns color for shipment status
  static Color getShipmentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'in-progress':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.mediumGray;
    }
  }

  // ========== Order Status (Future Phase 2B) ==========

  /// Returns Spanish label for order status
  static String getOrderStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'Preparando';
      case 'ready':
        return 'Listo';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'paid':
        return 'Pagado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  /// Returns color for order status
  static Color getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'preparing':
        return AppTheme.warning;
      case 'ready':
      case 'shipped':
        return AppTheme.blue;
      case 'delivered':
      case 'paid':
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.mediumGray;
    }
  }

  // ========== Payment Status (Future Phase 2B) ==========

  /// Returns Spanish label for payment status
  static String getPaymentStatusLabel(String status) {
    switch (status) {
      case 'pending_approval':
        return 'Pendiente Aprobación';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  /// Returns color for payment status
  static Color getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return AppTheme.warning;
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.danger;
      default:
        return AppTheme.mediumGray;
    }
  }

  // ========== Stock Status ==========

  /// Returns Spanish label and color for stock level
  static ({String label, Color color}) getStockStatus(int stock) {
    if (stock == 0) {
      return (label: 'Sin stock', color: AppTheme.mediumGray);
    } else if (stock < 3) {
      return (label: 'Crítico', color: AppTheme.danger);
    } else if (stock < 10) {
      return (label: 'Bajo', color: AppTheme.warning);
    } else {
      return (label: 'Disponible', color: AppTheme.success);
    }
  }

  // ========== Delivery Status ==========

  /// Returns Spanish label for delivery status
  static String getDeliveryStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'picked_up':
        return 'Recogido';
      case 'delivered':
        return 'Entregado';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  /// Returns color for delivery status
  static Color getDeliveryStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'picked_up':
        return AppTheme.blue;
      case 'delivered':
      case 'completed':
        return AppTheme.success;
      default:
        return AppTheme.mediumGray;
    }
  }
}
