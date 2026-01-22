# XEPI Admin System - AI Agent Instructions

## Project Overview

Flutter web admin application for XEPI, a Guatemalan retail company. Manages inventory, sales, orders, and finances for ~600 decorative products across 1 warehouse + 1 store.

**Current State:** Phase 1 (Products & Categories) complete. Phase 2 (Inventory Management) in progress - Recepciones and Movimientos fully functional with Firestore backend. Products (1,066) and Categories (24) migrated. Orders and Register Sale pending.

**Current Phase:** Phase 2 - Inventory Management (50% complete)

**Tech Stack:** Flutter (web), Firebase (Auth, Firestore, Storage, Hosting)  
**Currency:** Guatemalan Quetzales (Q)  
**Languages:** Spanish UI, English code  
**Hardware:** Physical barcode scanners (USB), camera scanning later
**Database:** ~1,066 products across 24 categories in Firestore

## Project Scope

### **What This System Replaces**
- ❌ Excel inventory tracking (manual, inaccurate, COUNTIF formulas)
- ❌ WhatsApp-only order management (messages get lost, no tracking)
- ❌ Manual cash tracking (paper notes, missing money)
- ❌ No sales data (can't identify trends, best sellers, dead stock)
- ❌ No financial oversight (Mom doesn't know profit/loss)

### **What This System Provides**
- ✅ Real-time inventory (warehouse + store, accurate stock levels)
- ✅ Automated stock management (shipment receipt, transfers, sales deduction)
- ✅ Order tracking (WhatsApp orders → system workflow → completion)
- ✅ Cash flow visibility (pending balances, deposit tracking, reconciliation)
- ✅ Sales analytics (best sellers, trends, revenue by channel/product/category)
- ✅ Financial reports (profit/loss, expense tracking, cash flow statements)
- ✅ Business intelligence (data-driven decisions on what to stock/discontinue)

### **10 Main Features (Admin Side)**
1. **Dashboard** - Per-user personalized view with quick actions, pending tasks, data summaries
2. **Products** - 1,066+ product catalog (3 view modes: cards/table/list, sort options, comments field)
3. **Categories** - Pricing structure, bulk pricing, category management (nested structure with CRUD)
4. **Orders** - WhatsApp/Facebook orders, status tracking (pending → delivered → paid → completed)
5. **Shipment Receipt** - Scan products as they arrive (contenedores), auto-update warehouse stock
6. **Stock Movements** - Transfer products warehouse ↔ store, approval workflow
7. **Register Sales** - POS transactions (store + delivery), payment tracking (efectivo/transferencia/tarjeta)
8. **Finances** - Cash pending by source, deposits with photos, expenses tracking (superuser only)
9. **Reports** - Dynamic tables & charts, sales/inventory/financial reports, export functionality
10. **Settings** - User management with granular permissions, WhatsApp config, alerts

### **Client-Side App (Public)**
1. **Product Browsing** - View all active products with images
2. **Category Navigation** - Organized by primary category → subcategory
3. **Product Detail Pages** - Individual product pages with full info
4. **Shopping Cart** - Persistent storage, add/remove items
5. **Search & Filters** - By name, tema (topic), category, subcategory
6. **WhatsApp Integration** - Send cart contents as WhatsApp message
7. **Product URLs** - Direct links to specific products
8. **Footer** - Important business info (hours, location, contact)
Note: Out of stock products are hidden from client view

### **User Roles & Permissions**

**NOTE: User management and role-based permissions will be implemented LAST. All features must work fully for superuser first before adding multi-user support.**

- **Superuser (Mom):**
  - Full access to all features
  - View finances, expenses, profit/loss
  - Approve/deny critical changes (bulk deletes, etc.)
  - Confirm deposits and payments
  - Manage all user permissions
  - User management dashboard

- **Marta (Main Employee):**
  - Modify products and categories
  - Register sales (kiosko + delivery)
  - Report deposits (cash from sales)
  - Request stock from warehouse
  - Receive shipments (contenedores)
  - Critical actions require superuser approval
  - NO finance access

- **Empleado Kiosko (Temporary Vacationist):**
  - Register kiosko sales only
  - View products and stock
  - Limited permissions (customizable)
  - Temporary account

- **Clarita (Warehouse Staff):**
  - Send stock from warehouse to store
  - View and fulfill stock requests
  - Receive shipments (contenedores)
  - NO sales or finance access

- **Sergio (Delivery Driver/Messenger):**
  - View assigned delivery orders only
  - Change delivery status (picked_up → delivered)
  - Report deposits (cash from deliveries)
  - NO access to sales creation or inventory

### **Product Categories**
1. Cuadros de Latón (20x30, 30x40, Círculos, Flechas, Escudos, etc) - ~500 variations (some sizes have bulk pricing)
2. Accesorios Decorativos (Rótulos LED, protectores de bar, etc) - to be decided if cuadros de latón is also accesorios decorativos
3. Juguetes Educativos (varied, individual pricing, color variations)
4. Casitas Miniaturas
5. Cajitas Musicales
6. Rompecabezas (2000, 1500, 1000)
7. Aviones (16cm, 20cm, gigantes)

## Data Preparation (Current Step)

### **Excel Files for Migration**

**1. Cuadros Excel (Exists, needs updates):**
```
Columns: CODIGO_BARRA | MEDIDA | FOTO | CODIGO | CANTIDAD | SALIDAS | EXISTENCIA_BODEGA | EXISTENCIA_KIOSCO
Add: NOMBRE (descriptive name) | TEMA (design theme: Coca Cola, Películas, etc.)
```

**2. Other Products Excel (Employee creating):**
```
Columns: CODIGO_BARRA | NOMBRE | CATEGORIA | SUBCATEGORIA | CODIGO_BODEGA | TEMA | COLOR | PRECIO

Example:
3452423000032 | Tobogán Amarillo | Juguetes Educativos | Tobogán | TOB-01 | 3 | 1 | Amarillo | 99
7778889990001 | Carrusel Musical | Carruseles Musicales | - | CAR-01 | 12 | 5 | Rosado | [uses category default]
```

**3. Category Pricing Sheet (Ready):**
```
Categoría | Subcategoría | Precio
Cuadros de latón | 20x30 cms | 35
Cuadros de latón | 30x40 cms | 59
```

### **Migration Plan**
1. ✅ Employee completed Excel files
2. ✅ Wrote Python import scripts (Excel → Firestore)
3. ✅ Created Firestore collections (`products`, `categories`, `temas`)
4. ✅ Ran migration (imported 1,066 products, 24 categories)
5. ✅ Linked Storage images to products (by barcode)
6. ✅ Verified data integrity
7. ✅ Phase 1A development complete

## Architecture

### 3-Phase Implementation

**Phase 1: Products & Categories Management (✅ Complete)**
- Dashboard (`dashboard_screen.dart`) - Overview, stats, alerts
- Products (`products_list_screen.dart`, `product_detail_screen.dart`, `add_product_screen.dart`) - Full CRUD with image management, sort options (name, price, stock)
- Categories (`categories_list_screen.dart`, `category_detail_screen.dart`) - Nested structure, cover images, product reordering, add/delete categories, isActive toggle, bulk pricing editor, display order management
- Settings (`settings_screen.dart`) - User management, config

**Phase 2: Inventory Management (🔄 In Progress - 50% complete)**
- ✅ Recepciones (`shipment_history_screen.dart`, `receive_shipment_screen.dart`, `shipment_detail_screen.dart`) - Scan products as they arrive, auto-update warehouse stock, shipment history with complete/cancel actions
- ✅ Movimientos (`movement_history_screen.dart`, `transfer_stock_screen.dart`, `movement_detail_screen.dart`) - Transfer products warehouse ↔ store, two-step workflow (send deducts origin, receive adds destination), edit/delete/undo operations
- ❌ Pedidos (`orders_list_screen.dart`, `order_detail_screen.dart`) - UI only, needs backend
- ❌ Registrar Venta (`register_sale_screen.dart`, `sales_history_screen.dart`) - UI only, needs backend

**Phase 3: Financial Management & Reports (🔄 Starting)**
Located in `lib/screens/`:
- Finanzas (`finances_screen.dart`) - Cash tracking overview, deposits summary, pending cash cards
- Gastos (`expenses_list_screen.dart`) - Expense submission (employee/admin), list & filters
- Categorías de Gastos (`expense_categories_screen.dart`) - Admin-managed categories (operativo/no_operativo)
- Reportes (`reports_screen.dart`) - Sales, inventory, product performance, financial reports
  - Dynamic tables with sorting/filtering
  - Interactive charts (pie, bar, line)
  - Export functionality (PDF, Excel, CSV)
  - Date range selectors
  - Custom report builders
Note: Phase 3 screens initially use mock data; Firestore integration will be added incrementally.

**Legacy Code:**  
- `admin_dashboard_legacy.dart` - OLD system, uses Realtime DB + Firestore hybrid
- **DO NOT modify** - kept for reference during migration

### Navigation Structure

**Main Layout** (`main_layout.dart`):
- Collapsible sidebar (240px expanded, 72px collapsed)
- Route via `_selectedIndex` and `NavigationItem` list pattern
- Phase 2 items have `.isPhase2 = true` for visual distinction

### Firebase Integration

**Current State:**
- Authentication via `FirebaseAuth` (email/password)
- Firestore collections: `products`, `categories` (nested subcollections), `temas`
- Storage structure: `products/{barcode}/{filename}`, `categories/{primaryName}/cover.jpg`, `categories/{primaryName}/subcategories/{code}/cover.jpg`
- Composite indexes deployed for queries
- Nested category structure: `categories/{primaryName}/subcategories/{code}`

**Products Collection:**
- Document ID: barcode (13-digit string)
- Fields: barcode, name, categoryCode, primaryCategory, subcategory, images[], priceOverride, stockWarehouse, stockStore, isActive, displayOrder, temas[], size, sizeFormatted, warehouseCode, comments, createdAt, updatedAt
- Query pattern: `.where('categoryCode', isEqualTo: code).orderBy('displayOrder')`
- Phase 3 addition: `costPrice` (number, optional) used for profit calculations
- Comments field: Optional text for internal notes about the product

**Categories Collection:**
- Structure: Nested subcollections `categories/{primaryName}/subcategories/{code}`
- Primary category fields: name, coverImageUrl, displayOrder, createdAt, updatedAt
- Subcategory fields: code, name, primaryCategory, primaryCode, subcategoryName, defaultPrice, coverImageUrl, bulkPricing, isActive, displayOrder, hasSubcategories
- 24 subcategories grouped into 8 primary categories
- Bulk pricing format: `{qty2: number, qty5Plus: number}` for volume discounts

**Temas Collection:**
- Separate collection for performance (50x faster than scanning all products)
- Used for autocomplete/filtering by design themes

**Barcode Scanning:**
- Physical USB scanners (acts as keyboard: types barcode + Enter)
- Use `TextField` with autofocus + `onSubmitted` callback
- Camera scanning (Phase 2) - use `mobile_scanner` package

**Config Pattern:**
```dart
// Copy firebase_options.dart.example → firebase_options.dart
// Fill with real credentials (gitignored)
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**Firestore Collections Design:**
- `categories/` - Product categories with default pricing, cover images
- `products/` - Individual products (barcode as doc ID) with images, stock, pricing
- `temas/` - Design themes for filtering/autocomplete
- `shipments/` - Shipment receipts (status: pending, completed, cancelled)
- `movements/` - Stock transfers (status: pending, sent, received, cancelled)
- `locations/` - Warehouse and store location metadata (stockField mappings)
- `sales/` - Sales records (kiosko + delivery) with payment/delivery tracking
- `deposits/` - Deposit records with comprobante photos, linked to sales
- `pendingCash/` - Real-time pending cash by source (store/mensajero/forza)
- `expenses/` - Operational and non-operational expenses with approval workflow
- `expense_categories/` - Admin-managed categories with `type: 'operativo' | 'no_operativo'`
- `users/` - User accounts with role-based permissions
- Future: `orders/`, `notifications/`, `reports/`

## Design System

### Theme (`config/app_theme.dart`)

**Colors:**
- Brand: `AppTheme.orange`, `.yellow`, `.blue` (accents only)
- Neutrals: `darkGray`, `mediumGray`, `lightGray`, `backgroundGray`, `white` (primary)
- Status: `success`, `warning`, `danger`

**Typography:**
- Headings: `GoogleFonts.montserrat` (600-700 weight)
- Body: `GoogleFonts.quicksand` (400-600 weight)
- Use predefined styles: `heading1`, `heading2`, `heading3`, `bodyLarge`, etc.

**Spacing:** `spacingXS` (4) → `spacingS` (8) → `spacingM` (16) → `spacingL` (24) → `spacingXL` (32) → `spacingXXL` (48)

**Shadows:** `subtleShadow`, `cardShadow`, `hoverShadow`

**Border Radius:** `borderRadiusSmall` (8), `borderRadiusMedium` (12), `borderRadiusLarge` (16)

### UI Patterns

**Screen Structure:**
```dart
Scaffold(
  backgroundColor: AppTheme.backgroundGray,
  body: Column(
    children: [
      // Fixed header with white background + shadow
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(/* Title + Actions */),
      ),
      // Scrollable content
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: /* Content */,
        ),
      ),
    ],
  ),
);
```

**Data Cards:**
- White background with `AppTheme.cardShadow`
- `borderRadiusMedium` corners
- `spacingL` padding internally

**Buttons:**
- Primary: `ElevatedButton` (blue background)
- Secondary: `OutlinedButton` (gray border)
- Icons: Use `Icons.*_rounded` variants for consistency

## Development Guidelines

### When Creating New Screens

1. **Phase 1 screens**: Implement Firestore integration immediately
2. **Phase 2 screens**: Mock data only, functional placeholders
3. Always follow the screen structure pattern (header + scrollable content)
4. Use Spanish for UI text (`Productos`, `Categorías`, `Agregar`, etc.) - Guatemalan Spanish if in doubt of which synonym to use
5. Add screen to `main_layout.dart` `_navItems` list

### Data Handling

**Phase 1 - Use Mock Data:**
```dart
final List<Map<String, dynamic>> _mockProducts = List.generate(
  24,
  (index) => {
    'id': 'prod_$index',
    'name': 'Product ${index + 1}',
    // ... full object structure
  },
);
```

**Phase 2 - Firestore Queries:**
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('products')
  .where('inStock', isEqualTo: true)
  .orderBy('name')
  .get();
```

