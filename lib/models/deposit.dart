import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';

class Deposit {
  final String id;
  final CashSource source;
  final double cashReceived;
  final double expenses;
  final double amount; // net = cashReceived - expenses
  final List<String> saleIds;
  final List<String> expenseIds;
  final String? destinationAccount;
  final String? comprobanteUrl;
  final String depositedBy;
  final Timestamp? createdAt;

  const Deposit({
    required this.id,
    required this.source,
    required this.cashReceived,
    required this.expenses,
    required this.amount,
    required this.saleIds,
    required this.expenseIds,
    this.destinationAccount,
    this.comprobanteUrl,
    required this.depositedBy,
    this.createdAt,
  });

  factory Deposit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Deposit(
      id: doc.id,
      source: CashSource.fromString(data['source'] as String?) ?? CashSource.store,
      cashReceived: (data['cashReceived'] as num?)?.toDouble() ?? 0,
      expenses: (data['expenses'] as num?)?.toDouble() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      saleIds: List<String>.from(data['saleIds'] as List? ?? []),
      expenseIds: List<String>.from(data['expenseIds'] as List? ?? []),
      destinationAccount: data['destinationAccount'] as String?,
      comprobanteUrl: data['comprobanteUrl'] as String?,
      depositedBy: data['depositedBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'source': source.value,
        'cashReceived': cashReceived,
        'expenses': expenses,
        'amount': amount,
        'saleIds': saleIds,
        'expenseIds': expenseIds,
        'destinationAccount': destinationAccount,
        'comprobanteUrl': comprobanteUrl,
        'depositedBy': depositedBy,
        'createdAt': createdAt,
      };
}
