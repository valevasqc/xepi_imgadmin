#!/usr/bin/env python3
"""
Initialize pendingCash collection in Firestore.
Creates documents for store, mensajero, and forza with amount=0 if they don't exist.
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin
cred = credentials.Certificate('../serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Define the three cash sources
sources = {
    'store': {
        'amount': 0,
        'source': 'store',
        'updatedAt': firestore.SERVER_TIMESTAMP,
        'saleIds': []
    },
    'mensajero': {
        'amount': 0,
        'source': 'mensajero',
        'updatedAt': firestore.SERVER_TIMESTAMP,
        'saleIds': []
    },
    'forza': {
        'amount': 0,
        'source': 'forza',
        'updatedAt': firestore.SERVER_TIMESTAMP,
        'saleIds': []
    }
}

def init_pending_cash():
    """Initialize pendingCash collection with all sources."""
    pending_cash_ref = db.collection('pendingCash')
    
    for source_id, data in sources.items():
        doc_ref = pending_cash_ref.document(source_id)
        doc = doc_ref.get()
        
        if doc.exists:
            print(f'✓ {source_id} document already exists with amount: {doc.to_dict().get("amount", 0)}')
        else:
            doc_ref.set(data)
            print(f'✓ Created {source_id} document with amount: 0')
    
    print('\n✅ pendingCash collection initialized!')
    print('Documents: store, mensajero, forza')

if __name__ == '__main__':
    init_pending_cash()