### Product-Specific Conventions

**Barcode Format:** 13-digit numeric strings (e.g., "1203023000562")

**Category Codes:** Pattern `{PREFIX}-{SUBCATEGORY}` (e.g., "CUA-2030", "JUG-MAIN")

**Stock Levels:**
- Red (<3): Critical low
- Yellow (3-10): Low
- Green (>10): Healthy

**Price Inheritance:**
```dart
finalPrice = product.priceOverride ?? category.defaultPrice;
```

**View Modes (Products):**
- Cards: Visual grid with images
- Table: Spreadsheet-style with inline editing
- List: Compact, maximum density

**Sort Options (Products):**
- Nombre (A-Z) / Nombre (Z-A)
- Precio (menor) / Precio (mayor)
- Stock (menor) / Stock (mayor)

## Recommended Build Order

### **Phase 1A: Products Foundation (Weeks 1-2)**
1. Create Firestore products collection structure
2. Build add product screen (scan barcode → save to Firestore)
3. Build products list (read from Firestore, search, filter)
4. Build product detail (view/edit product)
5. Link existing images from Storage to products

### **Phase 1B: Stock Tracking (Weeks 3-4)**
1. Add stock fields (stockWarehouse, stockStore)
2. Manual stock adjustment UI (+/- buttons)
3. Color-coded stock levels (red/yellow/green)
4. Low stock alerts on dashboard

