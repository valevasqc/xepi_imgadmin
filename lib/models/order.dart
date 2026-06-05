import 'package:cloud_firestore/cloud_firestore.dart';
import 'sale_item.dart';

/// Legacy COD pre-sale model. Read from the `orders` collection.
/// Non-canonical — delivery workflow lives in `sales`.
/// Do not build on this until the web-checkout intake decision is made.
/// See docs/DATA_MODEL.md and docs/DELIVERY_AND_PAYMENTS.md §4.
class Order {
  final String id;
  final String status; // pending | preparing | ready | shipped | delivered | completed
  final List<SaleItem> items;
  final String customerName;
  final String? phone;
  final String? address;
  final String? convertedSaleId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Order({
    required this.id,
    required this.status,
    required this.items,
    required this.customerName,
    this.phone,
    this.address,
    this.convertedSaleId,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Order(
      id: doc.id,
      status: data['status'] as String? ?? 'pending',
      items: rawItems
          .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      customerName: data['customerName'] as String? ?? '',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      convertedSaleId: data['convertedSaleId'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'convertedSaleId': convertedSaleId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
