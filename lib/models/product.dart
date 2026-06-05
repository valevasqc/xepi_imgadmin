import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String barcode; // document ID
  final String name;
  final String? warehouseCode;
  final String? categoryCode;
  final String? primaryCategory;
  final String? categoryName;
  final int stockStore;
  final int stockWarehouse;
  final double? priceOverride;
  final double? costPrice;
  final List<String> images;
  final String? color;
  final double? width;
  final double? height;
  final String? size;
  final String? notes;
  final List<String> temas;
  final bool isActive;
  final Timestamp? updatedAt;

  const Product({
    required this.barcode,
    required this.name,
    this.warehouseCode,
    this.categoryCode,
    this.primaryCategory,
    this.categoryName,
    required this.stockStore,
    required this.stockWarehouse,
    this.priceOverride,
    this.costPrice,
    required this.images,
    this.color,
    this.width,
    this.height,
    this.size,
    this.notes,
    required this.temas,
    required this.isActive,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      barcode: doc.id,
      name: data['name'] as String? ?? '',
      warehouseCode: data['warehouseCode'] as String?,
      categoryCode: data['categoryCode'] as String?,
      primaryCategory: data['primaryCategory'] as String?,
      categoryName: data['categoryName'] as String?,
      stockStore: (data['stockStore'] as num?)?.toInt() ?? 0,
      stockWarehouse: (data['stockWarehouse'] as num?)?.toInt() ?? 0,
      priceOverride: (data['priceOverride'] as num?)?.toDouble(),
      costPrice: (data['costPrice'] as num?)?.toDouble(),
      images: List<String>.from(data['images'] as List? ?? []),
      color: data['color'] as String?,
      width: (data['width'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      size: data['size'] as String?,
      notes: data['notes'] as String?,
      temas: List<String>.from(data['temas'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'barcode': barcode,
        'name': name,
        'warehouseCode': warehouseCode,
        'categoryCode': categoryCode,
        'primaryCategory': primaryCategory,
        'categoryName': categoryName,
        'stockStore': stockStore,
        'stockWarehouse': stockWarehouse,
        'priceOverride': priceOverride,
        'costPrice': costPrice,
        'images': images,
        'color': color,
        'width': width,
        'height': height,
        'size': size,
        'notes': notes,
        'temas': temas,
        'isActive': isActive,
        'updatedAt': updatedAt,
      };

  int stockFor(String location) =>
      location == 'store' ? stockStore : stockWarehouse;
}