### **Phase 1C: Shipment Receipt (Month 2)**
1. Receive shipment screen (scan barcodes)
2. Auto-increment warehouse stock
3. Shipment history/audit trail
4. **Replaces Excel scanning workflow**

### **Phase 2A: Movements & Orders (Month 2-3)**
1. Stock transfers (warehouse ↔ store)
2. Order management (WhatsApp/Facebook)
3. Order status tracking (pending → ready → delivered → paid)

### **Phase 2B: Sales & Cash Tracking (Month 3)**
1. Register sales (POS + delivery)
2. Cash balance tracking (store/messenger/Forza)
3. Link sales to deposits

### **Phase 3: Financial System (Month 4)**
1. Deposits management
2. Expenses tracking
3. Financial reports (profit/loss, cash flow)
4. Reconciliation (all cash accounted for)

## Commands & Workflows

### Run Development
```bash
flutter run -d chrome  # Web development
flutter build web      # Production build
```

### Firebase Deploy
```bash
firebase deploy --only hosting  # Deploy web app
```

### Common Tasks

**Add new dependency:**
```bash
flutter pub add package_name
flutter pub get
```

**Analyze code:**
```bash
flutter analyze
```

**Format code:**
```bash
flutter format lib/
```

## Key Files Reference

- `lib/main.dart` - Entry point, auth stream
- `lib/config/app_theme.dart` - Design system
- `lib/screens/main_layout.dart` - Navigation structure
- `lib/firebase_options.dart` - Config (gitignored, use .example)
- `pubspec.yaml` - Dependencies (Flutter 3.5.4, Dart 3.5.4+)
- `firebase.json` - Hosting config for web deployment

