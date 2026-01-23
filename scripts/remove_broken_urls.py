#!/usr/bin/env python3
"""
Remove URLs from Realtime Database that point to non-existent Storage files.
"""

import firebase_admin
from firebase_admin import credentials, db, storage
import requests

cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com',
    'storageBucket': 'xepi-f5c22.firebasestorage.app'
})

def check_url_exists(url):
    """Check if a Storage URL returns 200 (file exists) or 404 (missing)"""
    try:
        response = requests.head(url, timeout=5)
        return response.status_code == 200
    except:
        return False

ref = db.reference('images')
categories = ref.get()

if not categories:
    print('❌ No categories found')
    exit(1)

total_checked = 0
total_broken = 0

for category_name, category_data in categories.items():
    if not isinstance(category_data, dict):
        continue
    
    products = category_data.get('products', {})
    if not products:
        continue
    
    print(f'\n📁 {category_name}')
    
    # Collect all URLs
    urls = []
    if isinstance(products, list):
        urls = [item for item in products if item and isinstance(item, str) and item.startswith('http')]
    else:
        urls = [value for value in products.values() if value and isinstance(value, str) and value.startswith('http')]
    
    print(f'   Checking {len(urls)} URLs...')
    
    # Check which URLs are valid
    valid_urls = []
    broken_count = 0
    
    for url in urls:
        total_checked += 1
        if check_url_exists(url):
            valid_urls.append(url)
        else:
            broken_count += 1
            total_broken += 1
            print(f'   ❌ Broken: {url.split("/")[-1][:50]}...')
    
    if broken_count > 0:
        print(f'   ⚠️  Found {broken_count} broken URLs')
        # Rewrite with only valid URLs
        cleaned = {str(i): url for i, url in enumerate(valid_urls)}
        db.reference(f'images/{category_name}/products').set(cleaned)
        print(f'   ✅ Cleaned - {len(valid_urls)} valid URLs remain')
    else:
        print(f'   ✅ All URLs valid')

print(f'\n' + '='*50)
print(f'📊 SUMMARY:')
print(f'   Checked: {total_checked} URLs')
print(f'   Removed: {total_broken} broken links')
print('='*50)
