#!/usr/bin/env python3
"""
Script de migración de temas de productos a colección separada.

Este script:
1. Lee todos los productos de Firestore
2. Extrae todos los temas únicos
3. Cuenta cuántos productos usan cada tema
4. Crea documentos en la colección 'temas' con metadata

Ejecutar: python migrate_temas.py
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
from datetime import datetime

def migrate_temas():
    """Migrar temas de productos a colección separada."""
    
    print("🔧 Iniciando migración de temas...\n")
    
    # Inicializar Firebase Admin SDK
    # NOTA: Debes descargar tu serviceAccountKey.json de Firebase Console
    try:
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
        print("✅ Firebase inicializado correctamente")
    except Exception as e:
        print(f"❌ Error al inicializar Firebase: {e}")
        print("\n⚠️  Asegúrate de tener serviceAccountKey.json en este directorio")
        print("   Descárgalo desde: Firebase Console > Project Settings > Service Accounts")
        return
    
    db = firestore.client()
    
    # 1. Leer todos los productos
    print("\n📖 Leyendo productos...")
    products_ref = db.collection('products')
    products = products_ref.where('temas', '!=', None).stream()
    
    # 2. Contar temas
    tema_count = defaultdict(int)
    tema_first_seen = {}
    total_products = 0
    
    for product in products:
        total_products += 1
        data = product.to_dict()
        temas = data.get('temas', [])
        
        if isinstance(temas, list):
            for tema in temas:
                tema_count[tema] += 1
                if tema not in tema_first_seen:
                    tema_first_seen[tema] = datetime.now()
    
    print(f"✅ Procesados {total_products} productos")
    print(f"✅ Encontrados {len(tema_count)} temas únicos\n")
    
    # 3. Crear documentos en colección temas
    print("📝 Creando colección de temas...")
    temas_ref = db.collection('temas')
    batch = db.batch()
    
    for tema, count in sorted(tema_count.items()):
        tema_doc_ref = temas_ref.document(tema)
        batch.set(tema_doc_ref, {
            'name': tema,
            'productCount': count,
            'createdAt': tema_first_seen.get(tema, datetime.now()),
            'lastUsed': datetime.now(),
        })
        print(f"  ✓ {tema}: {count} producto(s)")
    
    # 4. Commit batch
    try:
        batch.commit()
        print(f"\n✅ Migración completada exitosamente!")
        print(f"   - {len(tema_count)} temas migrados")
        print(f"   - {total_products} productos procesados")
        print(f"\n🎉 Ahora los temas se cargan desde la colección 'temas'")
    except Exception as e:
        print(f"\n❌ Error al guardar temas: {e}")

if __name__ == '__main__':
    migrate_temas()
