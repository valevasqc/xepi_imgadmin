#!/usr/bin/env python3
"""
Remove duplicate images from a category and reindex sequentially.
"""

import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com'
})

category = input('Enter category name (e.g., "Cuadros Decorativos"): ')

ref = db.reference(f'images/{category}/products')
data = ref.get()

if not data:
    print(f'❌ No products found for category: {category}')
    exit(1)

print(f'Found {len(data)} entries')

# Collect unique URLs
seen = set()
unique_images = []

if isinstance(data, list):
    for item in data:
        if item and isinstance(item, str) and item.startswith('http'):
            if item not in seen:
                seen.add(item)
                unique_images.append(item)
else:
    for key, value in data.items():
        if value and isinstance(value, str) and value.startswith('http'):
            if value not in seen:
                seen.add(value)
                unique_images.append(value)

print(f'\n✅ Found {len(unique_images)} unique images')
print(f'⚠️  Removing {len(data) - len(unique_images)} duplicates')

proceed = input('\nProceed with cleanup? (yes/no): ')
if proceed.lower() != 'yes':
    print('Cancelled')
    exit(0)

# Rewrite with sequential keys
cleaned = {str(i): url for i, url in enumerate(unique_images)}
ref.set(cleaned)

print(f'\n✅ Database cleaned! {len(unique_images)} images remain.')