## Business Logic Notes

**Current Workflow (Excel-based):**
- Scan barcodes to Excel during shipment receipt
- Use COUNTIF to track inventory counts
- Manual cash tracking
- WhatsApp orders handled via chat (no system)

**Sales & Delivery System:**

**Payment Methods:**
- **Efectivo** (Cash) - requires deposit with comprobante photo
- **Transferencia Bancaria** (Bank transfer) - requires superuser payment verification
- **Tarjeta** (Credit/debit card via POS device) - requires superuser payment verification, employee uploads POS summary photo

**Sale Types (internal):**
- **Kiosko** (store sales) - customer buys at physical store
- **Delivery** (mensajero or Forza) - delivery to customer address

**Delivery Methods:**
- **Mensajero** (own delivery guy) - can track picked_up/delivered/paid with own account (Phase 2C)
- **Forza** (third-party delivery company) - employee tracks shipped/delivered

**Register Sale Screen:**
- Same screen for kiosko and delivery
- Toggle sale type: when "Delivery" selected → show address + delivery method fields
- Customer info: name optional for kiosko, required for delivery (phone + address required for delivery)
- NIT required for all sales (default "CF" for consumidor final)
- Stock deduction: default from store, rare option for warehouse
- Payment approval: transferencia/tarjeta sales marked pending_approval until superuser confirms

