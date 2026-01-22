import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/utils/status_helper.dart';
import 'package:xepi_imgadmin/widgets/status_filter_chips.dart';
import 'package:xepi_imgadmin/screens/future/sale_detail_screen.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  String _statusFilter = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      // Load delivery sales that are still in progress (not yet delivered)
      final snapshot = await FirebaseFirestore.instance
          .collection('sales')
          .where('saleType', isEqualTo: 'delivery')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      // Convert to list and filter client-side
      final allOrders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id; // Use saleId as orderId for compatibility
        return data;
      }).toList();

      // Filter based on delivery status
      final filteredOrders = _statusFilter == 'all'
          ? allOrders
          : allOrders.where((order) {
              final deliveryStatus = order['deliveryStatus'] as String?;
              return deliveryStatus == _statusFilter;
            }).toList();

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pedidos: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: Column(
        children: [
          // Fixed header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                Text('Envíos', style: AppTheme.heading1),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter chips
                        Row(
                          children: [
                            Flexible(
                              child: StatusFilterChips(
                                selectedStatus: _statusFilter,
                                options: OrderStatusFilters.options,
                                onStatusChanged: (newStatus) {
                                  setState(() => _statusFilter = newStatus);
                                  _loadOrders();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),

                        // Stats row
                        _buildStatsRow(),
                        const SizedBox(height: AppTheme.spacingL),

                        // Empty state
                        if (_orders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingXXL),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 64,
                                    color: AppTheme.mediumGray
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: AppTheme.spacingL),
                                  Text(
                                    _getEmptyMessage(),
                                    style: AppTheme.bodyLarge
                                        .copyWith(color: AppTheme.mediumGray),
                                  ),
                                  if (_statusFilter != 'all') ...[
                                    const SizedBox(height: AppTheme.spacingM),
                                    Text(
                                      'Intenta con otro filtro de estado',
                                      style: AppTheme.bodyMedium
                                          .copyWith(color: AppTheme.mediumGray),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          // Orders list
                          ..._orders.map((order) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacingM),
                                child: _buildOrderCard(order),
                              )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_statusFilter) {
      case 'pending':
        return 'No hay pedidos pendientes';
      case 'preparing':
        return 'No hay pedidos en preparación';
      case 'ready':
        return 'No hay pedidos listos';
      case 'shipped':
        return 'No hay pedidos enviados';
      case 'delivered':
        return 'No hay pedidos entregados';
      case 'paid':
        return 'No hay pedidos pagados';
      case 'completed':
        return 'No hay pedidos completados';
      case 'cancelled':
        return 'No hay pedidos cancelados';
      default:
        return 'No hay pedidos registrados';
    }
  }

  Widget _buildStatsRow() {
    // Calculate stats from filtered orders
    final totalOrders = _orders.length;
    final totalAmount = _orders.fold<double>(
        0, (sum, order) => sum + (order['total'] as num).toDouble());
    final pendingOrders = _orders
        .where((o) => o['status'] == 'pending' || o['status'] == 'preparing')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Pedidos',
            totalOrders.toString(),
            AppTheme.blue,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Valor Total',
            'Q${totalAmount.toStringAsFixed(0)}',
            AppTheme.success,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            pendingOrders.toString(),
            AppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.heading1.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] as String;
    final date = order['createdAt'] as Timestamp?;
    final customerName = order['customerName'] as String;
    final customerPhone = order['customerPhone'] as String?;
    final deliveryMethod = order['deliveryMethod'] as String;
    final total = (order['total'] as num).toDouble();
    final items = (order['items'] as List?)?.length ?? 0;
    final deliveryStatus = order['deliveryStatus'] as String? ?? 'pending';

    final statusColor = StatusHelper.getDeliveryStatusColor(deliveryStatus);
    final statusLabel = StatusHelper.getDeliveryStatusLabel(deliveryStatus);

    // Determine icon based on delivery method
    final IconData deliveryIcon;
    final String deliveryLabel;
    if (deliveryMethod == 'mensajero') {
      deliveryIcon = Icons.moped_rounded;
      deliveryLabel = 'Mensajero';
    } else {
      deliveryIcon = Icons.local_shipping_rounded;
      deliveryLabel = 'Forza';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailScreen(saleId: orderId),
          ),
        ).then((_) => _loadOrders());
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
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Text(orderId, style: AppTheme.heading3),
                      const SizedBox(width: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
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

                  // Date and time
                  Text(
                    date != null
                        ? DateFormatter.formatDateWithTime(date)
                        : 'Fecha no disponible',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Details row
                  Wrap(
                    spacing: AppTheme.spacingL,
                    runSpacing: AppTheme.spacingS,
                    children: [
                      // Customer
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 16, color: AppTheme.mediumGray),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(customerName, style: AppTheme.bodyMedium),
                        ],
                      ),

                      // Phone
                      if (customerPhone != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 16, color: AppTheme.mediumGray),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(customerPhone, style: AppTheme.bodyMedium),
                          ],
                        ),

                      // Delivery method
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(deliveryIcon,
                              size: 16, color: AppTheme.mediumGray),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(deliveryLabel, style: AppTheme.bodyMedium),
                        ],
                      ),

                      // Items and total
                      Text(
                        '$items ${items == 1 ? 'producto' : 'productos'} • Q${total.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick action button for delivery progression (or arrow)
            if (deliveryStatus == 'pending')
              AbsorbPointer(
                absorbing: false,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Marcar como Recogido',
                    // TODO not working
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _quickUpdateDeliveryStatus(orderId, 'picked_up');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: AppTheme.blue),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (deliveryStatus == 'picked_up')
              AbsorbPointer(
                absorbing: false,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Marcar como Entregado',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _quickUpdateDeliveryStatus(orderId, 'delivered');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          child: const Icon(Icons.home_rounded,
                              color: AppTheme.success),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.mediumGray),
          ],
        ),
      ),
    );
  }

  Future<void> _quickUpdateDeliveryStatus(
      String saleId, String newStatus) async {
    try {
      final saleRef =
          FirebaseFirestore.instance.collection('sales').doc(saleId);
      final saleDoc = await saleRef.get();

      if (!saleDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Venta no encontrada'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      final saleData = saleDoc.data()!;

      // Prepare updates
      final Map<String, dynamic> updates = {
        'deliveryStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'picked_up') {
        updates['pickedUpAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'delivered') {
        // Ensure pickedUpAt exists
        if (saleData['pickedUpAt'] == null) {
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
        }
        updates['deliveredAt'] = FieldValue.serverTimestamp();

        // Deduct stock if in_transit
        final stockStatus = saleData['stockStatus'] as String? ?? 'completed';
        if (stockStatus == 'in_transit') {
          final batch = FirebaseFirestore.instance.batch();
          final items = saleData['items'] as List<dynamic>;
          final deductFrom = saleData['deductFrom'] as String? ?? 'store';
          final stockField =
              deductFrom == 'warehouse' ? 'stockWarehouse' : 'stockStore';

          for (final item in items) {
            final barcode = item['barcode'] as String;
            final quantity = item['quantity'] as int;
            final productRef =
                FirebaseFirestore.instance.collection('products').doc(barcode);
            batch.update(productRef, {
              stockField: FieldValue.increment(-quantity),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          updates['stockStatus'] = 'completed';
          batch.update(saleRef, updates);
          await batch.commit();
        } else {
          await saleRef.update(updates);
        }
      } else {
        await saleRef.update(updates);
      }

      if (mounted) {
        final statusLabel = newStatus == 'picked_up' ? 'Recogido' : 'Entregado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.white),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Pedido marcado como $statusLabel',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reload orders to reflect change
        _loadOrders();
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
    }
  }
}
