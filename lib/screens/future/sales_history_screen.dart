import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';
import 'package:xepi_imgadmin/utils/date_formatter.dart';
import 'package:xepi_imgadmin/widgets/status_filter_chips.dart';
import 'package:xepi_imgadmin/screens/future/register_sale_screen.dart';
import 'package:xepi_imgadmin/screens/future/sale_detail_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _saleTypeFilter = 'all'; // Filter by sale type (kiosko/delivery)
  String _paymentMethodFilter = 'all'; // Filter by payment method
  bool _isLoading = true;
  List<Map<String, dynamic>> _sales = [];
  String _viewMode = 'cards'; // 'cards' | 'table'

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);

    try {
      // Load from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      // Convert to list and filter client-side
      final allSales = snapshot.docs.map((doc) {
        final data = doc.data();
        data['saleId'] = doc.id;
        return data;
      }).toList();

      // Filter by sale type and payment method
      final filteredSales = allSales.where((sale) {
        // Filter by sale type
        if (_saleTypeFilter != 'all') {
          final saleType = sale['saleType'] as String? ?? 'kiosko';
          if (saleType != _saleTypeFilter) return false;
        }

        // Filter by payment method
        if (_paymentMethodFilter != 'all') {
          final paymentMethod = sale['paymentMethod'] as String? ?? 'efectivo';
          if (paymentMethod != _paymentMethodFilter) return false;
        }

        return true;
      }).toList();

      setState(() {
        _sales = filteredSales;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ventas: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        setState(() {
          _sales = [];
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegisterSale() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterSaleScreen()),
    ).then((_) => _loadSales());
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
                Text('Ventas', style: AppTheme.heading1),
                const Spacer(),
                // View mode toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeButton(
                        icon: Icons.view_agenda_rounded,
                        mode: 'cards',
                        tooltip: 'Vista de Tarjetas',
                      ),
                      _buildViewModeButton(
                        icon: Icons.table_rows_rounded,
                        mode: 'table',
                        tooltip: 'Vista de Tabla',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: _navigateToRegisterSale,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                  ),
                ),
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
                        // Filter chips for sale type
                        Row(
                          children: [
                            Text(
                              'Tipo de Venta:',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Flexible(
                              child: StatusFilterChips(
                                selectedStatus: _saleTypeFilter,
                                options: SaleTypeFilters.options,
                                onStatusChanged: (newStatus) {
                                  setState(() => _saleTypeFilter = newStatus);
                                  _loadSales();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingM),

                        // Filter chips for payment method
                        Row(
                          children: [
                            Text(
                              'Método de Pago:',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Flexible(
                              child: StatusFilterChips(
                                selectedStatus: _paymentMethodFilter,
                                options: PaymentMethodFilters.options,
                                onStatusChanged: (newStatus) {
                                  setState(
                                      () => _paymentMethodFilter = newStatus);
                                  _loadSales();
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
                        if (_sales.isEmpty)
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
                                  if (_saleTypeFilter != 'all' ||
                                      _paymentMethodFilter != 'all') ...[
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
                        // Sales list - cards or table
                        if (_viewMode == 'cards')
                          ..._sales.map((sale) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacingM),
                                child: _buildSaleCard(sale),
                              ))
                        else
                          _buildSalesTable(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppTheme.backgroundGray,
          ),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Items')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Pago')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: _sales.map((sale) {
            final saleId = sale['saleId'] as String;
            final createdAt = sale['createdAt'] as Timestamp?;
            final saleType = sale['saleType'] as String? ?? 'kiosko';
            final customerName = sale['customerName'] as String? ?? '-';
            final items = sale['items'] as List? ?? [];
            final total = sale['total'] ?? 0.0;
            final paymentMethod =
                sale['paymentMethod'] as String? ?? 'efectivo';
            final status = sale['status'] as String? ?? 'approved';

            // Payment badge color
            Color paymentColor;
            String paymentLabel;
            switch (paymentMethod) {
              case 'efectivo':
                paymentColor = AppTheme.success;
                paymentLabel = 'Efectivo';
                break;
              case 'transferencia':
                paymentColor = AppTheme.blue;
                paymentLabel = 'Transfer.';
                break;
              case 'tarjeta':
                paymentColor = AppTheme.warning;
                paymentLabel = 'Tarjeta';
                break;
              default:
                paymentColor = AppTheme.mediumGray;
                paymentLabel = paymentMethod;
            }

            // Status badge color
            Color statusColor;
            String statusLabel;
            switch (status) {
              case 'pending_approval':
                statusColor = AppTheme.warning;
                statusLabel = 'Pendiente';
                break;
              case 'approved':
                statusColor = AppTheme.success;
                statusLabel = 'Aprobado';
                break;
              default:
                statusColor = AppTheme.mediumGray;
                statusLabel = status;
            }

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '#${saleId.substring(0, 6)}',
                    style: AppTheme.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    createdAt != null
                        ? DateFormatter.formatDate(createdAt)
                        : '-',
                    style: AppTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: saleType == 'delivery'
                          ? AppTheme.blue.withOpacity(0.1)
                          : AppTheme.mediumGray.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      saleType == 'delivery' ? 'Delivery' : 'Tienda',
                      style: AppTheme.bodySmall.copyWith(
                        color: saleType == 'delivery'
                            ? AppTheme.blue
                            : AppTheme.darkGray,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    customerName,
                    style: AppTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: AppTheme.bodySmall,
                  ),
                ),
                DataCell(
                  Text(
                    'Q${total.toStringAsFixed(2)}',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: paymentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      paymentLabel,
                      style: AppTheme.bodySmall.copyWith(
                        color: paymentColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
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
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SaleDetailScreen(saleId: saleId),
                        ),
                      ).then((_) => _loadSales());
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.blue,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    if (_saleTypeFilter == 'kiosko') {
      return 'No hay ventas de kiosko';
    } else if (_saleTypeFilter == 'delivery') {
      return 'No hay envíos registrados';
    } else if (_paymentMethodFilter != 'all') {
      return 'No hay ventas con este método de pago';
    }
    return 'No hay ventas registradas';
  }

  Widget _buildStatsRow() {
    // Calculate stats from filtered sales
    final totalSales = _sales.length;
    final totalAmount =
        _sales.fold<double>(0, (sum, sale) => sum + sale['total']);
    final avgAmount = totalSales > 0 ? totalAmount / totalSales : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Ventas',
            totalSales.toString(),
            AppTheme.blue,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Total Ingresos',
            'Q${totalAmount.toStringAsFixed(0)}',
            AppTheme.success,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Ticket Promedio',
            'Q${avgAmount.toStringAsFixed(0)}',
            AppTheme.orange,
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

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final saleId = sale['saleId'] as String;
    final date = sale['createdAt'] as Timestamp?;
    final saleType = sale['saleType'] as String;
    final paymentMethod = sale['paymentMethod'] as String;
    final total = (sale['total'] as num).toDouble();
    final items = (sale['items'] as List?)?.length ?? 0;
    final customerName = sale['customerName'] as String?;
    final paymentVerified = sale['paymentVerified'] as bool;
    final status = sale['status'] as String;
    final deliveryStatus = sale['deliveryStatus'] as String? ?? 'pending';
    final isDelivery = saleType == 'delivery';

    // Determine icon and color based on sale type
    final IconData saleIcon;
    final Color saleColor;
    final String saleTypeLabel;

    if (isDelivery) {
      saleIcon = Icons.local_shipping_rounded;
      saleColor = AppTheme.blue;
      saleTypeLabel = sale['deliveryMethod'] == 'mensajero'
          ? 'Delivery (Mensajero)'
          : 'Delivery (Forza)';
    } else {
      saleIcon = Icons.store_rounded;
      saleColor = AppTheme.success;
      saleTypeLabel = 'Tienda';
    }

    // Payment status badge
    final Color paymentStatusColor;
    final String paymentStatusLabel;

    if (status == 'pending_approval') {
      paymentStatusColor = AppTheme.warning;
      paymentStatusLabel = 'Pendiente Aprobación';
    } else if (!paymentVerified) {
      paymentStatusColor = AppTheme.danger;
      paymentStatusLabel = 'No Verificado';
    } else {
      paymentStatusColor = AppTheme.success;
      paymentStatusLabel = 'Completado';
    }

    // Delivery status badge (for delivery sales only)
    final Color deliveryStatusColor;
    final String deliveryStatusLabel;

    if (isDelivery) {
      switch (deliveryStatus) {
        case 'pending':
          deliveryStatusColor = AppTheme.warning;
          deliveryStatusLabel = 'Pendiente';
          break;
        case 'picked_up':
          deliveryStatusColor = AppTheme.blue;
          deliveryStatusLabel = 'Recogido';
          break;
        case 'delivered':
          deliveryStatusColor = AppTheme.success;
          deliveryStatusLabel = 'Entregado';
          break;
        case 'completed':
          deliveryStatusColor = AppTheme.success;
          deliveryStatusLabel = 'Completado';
          break;
        case 'anulado':
          deliveryStatusColor = AppTheme.danger;
          deliveryStatusLabel = 'Anulado';
          break;
        default:
          deliveryStatusColor = AppTheme.mediumGray;
          deliveryStatusLabel = deliveryStatus;
      }
    } else {
      deliveryStatusColor = AppTheme.mediumGray;
      deliveryStatusLabel = '';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailScreen(saleId: saleId),
          ),
        ).then((_) => _loadSales());
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
                color: saleColor.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(saleIcon, color: saleColor, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingL),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with badges
                  Row(
                    children: [
                      Text('#${saleId.substring(0, 8)}',
                          style: AppTheme.heading3),
                      const SizedBox(width: AppTheme.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paymentStatusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentStatusLabel,
                          style: AppTheme.caption.copyWith(
                            color: paymentStatusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isDelivery) ...[
                        const SizedBox(width: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: deliveryStatusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            deliveryStatusLabel,
                            style: AppTheme.caption.copyWith(
                              color: deliveryStatusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
                      // Sale type
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(saleIcon, size: 16, color: AppTheme.mediumGray),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(saleTypeLabel, style: AppTheme.bodyMedium),
                        ],
                      ),

                      // Payment method
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentIcon(paymentMethod),
                            size: 16,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            _getPaymentLabel(paymentMethod),
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),

                      // Items and total
                      Text(
                        '$items ${items == 1 ? 'producto' : 'productos'} • Q${total.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),

                      // Customer name (if available)
                      if (customerName != null && customerName.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 16, color: AppTheme.mediumGray),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(customerName, style: AppTheme.bodyMedium),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick action button for delivery progression (or arrow)
            if (isDelivery && deliveryStatus == 'pending')
              AbsorbPointer(
                absorbing: false,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Marcar como Recogido',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _quickUpdateDeliveryStatus(saleId, 'picked_up');
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
            else if (isDelivery && deliveryStatus == 'picked_up')
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
                          _quickUpdateDeliveryStatus(saleId, 'delivered');
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
    if (!mounted) return;

    try {
      final saleRef =
          FirebaseFirestore.instance.collection('sales').doc(saleId);
      final saleDoc = await saleRef.get();

      if (!mounted) return;

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

        // Add to pending cash if efectivo payment
        final paymentMethod =
            saleData['paymentMethod'] as String? ?? 'efectivo';
        if (paymentMethod == 'efectivo') {
          // Determine cash source
          final saleType = saleData['saleType'] as String? ?? 'delivery';
          final deliveryMethod = saleData['deliveryMethod'] as String?;
          String cashSource;
          if (saleType == 'kiosko') {
            cashSource = 'store';
          } else if (deliveryMethod == 'mensajero') {
            cashSource = 'mensajero';
          } else {
            cashSource = 'forza';
          }

          // Add to pending cash
          final total = saleData['total'] as num;
          final pendingCashRef = FirebaseFirestore.instance
              .collection('pendingCash')
              .doc(cashSource);

          final batch = FirebaseFirestore.instance.batch();
          batch.set(
            pendingCashRef,
            {
              'source': cashSource,
              'amount': FieldValue.increment(total.toDouble()),
              'saleIds': FieldValue.arrayUnion([saleId]),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Update sale with pending cash tracking
          updates['pendingCashSource'] = cashSource;

          // Handle stock deduction
          final stockStatus = saleData['stockStatus'] as String? ?? 'completed';
          if (stockStatus == 'in_transit') {
            final items = saleData['items'] as List<dynamic>;
            final deductFrom = saleData['deductFrom'] as String? ?? 'store';
            final stockField =
                deductFrom == 'warehouse' ? 'stockWarehouse' : 'stockStore';

            for (final item in items) {
              final barcode = item['barcode'] as String;
              final quantity = item['quantity'] as int;
              final productRef = FirebaseFirestore.instance
                  .collection('products')
                  .doc(barcode);
              batch.update(productRef, {
                stockField: FieldValue.increment(-quantity),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }

            updates['stockStatus'] = 'completed';
          }

          batch.update(saleRef, updates);
          await batch.commit();
        } else {
          // Non-efectivo: just handle stock deduction
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
              final productRef = FirebaseFirestore.instance
                  .collection('products')
                  .doc(barcode);
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
        }
      } else if (newStatus == 'completed') {
        // Ensure timestamps exist
        if (saleData['pickedUpAt'] == null) {
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
        }
        if (saleData['deliveredAt'] == null) {
          updates['deliveredAt'] = FieldValue.serverTimestamp();
        }
        updates['completedAt'] = FieldValue.serverTimestamp();
        await saleRef.update(updates);
      } else {
        await saleRef.update(updates);
      }

      if (mounted) {
        final statusLabel = _getDeliveryStatusLabel(newStatus);
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

        // Reload sales to reflect change
        if (mounted) {
          _loadSales();
        }
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

  String _getDeliveryStatusLabel(String status) {
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

  Widget _buildViewModeButton({
    required IconData icon,
    required String mode,
    required String tooltip,
  }) {
    final isSelected = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        borderRadius: AppTheme.borderRadiusSmall,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white : Colors.transparent,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppTheme.blue : AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }
}