**Stock States:**
- `stockWarehouse` - products in warehouse
- `stockStore` - products in store  
- `stockInTransit` - delivery sales not paid yet (prevents double-counting)
- When delivery paid → remove from in_transit, deduct from origin location

**Sale Record Structure:**
```
{
  saleId: auto-generated
  saleType: 'kiosko' | 'delivery'
  deliveryMethod: null | 'mensajero' | 'forza'
  paymentMethod: 'efectivo' | 'transferencia' | 'tarjeta'
  items: [{barcode, name, quantity, unitPrice, subtotal}]
  subtotal: number
  discount: number
  total: number
  nit: string (required, "CF" if no factura)
  
  // Customer
  customerName: optional kiosko, required delivery
  customerPhone: optional kiosko, required delivery
  deliveryAddress: null kiosko, required delivery
  
  // Stock
  deductFrom: 'store' | 'warehouse'
  stockStatus: 'completed' | 'in_transit'
  
  // Payment
  paymentVerified: boolean (superuser confirms)
  status: 'pending_approval' | 'approved'
  
  // Deposit
  depositId: links to deposit record
  
  // Delivery tracking
  deliveryStatus: 'pending' | 'picked_up' | 'delivered' | 'completed'
  pickedUpAt, pickedUpBy, deliveredAt
  
  // Audit
  createdBy: userId
  createdAt: timestamp
}
```

