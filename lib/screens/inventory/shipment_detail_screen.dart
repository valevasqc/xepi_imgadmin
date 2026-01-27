import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';
import 'package:xepi_imgadmin/screens/inventory/receive_shipment_screen.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;

  const ShipmentDetailScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _shipment;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  Future<void> _loadShipment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await _firestore.collection('shipments').doc(widget.shipmentId).get();

      if (!doc.exists) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recepción no encontrada'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      setState(() {
        _shipment = {
          'id': doc.id,
          ...doc.data()!,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar recepción: $e'),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_shipment == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundGray,
        body: Center(child: Text('Recepción no encontrada')),
      );
    }

    final status = _shipment!['status'] as String;
    final items = _shipment!['items'] as List<dynamic>? ?? [];
    final totalProducts = _shipment!['totalProducts'] ?? 0;
    final totalItems = _shipment!['totalItems'] ?? 0;
    final receivedByName = _shipment!['receivedByName'] ?? 'Usuario';

    final statusColor = StatusHelper.getShipmentStatusColor(status);
    final statusLabel = StatusHelper.getShipmentStatusLabel(status);

    final shipmentDate = _shipment!['date'] as Timestamp?;
    final dateStr = DateFormatter.formatDate(shipmentDate);
    String timeStr = '';
    if (shipmentDate != null) {
      final dt = shipmentDate.toDate();
      timeStr = '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
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
                Text(
                  'Detalle de Recepción',
                  style: AppTheme.heading1,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTheme.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (status == 'in-progress')
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _editShipment(),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                  ),
                if (status == 'completed')
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _undoShipment(),
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Deshacer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                    ),
                  ),
                if (status == 'cancelled') ...[
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _editShipment(),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _recompleteShipment(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Re-completar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                  ),
                ],
                const SizedBox(width: AppTheme.spacingM),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _isProcessing ? null : () => _deleteShipment(),
                  color: AppTheme.danger,
                  tooltip: 'Eliminar recepción',
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
                    child: _buildProductsList(items),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: _buildInfoCard(
                      dateStr,
                      timeStr,
                      receivedByName,
                      totalProducts,
                      totalItems,
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

  Widget _buildInfoCard(
    String dateStr,
    String timeStr,
    String receivedByName,
    int totalProducts,
    int totalItems,
  ) {
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
          Text('Información de Recepción', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          _buildInfoRow(
              'ID', '#${_shipment!['id'].substring(0, 8).toUpperCase()}'),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow('Fecha', dateStr),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow('Hora', timeStr),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow('Recibido por', receivedByName),
          const Divider(height: AppTheme.spacingXL),
          _buildInfoRow('Total Productos', '$totalProducts'),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow('Total Unidades', '$totalItems', highlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.blue : AppTheme.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList(List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: AppTheme.borderRadiusMedium,
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: Text('No hay productos en esta recepción'),
        ),
      );
    }

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
          Row(
            children: [
              Text('Productos Recibidos', style: AppTheme.heading3),
              const Spacer(),
              Text(
                '${items.length} productos',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: _buildProductItem(item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final images = item['images'] as List<dynamic>? ?? [];
    final barcode = item['barcode'] ?? '';
    final productName = item['productName'] ?? '';
    final warehouseCode = item['warehouseCode'] ?? '';
    final displayName = productName.isNotEmpty
        ? productName
        : (warehouseCode.isNotEmpty ? warehouseCode : 'Sin nombre');
    final quantity = item['quantity'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: images.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        color: AppTheme.blue,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.blue,
                  ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style:
                      AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  barcode,
                  style:
                      AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppTheme.blue.withOpacity(0.1),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Text(
              'x$quantity',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editShipment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReceiveShipmentScreen(shipmentId: widget.shipmentId),
      ),
    );

    if (result == true) {
      _loadShipment(); // Reload data
      if (mounted) {
        Navigator.pop(context, true); // Return to history
      }
    }
  }

  Future<void> _undoShipment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deshacer Recepción'),
        content: const Text(
          'Esto revertirá el stock de todos los productos. La recepción quedará marcada como cancelada.',
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

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();
      final items = _shipment!['items'] as List<dynamic>;

      // Reverse stock changes
      for (var item in items) {
        final barcode = item['barcode'] as String;
        final quantity = item['quantity'] as int;

        final productRef = _firestore.collection('products').doc(barcode);
        batch.update(productRef, {
          'stockWarehouse': FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update shipment status
      final shipmentRef =
          _firestore.collection('shipments').doc(widget.shipmentId);
      batch.update(shipmentRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción deshecha exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadShipment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al deshacer recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _recompleteShipment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-completar Recepción'),
        content: const Text(
          'Esto volverá a aplicar los cambios de stock de todos los productos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Re-completar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();
      final items = _shipment!['items'] as List<dynamic>;

      // Apply stock changes again
      for (var item in items) {
        final barcode = item['barcode'] as String;
        final quantity = item['quantity'] as int;

        final productRef = _firestore.collection('products').doc(barcode);
        batch.update(productRef, {
          'stockWarehouse': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update shipment status
      final shipmentRef =
          _firestore.collection('shipments').doc(widget.shipmentId);
      batch.update(shipmentRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción re-completada exitosamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadShipment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al re-completar recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deleteShipment() async {
    final status = _shipment!['status'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Recepción'),
        content: Text(
          status == 'completed'
              ? 'Esto revertirá el stock de todos los productos antes de eliminar la recepción. Esta acción no se puede deshacer. ¿Estás seguro?'
              : 'Esta acción no se puede deshacer. ¿Estás seguro?',
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

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final batch = _firestore.batch();

      // If shipment is completed, revert stock changes before deleting
      if (status == 'completed') {
        final items = _shipment!['items'] as List<dynamic>;

        for (var item in items) {
          final barcode = item['barcode'] as String;
          final quantity = item['quantity'] as int;

          final productRef = _firestore.collection('products').doc(barcode);
          batch.update(productRef, {
            'stockWarehouse': FieldValue.increment(-quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Delete shipment
      final shipmentRef =
          _firestore.collection('shipments').doc(widget.shipmentId);
      batch.delete(shipmentRef);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción eliminada'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true); // Return to history
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar recepción: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
