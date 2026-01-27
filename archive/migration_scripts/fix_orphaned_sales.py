#!/usr/bin/env python3
"""
Fix orphaned sales that should be in pending cash but aren't.
This happens for sales created before the pending cash logic was implemented.
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
cred = credentials.Certificate('../serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

print("="*60)
print("FIXING ORPHANED SALES")
print("="*60)

# Find all efectivo sales that should be in pending cash but aren't
sales_ref = db.collection('sales')
all_sales = sales_ref.where('paymentMethod', '==', 'efectivo').where('status', '==', 'approved').get()

fixed_sales = []
skipped_sales = []

for sale_doc in all_sales:
    data = sale_doc.to_dict()
    sale_id = sale_doc.id
    sale_type = data.get('saleType')
    stock_status = data.get('stockStatus')
    delivery_status = data.get('deliveryStatus')
    deposit_id = data.get('depositId')
    delivery_method = data.get('deliveryMethod')
    total = data.get('total', 0)
    
    # Skip if already deposited
    if deposit_id:
        skipped_sales.append(f"{sale_id[:8]} - already deposited")
        continue
    
    # Determine if should be in pending cash
    should_be_in_pending = False
    expected_source = None
    
    if sale_type == 'kiosko' and stock_status == 'completed':
        should_be_in_pending = True
        expected_source = 'store'
    elif sale_type == 'delivery' and delivery_status == 'delivered':
        should_be_in_pending = True
        if delivery_method == 'mensajero':
            expected_source = 'mensajero'
        elif delivery_method == 'forza':
            expected_source = 'forza'
        else:
            expected_source = 'store'  # Default fallback
    
    if should_be_in_pending:
        # Check if already in pending cash
        pending_doc = db.collection('pendingCash').document(expected_source).get()
        if pending_doc.exists:
            pending_data = pending_doc.to_dict()
            pending_sale_ids = pending_data.get('saleIds', [])
            
            if sale_id not in pending_sale_ids:
                # Add to pending cash
                print(f"\nFixing sale: {sale_id[:8]}...")
                print(f"  Type: {sale_type}")
                print(f"  Total: Q{total:.2f}")
                print(f"  Adding to: pendingCash/{expected_source}")
                
                # Update pending cash
                pending_ref = db.collection('pendingCash').document(expected_source)
                pending_ref.update({
                    'amount': firestore.Increment(total),
                    'saleIds': firestore.ArrayUnion([sale_id]),
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
                
                fixed_sales.append({
                    'id': sale_id,
                    'source': expected_source,
                    'total': total
                })
                print(f"  ✅ Fixed!")
            else:
                skipped_sales.append(f"{sale_id[:8]} - already in pending cash")

print("\n" + "="*60)
print("SUMMARY")
print("="*60)
print(f"Fixed: {len(fixed_sales)} sales")
print(f"Skipped: {len(skipped_sales)} sales")

if fixed_sales:
    print("\nFixed sales:")
    for sale in fixed_sales:
        print(f"  - {sale['id'][:8]} → {sale['source']} (Q{sale['total']:.2f})")

if skipped_sales:
    print(f"\nSkipped sales: {skipped_sales[:5]}")
    if len(skipped_sales) > 5:
        print(f"  ... and {len(skipped_sales) - 5} more")

print("\n✅ Done!")
