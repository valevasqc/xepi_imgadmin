#!/usr/bin/env python3
import firebase_admin
from firebase_admin import credentials, db

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com'
})

category = 'Rompecabezas'
ref = db.reference(f'images/{category}')
data = ref.get()

if not data:
    print(f"No data found for {category}")
    exit()

print(f"Current keys in {category}:")
for key in data.keys():
    print(f"  - {key}")

# Remove all img_* keys (old structure)
updates = {}
for key in data.keys():
    if key.startswith('img_'):
        updates[key] = None  # Delete by setting to None
        print(f"Will delete: {key}")

if updates:
    print(f"\nDeleting {len(updates)} top-level image keys...")
    ref.update(updates)
    print("Done!")
else:
    print("No top-level image keys to delete")
