import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility functions for date formatting
class DateFormatter {
  /// Formats a Firestore Timestamp to "DD Mes YYYY" format
  /// Example: "2 Dic 2024"
  static String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';

    final date = timestamp.toDate();
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  /// Formats a DateTime to "DD Mes YYYY" format
  /// Example: "2 Dic 2024"
  static String formatDateTime(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  /// Formats a Firestore Timestamp to "DD Mes YYYY HH:MM" format
  /// Example: "2 Dic 2024 14:30"
  static String formatDateWithTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';

    final date = timestamp.toDate();
    final timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '${formatDateTime(date)} $timeStr';
  }

  /// Returns Spanish abbreviated month name
  static String getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month - 1];
  }

  /// Returns full Spanish month name
  static String getMonthNameFull(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  /// Returns relative time string (e.g., "Hace 2 días")
  static String getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin fecha';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Hace ${years == 1 ? '1 año' : '$years años'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Hace ${months == 1 ? '1 mes' : '$months meses'}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays == 1 ? '1 día' : '${difference.inDays} días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours == 1 ? '1 hora' : '${difference.inHours} horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes == 1 ? '1 minuto' : '${difference.inMinutes} minutos'}';
    } else {
      return 'Hace un momento';
    }
  }
}
