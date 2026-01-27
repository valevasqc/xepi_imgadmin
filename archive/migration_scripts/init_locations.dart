import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:xepi_imgadmin/firebase_options.dart';

/// Run this script to initialize the locations collection in Firestore
///
/// Execute with: dart run scripts/init_locations.dart
///
/// This creates:
/// - locations/warehouse (Bodega Principal, maps to stockWarehouse)
/// - locations/store (Kiosco Zona 13, maps to stockStore)

Future<void> main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('Connected to Firestore');

  try {
    // Create warehouse location
    print('\nCreating warehouse location...');
    await firestore.collection('locations').doc('warehouse').set({
      'id': 'warehouse',
      'name': 'Bodega Principal',
      'type': 'warehouse',
      'stockField': 'stockWarehouse',
      'isActive': true,
      'displayOrder': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✓ Warehouse location created');

    // Create store location
    print('\nCreating store location...');
    await firestore.collection('locations').doc('store').set({
      'id': 'store',
      'name': 'Kiosco Zona 13',
      'type': 'store',
      'stockField': 'stockStore',
      'isActive': true,
      'displayOrder': 2,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✓ Store location created');

    // Verify creation
    print('\nVerifying locations...');
    final snapshot = await firestore.collection('locations').get();
    print('Total locations: ${snapshot.docs.length}');
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('  - ${data['name']} (${data['type']}) -> ${data['stockField']}');
    }

    print('\n✓ Locations collection initialized successfully!');
  } catch (e) {
    print('\n✗ Error: $e');
  }
}
