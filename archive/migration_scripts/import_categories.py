"""
Import categories from Excel to Firestore
Usage: python scripts/import_categories.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
from datetime import datetime

# Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Bulk pricing configuration (only for specific categories)
BULK_PRICING_CATEGORIES = {
    'LAT-2030': {
        'normal': 35,
        'qty2': 30,      # Price per unit when buying 2
        'qty3Plus': 25   # Price per unit when buying 3+
    },
    'LAT-1530': {
        'normal': 35,
        'qty2': 30,
        'qty3Plus': 25
    }
}

def extract_primary_code(code):
    """Extract primary category code (e.g., 'LAT' from 'LAT-2030')"""
    if '-' in code:
        return code.split('-')[0]
    return code

def generate_category_name(categoria, subcategoria):
    """Generate full category name"""
    if pd.isna(subcategoria) or subcategoria == '':
        return categoria
    return f"{categoria} {subcategoria}"

def import_categories():
    """Import categories from Excel to Firestore"""
    
    print("📊 Reading Excel file...")
    df = pd.read_excel('data/categorias.xlsx')
    
    print(f"✅ Found {len(df)} categories\n")
    
    # Track stats
    imported = 0
    errors = 0
    
    for index, row in df.iterrows():
        try:
            code = row['Code'].strip()
            categoria = row['Categoría'].strip()
            subcategoria = row['Subcategoría'] if pd.notna(row['Subcategoría']) else None
            precio = row['Precio'] if pd.notna(row['Precio']) else None
            
            # Extract primary code
            primary_code = extract_primary_code(code)
            
            # Generate full name
            name = generate_category_name(categoria, subcategoria)
            
            # Build category document
            category_doc = {
                'code': code,
                'name': name,
                'primaryCategory': categoria,
                'primaryCode': primary_code,
                'subcategoryName': subcategoria,
                'hasSubcategories': subcategoria is not None,
                'defaultPrice': precio,
                'bulkPricing': BULK_PRICING_CATEGORIES.get(code),  # None if not in dict
                'isActive': True,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'displayOrder': index + 1,  # Keep Excel order
                'coverImageUrl': None,
                'notes': None
            }
            
            # Import to Firestore (using code as document ID)
            db.collection('categories').document(code).set(category_doc)
            
            # Print progress
            bulk_indicator = " 🎁 (bulk pricing)" if code in BULK_PRICING_CATEGORIES else ""
            price_str = f"Q{precio}" if precio else "No price"
            print(f"✅ {code}: {name} - {price_str}{bulk_indicator}")
            
            imported += 1
            
        except Exception as e:
            print(f"❌ Error importing row {index + 1}: {e}")
            errors += 1
    
    print(f"\n{'='*60}")
    print(f"📦 Import Complete!")
    print(f"✅ Successfully imported: {imported}")
    if errors > 0:
        print(f"❌ Errors: {errors}")
    print(f"{'='*60}\n")
    
    # Print summary by primary category
    print("📊 Summary by Primary Category:")
    df_summary = df.groupby('Categoría').size()
    for categoria, count in df_summary.items():
        print(f"   {categoria}: {count} subcategories")

if __name__ == '__main__':
    try:
        import_categories()
        print("\n✨ All done! Check Firestore Console to verify.")
    except FileNotFoundError as e:
        if 'serviceAccountKey.json' in str(e):
            print("\n❌ ERROR: serviceAccountKey.json not found!")
            print("📝 Please download it from Firebase Console:")
            print("   1. Go to Project Settings → Service Accounts")
            print("   2. Click 'Generate new private key'")
            print("   3. Save as 'serviceAccountKey.json' in project root\n")
        elif 'categorias.xlsx' in str(e):
            print("\n❌ ERROR: data/categorias.xlsx not found!")
            print("📝 Please make sure the Excel file exists in the data/ folder\n")
        else:
            print(f"\n❌ ERROR: {e}\n")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}\n")
