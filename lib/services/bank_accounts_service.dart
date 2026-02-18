import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccountsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bankAccounts';

  // Get all bank accounts
  Stream<List<Map<String, dynamic>>> getBankAccountsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('bankName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get single bank account
  Future<Map<String, dynamic>?> getBankAccount(String accountId) async {
    final doc = await _firestore.collection(_collection).doc(accountId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  // Add new bank account
  Future<String> addBankAccount({
    required String accountName,
    required String bankName,
    required String accountType, // 'business' | 'personal'
    required String currency, // 'QTZ' | 'USD'
    required String last4Digits,
    required double initialBalance,
    String? notes,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'accountName': accountName,
      'bankName': bankName,
      'accountType': accountType,
      'currency': currency,
      'last4Digits': last4Digits,
      'currentBalance': initialBalance,
      'notes': notes ?? '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Update bank account
  Future<void> updateBankAccount(String accountId, {
    String? accountName,
    String? bankName,
    String? accountType,
    String? currency,
    String? last4Digits,
    double? currentBalance,
    String? notes,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (accountName != null) updates['accountName'] = accountName;
    if (bankName != null) updates['bankName'] = bankName;
    if (accountType != null) updates['accountType'] = accountType;
    if (currency != null) updates['currency'] = currency;
    if (last4Digits != null) updates['last4Digits'] = last4Digits;
    if (currentBalance != null) updates['currentBalance'] = currentBalance;
    if (notes != null) updates['notes'] = notes;
    if (isActive != null) updates['isActive'] = isActive;

    await _firestore.collection(_collection).doc(accountId).update(updates);
  }

  // Delete bank account
  Future<void> deleteBankAccount(String accountId) async {
    await _firestore.collection(_collection).doc(accountId).delete();
  }

  // Update balance only (for weekly reconciliation)
  Future<void> updateBalance(String accountId, double newBalance) async {
    await _firestore.collection(_collection).doc(accountId).update({
      'currentBalance': newBalance,
      'lastReconciled': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get active accounts only (for dropdowns)
  Future<List<Map<String, dynamic>>> getActiveAccounts() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('bankName')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Get accounts by currency (for filtering)
  Future<List<Map<String, dynamic>>> getAccountsByCurrency(String currency) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('currency', isEqualTo: currency)
        .where('isActive', isEqualTo: true)
        .orderBy('bankName')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Calculate total balance across all accounts
  Future<Map<String, double>> getTotalBalances() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .get();

    double totalQTZ = 0;
    double totalUSD = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final balance = (data['currentBalance'] as num?)?.toDouble() ?? 0;
      final currency = data['currency'] as String?;

      if (currency == 'QTZ') {
        totalQTZ += balance;
      } else if (currency == 'USD') {
        totalUSD += balance;
      }
    }

    return {
      'QTZ': totalQTZ,
      'USD': totalUSD,
    };
  }
}
