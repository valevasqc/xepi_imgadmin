#!/usr/bin/env python3
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

print('=== CHECKING PENDING CASH ===')
pending_cash_docs = db.collection('pendingCash').get()
if not pending_cash_docs:
    print('No pendingCash documents found')
else:
    for doc in pending_cash_docs:
        data = doc.to_dict()
        print(f'{doc.id}: amount={data.get("amount", 0)}, saleIds={len(data.get("saleIds", []))} sales')
        print(f'  Full data: {data}')

print('\n=== CHECKING RECENT SALES (last 3) ===')
sales_docs = db.collection('sales').order_by('createdAt', direction=firestore.Query.DESCENDING).limit(3).get()

if not sales_docs:
    print('No sales found')
else:
    for doc in sales_docs:
        data = doc.to_dict()
        print(f'\nSale ID: {doc.id}')
        print(f'  Type: {data.get("saleType")}')
        print(f'  Payment: {data.get("paymentMethod")}')
        print(f'  Total: Q{data.get("total", 0):.2f}')
        print(f'  Status: {data.get("status")}')
        print(f'  Delivery Status: {data.get("deliveryStatus")}')
        print(f'  Stock Status: {data.get("stockStatus")}')
        print(f'  DepositId: {data.get("depositId")}')
        print(f'  Created: {data.get("createdAt")}')

print('\n=== CHECKING DEPOSITS (last 3) ===')
deposits_docs = db.collection('deposits').order_by('depositedAt', direction=firestore.Query.DESCENDING).limit(3).get()

if not deposits_docs:
    print('No deposits found')
else:
    for doc in deposits_docs:
        data = doc.to_dict()
        print(f'\nDeposit ID: {doc.id}')
        print(f'  Source: {data.get("source")}')
        print(f'  Amount: Q{data.get("amount", 0):.2f}')
        print(f'  Sale IDs: {len(data.get("saleIds", []))} sales')
        print(f'  Created: {data.get("depositedAt")}')

print('\n=== CHECKING SPECIFIC SALE (eS15lbAyecuJ4Hhfgitc) ===')
specific_sale = db.collection('sales').document('eS15lbAyecuJ4Hhfgitc').get()
if specific_sale.exists:
    data = specific_sale.to_dict()
    print('Sale Details:')
    print(f'  saleType: {data.get("saleType")}')
    print(f'  deliveryMethod: {data.get("deliveryMethod")}')
    print(f'  paymentMethod: {data.get("paymentMethod")}')
    print(f'  total: Q{data.get("total")}')
    print(f'  deliveryStatus: {data.get("deliveryStatus")}')
    print(f'  depositId: {data.get("depositId")}')
    print(f'  pendingCashSource: {data.get("pendingCashSource")}')
