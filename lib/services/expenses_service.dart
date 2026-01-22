import 'package:cloud_firestore/cloud_firestore.dart';

class ExpensesService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Categories
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    final snap = await _db
        .collection('expense_categories')
        .orderBy('displayOrder')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Future<void> addCategory(String name, String type,
      {int? displayOrder, bool isActive = true}) async {
    await _db.collection('expense_categories').add({
      'name': name,
      'type': type,
      'displayOrder': displayOrder ?? DateTime.now().millisecondsSinceEpoch,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateCategory(String id,
      {String? name, String? type, int? displayOrder, bool? isActive}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (displayOrder != null) updates['displayOrder'] = displayOrder;
    if (isActive != null) updates['isActive'] = isActive;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('expense_categories').doc(id).update(updates);
  }

  static Future<void> deleteCategory(String id) async {
    await _db.collection('expense_categories').doc(id).delete();
  }

  // Expenses
  static Future<List<Map<String, dynamic>>> fetchExpenses(
      {String? type, String? status}) async {
    var ref = _db.collection('expenses').orderBy('createdAt', descending: true);
    if (type != null && type != 'todos') {
      ref = _db
          .collection('expenses')
          .where('categoryType', isEqualTo: type)
          .orderBy('createdAt', descending: true);
    }
    final snap = await ref.get();
    final items = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    if (status != null && status != 'todos') {
      return items.where((e) => e['status'] == status).toList();
    }
    return items;
  }

  static Future<void> addExpense({
    required double amount,
    required String category,
    required String categoryType,
    required String description,
    required String createdBy,
    String? receiptUrl,
    String status = 'pending_approval',
  }) async {
    await _db.collection('expenses').add({
      'amount': amount,
      'category': category,
      'categoryType': categoryType,
      'description': description,
      'receiptUrl': receiptUrl,
      'status': status,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedBy': null,
      'approvedAt': null,
    });
  }

  static Future<void> approveExpense(String id, String approvedBy) async {
    await _db.collection('expenses').doc(id).update({
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rejectExpense(String id, String approvedBy) async {
    await _db.collection('expenses').doc(id).update({
      'status': 'rejected',
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }
}
