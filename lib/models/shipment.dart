import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';

class ShipmentItem {
  final String barcode;
  final String productName;
  final int quantity;
  final String? categoryCode;

  const ShipmentItem({
    required this.barcode,
    required this.productName,
    required this.quantity,
    this.categoryCode,
  });

  factory ShipmentItem.fromMap(Map<String, dynamic> map) {
    return ShipmentItem(
      barcode: map['barcode'] as String? ?? '',
      productName: map['productName'] as String? ?? map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      categoryCode: map['categoryCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'productName': productName,
        'quantity': quantity,
        'categoryCode': categoryCode,
      };
}

class Shipment {
  final String id;
  final ShipmentStatus status;
  final List<ShipmentItem> items;
  final String? supplierId; // to add when Supplier entity is built
  final String? receivedBy;
  final String? receivedByName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Shipment({
    required this.id,
    required this.status,
    required this.items,
    this.supplierId,
    this.receivedBy,
    this.receivedByName,
    this.createdAt,
    this.updatedAt,
  });

  factory Shipment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Shipment(
      id: doc.id,
      status: ShipmentStatus.fromString(data['status'] as String?) ??
          ShipmentStatus.inProgress,
      items: rawItems
          .map((e) => ShipmentItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      supplierId: data['supplierId'] as String?,
      receivedBy: data['receivedBy'] as String?,
      receivedByName: data['receivedByName'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'items': items.map((e) => e.toMap()).toList(),
        'supplierId': supplierId,
        'receivedBy': receivedBy,
        'receivedByName': receivedByName,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  bool get isCompleted => status == ShipmentStatus.completed;
}
