import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/screens/inventory/transfer_stock_screen.dart';
import 'package:xepi_imgadmin/screens/inventory/movement_detail_screen.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';
import 'package:xepi_imgadmin/widgets/status_filter_chips.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';

class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _statusFilter = 'all';

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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Historial de Movimientos', style: AppTheme.heading1),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransferStockScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo Traslado'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.orange,
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
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusFilterChips(
                    selectedStatus: _statusFilter,
                    options: MovementStatusFilters.options,
                    onStatusChanged: (status) {
                      setState(() {
                        _statusFilter = status;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Expanded(child: _buildMovementsList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList() {
    Query query = _firestore
        .collection('movements')
        .orderBy('createdAt', descending: true);

    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movements = snapshot.data?.docs ?? [];

        if (movements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz_rounded,
                    size: 64,
                    color: AppTheme.mediumGray.withValues(alpha: 0.5)),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  _statusFilter == 'all'
                      ? 'No hay movimientos registrados'
                      : 'No hay movimientos con estado $_statusFilter',
                  style:
                      AppTheme.bodyLarge.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: movements.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppTheme.spacingM),
          itemBuilder: (context, index) {
            final movement = movements[index];
            final data = movement.data() as Map<String, dynamic>;
            return _buildMovementCard(movement.id, data);
          },
        );
      },
    );
  }

  Widget _buildMovementCard(String id, Map<String, dynamic> data) {
    final status = data['status'] as String;
    final items = data['items'] as List<dynamic>;
    final totalUnits =
        items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovementDetailScreen(movementId: id),
          ),
        );
      },
      borderRadius: AppTheme.borderRadiusMedium,
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
                color: StatusHelper.getMovementStatusColor(status)
                    .withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                color: StatusHelper.getMovementStatusColor(status),
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
                      Text('#${id.substring(0, 8)}', style: AppTheme.heading3),
                      const SizedBox(width: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: StatusHelper.getMovementStatusColor(status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          StatusHelper.getMovementStatusLabel(status),
                          style: AppTheme.caption.copyWith(
                            color: StatusHelper.getMovementStatusColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  if (createdAt != null)
                    Text(
                      '${createdAt.day}/${createdAt.month}/${createdAt.year} • ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                  const SizedBox(height: AppTheme.spacingM),
                  FutureBuilder<Map<String, String>>(
                    future: _getLocationNames(data['originLocationId'],
                        data['destinationLocationId']),
                    builder: (context, snapshot) {
                      final origin = snapshot.data?['origin'] ?? 'Cargando...';
                      final destination =
                          snapshot.data?['destination'] ?? 'Cargando...';

                      return Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: AppTheme.mediumGray),
                                const SizedBox(width: AppTheme.spacingS),
                                Flexible(
                                    child: Text(origin,
                                        style: AppTheme.bodySmall)),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 16, color: AppTheme.mediumGray),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 16, color: AppTheme.mediumGray),
                                const SizedBox(width: AppTheme.spacingS),
                                Flexible(
                                    child: Text(destination,
                                        style: AppTheme.bodySmall)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '${items.length} productos • $totalUnits unidades',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (status == 'pending')
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.blue),
                tooltip: 'Enviar',
                onPressed: () => _quickSend(id, data),
              )
            else if (status == 'sent')
              IconButton(
                icon: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success),
                tooltip: 'Recibir',
                onPressed: () => _quickReceive(id, data),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }

  Future<void> _quickSend(String movementId, Map<String, dynamic> data) async {
    try {
      // Load locations
      final originDoc = await _firestore
          .collection('locations')
          .doc(data['originLocationId'])
          .get();

      if (!originDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: Ubicación de origen no encontrada')),
          );
        }
        return;
      }

      final originLocation = originDoc.data()!;
      final batch = _firestore.batch();
      final items = data['items'] as List<dynamic>;
      final stockField = originLocation['stockField'] as String;

      // Deduct stock from origin for each item
      for (final item in items) {
        final barcode = item['barcode'] as String;
        final quantity = item['quantity'] as int;

        final productRef = _firestore.collection('products').doc(barcode);
        batch.update(productRef, {
          stockField: FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update movement status
      final movementRef = _firestore.collection('movements').doc(movementId);
      batch.update(movementRef, {
        'status': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': AuthService.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado enviado exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _quickReceive(
      String movementId, Map<String, dynamic> data) async {
    try {
      // Load locations
      final destDoc = await _firestore
          .collection('locations')
          .doc(data['destinationLocationId'])
          .get();

      if (!destDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: Ubicación de destino no encontrada')),
          );
        }
        return;
      }

      final destLocation = destDoc.data()!;
      final batch = _firestore.batch();
      final items = data['items'] as List<dynamic>;
      final stockField = destLocation['stockField'] as String;

      // Add stock to destination for each item
      for (final item in items) {
        final barcode = item['barcode'] as String;
        final quantity = item['quantity'] as int;

        final productRef = _firestore.collection('products').doc(barcode);
        batch.update(productRef, {
          stockField: FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update movement status
      final movementRef = _firestore.collection('movements').doc(movementId);
      batch.update(movementRef, {
        'status': 'received',
        'receivedAt': FieldValue.serverTimestamp(),
        'receivedBy': AuthService.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado recibido exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recibir: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<Map<String, String>> _getLocationNames(
      String? originId, String? destId) async {
    try {
      final results = await Future.wait([
        if (originId != null)
          _firestore.collection('locations').doc(originId).get(),
        if (destId != null)
          _firestore.collection('locations').doc(destId).get(),
      ]);

      return {
        'origin': originId != null && results[0].exists
            ? (results[0].data()?['name'] ?? originId)
            : 'Desconocido',
        'destination': destId != null && results.length > 1 && results[1].exists
            ? (results[1].data()?['name'] ?? destId)
            : 'Desconocido',
      };
    } catch (e) {
      return {'origin': 'Error', 'destination': 'Error'};
    }
  }
}
