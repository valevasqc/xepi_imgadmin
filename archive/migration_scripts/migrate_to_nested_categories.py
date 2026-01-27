"""
Migrate categories from flat structure to nested subcollections
Usage: python scripts/migrate_to_nested_categories.py
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
try:
    db = firestore.client()
except ValueError:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()

def migrate_categories():
    """Migrate flat categories to nested structure with subcollections"""
    
    print("📊 Reading current categories...")
    
    # Get all current categories
    categories_ref = db.collection('categories')
    categories = categories_ref.get()
    
    print(f"✅ Found {len(categories)} categories\n")
    
    # Group by primaryCategory
    grouped = {}
    for doc in categories:
        data = doc.to_dict()
        primary = data['primaryCategory']
        
        if primary not in grouped:
            grouped[primary] = []
        
        grouped[primary].append({
            'id': doc.id,
            'data': data
        })
    
    print(f"📦 Grouped into {len(grouped)} primary categories:")
    for primary, items in grouped.items():
        print(f"   {primary}: {len(items)} subcategories")
    
    print("\n🔄 Starting migration...\n")
    
    migrated_primary = 0
    migrated_sub = 0
    
    for primary_name, subcategories in grouped.items():
        print(f"📁 Creating primary category: {primary_name}")
        
        # Create primary category document
        primary_ref = db.collection('categories').document(primary_name)
        
        # Get primaryCode from first subcategory
        primary_code = subcategories[0]['data']['primaryCode']
        
        primary_data = {
            'name': primary_name,
            'primaryCode': primary_code,
            'coverImageUrl': None,  # To be set manually via admin
            'isActive': True,
            'displayOrder': subcategories[0]['data']['displayOrder'],  # Use first sub's order
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        
        primary_ref.set(primary_data)
        migrated_primary += 1
        
        # Create subcategories in subcollection
        for subcat in subcategories:
            code = subcat['id']
            data = subcat['data']
            
            sub_ref = primary_ref.collection('subcategories').document(code)
            
            # Remove primaryCategory from subcategory (now implied by parent)
            sub_data = {
                'code': data['code'],
                'name': data['name'],
                'subcategoryName': data.get('subcategoryName'),
                'defaultPrice': data.get('defaultPrice'),
                'coverImageUrl': data.get('coverImageUrl'),
                'bulkPricing': data.get('bulkPricing'),
                'hasSubcategories': data.get('hasSubcategories', False),
                'isActive': data.get('isActive', True),
                'displayOrder': data.get('displayOrder', 0),
                'createdAt': data.get('createdAt', firestore.SERVER_TIMESTAMP),
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'notes': data.get('notes'),
            }
            
            sub_ref.set(sub_data)
            migrated_sub += 1
            
            print(f"   ✅ {code}: {data['name']}")
    
    print(f"\n{'='*60}")
    print(f"✨ Migration Complete!")
    print(f"✅ Primary categories created: {migrated_primary}")
    print(f"✅ Subcategories migrated: {migrated_sub}")
    print(f"{'='*60}\n")
    
    # Ask for confirmation to delete old collection
    print("⚠️  OLD FLAT CATEGORIES STILL EXIST")
    print("After verifying the new structure works, delete old categories:")
    print("   - Go to Firebase Console → Firestore")
    print("   - Manually delete the 24 old top-level category documents")
    print("   - Keep the 8 new primary category documents with subcollections")

if __name__ == '__main__':
    try:
        confirm = input("\n⚠️  This will create a new nested category structure.\nType 'YES' to continue: ")
        
        if confirm != 'YES':
            print("❌ Migration cancelled")
            exit(0)
        
        migrate_categories()
        print("\n✨ Done! Test the admin app, then manually delete old categories.")
        
    except FileNotFoundError as e:
        if 'serviceAccountKey.json' in str(e):
            print("\n❌ ERROR: serviceAccountKey.json not found!")
            print("📝 Please download it from Firebase Console")
        else:
            raise e
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
