"""
Import products from Excel to Firestore
Usage: python scripts/import_products.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import re

# Initialize Firebase (reuse existing app if already initialized)
try:
    db = firestore.client()
except ValueError:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()

def format_size(medida):
    """Format size string (e.g., '8X60' -> '8 x 60 cms')"""
    if pd.isna(medida) or medida == '':
        return None
    
    # Convert to string and uppercase
    medida_str = str(medida).upper().strip()
    
    # Match patterns like 8X60, 20X30, etc.
    match = re.match(r'(\d+)\s*X\s*(\d+)', medida_str)
    if match:
        width, height = match.groups()
        return f"{width} x {height} cms"
    
    # If already has 'cms' or other format, return as-is
    return medida_str

def extract_temas(tema):
    """Convert tema to array, even if single value"""
    if pd.isna(tema) or tema == '':
        return []
    
    # For now, single tema. Future: split by comma or semicolon
    return [str(tema).strip()]

def import_products():
    """Import products from Excel to Firestore"""
    
    print("📊 Reading Excel file (all sheets)...")
    
    # Read all sheets
    excel_file = pd.ExcelFile('data/productos.xlsx')
    all_sheets = excel_file.sheet_names
    
    print(f"✅ Found {len(all_sheets)} sheets: {all_sheets}\n")
    
    # Track stats
    total_imported = 0
    total_errors = 0
    total_skipped = 0
    sheet_stats = {}
    
    for sheet_num in range(1, 21):  # Sheets 1-20
        sheet_name = str(sheet_num)
        
        # Skip sheet 18 (no barcodes)
        if sheet_num == 18:
            print(f"⏭️  Sheet {sheet_num}: SKIPPED (no barcodes)\n")
            total_skipped += 1
            continue
        
        if sheet_name not in all_sheets:
            print(f"⚠️  Sheet {sheet_num}: NOT FOUND in Excel\n")
            continue
        
        print(f"📄 Processing Sheet {sheet_num}...")
        
        # Read sheet
        df = pd.read_excel('data/productos.xlsx', sheet_name=sheet_name)
        
        # Verify required columns exist
        required_cols = ['CODIGO_BARRA', 'ID_BODEGA', 'ID_CATEGORIA', 'Categoría', 'Subcategoría']
        missing_cols = [col for col in required_cols if col not in df.columns]
        
        if missing_cols:
            print(f"   ❌ Missing required columns: {missing_cols}\n")
            total_errors += 1
            continue
        
        imported = 0
        errors = 0
        
        for index, row in df.iterrows():
            try:
                # Skip if no barcode
                if pd.isna(row['CODIGO_BARRA']) or row['CODIGO_BARRA'] == '':
                    continue
                
                barcode = str(int(row['CODIGO_BARRA'])).strip()  # Convert to string, remove decimals
                
                # Extract fields
                nombre = row.get('NOMBRE', None)
                if pd.notna(nombre):
                    nombre = str(nombre).strip()
                else:
                    nombre = None
                
                warehouse_code = str(row['ID_BODEGA']).strip() if pd.notna(row['ID_BODEGA']) else None
                category_code = str(row['ID_CATEGORIA']).strip() if pd.notna(row['ID_CATEGORIA']) else None
                primary_category = str(row['Categoría']).strip() if pd.notna(row['Categoría']) else None
                subcategory = str(row['Subcategoría']).strip() if pd.notna(row['Subcategoría']) and row['Subcategoría'] != '' else None
                
                # Size
                medida = row.get('MEDIDA', None)
                size_raw = str(medida).strip() if pd.notna(medida) and medida != '' else None
                size_formatted = format_size(medida)
                
                # Temas
                tema = row.get('Tema', None)
                temas = extract_temas(tema)
                
                # Build product document
                product_doc = {
                    # Identity
                    'barcode': barcode,
                    'name': nombre,
                    'warehouseCode': warehouse_code,
                    
                    # Category linkage
                    'categoryCode': category_code,
                    'primaryCategory': primary_category,
                    'subcategory': subcategory,
                    
                    # Attributes
                    'size': size_raw,
                    'sizeFormatted': size_formatted,
                    'temas': temas,
                    'color': None,  # To be added manually later
                    
                    # Images (empty for now)
                    'images': [],
                    'primaryImageUrl': None,
                    
                    # Pricing (inherit from category)
                    'priceOverride': None,
                    
                    # Stock (initialized to 0)
                    'inStock': True,  # Product exists
                    'stockWarehouse': 0,
                    'stockStore': 0,
                    
                    # Metadata
                    'isActive': True,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                    'notes': None,
                    
                    # Source tracking
                    'importSource': 'productos.xlsx',
                    'sheetNumber': sheet_num
                }
                
                # Import to Firestore (using barcode as document ID)
                db.collection('products').document(barcode).set(product_doc)
                
                imported += 1
                
                # Print progress (only first 3 per sheet to avoid clutter)
                if imported <= 3:
                    display_name = nombre if nombre else f"{primary_category} ({warehouse_code})"
                    print(f"   ✅ {barcode}: {display_name}")
                elif imported == 4:
                    print(f"   ... (continuing to import remaining products)")
                
            except Exception as e:
                print(f"   ❌ Error at row {index + 2}: {e}")
                errors += 1
        
        # Sheet summary
        print(f"   📊 Sheet {sheet_num}: {imported} imported, {errors} errors\n")
        sheet_stats[sheet_num] = {'imported': imported, 'errors': errors}
        total_imported += imported
        total_errors += errors
    
    # Final summary
    print(f"{'='*60}")
    print(f"📦 Import Complete!")
    print(f"✅ Total products imported: {total_imported}")
    print(f"⏭️  Sheets skipped: {total_skipped} (sheet 18)")
    if total_errors > 0:
        print(f"❌ Total errors: {total_errors}")
    print(f"{'='*60}\n")
    
    # Detailed breakdown
    print("📊 Breakdown by Sheet:")
    for sheet_num, stats in sheet_stats.items():
        print(f"   Sheet {sheet_num:2d}: {stats['imported']:3d} products")
    
    print(f"\n💾 All data saved to Firestore collection: products/")
    print(f"📝 Next steps:")
    print(f"   1. Verify in Firestore Console")
    print(f"   2. Upload product images to Firebase Storage (named by barcode)")
    print(f"   3. Run image linking script (coming next)")
    print(f"   4. Add stock counts manually or via admin UI")

if __name__ == '__main__':
    try:
        import_products()
        print("\n✨ All done! Check Firestore Console to verify.")
    except FileNotFoundError as e:
        if 'serviceAccountKey.json' in str(e):
            print("\n❌ ERROR: serviceAccountKey.json not found!")
            print("📝 Please make sure it's in the project root\n")
        elif 'productos.xlsx' in str(e):
            print("\n❌ ERROR: data/productos.xlsx not found!")
            print("📝 Please make sure the Excel file exists in the data/ folder\n")
        else:
            print(f"\n❌ ERROR: {e}\n")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}\n")
        import traceback
        traceback.print_exc()
