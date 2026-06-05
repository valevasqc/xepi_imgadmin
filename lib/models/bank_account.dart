import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccount {
  final String id;
  final String bankName;
  final String accountName;
  final String accountType;
  final String currency; // 'QTZ' | 'USD'
  final double currentBalance;
  final bool isActive;
  final String? last4Digits;
  final Timestamp? updatedAt;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountType,
    required this.currency,
    required this.currentBalance,
    required this.isActive,
    this.last4Digits,
    this.updatedAt,
  });

  factory BankAccount.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BankAccount(
      id: doc.id,
      bankName: data['bankName'] as String? ?? '',
      accountName: data['accountName'] as String? ?? '',
      accountType: data['accountType'] as String? ?? '',
      currency: data['currency'] as String? ?? 'QTZ',
      currentBalance: (data['currentBalance'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      last4Digits: data['last4Digits'] as String?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'bankName': bankName,
        'accountName': accountName,
        'accountType': accountType,
        'currency': currency,
        'currentBalance': currentBalance,
        'isActive': isActive,
        'last4Digits': last4Digits,
        'updatedAt': updatedAt,
      };
}