**Deposits:**
- One deposit covers multiple sales
- Store comprobante photos: `deposits/{depositId}/comprobante.jpg`
- Sales link to depositId for tracking
- Required for efectivo (all locations) and tarjeta (POS summary)
 - Example `deposits` document fields:
   - `amount` (number), `source` ('store'|'mensajero'|'forza'), `comprobanteUrl` (string)
   - `createdAt`, `depositedAt` (timestamps), `depositedBy` (uid), `saleIds` (array of saleId strings), `notes` (string)

**Cash Flow Tracking:**
- Efectivo at kiosko → pending cash source: 'store', needs deposit
- Efectivo delivery mensajero → pending cash source: 'mensajero', needs deposit
- Efectivo delivery Forza → pending cash source: 'forza', needs deposit
- Transferencia → superuser verifies payment received at bank
- Tarjeta → superuser verifies payment + employee uploads POS summary
- **Goal:** Track every quetzal until deposited

**Inventory Flow:**
- Shipments → Warehouse first (always)
- Warehouse → Store (transfers on demand)
- Sales default deduct from store (rare warehouse option)
- Deliveries go out from store (or warehouse if selected)
- Stock tracking: warehouse + store + in_transit

**User Roles:**
- **Superuser (Mom):** Full access, approves payments (transferencia/tarjeta), views finances
- **Employee:** Create sales (pending approval), operations only, NO finance access
- **Mensajero (Phase 2C):** Own deliveries only, mark picked_up/delivered/paid

**Product Data:**
- ~600 products across multiple categories
- 13-digit barcodes printed on all products
- Categories have default pricing, products can override
- Multiple images per product (especially juguetes)

## Anti-Patterns to Avoid

❌ Don't use Realtime Database (`FirebaseDatabase.instance`) - use Firestore  
❌ Don't modify `admin_dashboard_legacy.dart` - it's deprecated  
❌ Don't implement Phase 2 backend logic yet - UI mockups only  
❌ Don't use custom colors - use `AppTheme.*` constants  
❌ Don't hardcode spacing - use `AppTheme.spacing*` values  
❌ Don't forget Spanish UI text  
❌ Don't mix Google Fonts - Montserrat (headings) + Quicksand (body)
❌ Don't forget to ask about Firestore field names - always verify structure first
❌ Don't make commits without asking first. Commit descriptions should be short and not AI style

## Common Snackbar Pattern

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.white),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: Text('Message', style: AppTheme.bodySmall.copyWith(color: AppTheme.white))),
      ],
    ),
    backgroundColor: AppTheme.blue,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ),
);
```

## Critical Business Logic

### **Price Calculation**
```dart
// Product inherits category default, unless override exists
finalPrice = product.priceOverride ?? category.defaultPrice;

