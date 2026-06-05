class SaleItem {
  final String barcode;
  final String name;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItem({
    required this.barcode,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      barcode: map['barcode'] as String,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ??
          (map['quantity'] as num).toDouble() *
              (map['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'subtotal': subtotal,
      };
}
