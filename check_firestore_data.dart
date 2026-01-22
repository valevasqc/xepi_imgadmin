import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final db = FirebaseFirestore.instance;
  
  print('=== CHECKING PENDING CASH ===');
  final pendingCashDocs = await db.collection('pendingCash').get();
  for (var doc in pendingCashDocs.docs) {
    print('${doc.id}: ${doc.data()}');
  }
  
  print('\n=== CHECKING RECENT SALES (last 5) ===');
  final salesDocs = await db.collection('sales')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();
  
  for (var doc in salesDocs.docs) {
    final data = doc.data();
    print('\nSale ID: ${doc.id}');
    print('  Type: ${data['saleType']}');
    print('  Payment: ${data['paymentMethod']}');
    print('  Total: ${data['total']}');
    print('  Status: ${data['status']}');
    print('  Delivery Status: ${data['deliveryStatus']}');
    print('  Stock Status: ${data['stockStatus']}');
    print('  DepositId: ${data['depositId']}');
    print('  Created: ${data['createdAt']}');
  }
  
  print('\n=== CHECKING DEPOSITS (last 3) ===');
  final depositsDocs = await db.collection('deposits')
      .orderBy('depositedAt', descending: true)
      .limit(3)
      .get();
  
  if (depositsDocs.docs.isEmpty) {
    print('No deposits found');
  } else {
    for (var doc in depositsDocs.docs) {
      print('\n${doc.id}: ${doc.data()}');
    }
  }
  
  exit(0);
}
