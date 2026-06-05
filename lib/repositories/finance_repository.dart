import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xepi_imgadmin/constants/constants.dart';
import 'package:xepi_imgadmin/models/models.dart';

class FinanceRepository {
  static final FinanceRepository instance = FinanceRepository._();
  FinanceRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------------

  Future<List<Expense>> getExpenses({ExpenseStatus? status}) async {
    Query<Map<String, dynamic>> q = _db.collection(Collections.expenses);
    if (status != null) {
      q = q.where('status', isEqualTo: status.value);
    }
    final snap = await q.orderBy('createdAt', descending: true).get();
    return snap.docs.map(Expense.fromFirestore).toList();
  }

  /// Raw-map version used by screens that have not yet migrated to typed models.
  /// Replace with [getExpenses] when the caller is migrated.
  Future<List<Map<String, dynamic>>> fetchExpensesRaw() async {
    final snap = await _db
        .collection(Collections.expenses)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ---------------------------------------------------------------------------
  // Expense categories
  // ---------------------------------------------------------------------------

  /// Raw-map version used by screens that have not yet migrated to typed models.
  Future<List<Map<String, dynamic>>> fetchCategoriesRaw() async {
    final snap = await _db
        .collection(Collections.expenseCategories)
        .orderBy('displayOrder')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> addCategory(String name, String type,
      {int? displayOrder, bool isActive = true}) async {
    await _db.collection(Collections.expenseCategories).add({
      'name': name,
      'type': type,
      'displayOrder':
          displayOrder ?? DateTime.now().millisecondsSinceEpoch,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(String id,
      {String? name, String? type, int? displayOrder, bool? isActive}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (displayOrder != null) updates['displayOrder'] = displayOrder;
    if (isActive != null) updates['isActive'] = isActive;
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(Collections.expenseCategories)
        .doc(id)
        .update(updates);
  }

  Future<void> deleteCategory(String id) async {
    await _db
        .collection(Collections.expenseCategories)
        .doc(id)
        .delete();
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required String categoryType,
    required String description,
    required String createdBy,
    String? receiptUrl,
    ExpenseStatus status = ExpenseStatus.pendingApproval,
    String paymentSource = 'efectivo',
  }) async {
    await _db.collection(Collections.expenses).add({
      'amount': amount,
      'category': category,
      'categoryType': categoryType,
      'description': description,
      'receiptUrl': receiptUrl,
      'status': status.value,
      'createdBy': createdBy,
      'paymentSource': paymentSource,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedBy': null,
      'approvedAt': null,
    });
  }

  Future<void> approveExpense(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    await _db.collection(Collections.expenses).doc(id).update({
      'status': ExpenseStatus.approved.value,
      'approvedBy': uid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectExpense(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    await _db.collection(Collections.expenses).doc(id).update({
      'status': ExpenseStatus.rejected.value,
      'approvedBy': uid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Bank accounts
  // ---------------------------------------------------------------------------

  Future<List<BankAccount>> getBankAccounts({bool activeOnly = false}) async {
    Query<Map<String, dynamic>> q = _db.collection(Collections.bankAccounts);
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final snap = await q.get();
    return snap.docs.map(BankAccount.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // Deposits
  // ---------------------------------------------------------------------------

  Future<List<Deposit>> getDeposits() async {
    final snap = await _db
        .collection(Collections.deposits)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(Deposit.fromFirestore).toList();
  }
}
