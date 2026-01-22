#!/usr/bin/env python3
"""
Script to check for orphaned images in Firebase Storage vs Realtime Database
"""
import firebase_admin
from firebase_admin import credentials, db, storage
import json

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://xepi-f5c22-default-rtdb.firebaseio.com',
    'storageBucket': 'xepi-f5c22.firebasestorage.app'
})

def check_orphaned_images():
    """Check for images in Storage that don't exist in Database"""
    db_ref = db.reference('images')
    categories = db_ref.get()
    
    if not categories:
        print("No categories found in database.")
        return
    
    # Get all image URLs from database
    db_image_urls = set()
    for category_name, category_data in categories.items():
        if not isinstance(category_data, dict):
            continue
            
        products = category_data.get('products', {})
        if isinstance(products, dict):
            for key, value in products.items():
                if value and isinstance(value, str) and value.startswith('http'):
                    db_image_urls.add(value)
        
        # Also check cover image
        cover_image = category_data.get('coverImage')
        if cover_image:
            db_image_urls.add(cover_image)
    
    print(f"Found {len(db_image_urls)} image URLs in database")
    
    # Check Storage
    bucket = storage.bucket()
    storage_images = []
    
    print("\nChecking Firebase Storage...")
    
    for category_name in categories.keys():
        # Check products folder
        blobs = bucket.list_blobs(prefix=f'products/{category_name}/')
        for blob in blobs:
            storage_images.append({
                'path': blob.name,
                'url': f'https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{blob.name.replace("/", "%2F")}?alt=media',
                'size': blob.size,
                'updated': blob.updated
            })
    
    print(f"Found {len(storage_images)} images in Storage\n")
    
    # Find orphans
    orphans = []
    for img in storage_images:
        # Try to find this image URL in database (fuzzy match since URL encoding might differ)
        found = False
        for db_url in db_image_urls:
            if img['path'].split('/')[-1] in db_url:  # Match by filename
                found = True
                break
        
        if not found:
            orphans.append(img)
    
    if orphans:
        print(f"{'='*60}")
        print(f"⚠️  Found {len(orphans)} orphaned images in Storage:")
        print(f"{'='*60}\n")
        
        for orphan in orphans:
            print(f"Path: {orphan['path']}")
            print(f"Size: {orphan['size']} bytes")
            print(f"Last updated: {orphan['updated']}")
            print()
        
        print(f"{'='*60}")
        print("These images exist in Storage but not in Database.")
        print("They may be causing empty cards to appear.")
        print(f"{'='*60}")
    else:
        print(f"{'='*60}")
        print("✓ No orphaned images found!")
        print("All Storage images have corresponding Database entries.")
        print(f"{'='*60}")

    # Also check for database entries with invalid URLs
    print("\n\nChecking for invalid URLs in database...")
    invalid_count = 0
    for category_name, category_data in categories.items():
        if not isinstance(category_data, dict):
            continue
            
        products = category_data.get('products', {})
        if isinstance(products, dict):
            for key, value in products.items():
                if not value or not isinstance(value, str) or not value.startswith('http'):
                    print(f"⚠️  Category '{category_name}', product key '{key}': Invalid URL = {repr(value)}")
                    invalid_count += 1
    
    if invalid_count == 0:
        print("✓ All database entries have valid URLs")
    else:
        print(f"\n⚠️  Found {invalid_count} invalid entries in database")

if __name__ == '__main__':
    print("Checking for orphaned images and data integrity issues...")
    print(f"{'='*60}\n")
    check_orphaned_images()
