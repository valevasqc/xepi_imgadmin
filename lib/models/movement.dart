import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';

class MovementItem {
  final String barcode;
  final int qty;

  const MovementItem({required this.barcode, required this.qty});

  factory MovementItem.fromMap(Map<String, dynamic> map) {
    return MovementItem(
      barcode: map['barcode'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ??
          (map['quantity'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toMap() => {'barcode': barcode, 'qty': qty};
}

class Movement {
  final String id;
  final MovementStatus status;
  final StockLocation origin;
  final StockLocation destination;
  final List<MovementItem> items;
  final String? createdBy;
  final Timestamp? createdAt;
  final Timestamp? sentAt;
  final Timestamp? receivedAt;
  final Timestamp? updatedAt;

  const Movement({
    required this.id,
    required this.status,
    required this.origin,
    required this.destination,
    required this.items,
    this.createdBy,
    this.createdAt,
    this.sentAt,
    this.receivedAt,
    this.updatedAt,
  });

  factory Movement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Movement(
      id: doc.id,
      status: MovementStatus.fromString(data['status'] as String?) ??
          MovementStatus.pending,
      origin: StockLocation.fromString(data['origin'] as String?) ??
          StockLocation.warehouse,
      destination: StockLocation.fromString(data['destination'] as String?) ??
          StockLocation.store,
      items: rawItems
          .map((e) => MovementItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      sentAt: data['sentAt'] as Timestamp?,
      receivedAt: data['receivedAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'origin': origin.value,
        'destination': destination.value,
        'items': items.map((e) => e.toMap()).toList(),
        'createdBy': createdBy,
        'createdAt': createdAt,
        'sentAt': sentAt,
        'receivedAt': receivedAt,
        'updatedAt': updatedAt,
      };
}
