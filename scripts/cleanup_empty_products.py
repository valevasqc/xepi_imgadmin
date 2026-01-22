#!/usr/bin/env python3
"""
Script to clean up empty/null product entries from Firebase Realtime Database
"""
import firebase_admin
from firebase_admin import credentials, db
import json

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com'
})

def cleanup_empty_products():
    """Remove null, empty, __placeholder__, and _empty entries from all categories"""
    ref = db.reference('images')
    categories = ref.get()
    
    if not categories:
        print("No categories found.")
        return
    
    total_removed = 0
    
    for category_name, category_data in categories.items():
        if not isinstance(category_data, dict):
            continue
            
        products = category_data.get('products', {})
        if not isinstance(products, dict):
            continue
        
        # Find keys to remove
        keys_to_remove = []
        for key, value in products.items():
            if (value is None or 
                key == '__placeholder__' or 
                key == '_empty' or
                (isinstance(value, str) and value.strip() == '')):
                keys_to_remove.append(key)
        
        # Remove empty entries
        if keys_to_remove:
            print(f"\nCategory: {category_name}")
            print(f"  Found {len(keys_to_remove)} empty entries to remove: {keys_to_remove}")
            
            for key in keys_to_remove:
                ref.child(category_name).child('products').child(key).delete()
                total_removed += 1
                print(f"  ✓ Removed: {key}")
    
    print(f"\n{'='*60}")
    print(f"Cleanup complete! Removed {total_removed} empty entries total.")
    print(f"{'='*60}")

if __name__ == '__main__':
    print("Starting cleanup of empty product entries...")
    print(f"{'='*60}")
    cleanup_empty_products()
