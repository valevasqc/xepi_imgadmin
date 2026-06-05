import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';
import 'package:xepi_imgadmin/models/models.dart';

class SalesRepository {
  static final SalesRepository instance = SalesRepository._();
  SalesRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  Future<Sale?> getSale(String id) async {
    final doc = await _db
        .collection(Collections.sales)
        .doc(id)
        .withConverter<Sale>(
          fromFirestore: (snap, _) => Sale.fromFirestore(snap),
          toFirestore: (sale, _) => sale.toMap(),
        )
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<Sale>> getDeliverySales() async {
    final snap = await _db
        .collection(Collections.sales)
        .where('saleType', isEqualTo: SaleType.delivery.value)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(Sale.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // Delivery status update — single source of truth for stock side effects.
  //
  // Uses runTransaction so the stockStatus read and all writes are atomic.
  // Eliminates the double stock-deduction race that existed when this logic
  // was duplicated across orders_history_screen and sale_detail_screen.
  // ---------------------------------------------------------------------------

  Future<void> updateDeliveryStatus(
      String saleId, DeliveryStatus newStatus) async {
    await _db.runTransaction((txn) async {
      final saleRef =
          _db.collection(Collections.sales).doc(saleId);
      final saleSnap = await txn.get(saleRef);

      if (!saleSnap.exists) {
        throw Exception('Venta no encontrada: $saleId');
      }

      final sale = Sale.fromFirestore(saleSnap);
      final updates = <String, dynamic>{
        'deliveryStatus': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (newStatus) {
        case DeliveryStatus.pickedUp:
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
          txn.update(saleRef, updates);

        case DeliveryStatus.delivered:
          if (sale.pickedUpAt == null) {
            updates['pickedUpAt'] = FieldValue.serverTimestamp();
          }
          updates['deliveredAt'] = FieldValue.serverTimestamp();

          if (sale.isInTransit) {
            updates['stockStatus'] = StockStatus.completed.value;
            _applyStockDeduction(txn, sale, updates, saleRef);
          } else {
            txn.update(saleRef, updates);
          }

          if (sale.paymentMethod == PaymentMethod.efectivo) {
            _addToPendingCash(txn, saleId, sale);
          }

        case DeliveryStatus.cashReceived:
          if (sale.pickedUpAt == null) {
            updates['pickedUpAt'] = FieldValue.serverTimestamp();
          }
          if (sale.deliveredAt == null) {
            updates['deliveredAt'] = FieldValue.serverTimestamp();
          }
          updates['cashReceivedAt'] = FieldValue.serverTimestamp();

          if (sale.isInTransit) {
            updates['stockStatus'] = StockStatus.completed.value;
            _applyStockDeduction(txn, sale, updates, saleRef);
          } else {
            txn.update(saleRef, updates);
          }

          // Only add cash if not already linked to a deposit
          if (sale.paymentMethod == PaymentMethod.efectivo &&
              sale.depositId == null) {
            _addToPendingCash(txn, saleId, sale);
          }

        case DeliveryStatus.pending:
          // Revert: clear timestamps, restore stock if already deducted
          updates['pickedUpAt'] = null;
          updates['deliveredAt'] = null;
          updates['cashReceivedAt'] = null;

          if (sale.stockStatus == StockStatus.completed) {
            updates['stockStatus'] = StockStatus.inTransit.value;
            _applyStockRestore(txn, sale, updates, saleRef);

            if (sale.paymentMethod == PaymentMethod.efectivo) {
              _removeFromPendingCash(txn, saleId, sale);
            }
          } else {
            txn.update(saleRef, updates);
          }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers — called only within a transaction
  // ---------------------------------------------------------------------------

  void _applyStockDeduction(
    Transaction txn,
    Sale sale,
    Map<String, dynamic> updates,
    DocumentReference saleRef,
  ) {
    txn.update(saleRef, updates);
    final stockField =
        sale.deductFrom == StockLocation.store.value ? 'stockStore' : 'stockWarehouse';
    for (final item in sale.items) {
      txn.update(_db.collection(Collections.products).doc(item.barcode), {
        stockField: FieldValue.increment(-item.quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _applyStockRestore(
    Transaction txn,
    Sale sale,
    Map<String, dynamic> updates,
    DocumentReference saleRef,
  ) {
    txn.update(saleRef, updates);
    final stockField =
        sale.deductFrom == StockLocation.store.value ? 'stockStore' : 'stockWarehouse';
    for (final item in sale.items) {
      txn.update(_db.collection(Collections.products).doc(item.barcode), {
        stockField: FieldValue.increment(item.quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _addToPendingCash(Transaction txn, String saleId, Sale sale) {
    final source = _cashSourceFor(sale.deliveryMethod);
    txn.set(
      _db.collection(Collections.pendingCash).doc(source),
      {
        'source': source,
        'amount': FieldValue.increment(sale.total),
        'saleIds': FieldValue.arrayUnion([saleId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _removeFromPendingCash(Transaction txn, String saleId, Sale sale) {
    final source = _cashSourceFor(sale.deliveryMethod);
    txn.set(
      _db.collection(Collections.pendingCash).doc(source),
      {
        'amount': FieldValue.increment(-sale.total),
        'saleIds': FieldValue.arrayRemove([saleId]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  String _cashSourceFor(DeliveryMethod? method) {
    if (method == DeliveryMethod.mensajero) return CashSource.mensajero.value;
    if (method == DeliveryMethod.forza) return CashSource.forza.value;
    return CashSource.store.value;
  }
}
