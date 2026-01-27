"""
Upload product images from local folder to Firebase Storage and link to Firestore
Usage: python scripts/upload_images.py

Images should be named by barcode (e.g., 1003023000018.jpg)
Multiple images per product: 1003023000018_1.jpg, 1003023000018_2.jpg, etc.
Main image will be the one with lowest suffix or the only image.

Supported formats: .jpg, .jpeg, .png, .webp, .gif
"""

import os
import re
import firebase_admin
from firebase_admin import credentials, firestore, storage
from datetime import datetime
from pathlib import Path

# Initialize Firebase (reuse existing app if already initialized)
try:
    db = firestore.client()
    bucket = storage.bucket()
except ValueError:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred, {
        'storageBucket': 'xepi-f5c22.firebasestorage.app'
    })
    db = firestore.client()
    bucket = storage.bucket()

# Supported image formats
IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.gif'}

def parse_image_filename(filename):
    """
    Parse image filename to extract barcode and suffix number
    
    Examples:
    - 1003023000018.jpg -> ('1003023000018', 0, '.jpg')
    - 1003023000018_1.jpg -> ('1003023000018', 1, '.jpg')
    - 1003023000018_2.jpg -> ('1003023000018', 2, '.jpg')
    
    Returns: (barcode, suffix_number, extension) or None if invalid
    """
    name, ext = os.path.splitext(filename)
    ext = ext.lower()
    
    if ext not in IMAGE_EXTENSIONS:
        return None
    
    # Check for suffix pattern (barcode_N)
    match = re.match(r'^(\d{13})(?:_(\d+))?$', name)
    if not match:
        return None
    
    barcode = match.group(1)
    suffix = int(match.group(2)) if match.group(2) else 0
    
    return (barcode, suffix, ext)

def get_images_by_barcode(images_folder):
    """
    Group images by barcode
    
    Returns: dict {barcode: [(filepath, suffix, extension), ...]}
    """
    images_by_barcode = {}
    
    for filename in os.listdir(images_folder):
        filepath = os.path.join(images_folder, filename)
        
        # Skip directories and hidden files
        if not os.path.isfile(filepath) or filename.startswith('.'):
            continue
        
        parsed = parse_image_filename(filename)
        if not parsed:
            print(f"⚠️  Skipping invalid filename: {filename}")
            continue
        
        barcode, suffix, ext = parsed
        
        if barcode not in images_by_barcode:
            images_by_barcode[barcode] = []
        
        images_by_barcode[barcode].append((filepath, suffix, ext))
    
    # Sort images by suffix (main image first)
    for barcode in images_by_barcode:
        images_by_barcode[barcode].sort(key=lambda x: x[1])
    
    return images_by_barcode

def upload_image_to_storage(filepath, barcode, filename):
    """
    Upload image to Firebase Storage
    
    Returns: public URL or None on error
    """
    try:
        # Storage path: products/{barcode}/{filename}
        blob_path = f'products/{barcode}/{filename}'
        blob = bucket.blob(blob_path)
        
        # Upload file
        blob.upload_from_filename(filepath)
        
        # Make publicly accessible
        blob.make_public()
        
        return blob.public_url
    
    except Exception as e:
        print(f"❌ Error uploading {filename}: {e}")
        return None

def update_product_images(barcode, image_urls):
    """
    Update product in Firestore with new image URLs
    Replaces existing images array
    
    Returns: True on success, False on error
    """
    try:
        product_ref = db.collection('products').document(barcode)
        product_doc = product_ref.get()
        
        if not product_doc.exists:
            print(f"❌ Product not found in Firestore: {barcode}")
            return False
        
        # Update with new images (replaces old ones)
        product_ref.update({
            'images': image_urls,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })
        
        return True
    
    except Exception as e:
        print(f"❌ Error updating Firestore for {barcode}: {e}")
        return False

def upload_product_images():
    """Main function to upload images and update Firestore"""
    
    images_folder = 'data/images'
    
    if not os.path.exists(images_folder):
        print(f"❌ Images folder not found: {images_folder}")
        return
    
    print("📷 Scanning images folder...")
    images_by_barcode = get_images_by_barcode(images_folder)
    
    if not images_by_barcode:
        print("⚠️  No valid images found in folder")
        return
    
    print(f"✅ Found {len(images_by_barcode)} product(s) with images\n")
    
    # Statistics
    total_products = len(images_by_barcode)
    total_images = sum(len(imgs) for imgs in images_by_barcode.values())
    success_count = 0
    error_count = 0
    
    print(f"📊 Total: {total_products} products, {total_images} images\n")
    print("🚀 Starting upload...\n")
    
    for barcode, image_files in images_by_barcode.items():
        print(f"📦 Processing product: {barcode}")
        print(f"   Images: {len(image_files)}")
        
        uploaded_urls = []
        
        # Upload all images for this product
        for i, (filepath, suffix, ext) in enumerate(image_files):
            filename = os.path.basename(filepath)
            print(f"   ↗️  Uploading {filename}...", end=' ')
            
            # Generate unique filename with timestamp
            timestamp = int(datetime.now().timestamp() * 1000)
            new_filename = f"{barcode}_{timestamp}_{filename}"
            
            url = upload_image_to_storage(filepath, barcode, new_filename)
            
            if url:
                uploaded_urls.append(url)
                main_marker = " (MAIN)" if i == 0 else ""
                print(f"✅{main_marker}")
            else:
                print(f"❌")
        
        # Update Firestore if at least one image uploaded successfully
        if uploaded_urls:
            print(f"   💾 Updating Firestore...", end=' ')
            if update_product_images(barcode, uploaded_urls):
                print(f"✅")
                success_count += 1
            else:
                print(f"❌")
                error_count += 1
        else:
            print(f"   ❌ No images uploaded for {barcode}")
            error_count += 1
        
        print()  # Blank line between products
    
    # Summary
    print("=" * 50)
    print("📊 UPLOAD SUMMARY")
    print("=" * 50)
    print(f"✅ Success: {success_count} products")
    print(f"❌ Errors: {error_count} products")
    print(f"📷 Total images uploaded: {sum(len(imgs) for imgs in images_by_barcode.values())}")
    print("=" * 50)
    
    if error_count == 0:
        print("\n🎉 All images uploaded successfully!")
    else:
        print(f"\n⚠️  {error_count} product(s) had errors. Check logs above.")

if __name__ == '__main__':
    try:
        upload_product_images()
    except KeyboardInterrupt:
        print("\n\n⚠️  Upload interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
