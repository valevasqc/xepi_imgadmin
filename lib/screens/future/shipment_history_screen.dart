import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/future/receive_shipment_screen.dart';
import 'package:xepi_imgadmin/screens/future/shipment_detail_screen.dart';
import 'package:xepi_imgadmin/widgets/status_filter_chips.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';

class ShipmentHistoryScreen extends StatefulWidget {
  const ShipmentHistoryScreen({super.key});

  @override
  State<ShipmentHistoryScreen> createState() => _ShipmentHistoryScreenState();
}

class _ShipmentHistoryScreenState extends State<ShipmentHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _shipments = [];
  bool _isLoading = true;
  String _statusFilter = 'all'; // all, completed, in-progress, cancelled

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all shipments and filter/sort client-side to avoid needing composite index
      final snapshot = await _firestore
          .collection('shipments')
          .orderBy('date', descending: true)
          .get();

      final allShipments = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Filter by status if needed
      final filteredShipments = _statusFilter == 'all'
          ? allShipments
          : allShipments
              .where((shipment) => shipment['status'] == _statusFilter)
              .toList();

      setState(() {
        _shipments = filteredShipments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar recepciones: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReceiveShipmentScreen(),
                      ),
                    );

                    if (result == true) {
                      _loadShipments(); // Refresh after completing shipment
                    }
                  },
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: StatusFilterChips(
                                selectedStatus: _statusFilter,
                                options: ShipmentStatusFilters.options,
                                onStatusChanged: (status) {
                                  setState(() {
                                    _statusFilter = status;
                                  });
                                  _loadShipments();
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                                vertical: AppTheme.spacingS,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: AppTheme.borderRadiusSmall,
                                border: Border.all(color: AppTheme.lightGray),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${_shipments.length} recepciones',
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  const Icon(
                                    Icons.filter_list_rounded,
                                    color: AppTheme.mediumGray,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        if (_shipments.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppTheme.spacingXXL),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: AppTheme.lightGray,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  'No hay recepciones ${_statusFilter == 'all' ? '' : _getStatusFilterLabel()}',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingS),
                                Text(
                                  _statusFilter == 'all'
                                      ? 'Crea una nueva recepción para comenzar'
                                      : 'Intenta con otro filtro',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.lightGray,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._shipments.map((shipment) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTheme.spacingM),
                              child: _buildShipmentCard(shipment),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getStatusFilterLabel() {
    switch (_statusFilter) {
      case 'completed':
        return 'completadas';
      case 'in-progress':
        return 'en progreso';
      case 'cancelled':
        return 'canceladas';
      default:
        return '';
    }
  }

  Widget _buildShipmentCard(Map<String, dynamic> shipment) {
    final status = shipment['status'] as String;
    final date = shipment['date'] as Timestamp?;
    final totalProducts = shipment['totalProducts'] ?? 0;
    final totalItems = shipment['totalItems'] ?? 0;
    final receivedByName = shipment['receivedByName'] ?? 'Usuario';

    final statusColor = StatusHelper.getShipmentStatusColor(status);
    final statusLabel = StatusHelper.getShipmentStatusLabel(status);

    final dateStr = DateFormatter.formatDate(date);
    String timeStr = '';
    if (date != null) {
      final dt = date.toDate();
      timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShipmentDetailScreen(shipmentId: shipment['id']),
          ),
        );

        if (result == true) {
          _loadShipments(); // Refresh if shipment was modified
        }
      },
      child: Container(
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
                color: statusColor.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${shipment['id'].substring(0, 8).toUpperCase()}',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTheme.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '$dateStr${timeStr.isNotEmpty ? ' • $timeStr' : ''}',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(receivedByName, style: AppTheme.bodyMedium),
                      const SizedBox(width: AppTheme.spacingL),
                      Text(
                        '$totalProducts productos • $totalItems unidades',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }
}
