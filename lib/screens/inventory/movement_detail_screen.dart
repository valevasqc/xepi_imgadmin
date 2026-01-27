import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';

class MovementDetailScreen extends StatefulWidget {
  final String movementId;

  const MovementDetailScreen({super.key, required this.movementId});

  @override
  State<MovementDetailScreen> createState() => _MovementDetailScreenState();
}

class _MovementDetailScreenState extends State<MovementDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _movement;
  Map<String, dynamic>? _originLocation;
  Map<String, dynamic>? _destinationLocation;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadMovement();
  }

  Future<void> _loadMovement() async {
    try {
      final movementDoc =
          await _firestore.collection('movements').doc(widget.movementId).get();

      if (!movementDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final movementData = movementDoc.data()!;

      // Load location details
      final originDoc = await _firestore
          .collection('locations')
          .doc(movementData['originLocationId'])
          .get();

      final destDoc = await _firestore
          .collection('locations')
          .doc(movementData['destinationLocationId'])
          .get();

      setState(() {
        _movement = {'id': movementDoc.id, ...movementData};
        _originLocation = originDoc.exists ? originDoc.data() : null;
        _destinationLocation = destDoc.exists ? destDoc.data() : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar traslado: $e')),
        );
      }
    }
  }

  Future<void> _sendMovement() async {
    if (_movement == null || _originLocation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Envío'),
        content: const Text(
          '¿Enviar productos desde origen? Esto deducirá el stock de la ubicación de origen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blue),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();
      final items = _movement!['items'] as List<dynamic>;
      final stockField = _originLocation!['stockField'] as String;

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
      final movementRef =
          _firestore.collection('movements').doc(widget.movementId);
      batch.update(movementRef, {
        'status': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': AuthService.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado enviado exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadMovement(); // Reload to show updated status
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _receiveMovement() async {
    if (_movement == null || _destinationLocation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Recepción'),
        content: const Text(
          '¿Confirmar recepción de productos? Esto agregará el stock a la ubicación de destino.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Recibir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();
      final items = _movement!['items'] as List<dynamic>;
      final stockField = _destinationLocation!['stockField'] as String;

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
      final movementRef =
          _firestore.collection('movements').doc(widget.movementId);
      batch.update(movementRef, {
        'status': 'received',
        'receivedAt': FieldValue.serverTimestamp(),
        'receivedBy': AuthService.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado recibido exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadMovement();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recibir traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _cancelMovement() async {
    if (_movement == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Traslado'),
        content: const Text(
          '¿Cancelar este traslado? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestore.collection('movements').doc(widget.movementId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': AuthService.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado cancelado'),
            backgroundColor: AppTheme.warning,
          ),
        );
        _loadMovement();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteMovement() async {
    if (_movement == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Traslado'),
        content: const Text(
          '¿Estás seguro de eliminar este traslado? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestore.collection('movements').doc(widget.movementId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado eliminado'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context); // Go back to history
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _editMovement() async {
    if (_movement == null || _originLocation == null) return;

    final items = List<Map<String, dynamic>>.from(_movement!['items'] as List);

    await showDialog(
      context: context,
      builder: (context) => _EditMovementDialog(
        items: items,
        originLocation: _originLocation!,
        onSave: (updatedItems) async {
          try {
            await _firestore
                .collection('movements')
                .doc(widget.movementId)
                .update({
              'items': updatedItems,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Traslado actualizado'),
                  backgroundColor: AppTheme.success,
                ),
              );
              _loadMovement();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar: $e'),
                  backgroundColor: AppTheme.danger,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _undoMovement() async {
    if (_movement == null || _originLocation == null) return;

    final status = _movement!['status'] as String;
    final isSent = status == 'sent';
    final isReceived = status == 'received';

    if (!isSent && !isReceived) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshacer Traslado'),
        content: Text(
          isSent
              ? '¿Deshacer el envío? Esto devolverá el stock al origen y cambiará el estado a "Pendiente".'
              : '¿Deshacer la recepción? Esto quitará el stock del destino y cambiará el estado a "Enviado".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();
      final items = _movement!['items'] as List<dynamic>;

      if (isSent) {
        // Undo sent: return stock to origin
        final originStockField = _originLocation!['stockField'] as String;

        for (final item in items) {
          final barcode = item['barcode'] as String;
          final quantity = item['quantity'] as int;

          final productRef = _firestore.collection('products').doc(barcode);
          batch.update(productRef, {
            originStockField: FieldValue.increment(quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update movement status back to pending
        final movementRef =
            _firestore.collection('movements').doc(widget.movementId);
        batch.update(movementRef, {
          'status': 'pending',
          'sentAt': FieldValue.delete(),
          'sentBy': FieldValue.delete(),
          'undoneAt': FieldValue.serverTimestamp(),
          'undoneBy': AuthService.currentUser?.email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (isReceived) {
        // Undo received: remove stock from destination
        if (_destinationLocation == null) return;
        final destStockField = _destinationLocation!['stockField'] as String;

        for (final item in items) {
          final barcode = item['barcode'] as String;
          final quantity = item['quantity'] as int;

          final productRef = _firestore.collection('products').doc(barcode);
          batch.update(productRef, {
            destStockField: FieldValue.increment(-quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update movement status back to sent
        final movementRef =
            _firestore.collection('movements').doc(widget.movementId);
        batch.update(movementRef, {
          'status': 'sent',
          'receivedAt': FieldValue.delete(),
          'receivedBy': FieldValue.delete(),
          'undoneAt': FieldValue.serverTimestamp(),
          'undoneBy': AuthService.currentUser?.email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traslado deshecho exitosamente'),
            backgroundColor: AppTheme.warning,
          ),
        );
        _loadMovement();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al deshacer traslado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_movement == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: Text('Traslado no encontrado')),
      );
    }

    final status = _movement!['status'] as String;
    final items = _movement!['items'] as List<dynamic>;
    final totalItems =
        items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Traslado #${widget.movementId.substring(0, 8)}',
                          style: AppTheme.heading1),
                      Text(_getStatusText(status),
                          style: AppTheme.bodySmall.copyWith(
                              color:
                                  StatusHelper.getMovementStatusColor(status))),
                    ],
                  ),
                ),
                if (status == 'pending') ...[
                  IconButton(
                    onPressed: _isProcessing ? null : _deleteMovement,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _editMovement,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  OutlinedButton(
                    onPressed: _isProcessing ? null : _cancelMovement,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _sendMovement,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isProcessing ? 'Enviando...' : 'Enviar'),
                  ),
                ],
                if (status == 'cancelled') ...[
                  IconButton(
                    onPressed: _isProcessing ? null : _deleteMovement,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                  ),
                ],
                if (status == 'sent') ...[
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _undoMovement,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Deshacer Envío'),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _receiveMovement,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(_isProcessing ? 'Recibiendo...' : 'Recibir'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success),
                  ),
                ],
                if (status == 'received') ...[
                  IconButton(
                    onPressed: _isProcessing ? null : _deleteMovement,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Eliminar',
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _undoMovement,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Deshacer'),
                  ),
                ],
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
                        _buildProductsList(items),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(child: _buildSummaryCard(totalItems)),
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
                Text('Origen',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Icon(
                      _originLocation?['type'] == 'warehouse'
                          ? Icons.warehouse_rounded
                          : Icons.store_rounded,
                      color: AppTheme.blue,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      _originLocation?['name'] ?? 'Desconocido',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            child: Icon(Icons.arrow_forward_rounded,
                color: AppTheme.blue, size: 32),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destino',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.mediumGray)),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Icon(
                      _destinationLocation?['type'] == 'warehouse'
                          ? Icons.warehouse_rounded
                          : Icons.store_rounded,
                      color: AppTheme.blue,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      _destinationLocation?['name'] ?? 'Desconocido',
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<dynamic> items) {
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
          Text('Productos (${items.length})', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: _buildProductItem(item),
              )),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
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
                Text(
                  item['name']?.isNotEmpty == true
                      ? item['name']
                      : item['warehouseCode'] ?? item['barcode'],
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  item['barcode'],
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
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
            child: Text(
              'x${item['quantity']}',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalItems) {
    final createdAt = (_movement!['createdAt'] as Timestamp?)?.toDate();
    final sentAt = (_movement!['sentAt'] as Timestamp?)?.toDate();
    final receivedAt = (_movement!['receivedAt'] as Timestamp?)?.toDate();

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
          Text('Información', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildInfoRow(Icons.person_rounded, 'Creado por',
              _movement!['createdBy'] ?? 'Desconocido'),
          const SizedBox(height: AppTheme.spacingM),
          if (createdAt != null) ...[
            _buildInfoRow(Icons.calendar_today_rounded, 'Fecha creación',
                '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
            const SizedBox(height: AppTheme.spacingM),
          ],
          if (sentAt != null) ...[
            _buildInfoRow(Icons.send_rounded, 'Enviado',
                '${sentAt.day}/${sentAt.month}/${sentAt.year}'),
            const SizedBox(height: AppTheme.spacingM),
          ],
          if (receivedAt != null) ...[
            _buildInfoRow(Icons.check_circle_rounded, 'Recibido',
                '${receivedAt.day}/${receivedAt.month}/${receivedAt.year}'),
            const SizedBox(height: AppTheme.spacingM),
          ],
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Unidades',
                  style:
                      AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray)),
              Text('$totalItems',
                  style: AppTheme.heading3.copyWith(color: AppTheme.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.mediumGray),
        const SizedBox(width: AppTheme.spacingS),
        Text('$label:',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente de envío';
      case 'sent':
        return 'Enviado - Pendiente de recepción';
      case 'received':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

class _EditMovementDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> originLocation;
  final Function(List<Map<String, dynamic>>) onSave;

  const _EditMovementDialog({
    required this.items,
    required this.originLocation,
    required this.onSave,
  });

  @override
  State<_EditMovementDialog> createState() => _EditMovementDialogState();
}

class _EditMovementDialogState extends State<_EditMovementDialog> {
  late List<Map<String, dynamic>> _editedItems;
  final Map<String, int> _maxQuantities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _editedItems =
        widget.items.map((item) => Map<String, dynamic>.from(item)).toList();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      final stockField = widget.originLocation['stockField'] as String;

      for (final item in _editedItems) {
        final barcode = item['barcode'] as String;
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(barcode)
            .get();

        if (doc.exists) {
          final currentStock = doc.data()?[stockField] as int? ?? 0;
          final currentQty = item['quantity'] as int;
          _maxQuantities[barcode] = currentStock + currentQty;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Traslado'),
      content: _isLoading
          ? const SizedBox(
              width: 300,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _editedItems.length; i++)
                      _buildItemRow(i),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSave(_editedItems);
                },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index) {
    final item = _editedItems[index];
    final barcode = item['barcode'] as String;
    final name = item['name']?.isNotEmpty == true
        ? item['name']
        : item['warehouseCode'] ?? barcode;
    final quantity = item['quantity'] as int;
    final maxQty = _maxQuantities[barcode] ?? quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: AppTheme.borderRadiusSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    barcode,
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: quantity > 1
                      ? () {
                          setState(() {
                            _editedItems[index]['quantity'] = quantity - 1;
                          });
                        }
                      : null,
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: AppTheme.borderRadiusSmall,
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Text(
                    '$quantity',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: quantity < maxQty
                      ? () {
                          setState(() {
                            _editedItems[index]['quantity'] = quantity + 1;
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger),
                  onPressed: _editedItems.length > 1
                      ? () {
                          setState(() {
                            _editedItems.removeAt(index);
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