// Bulk pricing (e.g., Tapitas: 1=Q15, 2=Q13, 3+=Q10)
if (category.bulkPricing != null && quantity >= 2) {
  unitPrice = quantity >= 3 
    ? category.bulkPricing.qty3Plus 
    : category.bulkPricing.qty2;
}
```

### **Stock Status Colors**
```dart
// Critical: Red (<3), Low: Yellow (3-10), OK: Green (>10), Out: Gray (0)
final totalStock = product.stockWarehouse + product.stockStore;
final color = totalStock == 0 ? Colors.grey
  : totalStock < 3 ? Colors.red
  : totalStock < 10 ? Colors.yellow
  : Colors.green;
```

### **Cash Flow Tracking**
```dart
// Every cash sale creates pending balance by source
if (paymentMethod == 'cash') {
  final source = saleLocation == 'store' ? 'store'
    : deliveryMethod == 'own_messenger' ? 'messenger'
    : 'forza';
  
  // Auto-added to pending balance, cleared on deposit
  await updatePendingCash(source, saleTotal);
}
```

**Expenses Collection (Phase 3):**
```
{
  amount: number,
  category: string,           // e.g., 'Salarios', 'Inventarios', 'Publicidad y marketing'
  categoryType: 'operativo' | 'no_operativo',
  description: string,
  receiptUrl: string | null,  // Storage path: expenses/{expenseId}/receipt.jpg
  status: 'pending_approval' | 'approved' | 'rejected',
  createdBy: uid,
  createdAt: timestamp,
  approvedBy: uid | null,
  approvedAt: timestamp | null,
}
```

**Expense Categories Collection (Phase 3):**
```
{
  name: string,
  type: 'operativo' | 'no_operativo',
  displayOrder: number,
  isActive: boolean,
  createdAt, updatedAt
}
```

### **Order Status Flow**
```
pending → preparing → ready → shipped → delivered → paid → completed
(any status can → cancelled)

