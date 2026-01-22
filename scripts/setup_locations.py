#!/usr/bin/env python3
"""
Setup locations collection in Firestore
Run: python3 scripts/setup_locations.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

print("Creating locations collection...\n")

# Create warehouse location
warehouse_data = {
    'id': 'warehouse',
    'name': 'Bodega Principal',
    'type': 'warehouse',
    'stockField': 'stockWarehouse',
    'isActive': True,
    'displayOrder': 1,
    'createdAt': firestore.SERVER_TIMESTAMP,
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('locations').document('warehouse').set(warehouse_data)
print("✓ Created warehouse location")

# Create store location
store_data = {
    'id': 'store',
    'name': 'Kiosco Zona 13',
    'type': 'store',
    'stockField': 'stockStore',
    'isActive': True,
    'displayOrder': 2,
    'createdAt': firestore.SERVER_TIMESTAMP,
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('locations').document('store').set(store_data)
print("✓ Created store location")

# Verify
locations = db.collection('locations').stream()
print("\nVerifying locations:")
for loc in locations:
    data = loc.to_dict()
    print(f"  - {data['name']} ({data['type']}) -> {data['stockField']}")

print("\n✓ Locations collection initialized successfully!")
