import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';
import 'package:xepi_imgadmin/models/models.dart';

class InventoryRepository {
  static final InventoryRepository instance = InventoryRepository._();
  InventoryRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Shipments
  // ---------------------------------------------------------------------------

  Future<List<Shipment>> getShipments({ShipmentStatus? status}) async {
    Query<Map<String, dynamic>> q = _db
        .collection(Collections.shipments)
        .orderBy('createdAt', descending: true);
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    final snap = await q.get();
    return snap.docs.map(Shipment.fromFirestore).toList();
  }

  Future<Shipment?> getShipment(String id) async {
    final doc =
        await _db.collection(Collections.shipments).doc(id).get();
    if (!doc.exists) return null;
    return Shipment.fromFirestore(doc);
  }

  // ---------------------------------------------------------------------------
  // Movements
  // ---------------------------------------------------------------------------

  Future<List<Movement>> getMovements({MovementStatus? status}) async {
    Query<Map<String, dynamic>> q = _db
        .collection(Collections.movements)
        .orderBy('createdAt', descending: true);
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    final snap = await q.get();
    return snap.docs.map(Movement.fromFirestore).toList();
  }

  Future<Movement?> getMovement(String id) async {
    final doc =
        await _db.collection(Collections.movements).doc(id).get();
    if (!doc.exists) return null;
    return Movement.fromFirestore(doc);
  }
}
