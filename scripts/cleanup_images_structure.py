#!/usr/bin/env python3
import firebase_admin
from firebase_admin import credentials, db, storage
import requests

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com',
    'storageBucket': 'xepi-f5c22.firebasestorage.app'
})

bucket = storage.bucket()
images_ref = db.reference('images')
all_categories = images_ref.get()

if not all_categories:
    print("No categories found")
    exit()

print(f"Found {len(all_categories)} categories\n")

for category, data in all_categories.items():
    if not isinstance(data, dict):
        continue
    
    print(f"\n{'='*60}")
    print(f"Category: {category}")
    print(f"{'='*60}")
    
    # Check old img_* keys and verify if URLs are valid
    old_keys = [k for k in data.keys() if k.startswith('img_')]
    if old_keys:
        print(f"Found {len(old_keys)} old img_* keys")
        
        broken_keys = []
        for key in old_keys:
            url = data[key]
            if not url or not isinstance(url, str) or not url.startswith('http'):
                broken_keys.append(key)
                print(f"  ✗ {key}: NULL/INVALID")
            else:
                # Check if URL is accessible
                try:
                    response = requests.head(url, timeout=5)
                    if response.status_code == 404:
                        broken_keys.append(key)
                        print(f"  ✗ {key}: 404 NOT FOUND")
                    else:
                        print(f"  ✓ {key}: OK")
                except Exception as e:
                    broken_keys.append(key)
                    print(f"  ✗ {key}: ERROR ({str(e)[:30]})")
        
        if broken_keys:
            print(f"\nDeleting {len(broken_keys)} broken img_* keys...")
            updates = {key: None for key in broken_keys}
            category_ref = db.reference(f'images/{category}')
            category_ref.update(updates)
            print("✓ Deleted")
        else:
            print("\n✓ All img_* keys are valid")
    else:
        print("No old img_* keys found")

print(f"\n{'='*60}")
print("Cleanup complete!")
