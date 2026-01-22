import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/services/auth_service.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({
    super.key,
    required this.saleId,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _saleData;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSaleData();
  }

  Future<void> _loadSaleData() async {
    setState(() => _isLoading = true);

    try {
      // Load from Firestore
      final doc = await _firestore.collection('sales').doc(widget.saleId).get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _saleData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _saleData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar venta: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDeliveryStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      final updates = <String, dynamic>{
        'deliveryStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle moving forward
      if (newStatus == 'picked_up') {
        updates['pickedUpAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('sales').doc(widget.saleId).update(updates);
      } else if (newStatus == 'delivered') {
        // Ensure pickedUpAt exists when jumping to delivered
        if (_saleData!['pickedUpAt'] == null) {
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
        }
        updates['deliveredAt'] = FieldValue.serverTimestamp();

        // When delivered, deduct stock if it was in_transit
        final stockStatus = _saleData!['stockStatus'] as String?;
        final paymentMethod = _saleData!['paymentMethod'] as String?;
        final saleType = _saleData!['saleType'] as String?;
        final deliveryMethod = _saleData!['deliveryMethod'] as String?;

        if (stockStatus == 'in_transit') {
          final batch = _firestore.batch();

          // Update sale to completed stock status
          batch.update(
            _firestore.collection('sales').doc(widget.saleId),
            {...updates, 'stockStatus': 'completed'},
          );

          // Deduct stock from products
          final deductFrom = _saleData!['deductFrom'] as String? ?? 'store';
          final stockField =
              deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';
          final items = _saleData!['items'] as List<dynamic>;

          for (var item in items) {
            final barcode = item['barcode'] as String;
            final quantity = item['quantity'] as int;
            final productRef = _firestore.collection('products').doc(barcode);

            batch.update(productRef, {
              stockField: FieldValue.increment(-quantity),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Add to pending cash if efectivo delivery sale
          if (paymentMethod == 'efectivo' && saleType == 'delivery') {
            String cashSource;
            if (deliveryMethod == 'mensajero') {
              cashSource = 'mensajero';
            } else if (deliveryMethod == 'forza') {
              cashSource = 'forza';
            } else {
              // Default to store if delivery method is missing
              cashSource = 'store';
            }

            final pendingCashRef =
                _firestore.collection('pendingCash').doc(cashSource);
            final total = (_saleData!['total'] as num?)?.toDouble() ?? 0.0;

            batch.set(
              pendingCashRef,
              {
                'source': cashSource,
                'amount': FieldValue.increment(total),
                'saleIds': FieldValue.arrayUnion([widget.saleId]),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }

          await batch.commit();
        } else {
          await _firestore
              .collection('sales')
              .doc(widget.saleId)
              .update(updates);
        }
      } else if (newStatus == 'completed') {
        // Ensure timestamps exist when jumping to completed
        if (_saleData!['pickedUpAt'] == null) {
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
        }
        if (_saleData!['deliveredAt'] == null) {
          updates['deliveredAt'] = FieldValue.serverTimestamp();
        }
        updates['completedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('sales').doc(widget.saleId).update(updates);
      } else if (newStatus == 'pending') {
        // Moving back to pending - clear all timestamps and restore stock if needed
        updates['pickedUpAt'] = null;
        updates['deliveredAt'] = null;
        updates['completedAt'] = null;

        final stockStatus = _saleData!['stockStatus'] as String?;
        final paymentMethod = _saleData!['paymentMethod'] as String?;
        final saleType = _saleData!['saleType'] as String?;
        final deliveryMethod = _saleData!['deliveryMethod'] as String?;

        if (stockStatus == 'completed') {
          final batch = _firestore.batch();

          batch.update(
            _firestore.collection('sales').doc(widget.saleId),
            {...updates, 'stockStatus': 'in_transit'},
          );

          // Restore stock
          final deductFrom = _saleData!['deductFrom'] as String? ?? 'store';
          final stockField =
              deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';
          final items = _saleData!['items'] as List<dynamic>;

          for (var item in items) {
            final barcode = item['barcode'] as String;
            final quantity = item['quantity'] as int;
            final productRef = _firestore.collection('products').doc(barcode);

            batch.update(productRef, {
              stockField: FieldValue.increment(quantity),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // Remove from pending cash if efectivo delivery sale
          if (paymentMethod == 'efectivo' && saleType == 'delivery') {
            String cashSource;
            if (deliveryMethod == 'mensajero') {
              cashSource = 'mensajero';
            } else if (deliveryMethod == 'forza') {
              cashSource = 'forza';
            } else {
              cashSource = 'store';
            }

            final pendingCashRef =
                _firestore.collection('pendingCash').doc(cashSource);
            final total = (_saleData!['total'] as num?)?.toDouble() ?? 0.0;

            batch.update(pendingCashRef, {
              'amount': FieldValue.increment(-total),
              'saleIds': FieldValue.arrayRemove([widget.saleId]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
        } else {
          await _firestore
              .collection('sales')
              .doc(widget.saleId)
              .update(updates);
        }
      } else {
        await _firestore.collection('sales').doc(widget.saleId).update(updates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    newStatus == 'picked_up'
                        ? 'Pedido marcado como recogido'
                        : newStatus == 'delivered'
                            ? 'Pedido entregado y stock actualizado'
                            : 'Pedido marcado como completado',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadSaleData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _approvePayment() async {
    if (!AuthService.isSuperuser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el superusuario puede aprobar pagos'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Update Firestore
      await _firestore.collection('sales').doc(widget.saleId).update({
        'paymentVerified': true,
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(child: Text('Pago aprobado exitosamente')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadSaleData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar pago: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteSale() async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: const Text(
          '¿Estás seguro de eliminar esta venta? Esta acción no se puede deshacer.\n\n'
          'Se restaurará el stock y se eliminará de efectivo pendiente si aplica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final batch = _firestore.batch();
      final saleRef = _firestore.collection('sales').doc(widget.saleId);

      // Restore stock if it was deducted
      final stockStatus = _saleData!['stockStatus'] as String?;
      if (stockStatus == 'completed') {
        final deductFrom = _saleData!['deductFrom'] as String? ?? 'store';
        final stockField =
            deductFrom == 'store' ? 'stockStore' : 'stockWarehouse';
        final items = _saleData!['items'] as List<dynamic>;

        for (var item in items) {
          final barcode = item['barcode'] as String;
          final quantity = item['quantity'] as int;
          final productRef = _firestore.collection('products').doc(barcode);

          batch.update(productRef, {
            stockField: FieldValue.increment(quantity), // Add back
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Remove from pending cash if efectivo
      final paymentMethod = _saleData!['paymentMethod'] as String?;
      final status = _saleData!['status'] as String?;
      if (paymentMethod == 'efectivo' && status == 'approved') {
        final saleType = _saleData!['saleType'] as String?;
        final deliveryMethod = _saleData!['deliveryMethod'] as String?;

        String cashSource;
        if (saleType == 'kiosko') {
          cashSource = 'store';
        } else if (deliveryMethod == 'mensajero') {
          cashSource = 'mensajero';
        } else {
          cashSource = 'forza';
        }

        final pendingCashRef =
            _firestore.collection('pendingCash').doc(cashSource);
        final total = _saleData!['total'] ?? 0.0;

        batch.update(pendingCashRef, {
          'amount': FieldValue.increment(-total),
          'saleIds': FieldValue.arrayRemove([widget.saleId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Delete the sale
      batch.delete(saleRef);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(child: Text('Venta eliminada exitosamente')),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar venta: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.blue),
              title: const Text('Editar Venta'),
              subtitle:
                  const Text('Modificar productos, cantidades o detalles'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de edición en desarrollo'),
                    backgroundColor: AppTheme.blue,
                  ),
                );
              },
            ),
            const Divider(),
            if (_saleData!['saleType'] == 'delivery')
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded,
                    color: AppTheme.warning),
                title: const Text('Cambiar Estado'),
                subtitle: const Text('Modificar estado de entrega'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeStatusDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppTheme.danger),
              title: const Text('Eliminar Venta'),
              subtitle: const Text('Restaurar stock y eliminar registro'),
              onTap: () {
                Navigator.pop(context);
                _deleteSale();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog() {
    final currentStatus = _saleData!['deliveryStatus'] as String? ?? 'pending';
    String? selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar Estado de Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado actual: ${_getStatusLabel(currentStatus)}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Estado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        const Text('Pendiente'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'picked_up',
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        const Text('Recogido'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        const Text('Entregado'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        const Text('Completado'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == currentStatus
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updateDeliveryStatus(selectedStatus!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundGray,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Detalle de Venta', style: AppTheme.heading1),
                const Spacer(),
                if (!_isLoading && _saleData != null)
                  IconButton(
                    onPressed: _isProcessing ? null : _showActionsMenu,
                    icon: const Icon(Icons.more_vert_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.blue.withOpacity(0.1),
                      foregroundColor: AppTheme.blue,
                    ),
                    tooltip: 'Acciones',
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _saleData == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppTheme.mediumGray.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Text(
                              'Venta no encontrada',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(),
                            const SizedBox(height: AppTheme.spacingL),
                            _buildItemsCard(),
                            const SizedBox(height: AppTheme.spacingL),
                            _buildTotalCard(),
                            if (_saleData!['depositId'] != null) ...[
                              const SizedBox(height: AppTheme.spacingL),
                              _buildDepositCard(),
                            ],
                            if (_saleData!['saleType'] == 'delivery') ...[
                              const SizedBox(height: AppTheme.spacingL),
                              _buildDeliveryCard(),
                            ],
                            if (_saleData!['status'] == 'pending_approval' &&
                                AuthService.isSuperuser) ...[
                              const SizedBox(height: AppTheme.spacingL),
                              _buildApprovalCard(),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final saleType = _saleData!['saleType'] as String;
    final paymentMethod = _saleData!['paymentMethod'] as String;
    final date = _saleData!['createdAt'] as Timestamp?;
    final status = _saleData!['status'] as String;
    final paymentVerified = _saleData!['paymentVerified'] as bool;

    final Color statusColor;
    final String statusLabel;

    if (status == 'pending_approval') {
      statusColor = AppTheme.warning;
      statusLabel = 'Pendiente Aprobación';
    } else if (!paymentVerified) {
      statusColor = AppTheme.danger;
      statusLabel = 'No Verificado';
    } else {
      statusColor = AppTheme.success;
      statusLabel = 'Completado';
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
              Text(widget.saleId, style: AppTheme.heading2),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Fecha',
            date != null
                ? DateFormatter.formatDateWithTime(date)
                : 'Fecha no disponible',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            saleType == 'delivery'
                ? Icons.local_shipping_rounded
                : Icons.store_rounded,
            'Tipo de Venta',
            saleType == 'delivery'
                ? 'Delivery (${_saleData!['deliveryMethod'] == 'mensajero' ? 'Mensajero' : 'Forza'})'
                : 'Tienda',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            _getPaymentIcon(paymentMethod),
            'Método de Pago',
            _getPaymentLabel(paymentMethod),
          ),
          if (_saleData!['customerName'] != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(
              Icons.person_rounded,
              'Cliente',
              _saleData!['customerName'] as String,
            ),
          ],
          if (_saleData!['customerPhone'] != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(
              Icons.phone_rounded,
              'Teléfono',
              _saleData!['customerPhone'] as String,
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            Icons.receipt_long_rounded,
            'NIT',
            _saleData!['nit'] as String,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.mediumGray),
        const SizedBox(width: AppTheme.spacingM),
        Text(
          '$label:',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard() {
    final items = _saleData!['items'] as List<dynamic>;

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
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            final isLast = entry.key == items.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Código: ${item['barcode']}',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'x${item['quantity']}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        Text(
                          'Q${(item['unitPrice'] as num).toDouble().toStringAsFixed(2)}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    Text(
                      'Q${(item['subtotal'] as num).toDouble().toStringAsFixed(2)}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacingL),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final subtotal = (_saleData!['subtotal'] as num).toDouble();
    final discount = (_saleData!['discount'] as num).toDouble();
    final total = (_saleData!['total'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', subtotal),
          if (discount > 0) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildTotalRow('Descuento', -discount, isDiscount: true),
          ],
          const Divider(height: AppTheme.spacingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTheme.heading3),
              Text(
                'Q${total.toStringAsFixed(2)}',
                style: AppTheme.heading2.copyWith(color: AppTheme.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
        ),
        Text(
          '${isDiscount ? '-' : ''}Q${value.abs().toStringAsFixed(2)}',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppTheme.danger : AppTheme.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildDepositCard() {
    final depositId = _saleData!['depositId'] as String?;

    if (depositId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('deposits').doc(depositId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final depositData = snapshot.data!.data() as Map<String, dynamic>;
        final comprobanteUrl = depositData['comprobanteUrl'] as String?;
        final depositedAt = depositData['depositedAt'] as Timestamp?;
        final notes = depositData['notes'] as String?;
        final source = depositData['source'] as String?;

        String sourceName = 'Desconocido';
        IconData sourceIcon = Icons.payment_rounded;

        switch (source) {
          case 'store':
            sourceName = 'Tienda';
            sourceIcon = Icons.store_rounded;
            break;
          case 'mensajero':
            sourceName = 'Mensajero';
            sourceIcon = Icons.delivery_dining_rounded;
            break;
          case 'forza':
            sourceName = 'Forza';
            sourceIcon = Icons.local_shipping_rounded;
            break;
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
                  const Icon(Icons.account_balance_rounded,
                      color: AppTheme.success, size: 24),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Información de Depósito', style: AppTheme.heading3),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Icon(sourceIcon, size: 20, color: AppTheme.mediumGray),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    'Origen:',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    sourceName,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (depositedAt != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 20, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingM),
                    Text(
                      'Depositado:',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.mediumGray),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      DateFormatter.formatDateWithTime(depositedAt),
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_rounded,
                        size: 20, color: AppTheme.mediumGray),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Text(
                        notes,
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (comprobanteUrl != null) ...[
                const SizedBox(height: AppTheme.spacingL),
                ElevatedButton.icon(
                  onPressed: () => _showComprobanteDialog(comprobanteUrl),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Ver Comprobante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showComprobanteDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppTheme.blue),
                  const SizedBox(width: AppTheme.spacingM),
                  Text('Comprobante de Depósito', style: AppTheme.heading3),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXXL),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(AppTheme.spacingXXL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: AppTheme.danger),
                        SizedBox(height: AppTheme.spacingM),
                        Text('Error al cargar imagen'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    final deliveryStatus = _saleData!['deliveryStatus'] as String?;
    final deliveryAddress = _saleData!['deliveryAddress'] as String?;
    final deliveryMethod = _saleData!['deliveryMethod'] as String?;
    final pickedUpAt = _saleData!['pickedUpAt'] as Timestamp?;
    final deliveredAt = _saleData!['deliveredAt'] as Timestamp?;
    final stockStatus = _saleData!['stockStatus'] as String?;

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
          Text('Información de Entrega', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Icon(
                deliveryMethod == 'mensajero'
                    ? Icons.moped_rounded
                    : Icons.local_shipping_rounded,
                size: 20,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                deliveryMethod == 'mensajero' ? 'Mensajero' : 'Forza',
                style:
                    AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 20, color: AppTheme.mediumGray),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  deliveryAddress ?? 'No especificada',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Text(
                'Estado:',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: _getDeliveryStatusColor(deliveryStatus ?? 'pending')
                      .withValues(alpha: 0.1),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Text(
                  _getDeliveryStatusLabel(deliveryStatus ?? 'pending'),
                  style: AppTheme.bodyMedium.copyWith(
                    color: _getDeliveryStatusColor(deliveryStatus ?? 'pending'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (pickedUpAt != null || deliveredAt != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            const Divider(),
            const SizedBox(height: AppTheme.spacingL),
          ],
          if (pickedUpAt != null) ...[
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 18, color: AppTheme.mediumGray),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Recogido: ${DateFormatter.formatDateWithTime(pickedUpAt)}',
                  style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
          if (deliveredAt != null) ...[
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 18, color: AppTheme.mediumGray),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Entregado: ${DateFormatter.formatDateWithTime(deliveredAt)}',
                  style: AppTheme.caption.copyWith(color: AppTheme.mediumGray),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
          if (stockStatus == 'in_transit') ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppTheme.warning),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Stock en tránsito - Se deducirá al marcar como entregado',
                      style: AppTheme.caption.copyWith(color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingL),
          Wrap(
            spacing: AppTheme.spacingM,
            runSpacing: AppTheme.spacingM,
            children: [
              if (deliveryStatus == 'pending')
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateDeliveryStatus('picked_up'),
                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                  label: const Text('Marcar Recogido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.white,
                  ),
                ),
              if (deliveryStatus == 'picked_up')
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateDeliveryStatus('delivered'),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Marcar Entregado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: AppTheme.white,
                  ),
                ),
              if (deliveryStatus == 'delivered')
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _updateDeliveryStatus('completed'),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Marcar Completado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: AppTheme.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: AppTheme.warning),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Aprobación de Pago Pendiente',
                style: AppTheme.heading3.copyWith(color: AppTheme.warning),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Esta venta requiere verificación de pago (${_getPaymentLabel(_saleData!['paymentMethod'] as String)}). '
            'Confirma que el pago ha sido recibido antes de aprobar.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _approvePayment,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Aprobar Pago'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'efectivo':
        return Icons.payments_rounded;
      case 'transferencia':
        return Icons.account_balance_rounded;
      case 'tarjeta':
        return Icons.credit_card_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  String _getPaymentLabel(String paymentMethod) {
    switch (paymentMethod) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      default:
        return paymentMethod;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'picked_up':
        return AppTheme.blue;
      case 'delivered':
        return AppTheme.success;
      default:
        return AppTheme.mediumGray;
    }
  }

  String _getDeliveryStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'picked_up':
        return 'Recogido';
      case 'delivered':
        return 'Entregado';
      default:
        return status;
    }
  }
}
