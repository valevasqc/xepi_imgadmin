#!/usr/bin/env python3
"""
Clean up pending cash collection - remove stale sale references and fix amounts.
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
cred = credentials.Certificate('../serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

def cleanup_pending_cash():
    """Clean up pending cash by validating all sale references."""
    pending_cash_ref = db.collection('pendingCash')
    
    for source_doc in pending_cash_ref.stream():
        source_id = source_doc.id
        data = source_doc.to_dict()
        
        sale_ids = data.get('saleIds', [])
        current_amount = data.get('amount', 0)
        
        print(f'\n=== Checking {source_id} ===')
        print(f'Current amount: Q{current_amount:.2f}')
        print(f'Sale IDs count: {len(sale_ids)}')
        
        if not sale_ids:
            print('No sales linked, skipping...')
            continue
        
        # Verify each sale exists and calculate correct total
        valid_sale_ids = []
        correct_total = 0.0
        
        for sale_id in sale_ids:
            sale_ref = db.collection('sales').document(sale_id)
            sale_doc = sale_ref.get()
            
            if sale_doc.exists:
                sale_data = sale_doc.to_dict()
                total = sale_data.get('total', 0)
                delivery_status = sale_data.get('deliveryStatus', 'N/A')
                payment_method = sale_data.get('paymentMethod', 'N/A')
                
                print(f'  ✓ Sale {sale_id}: Q{total:.2f} ({payment_method}, {delivery_status})')
                valid_sale_ids.append(sale_id)
                correct_total += total
            else:
                print(f'  ✗ Sale {sale_id}: NOT FOUND (will be removed)')
        
        # Update if needed
        if len(valid_sale_ids) != len(sale_ids) or abs(correct_total - current_amount) > 0.01:
            print(f'\n⚠️  Updating {source_id}:')
            print(f'  Old: {len(sale_ids)} sales, Q{current_amount:.2f}')
            print(f'  New: {len(valid_sale_ids)} sales, Q{correct_total:.2f}')
            
            if valid_sale_ids:
                # Update with correct values
                pending_cash_ref.document(source_id).update({
                    'amount': correct_total,
                    'saleIds': valid_sale_ids,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
                print(f'✅ Updated {source_id}')
            else:
                # No valid sales, reset to 0
                pending_cash_ref.document(source_id).update({
                    'amount': 0,
                    'saleIds': [],
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
                print(f'✅ Reset {source_id} to zero')
        else:
            print(f'✓ {source_id} is correct, no update needed')
    
    print('\n✅ Cleanup complete!')

if __name__ == '__main__':
    cleanup_pending_cash()