CRITICAL: Only when status = "paid" do we:
1. Create sale record
2. Deduct stock
3. Add to pending cash (if COD)
```

### **Stock Deduction**
```dart
// Sales ALWAYS deduct from store (even if delivery order)
// Warehouse only increases on shipment receipt
// Store requests transfers from warehouse when low
await productRef.update({
  'stockStore': FieldValue.increment(-quantity),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

## Barcode Scanner Integration

**Physical USB Scanner:**
```dart
// Acts as keyboard - types barcode + Enter
TextField(
  autofocus: true,
  onSubmitted: (barcode) async {
    final product = await searchProductByBarcode(barcode);
    if (product != null) {
      _addToCart(product); // or _addToShipment(), etc.
    } else {
      _showProductNotFoundDialog(barcode);
    }
  },
)
```

**Scan Context Behaviors:**
- Products List: Jump to product detail
- Add Product: Fill barcode field
- Receive Shipment: Add to shipment list (+1 qty per scan)
- Transfer Stock: Add to transfer list
- Register Sale: Add to cart
- Create Order: Add to order items

## Firestore Security Rules Pattern

```javascript
// Helper functions
function isAuthenticated() {
  return request.auth != null;
}

function isSuperuser() {
  return isAuthenticated() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superuser';
}

// Products/Categories: Public read (for client app)
match /products/{productId} {
  allow read: if true;
  allow write: if isAuthenticated();
}

// Operations: Authenticated only
match /orders/{orderId} {
  allow read, write: if isAuthenticated();
}

// Finances: Superuser only
match /deposits/{depositId} {
  allow read, write: if isSuperuser();
}
```

## Key Workflows to Understand

**Shipment Receipt (Replaces Excel COUNTIF):**
1. Employee scans each barcode as products arrive
2. System increments quantity per scan (or type quantity)
3. On "Complete Shipment" → auto-adds to warehouse stock
4. Creates audit trail (who, when, what)
5. Excel can also be uploaded. Create new product if barcode not found, or ask to replace (or just sum totals) info if barcode exists.

**Store Requests Stock:**
1. Store sees low stock (e.g., Carrusel Rosado: W:12, S:2)
2. Creates transfer request (W→S, qty: 5)
3. Warehouse sees pending request notification
4. Warehouse pulls items, confirms "Send Now"
5. Store confirms receipt → stock updated both locations

**WhatsApp Order Flow:**
1. Customer sends cart via WhatsApp
2. Employee creates order in admin (scan or type products)
3. System checks stock availability
4. Employee enters customer info + delivery method + payment
5. Status: pending → preparing → ready → shipped → delivered
6. When customer pays → status: paid
7. System creates sale record + deducts stock + tracks cash (if COD)

**Cash Deposit Recording:**
1. Mom opens Finances page
2. Sees pending: Store Q850 (7 days 🔴), Messenger Q1,600
3. Records deposit: source, amount, bank, photo
4. System links deposit to specific sales (FIFO)
5. Clears pending balance + removes alert

## Alert System Logic

**Low Stock:** totalStock < 10 (warning), < 3 (urgent)  
**Cash Overdue:** >3 days (warning), >7 days (urgent)  
**Payment Overdue:** Customer hasn't paid >3 days after delivery  
**Order Stuck:** No status change >3 days

Run alert generation:
- On dashboard load
- Every 30 minutes (background)
- When relevant data changes

## Design Principles

**Mobile-First:** Employee uses tablet in warehouse (large touch targets 44x44px)  
**Color-Coded:** Red=urgent, Yellow=warning, Green=ok, Gray=inactive  
**Quick Actions:** Prominent buttons, floating action button where needed  
**Visual Feedback:** Success/error toasts, loading states on all async operations  
**Consistent Layout:** Same structure across pages (header + scrollable content)

## Testing Checklist

**Before Each Feature:**
- [ ] Works with physical barcode scanner
- [ ] Loading state shows during async operations
- [ ] Error messages are user-friendly (no raw Firebase errors)
- [ ] Success feedback confirms action completed
- [ ] Real-time updates work (test on 2 devices)
- [ ] Employee role cannot see superuser features
- [ ] Offline mode caches essential data

**Before Deployment:**
- [ ] All 600 products migrated to Firestore
- [ ] Security rules deployed
- [ ] Firebase indexes created for queries
- [ ] Test complete sale end-to-end
- [ ] Test shipment receipt workflow
- [ ] Verify cash tracking updates correctly
- [ ] Employee training completed

## Success Metrics

**Phase 1A Success (Products Database):**
- ✅ All ~600 products in Firestore with accurate data
- ✅ Employee can search/edit products easily
- ✅ Barcode scanning works (USB scanner tested)
- ✅ Categories properly structured with pricing inheritance

**Phase 1B Success (Stock Tracking):**
- ✅ Manual stock adjustment works (+/- buttons)
- ✅ Color-coded stock levels display correctly
- ✅ Dashboard shows low stock alerts
- ✅ Stock counts match physical inventory

**Phase 1C Success (Shipment Receipt):**
- ✅ Employee can receive shipments via barcode scanning
- ✅ Stock auto-increments in warehouse
- ✅ Shipment history audit trail works
- ✅ **Excel COUNTIF workflow completely replaced**

**Phase 2 Success (Operations):**
- ✅ Stock transfers work smoothly (warehouse ↔ store)
- ✅ WhatsApp orders tracked in system
- ✅ All sales recorded accurately (store + delivery)
- ✅ Order status progression works end-to-end

**Phase 3 Success (Finances):**
- ✅ All cash accounted for (no missing money)
- ✅ Mom can see profit/loss monthly
- ✅ Deposit alerts prevent cash drawer buildup
- ✅ Business decisions are data-driven (reports show trends)

**Final Success Criteria:**
- ✅ Inventory accurate within 2% (physical vs system)
- ✅ All sales tracked (no "off the books" transactions)
- ✅ Employee saves 5+ hours/week (vs Excel)
- ✅ Mom has clear financial picture monthly
- ✅ Data shows which products to stock/discontinue
- ✅ Cash reconciliation happens automatically
- ✅ System pays for itself (time saved + better decisions)
