#!/usr/bin/env python3
"""
Fix sales that were marked as 'completed' without adding to pending cash.
Finds delivery+efectivo sales with deliveryStatus='completed' and no depositId,
then adds them to pending cash.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase
cred = credentials.Certificate('../serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 60)
print("FIXING COMPLETED SALES WITHOUT PENDING CASH")
print("=" * 60)

# Find all delivery + efectivo sales with deliveryStatus='completed' and no deposit
sales_ref = db.collection('sales')
all_sales = sales_ref.where('saleType', '==', 'delivery').where('paymentMethod', '==', 'efectivo').get()

fixed_count = 0
skipped_count = 0

for sale_doc in all_sales:
    sale_data = sale_doc.to_dict()
    sale_id = sale_doc.id
    
    delivery_status = sale_data.get('deliveryStatus')
    deposit_id = sale_data.get('depositId')
    
    # Only fix if completed/cash_received and no deposit
    if delivery_status in ['completed', 'cash_received'] and deposit_id is None:
        delivery_method = sale_data.get('deliveryMethod')
        total = sale_data.get('total', 0)
        
        # Determine cash source
        if delivery_method == 'mensajero':
            cash_source = 'mensajero'
        elif delivery_method == 'forza':
            cash_source = 'forza'
        else:
            cash_source = 'store'
        
        print(f"Fixing sale: {sale_id[:8]}...")
        print(f"  Type: delivery")
        print(f"  Total: Q{total:.2f}")
        print(f"  Adding to: pendingCash/{cash_source}")
        
        # Add to pending cash
        pending_cash_ref = db.collection('pendingCash').document(cash_source)
        pending_cash_ref.set({
            'source': cash_source,
            'amount': firestore.firestore.Increment(total),
            'saleIds': firestore.firestore.ArrayUnion([sale_id]),
            'updatedAt': firestore.firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        print(f"  ✅ Fixed!")
        fixed_count += 1
    else:
        skipped_count += 1

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"Fixed: {fixed_count} sales")
print(f"Skipped: {skipped_count} sales")

if fixed_count > 0:
    print("\nFixed sales have been added to pending cash.")
    
print("\n✅ Done!")
