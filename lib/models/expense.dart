import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/constants/constants.dart';

class Expense {
  final String id;
  final ExpenseStatus status;
  final String category;
  final ExpenseType? type;
  final double amount;
  final String? description;
  final String? paymentSource;
  final String createdBy;
  final String? approvedBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Expense({
    required this.id,
    required this.status,
    required this.category,
    this.type,
    required this.amount,
    this.description,
    this.paymentSource,
    required this.createdBy,
    this.approvedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Expense(
      id: doc.id,
      status: ExpenseStatus.fromString(data['status'] as String?) ??
          ExpenseStatus.pendingApproval,
      category: data['category'] as String? ?? '',
      type: ExpenseType.fromString(data['categoryType'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String?,
      paymentSource: data['paymentSource'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      approvedBy: data['approvedBy'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'category': category,
        'categoryType': type?.value,
        'amount': amount,
        'description': description,
        'paymentSource': paymentSource,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  bool get isApproved => status == ExpenseStatus.approved;
}
