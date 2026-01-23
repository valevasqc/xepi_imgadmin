#!/usr/bin/env python3
"""
Clean all categories - remove duplicates and keep only unique URLs.
"""

import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com'
})

ref = db.reference('images')
categories = ref.get()

if not categories:
    print('❌ No categories found')
    exit(1)

total_before = 0
total_after = 0

for category_name, category_data in categories.items():
    if not isinstance(category_data, dict):
        continue
    
    products = category_data.get('products', {})
    if not products:
        continue
    
    print(f'\n📁 {category_name}')
    
    # Count original
    if isinstance(products, list):
        original_count = len(products)
    else:
        original_count = len(products)
    
    print(f'   Found {original_count} entries')
    
    # Collect unique URLs
    seen = set()
    unique_images = []
    
    if isinstance(products, list):
        for item in products:
            if item and isinstance(item, str) and item.startswith('http'):
                if item not in seen:
                    seen.add(item)
                    unique_images.append(item)
    else:
        for key, value in products.items():
            if value and isinstance(value, str) and value.startswith('http'):
                if value not in seen:
                    seen.add(value)
                    unique_images.append(value)
    
    unique_count = len(unique_images)
    removed = original_count - unique_count
    
    if removed > 0:
        print(f'   ⚠️  Removing {removed} duplicates/invalid entries')
        # Rewrite with sequential keys
        cleaned = {str(i): url for i, url in enumerate(unique_images)}
        db.reference(f'images/{category_name}/products').set(cleaned)
        print(f'   ✅ Cleaned - {unique_count} images remain')
    else:
        print(f'   ✅ Already clean')
    
    total_before += original_count
    total_after += unique_count

print(f'\n' + '='*50)
print(f'📊 SUMMARY:')
print(f'   Before: {total_before} total entries')
print(f'   After: {total_after} unique images')
print(f'   Removed: {total_before - total_after} duplicates/invalid')
print('='*50)
