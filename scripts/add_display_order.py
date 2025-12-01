#!/usr/bin/env python3
"""
Add displayOrder field to all existing products in Firestore
"""

import firebase_admin
from firebase_admin import credentials, firestore

def main():
    # Initialize Firebase
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    
    print("Adding displayOrder to all products...")
    
    # Get all products
    products_ref = db.collection('products')
    products = products_ref.stream()
    
    batch = db.batch()
    count = 0
    
    for product in products:
        product_data = product.to_dict()
        
        # Only add if displayOrder doesn't exist
        if 'displayOrder' not in product_data:
            product_ref = products_ref.document(product.id)
            batch.update(product_ref, {'displayOrder': 0})
            count += 1
            
            if count % 500 == 0:
                print(f"Processed {count} products...")
                batch.commit()
                batch = db.batch()
    
    # Commit remaining
    if count % 500 != 0:
        batch.commit()
    
    print(f"✅ Added displayOrder to {count} products")
    print("Products will maintain current order until manually reordered in category detail screen")

if __name__ == '__main__':
    main()
