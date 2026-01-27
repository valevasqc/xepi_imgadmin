#!/usr/bin/env python3
"""
Check the complete deposits flow - sales, pending cash, and deposits.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin
cred = credentials.Certificate('../serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

print("="*60)
print("CHECKING DEPOSITS FLOW")
print("="*60)

# 1. Check pending cash collection
print("\n1. PENDING CASH STATE:")
print("-" * 40)
pending_cash_ref = db.collection('pendingCash')
pending_cash_docs = pending_cash_ref.get()

if not pending_cash_docs:
    print("⚠️  NO pendingCash documents found!")
    print("   Run: python3 init_pending_cash.py")
else:
    for doc in pending_cash_docs:
        data = doc.to_dict()
        source = doc.id
        amount = data.get('amount', 0)
        sale_ids = data.get('saleIds', [])
        updated_at = data.get('updatedAt')
        
        print(f"\nSource: {source}")
        print(f"  Amount: Q{amount:.2f}")
        print(f"  Sales: {len(sale_ids)}")
        if updated_at:
            print(f"  Updated: {updated_at}")
        if sale_ids:
            print(f"  Sale IDs: {sale_ids[:3]}{'...' if len(sale_ids) > 3 else ''}")

# 2. Check recent sales
print("\n\n2. RECENT SALES (last 5):")
print("-" * 40)
sales_ref = db.collection('sales')
recent_sales = sales_ref.order_by('createdAt', direction=firestore.Query.DESCENDING).limit(5).get()

if not recent_sales:
    print("No sales found")
else:
    for sale_doc in recent_sales:
        data = sale_doc.to_dict()
        sale_id = sale_doc.id
        sale_type = data.get('saleType', 'N/A')
        payment_method = data.get('paymentMethod', 'N/A')
        total = data.get('total', 0)
        status = data.get('status', 'N/A')
        stock_status = data.get('stockStatus', 'N/A')
        delivery_status = data.get('deliveryStatus', 'N/A')
        deposit_id = data.get('depositId')
        delivery_method = data.get('deliveryMethod')
        created_at = data.get('createdAt')
        
        print(f"\nSale ID: {sale_id[:8]}...")
        print(f"  Type: {sale_type} | Payment: {payment_method} | Total: Q{total:.2f}")
        print(f"  Status: {status} | Stock: {stock_status}")
        if sale_type == 'delivery':
            print(f"  Delivery: {delivery_method} | Status: {delivery_status}")
        print(f"  Deposit ID: {deposit_id if deposit_id else 'None'}")
        if created_at:
            print(f"  Created: {created_at}")
        
        # Check if this sale should be in pending cash
        if payment_method == 'efectivo' and status == 'approved':
            if sale_type == 'kiosko' and stock_status == 'completed':
                print(f"  ✓ Should be in pendingCash/store")
            elif sale_type == 'delivery' and delivery_status == 'delivered':
                expected_source = delivery_method if delivery_method else 'unknown'
                print(f"  ✓ Should be in pendingCash/{expected_source}")
            elif sale_type == 'delivery' and delivery_status != 'delivered':
                print(f"  ⏳ Waiting for delivery (not in pending cash yet)")

# 3. Check deposits
print("\n\n3. RECENT DEPOSITS (last 3):")
print("-" * 40)
deposits_ref = db.collection('deposits')
recent_deposits = deposits_ref.order_by('depositedAt', direction=firestore.Query.DESCENDING).limit(3).get()

if not recent_deposits:
    print("No deposits found")
else:
    for deposit_doc in recent_deposits:
        data = deposit_doc.to_dict()
        deposit_id = deposit_doc.id
        source = data.get('source', 'N/A')
        amount = data.get('amount', 0)
        sale_ids = data.get('saleIds', [])
        deposited_at = data.get('depositedAt')
        
        print(f"\nDeposit ID: {deposit_id[:8]}...")
        print(f"  Source: {source} | Amount: Q{amount:.2f}")
        print(f"  Sales linked: {len(sale_ids)}")
        if deposited_at:
            print(f"  Deposited: {deposited_at}")

# 4. Flow validation
print("\n\n4. FLOW VALIDATION:")
print("-" * 40)

# Check for efectivo sales not in pending cash and not deposited
all_sales = sales_ref.where('paymentMethod', '==', 'efectivo').where('status', '==', 'approved').get()
orphaned_sales = []

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
        continue
    
    # Check if should be in pending cash
    should_be_in_pending = False
    expected_source = None
    
    if sale_type == 'kiosko' and stock_status == 'completed':
        should_be_in_pending = True
        expected_source = 'store'
    elif sale_type == 'delivery' and delivery_status == 'delivered':
        should_be_in_pending = True
        expected_source = delivery_method if delivery_method else 'unknown'
    
    if should_be_in_pending:
        # Check if in pending cash
        pending_doc = db.collection('pendingCash').document(expected_source).get()
        if pending_doc.exists:
            pending_data = pending_doc.to_dict()
            pending_sale_ids = pending_data.get('saleIds', [])
            if sale_id not in pending_sale_ids:
                orphaned_sales.append({
                    'id': sale_id,
                    'type': sale_type,
                    'source': expected_source,
                    'total': total
                })

if orphaned_sales:
    print(f"⚠️  Found {len(orphaned_sales)} sales NOT in pending cash:")
    for sale in orphaned_sales[:5]:
        print(f"  - {sale['id'][:8]}... ({sale['type']}) → should be in {sale['source']}, Q{sale['total']:.2f}")
else:
    print("✅ All efectivo sales are properly tracked!")

print("\n" + "="*60)
print("Check complete!")
print("="*60)
