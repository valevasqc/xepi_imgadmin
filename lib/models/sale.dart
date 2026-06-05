import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';
import 'sale_item.dart';

class Sale {
  final String id;
  final SaleType saleType;
  final SaleStatus status;
  final StockStatus stockStatus;
  final DeliveryStatus? deliveryStatus;
  final PaymentMethod paymentMethod;
  final bool paymentVerified;
  final DeliveryMethod? deliveryMethod;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String nit;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String deductFrom;
  final String? destinationAccount;
  final String? depositId;
  final String? paymentProof;
  final String createdBy;
  final String? approvedBy;
  final Timestamp? createdAt;
  final Timestamp? pickedUpAt;
  final Timestamp? deliveredAt;
  final Timestamp? cashReceivedAt;

  const Sale({
    required this.id,
    required this.saleType,
    required this.status,
    required this.stockStatus,
    this.deliveryStatus,
    required this.paymentMethod,
    required this.paymentVerified,
    this.deliveryMethod,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.nit,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    required this.deductFrom,
    this.destinationAccount,
    this.depositId,
    this.paymentProof,
    required this.createdBy,
    this.approvedBy,
    this.createdAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cashReceivedAt,
  });

  factory Sale.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Sale(
      id: doc.id,
      saleType: SaleType.fromString(data['saleType'] as String?) ?? SaleType.kiosko,
      status: SaleStatus.fromString(data['status'] as String?) ?? SaleStatus.approved,
      stockStatus: StockStatus.fromString(data['stockStatus'] as String?) ?? StockStatus.completed,
      deliveryStatus: DeliveryStatus.fromString(data['deliveryStatus'] as String?),
      paymentMethod: PaymentMethod.fromString(data['paymentMethod'] as String?) ?? PaymentMethod.efectivo,
      paymentVerified: data['paymentVerified'] as bool? ?? false,
      deliveryMethod: DeliveryMethod.fromString(data['deliveryMethod'] as String?),
      items: rawItems.map((e) => SaleItem.fromMap(e as Map<String, dynamic>)).toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      nit: data['nit'] as String? ?? '',
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      deliveryAddress: data['deliveryAddress'] as String?,
      deductFrom: data['deductFrom'] as String? ?? 'store',
      destinationAccount: data['destinationAccount'] as String?,
      depositId: data['depositId'] as String?,
      paymentProof: data['paymentProof'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      approvedBy: data['approvedBy'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      pickedUpAt: data['pickedUpAt'] as Timestamp?,
      deliveredAt: data['deliveredAt'] as Timestamp?,
      cashReceivedAt: data['cashReceivedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'saleType': saleType.value,
        'status': status.value,
        'stockStatus': stockStatus.value,
        'deliveryStatus': deliveryStatus?.value,
        'paymentMethod': paymentMethod.value,
        'paymentVerified': paymentVerified,
        'deliveryMethod': deliveryMethod?.value,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'nit': nit,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'deductFrom': deductFrom,
        'destinationAccount': destinationAccount,
        'depositId': depositId,
        'paymentProof': paymentProof,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'createdAt': createdAt,
        'pickedUpAt': pickedUpAt,
        'deliveredAt': deliveredAt,
        'cashReceivedAt': cashReceivedAt,
      };

  bool get isDelivery => saleType == SaleType.delivery;
  bool get isPendingApproval => status == SaleStatus.pendingApproval;
  bool get isInTransit => stockStatus == StockStatus.inTransit;
  bool get isDelivered => deliveryStatus == DeliveryStatus.delivered;
}
