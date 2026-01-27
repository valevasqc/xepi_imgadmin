import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    setState(() => _isLoading = true);

    try {
      final doc =
          await _firestore.collection('orders').doc(widget.orderId).get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _orderData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _orderData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pedido: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
                      'Estado actualizado: ${StatusHelper.getOrderStatusLabel(newStatus)}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadOrderData();
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

  Future<void> _convertToSale() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: const Text(
          '¿El cliente ha pagado este pedido?\n\n'
          'Esta acción creará una venta, deducirá el stock y marcará el pedido como completado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final batch = _firestore.batch();

      // Create sale from order
      final saleRef = _firestore.collection('sales').doc();
      final saleData = {
        'saleType': 'delivery',
        'deliveryMethod': _orderData!['deliveryMethod'],
        'paymentMethod':
            'efectivo', // Orders are assumed COD (cash on delivery)
        'items': _orderData!['items'],
        'subtotal': _orderData!['total'],
        'discount': 0.0,
        'total': _orderData!['total'],
        'nit': 'CF',
        'customerName': _orderData!['customerName'],
        'customerPhone': _orderData!['customerPhone'],
        'deliveryAddress': _orderData!['deliveryAddress'],
        'deductFrom': 'store', // Default deduct from store
        'stockStatus': 'completed', // Stock already deducted
        'paymentVerified': true, // Cash received
        'status': 'approved',
        'depositId': null,
        'deliveryStatus': 'delivered', // Already delivered when paid
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'orderId': widget.orderId, // Link back to order
      };

      batch.set(saleRef, saleData);

      // Deduct stock for each item
      final items = _orderData!['items'] as List<dynamic>;
      for (var item in items) {
        final barcode = item['barcode'] as String;
        final quantity = item['quantity'] as int;
        final productRef = _firestore.collection('products').doc(barcode);

        batch.update(productRef, {
          'stockStore': FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update order status to completed and link to sale
      batch.update(_firestore.collection('orders').doc(widget.orderId), {
        'status': 'completed',
        'saleId': saleRef.id,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.white),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text('Venta creada y stock actualizado exitosamente'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadOrderData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al convertir a venta: $e'),
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

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content:
            const Text('¿Estás seguro de que deseas cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus('cancelled');
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
                Text('Detalle del Pedido', style: AppTheme.heading1),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orderData == null
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
                              'Pedido no encontrado',
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
                            const SizedBox(height: AppTheme.spacingL),
                            _buildActionsCard(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final status = _orderData!['status'] as String;
    final date = _orderData!['createdAt'] as Timestamp?;
    final customerName = _orderData!['customerName'] as String;
    final customerPhone = _orderData!['customerPhone'] as String;
    final deliveryAddress = _orderData!['deliveryAddress'] as String;
    final deliveryMethod = _orderData!['deliveryMethod'] as String;
    final notes = _orderData!['notes'] as String?;

    final statusColor = StatusHelper.getOrderStatusColor(status);
    final statusLabel = StatusHelper.getOrderStatusLabel(status);

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
              Text(widget.orderId, style: AppTheme.heading2),
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
            Icons.person_rounded,
            'Cliente',
            customerName,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            Icons.phone_rounded,
            'Teléfono',
            customerPhone,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            Icons.location_on_rounded,
            'Dirección',
            deliveryAddress,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            deliveryMethod == 'mensajero'
                ? Icons.moped_rounded
                : Icons.local_shipping_rounded,
            'Entrega',
            deliveryMethod == 'mensajero' ? 'Mensajero' : 'Forza',
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(
              Icons.note_rounded,
              'Notas',
              notes,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    final items = _orderData!['items'] as List<dynamic>;

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
    final total = (_orderData!['total'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total', style: AppTheme.heading3),
          Text(
            'Q${total.toStringAsFixed(2)}',
            style: AppTheme.heading2.copyWith(color: AppTheme.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    final status = _orderData!['status'] as String;

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
          Text('Acciones', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          if (status == 'completed') ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Pedido completado - Venta registrada',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'cancelled') ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppTheme.danger),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      'Pedido cancelado',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: AppTheme.spacingM,
              runSpacing: AppTheme.spacingM,
              children: [
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('preparing'),
                    icon: const Icon(Icons.restaurant_rounded, size: 18),
                    label: const Text('Iniciar Preparación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                if (status == 'preparing')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('ready'),
                    icon: const Icon(Icons.inventory_2_rounded, size: 18),
                    label: const Text('Marcar Listo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                if (status == 'ready')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('shipped'),
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text('Marcar Enviado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                if (status == 'shipped')
                  ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _updateStatus('delivered'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Marcar Entregado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                if (status == 'delivered')
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _convertToSale,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Confirmar Pago y Completar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                if (status != 'completed')
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _cancelOrder,
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('Cancelar Pedido'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
