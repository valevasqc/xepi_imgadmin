import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';
import 'package:xepi_imgadmin/models/models.dart';

class ProductsRepository {
  static final ProductsRepository instance = ProductsRepository._();
  ProductsRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Product?> getProduct(String barcode) async {
    final doc =
        await _db.collection(Collections.products).doc(barcode).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  Future<List<Product>> getProducts({bool activeOnly = false}) async {
    Query<Map<String, dynamic>> q = _db.collection(Collections.products);
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final snap = await q.get();
    return snap.docs.map(Product.fromFirestore).toList();
  }

  /// Adjusts stock by [delta] (positive = add, negative = deduct).
  /// Must be called from within a Firestore transaction for atomicity.
  void adjustStockInTransaction(
    Transaction txn,
    String barcode,
    String stockField,
    int delta,
  ) {
    txn.update(_db.collection(Collections.products).doc(barcode), {
      stockField: FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
