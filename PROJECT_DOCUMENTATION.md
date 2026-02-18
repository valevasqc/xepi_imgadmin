# XEPI Admin System - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Business Context](#business-context)
3. [Technology Stack](#technology-stack)
4. [Architecture & Structure](#architecture--structure)
5. [Design System](#design-system)
6. [Firebase Integration](#firebase-integration)
7. [Features & Implementation](#features--implementation)
8. [User Roles & Permissions](#user-roles--permissions)
9. [Development Guidelines](#development-guidelines)
10. [Phase Implementation](#phase-implementation)

---

## Project Overview

### What is XEPI Admin?

XEPI Admin is a comprehensive web-based inventory and sales management system built for XEPI, a Guatemalan retail company specializing in decorative products. The system manages approximately 1,066 products across 24 categories, distributed between a warehouse and a physical store location.

### Core Problem Being Solved

**Before XEPI Admin:**
- ❌ Manual inventory tracking in Excel spreadsheets with COUNTIF formulas
- ❌ WhatsApp-only order management (messages lost, no tracking)
- ❌ Excel cash tracking with frequent discrepancies
- ❌ No sales analytics or trend identification
- ❌ No financial oversight (Mom doesn't know profit/loss)
- ❌ No data-driven business decisions

**After XEPI Admin:**
- ✅ Real-time inventory management (warehouse + store)
- ✅ Automated stock updates (shipments, transfers, sales)
- ✅ Complete order tracking workflow
- ✅ Cash flow visibility and reconciliation
- ✅ Sales analytics (best sellers, trends, revenue breakdowns)
- ✅ Financial reports (profit/loss, expense tracking, cash flow)
- ✅ Business intelligence for inventory decisions

### Key Metrics

- **~1,066 products** across 24 categories
- **2 locations:** 1 warehouse + 1 physical store (kiosko)
- **3 sales channels:** Store, Mensajero delivery, Forza delivery
- **Currency:** Guatemalan Quetzales (Q)
- **Languages:** Spanish UI, English code
- **Target Users:** 2 superusers (Valeria (developer) & Michelle (mom)), 1 store employee (Marta), 1 mensajero (Sergio), 1 warehouse employee (Clarita), 1 temporary store employee when demand is too high 

---

## Business Context

### Company Background

XEPI is a family-owned Guatemalan retail business specializing in decorative products:
- **Cuadros de Latón** (Brass frames) - ~500 variations across multiple sizes
- **Accesorios Decorativos** (Decorative accessories) - LED signs, bar protectors
- **Juguetes Educativos** (Educational toys) - varied with color variations
- **Casitas Miniaturas** (Miniature houses)
- **Cajitas Musicales** (Music boxes)
- **Rompecabezas** (Puzzles) - 2000, 1500, 1000 pieces
- **Aviones** (Airplanes) - 16cm, 20cm, gigantes, militares

### Current Workflow

1. **Shipment Receipt:** Products arrive in containers → scanned/recorded in Excel
2. **Warehouse Storage:** All inventory starts in warehouse
3. **Store Transfers:** On-demand transfers from warehouse to store
4. **Sales:** Physical store + delivery orders (own messenger or Forza)
5. **Cash Collection:** From store, messenger, or Forza. Cash, bank transfer or credit card
6. **Deposits:** Cash collected → deposited with photo receipt
7. **Client website:** (future) client website is built, pending connection to admin site.

### Pain Points Addressed

1. **Inventory Accuracy:** Excel COUNTIF prone to human error, no audit trail
2. **Order Management:** WhatsApp messages get buried, no status tracking
3. **Cash Tracking:** Money goes missing, no reconciliation process
4. **Decision Making:** No data on what sells, what to restock, what to discontinue
5. **Financial Visibility:** Mom can't see profit margins or cash flow

---

## MVP Definition & Go-Live Criteria

### What Must Work Before Production

**Critical Workflows (Must be 100% functional):**
1. ✅ **Shipment Receipt** - Scan products, auto-update warehouse stock
2. ✅ **Stock Transfers** - Warehouse → Store with two-step workflow
3. ✅ **Register Sales** - Kiosko + delivery with stock deduction
4. ✅ **Deposit Recording** - Cash tracking with comprobante photos
5. ✅ **Reports** - Sales analytics, top sellers, financial summaries

**Data Integrity Requirements:**
- Stock never goes negative
- All sales linked to deposits
- Pending cash reconciles with deposits
- No orphaned references (sale IDs that don't exist)

**Stability Criteria:**
- 30 days without critical bugs
- 30 days without stock mismatches
- No data loss incidents
- All atomic operations work correctly

**Sign-Off Required From:**
- Valeria (developer) - Technical validation
- Michelle (superuser) - Business validation
- Marta (employee) - Usability validation

### Explicitly NOT Required for MVP

❌ User management with dynamic roles (hardcoded superusers OK)  
❌ Email notifications  
❌ Automated tax reporting (FEL)  
❌ Multi-branch support  
❌ Offline mode
❌ Mobile apps (web-only for now)
❌ Advanced analytics (cohort analysis, forecasting)
❌ Export to Excel/PDF (nice-to-have, not blocking)

### Post-MVP Enhancements (Phase 4+)

1. **Phase 4:** Dynamic user management with permissions
2. **Phase 5:** Client website integration
3. **Phase 6:** FEL integration for legal invoicing
4. **Future:** Mobile apps, offline support, predictive inventory

---

## Technology Stack

### Frontend Framework
- **Flutter 3.5.4** (Web) - Cross-platform UI framework
- **Dart 3.5.4** - Programming language

### Backend Services (Firebase)
- **Firebase Authentication** - Email/password auth
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - Product images, receipts, deposit photos
- **Firebase Hosting** - Web app hosting

### Scalability Assumptions

**Current Scale:**
- 1,066 products (expected max: 2,000)
- 5 concurrent users max (2 superusers + 3 employees)
- ~50-100 sales/day peak
- ~10 deposits/month
- ~50 expenses/month

**Query Performance:**
- Products list: <2s load time (pagination NEEDED to not lag because of scale)
- Sales history: Paginated at 50 items (sufficient for now)
- Reports: In-memory filtering OK for current data volume
- No Firestore composite index explosion (use in-memory filters)

**Not Designed For:**
- E-commerce-scale traffic (thousands of concurrent users)
- Real-time multiplayer collaboration
- Complex supply chain with 50+ locations

### Key Dependencies

```yaml
# Core
flutter: sdk
firebase_core: ^3.8.1
cloud_firestore: ^5.6.12
firebase_auth: ^5.3.1
firebase_storage: ^12.3.1

# UI Components
google_fonts: ^6.2.1         # Montserrat (headings) + Quicksand (body)
font_awesome_flutter: 9.2.0  # Icons
reorderable_grid_view: ^2.2.8 # Drag-drop product ordering

# Data Visualization
fl_chart: ^0.69.0            # Charts for reports

# File Handling
image_picker: ^1.1.2         # Camera/gallery image selection
file_picker: ^8.1.4          # Excel file upload
pdf: ^3.11.1                 # PDF export (future)
csv: ^6.0.0                  # CSV export
syncfusion_flutter_xlsio: ^27.1.58  # Excel generation

# Utilities
intl: ^0.19.0                # Date formatting, currency
path_provider: ^2.1.5        # Local file paths
```

### Development Tools
- **Python 3.13+** - Migration scripts (Excel → Firestore)
- **Firebase CLI** - Deployment and configuration
- **Visual Studio Code** - Primary IDE

---

## Architecture & Structure

### Project Directory Structure

```
xepi_imgadmin/
├── lib/
│   ├── main.dart                    # App entry point, auth stream
│   ├── firebase_options.dart        # Firebase config (gitignored)
│   │
│   ├── config/
│   │   └── app_theme.dart           # Design system constants
│   │
│   ├── screens/
│   │   ├── main_layout.dart         # Navigation shell with sidebar
│   │   ├── dashboard_screen.dart    # Home page with stats
│   │   ├── admin_login.dart         # Authentication screen
│   │   ├── settings_screen.dart     # User settings
│   │   │
│   │   ├── products_list_screen.dart        # Product catalog (3 views)
│   │   ├── product_detail_screen.dart      # Edit product + images
│   │   ├── add_product_screen.dart         # Create new product
│   │   │
│   │   ├── categories_list_screen.dart      # Category management
│   │   ├── category_detail_screen.dart     # Edit category + reorder
│   │   │
│   │   ├── inventory/
│   │   │   ├── receive_shipment_screen.dart    # Scan products as they arrive
│   │   │   ├── shipment_history_screen.dart    # Past shipments
│   │   │   ├── shipment_detail_screen.dart     # View shipment details
│   │   │   ├── transfer_stock_screen.dart      # Move inventory between locations
│   │   │   ├── movement_history_screen.dart    # Past transfers
│   │   │   └── movement_detail_screen.dart     # View transfer details
│   │   │
│   │   ├── sales/
│   │   │   ├── register_sale_screen.dart       # POS + delivery orders
│   │   │   ├── sales_history_screen.dart       # All sales records
│   │   │   └── sale_detail_screen.dart         # View sale details
│   │   │
│   │   ├── orders/
│   │   │   ├── orders_history_screen.dart      # Delivery orders (envíos)
│   │   │   └── order_detail_screen.dart        # Track delivery status
│   │   │
│   │   ├── finances/
│   │   │   ├── finances_screen.dart            # Overview dashboard
│   │   │   ├── bank_accounts_screen.dart       # Manage bank accounts
│   │   │   ├── deposits_screen.dart            # Record cash deposits
│   │   │   ├── expenses_list_screen.dart       # Expense tracking
│   │   │   └── expense_categories_screen.dart  # Admin categories
│   │   │
│   │   └── future/
│   │       └── reports_screen.dart             # Analytics & reports
│   │
│   ├── services/
│   │   ├── auth_service.dart                # Auth helpers, role checks
│   │   ├── bank_accounts_service.dart       # Bank account CRUD
│   │   ├── expenses_service.dart            # Expense CRUD
│   │   └── reports_service.dart             # Data aggregation
│   │
│   ├── widgets/
│   │   ├── product_search_dialog.dart       # Reusable product picker
│   │   └── status_filter_chips.dart         # Filter chips UI
│   │
│   └── utils/
│       ├── date_formatter.dart              # Spanish date formatting
│       └── status_helper.dart               # Status labels/colors
│
├── web/
│   ├── index.html                           # Web entry point
│   ├── firebase-config.js                   # Firebase web config (gitignored)
│   └── icons/                               # PWA icons
│
├── archive/
│   ├── data/
│   │   └── images/                          # Product images for migration
│   └── migration_scripts/
│       ├── import_products.py               # Excel → Firestore products
│       ├── import_categories.py             # Excel → Firestore categories
│       ├── upload_images.py                 # Storage bulk upload
│       └── requirements.txt                 # Python dependencies
│
├── firebase.json                            # Firebase project config
├── firestore.rules                          # Security rules
├── firestore.indexes.json                   # Composite indexes
├── storage.rules                            # Storage security rules
└── pubspec.yaml                             # Flutter dependencies
```

### Navigation Architecture

The app uses a **collapsible sidebar navigation** pattern:

**Main Layout** (`main_layout.dart`):
- Sidebar: 240px (expanded) / 72px (collapsed)
- Grouped navigation items with dropdowns
- Role-based visibility (superuser sees all, employees see limited)
- Active page highlighting

**Navigation Groups:**
1. **Inicio** (Home) - Dashboard
2. **Catálogo** (Catalog) - Products + Categories
3. **Inventario** (Inventory) - Recepciones + Movimientos
4. **Ventas** (Sales) - Envíos + Ventas
5. **Finanzas** (Finance) - Resumen + Cuentas + Depósitos + Reportes *(superuser only)*
6. **Configuración** (Settings) - User management

### Authentication Flow

```dart
// main.dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return const MainLayout();  // Logged in
    }
    return const AdminLoginScreen();  // Show login
  },
)
```

**Role Checking** (`AuthService`):
```dart
// Hardcoded superuser UIDs (temporary until user management)
static const List<String> _superuserUids = [
  '9QFhlKjJMkXMvrB0ISh1rghfPAl1',  // Valeria
  'yMnQBCQrtpblH3yTHd05XLVloZu2'   // Michelle
];

static bool get isSuperuser => _superuserUids.contains(currentUser?.uid);
```

---

## Design System

### Color Palette

**Brand Colors** (Accents only - not for backgrounds):
```dart
orange = #DB6A19   // XEPI brand orange
yellow = #FEC800   // XEPI brand yellow
blue   = #00ACC0   // Primary action color
```

**Neutral Colors** (Primary UI palette):
```dart
darkGray       = #2B2B2B   // Primary text, headings
mediumGray     = #6B6B6B   // Secondary text
lightGray      = #E5E5E5   // Borders, dividers
backgroundGray = #F8F8F8   // Page background
white          = #FFFFFF   // Cards, containers
```

**Status Colors:**
```dart
success = #10B981   // Green - completed, approved
warning = #F59E0B   // Yellow - pending, low stock
danger  = #EF4444   // Red - cancelled, error, critical
```

### Typography

**Font Families:**
- **Headings:** Montserrat (600-700 weight)
- **Body Text:** Quicksand (400-600 weight)

**Type Scale:**
```dart
heading1   = 32px / 700 / Montserrat  // Page titles
heading2   = 24px / 600 / Montserrat  // Section headings
heading3   = 18px / 600 / Montserrat  // Card titles
heading4   = 16px / 600 / Montserrat  // Small headings

bodyLarge  = 16px / 500 / Quicksand   // Emphasized content
bodyMedium = 14px / 500 / Quicksand   // Standard text
bodySmall  = 12px / 500 / Quicksand   // Auxiliary text
caption    = 11px / 400 / Quicksand   // Hints, timestamps
```

### Spacing System

```dart
spacingXS  = 4px
spacingS   = 8px
spacingM   = 16px
spacingL   = 24px
spacingXL  = 32px
spacingXXL = 48px
```

### Border Radius

```dart
borderRadiusSmall  = 8px
borderRadiusMedium = 12px
borderRadiusLarge  = 16px
```

### Shadows

```dart
subtleShadow = BoxShadow(color: #00000010, blur: 8px, offset: (0, 2))
cardShadow   = BoxShadow(color: #0000000F, blur: 12px, offset: (0, 4))
hoverShadow  = BoxShadow(color: #00000014, blur: 16px, offset: (0, 6))
```

### UI Patterns

**Screen Structure:**
```dart
Scaffold(
  backgroundColor: AppTheme.backgroundGray,
  body: Column(
    children: [
      // Fixed header (white bg + shadow)
      Container(
        padding: EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(/* Title + Actions */),
      ),
      
      // Scrollable content
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingXL),
          child: /* Content */,
        ),
      ),
    ],
  ),
);
```

**Data Cards:**
```dart
Container(
  padding: EdgeInsets.all(AppTheme.spacingL),
  decoration: BoxDecoration(
    color: AppTheme.white,
    borderRadius: AppTheme.borderRadiusMedium,
    boxShadow: AppTheme.cardShadow,
  ),
  child: /* Content */,
)
```

**Success Snackbar:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.white),
        SizedBox(width: AppTheme.spacingM),
        Expanded(child: Text('Acción completada')),
      ],
    ),
    backgroundColor: AppTheme.success,
    behavior: SnackBarBehavior.floating,
  ),
);
```

---

## Firebase Integration

### Firestore Database Structure

#### Collections Overview

```
firestore/
├── products/                  # Product catalog
├── categories/                # Primary categories
│   └── {primaryName}/
│       └── subcategories/     # Nested subcategories
├── temas/                     # Design themes for filtering
├── locations/                 # Warehouse/Store metadata
├── shipments/                 # Shipment receipts
├── movements/                 # Stock transfers
├── sales/                     # All sales records
├── pendingCash/               # Real-time pending cash tracking
├── deposits/                  # Cash deposit records
├── expenses/                  # Expense tracking
├── expense_categories/        # Admin-managed expense categories
├── bankAccounts/              # Bank account management
└── users/                     # User accounts (future)
```

### Detailed Data Models

#### Products Collection
**Document ID:** 13-digit barcode (string)

```typescript
{
  barcode: string,              // "1203023000562"
  name: string,                 // "Cuadro Coca Cola 20x30"
  categoryCode: string,         // "CUA-2030"
  primaryCategory: string,      // "Cuadros de latón"
  subcategory: string,          // "20x30 cms"
  
  // Pricing
  priceOverride: number | null, // Manual price override
  costPrice: number | null,     // Cost for profit calculation
  
  // Inventory
  stockWarehouse: number,       // Units in warehouse
  stockStore: number,           // Units in store
  warehouseCode: string,        // "CUA-01" (internal ref)
  
  // Metadata
  images: string[],             // Storage URLs
  temas: string[],              // ["Coca Cola", "Vintage"]
  color: string | null,         // For toys
  size: {                       // Parsed dimensions
    width: number,
    height: number,
    unit: 'cms' | 'pulgadas'
  } | null,
  sizeFormatted: string | null, // "20x30 cms"
  notes: string,                // Internal comments
  
  // Display
  displayOrder: number,         // For category sorting
  isActive: boolean,            // Show in client app
  
  // Audit
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- `categoryCode + displayOrder` (product list by category)
- `isActive + name` (active products search)

#### Categories Collection
**Nested Structure:** `categories/{primaryName}/subcategories/{code}`

**Primary Category:**
```typescript
{
  name: string,                 // "Cuadros de latón"
  coverImageUrl: string | null, // Primary category image
  displayOrder: number,         // Sorting order
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Subcategory:**
```typescript
{
  code: string,                 // "CUA-2030"
  name: string,                 // "Cuadro de latón 20x30 cms"
  primaryCategory: string,      // "Cuadros de latón"
  subcategoryName: string,      // "20x30 cms"
  primaryCode: string,          // "CUA"
  
  // Pricing
  defaultPrice: number,         // Q35.00
  bulkPricing: {                // Only for CUA-2030, CUA-1530
    qty2: number,               // 2-4 units: Q30
    qty5Plus: number            // 5+ units: Q25
  } | null,
  
  // Display
  coverImageUrl: string | null, // Subcategory cover (or inherits primary)
  displayOrder: number,
  hasSubcategories: boolean,    // Always true (nested structure)
  isActive: boolean,
  
  // Audit
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Sales Collection
```typescript
{
  saleId: string,               // Auto-generated
  saleType: 'kiosko' | 'delivery',
  
  // Items
  items: [
    {
      barcode: string,
      name: string,
      categoryCode: string,
      quantity: number,
      unitPrice: number,        // Applied price (with bulk discount if eligible)
      subtotal: number
    }
  ],
  
  // Pricing
  subtotal: number,
  discount: number,
  total: number,
  
  // Customer (optional for kiosko, required for delivery)
  customerName: string | null,
  customerPhone: string | null,
  deliveryAddress: string | null,
  nit: string,                  // "CF" for consumidor final
  
  // Payment
  paymentMethod: 'efectivo' | 'transferencia' | 'tarjeta',
  destinationAccount: string | null,  // Bank account ID (transferencia/tarjeta)
  paymentVerified: boolean,     // Superuser confirmation
  
  // Delivery (for saleType: delivery)
  deliveryMethod: 'mensajero' | 'forza' | null,
  deliveryStatus: 'pending' | 'picked_up' | 'delivered' | 'completed',
  pickedUpAt: Timestamp | null,
  pickedUpBy: string | null,    // uid
  deliveredAt: Timestamp | null,
  
  // Stock
  deductFrom: 'store' | 'warehouse',
  stockStatus: 'completed' | 'in_transit',
  
  // Deposit linking
  depositId: string | null,     // Links to deposit record
  
  // Audit
  createdBy: string,            // uid
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Deposits Collection
```typescript
{
  // Amounts
  cashReceived: number,         // Total cash before expenses
  expenses: number,             // Total expenses paid from cash
  amount: number,               // Net deposit (cashReceived - expenses)
  
  // Source & Destination
  source: 'store' | 'mensajero' | 'forza',
  destinationAccount: string,   // Bank account ID
  
  // Proof
  comprobanteUrl: string,       // Storage path to deposit receipt photo
  
  // Employee expenses tracking
  expenseIds: string[],         // IDs of expense records created from this deposit
  
  // Sales linking
  saleIds: string[],            // Sales included in this deposit
  
  // Metadata
  notes: string,
  depositedBy: string,          // uid
  depositedAt: Timestamp,
  createdAt: Timestamp
}
```

#### Expenses Collection
```typescript
{
  amount: number,
  category: string,             // "Salarios", "Inventarios", "Marketing"
  categoryType: 'operativo' | 'no_operativo',
  description: string,
  
  // Payment
  paymentSource: string,        // Bank account ID or 'efectivo'
  receiptUrl: string | null,    // Storage path to receipt photo
  
  // Approval workflow
  status: 'pending_approval' | 'approved' | 'rejected',
  approvedBy: string | null,    // uid
  approvedAt: Timestamp | null,
  
  // Deposit linking (for efectivo expenses)
  depositId: string | null,     // If paid from collected cash before deposit
  
  // Audit
  createdBy: string,            // uid
  createdAt: Timestamp
}
```

#### Bank Accounts Collection
```typescript
{
  accountName: string,          // "BI Cuenta Corriente"
  bankName: string,             // "Banco Industrial"
  accountType: 'business' | 'personal',
  currency: 'QTZ' | 'USD',
  last4Digits: string,          // "1234" (security)
  
  // Balance tracking
  currentBalance: number,       // Manually updated weekly
  lastReconciled: Timestamp | null,
  
  // Metadata
  notes: string,                // "Para recibir pagos de clientes"
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Pending Cash Collection
**Document IDs:** 'store', 'mensajero', 'forza'

```typescript
{
  source: string,               // Document ID
  amount: number,               // Total pending cash
  saleIds: string[],            // Sales not yet deposited
  updatedAt: Timestamp
}
```

**Workflow:**
1. Sale created (efectivo) → Add to pendingCash
2. Deposit created → Deduct from pendingCash, link saleIds
3. Cleanup job periodically verifies saleIds still exist

#### Shipments Collection
```typescript
{
  status: 'pending' | 'in-progress' | 'completed' | 'cancelled',
  items: [
    {
      barcode: string,
      productName: string,
      quantity: number
    }
  ],
  totalItems: number,           // Sum of quantities
  createdBy: string,            // uid
  createdAt: Timestamp,
  completedAt: Timestamp | null
}
```

#### Movements Collection
```typescript
{
  originLocationId: string,     // 'warehouse' | 'store'
  destinationLocationId: string,
  status: 'pending' | 'sent' | 'received' | 'cancelled',
  
  items: [
    {
      barcode: string,
      productName: string,
      quantity: number
    }
  ],
  totalItems: number,
  
  // Two-step workflow
  sentAt: Timestamp | null,     // Step 1: Origin deducts stock
  sentBy: string | null,        // uid
  receivedAt: Timestamp | null, // Step 2: Destination adds stock
  receivedBy: string | null,    // uid
  
  // Audit
  createdBy: string,            // uid
  createdAt: Timestamp
}
```

### Storage Structure

```
storage/
├── products/
│   └── {barcode}/
│       ├── 1.jpg
│       ├── 2.jpg
│       └── ...
│
├── categories/
│   ├── {primaryName}/
│   │   ├── cover.jpg
│   │   └── subcategories/
│   │       └── {code}/
│   │           └── cover.jpg
│
├── deposits/
│   └── {depositId}/
│       └── comprobante.jpg
│
└── expenses/
    └── {expenseId}/
        └── receipt.jpg
```

### Security Rules

**Philosophy:**
- Public read for products/categories (client app)
- Authenticated write for operational data
- Superuser-only for financial data

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isSuperuser() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superuser';
    }
    
    // Products - Public read, authenticated write
    match /products/{productId} {
      allow read: if true;
      allow write: if isAuthenticated();
    }
    
    // Categories - Public read, authenticated write
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if isAuthenticated();
      
      match /subcategories/{subId} {
        allow read: if true;
        allow write: if isAuthenticated();
      }
    }
    
    // Financial data - Superuser only
    match /deposits/{depositId} {
      allow read, create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (request.auth.uid == '9QFhlKjJMkXMvrB0ISh1rghfPAl1' || 
         request.auth.uid == 'yMnQBCQrtpblH3yTHd05XLVloZu2');
    }
    
    match /expenses/{expenseId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
        (request.auth.uid == '9QFhlKjJMkXMvrB0ISh1rghfPAl1' || 
         request.auth.uid == 'yMnQBCQrtpblH3yTHd05XLVloZu2');
    }
  }
}
```

### Composite Indexes

**Required indexes** (firestore.indexes.json):

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "fields": [
        { "fieldPath": "categoryCode", "order": "ASCENDING" },
        { "fieldPath": "displayOrder", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "movements",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "expenses",
      "fields": [
        { "fieldPath": "createdAt", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Features & Implementation

### 1. Dashboard

**Purpose:** Personalized overview with quick actions and key metrics.

**Key Metrics:**
- Daily/Monthly sales totals
- Monthly expenses
- Pending cash by source (store, mensajero, forza)
- Pending shipments count
- Recent sales/expenses list

**Implementation:**
```dart
// Load data in parallel
await Future.wait([
  _loadSalesData(startOfDay, startOfMonth),
  _loadExpensesData(startOfMonth),
  _loadPendingCash(),
  _loadRecentActivity(),
  _loadPendingShipments(),
]);
```

**Quick Actions:**
- Registrar Venta
- Recibir Mercadería
- Ver Depósitos
- Ver Finanzas

---

### 2. Products Management

**Main Screen:** `products_list_screen.dart`

**Features:**
- **3 View Modes:** Cards (visual), Table (spreadsheet), List (compact)
- **Advanced Search:** Name, barcode, warehouse code, themes
- **Filters:** Category, subcategory, location, stock status
- **Sort Options:** Name (A-Z/Z-A), Price (low/high), Stock (low/high)
- **Pagination:** 50 products per page (virtual scrolling)
- **Stock Status Colors:**
  - 🔴 Red: < 3 units (critical)
  - 🟡 Yellow: 3-10 units (low)
  - 🟢 Green: > 10 units (healthy)
  - ⚪ Gray: 0 units (out of stock)

**Product Detail Screen:**
- Image gallery with main image + thumbnails
- Upload/reorder/delete images
- Edit all product fields inline
- Change category/subcategory
- Stock adjustment controls (+/-)
- Price override
- Cost price (for profit calculation)
- Themes management (chips)
- Size dimensions (width x height)
- Color field (for toys)
- Internal notes field
- Unsaved changes indicator
- Real-time save on edit

**Add Product Screen:**
- Barcode input (USB scanner or manual)
- Category/subcategory selection
- Image upload (multiple)
- Initial stock values
- All product metadata

**Key Logic:**

```dart
// Price inheritance
final effectivePrice = product.priceOverride ?? category.defaultPrice;

// Bulk pricing (cuadros 20x30 and 15x30)
if (totalBulkEligibleQty >= 5) {
  return bulkPricing.qty5Plus;  // Q25
} else if (totalBulkEligibleQty >= 2) {
  return bulkPricing.qty2;      // Q30
} else {
  return defaultPrice;          // Q35
}

// Stock color coding
final totalStock = stockWarehouse + stockStore;
final color = totalStock == 0 ? Colors.grey
  : totalStock < 3 ? Colors.red
  : totalStock < 10 ? Colors.yellow
  : Colors.green;
```

---

### 3. Categories Management

**Main Screen:** `categories_list_screen.dart`

**Structure:**
- Nested categories: Primary → Subcategories
- 8 primary categories, 24 total subcategories
- Product count per category
- Cover images (primary + subcategory)
- Bulk pricing editor (for cuadros)
- Display order management
- Active/inactive toggle

**Category Detail Screen:**
- Edit cover image
- Reorder products (drag-and-drop grid)
- Edit default price
- Edit bulk pricing tiers
- View product list

**Key Features:**
- If only 1 subcategory → inherits primary cover image
- Bulk pricing only for CUA-2030 and CUA-1530
- Display order changes save immediately to Firestore

---

### 4. Inventory Management

#### A. Recepciones (Shipment Receipt)

**Purpose:** Replace Excel COUNTIF workflow - scan products as they arrive.

**Workflow:**
1. Employee creates new shipment
2. Scans barcodes (USB scanner) or searches products
3. Each scan increments quantity
4. Optional: Upload Excel file for bulk import
5. "Confirmar Recepción" → Auto-increment warehouse stock
6. Creates audit trail

**Implementation Features:**
- In-progress shipments auto-save to Firestore
- Edit quantity manually
- Remove items
- Complete shipment → status: 'completed', updates stock
- Cancel shipment (doesn't affect stock)
- Excel upload parses barcodes + quantities

**Stock Update Logic:**
```dart
// On complete shipment
for (var item in shipment.items) {
  await _firestore.collection('products').doc(item.barcode).update({
    'stockWarehouse': FieldValue.increment(item.quantity),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### B. Movimientos (Stock Transfers)

**Purpose:** Move inventory between warehouse and store.

**Two-Step Workflow:**
1. **Send:** Origin deducts stock, status: 'sent'
2. **Receive:** Destination adds stock, status: 'received'

**Features:**
- Select origin/destination locations
- Scan products or search
- Quantity validation (can't transfer more than available)
- Edit/delete movements (before completion)
- Undo received movements
- Audit trail with user IDs and timestamps

**Location Metadata:**
```dart
// Firestore: locations/{locationId}
{
  name: "Bodega" | "Tienda",
  stockField: "stockWarehouse" | "stockStore",
  displayOrder: 1,
  isActive: true
}
```

**Movement Status Flow:**
```
pending → sent → received
          ↓
       cancelled (revert stock if sent)
```

---

### 5. Sales & Orders

#### A. Register Sale

**Purpose:** Unified POS for store sales and delivery orders.

**Sale Types:**
1. **Kiosko** (Store) - Customer buys at physical location
2. **Delivery** - Order shipped to customer, Mensajero or Forza

**Payment Methods:**
- **Efectivo** (Cash) - Requires deposit with photo
- **Transferencia** (Bank Transfer) - Superuser verifies
- **Tarjeta** (Card) - Requires POS summary photo, superuser verifies

**Workflow:**
1. Select sale type (kiosko/delivery)
2. Scan products or search (adds to cart)
3. Adjust quantities
4. Apply discount (optional)
5. Enter customer info (required for delivery)
6. Select payment method
7. For transferencia/tarjeta: Select bank account
8. For delivery: Select delivery method (mensajero/forza)
9. Stock deduction location (store default, warehouse optional)
10. Create sale → Deduct stock, create pending cash (if efectivo)

**Key Features:**
- Bulk pricing auto-applied (cuadros 20x30/15x30)
- Real-time cart total calculation
- NIT field (default "CF" for consumidor final)
- Payment approval workflow for transferencia/tarjeta
- Stock validation before sale creation

**Cart Item Structure:**
```dart
{
  'barcode': string,
  'name': string,
  'categoryCode': string,
  'quantity': int,
  'unitPrice': double,        // Effective price after bulk discount
  'subtotal': double,
  'productData': {            // For bulk pricing calculation
    'categoryCode': string,
    'bulkPricing': {...}
  }
}
```

#### B. Sales History

**Features:**
- Cards view + Table view toggle
- Filter by sale type (kiosko/delivery)
- Filter by payment method
- View sale details
- Date range filtering
- Export to Excel (future)

**Metrics Displayed:**
- Total sales count
- Total revenue
- Average ticket size
- Payment method breakdown

#### C. Orders (Envíos)

**Purpose:** Track delivery orders separately from store sales.

**Features:**
- Shows only delivery sales
- Filter by delivery status (pending → delivered)
- Update delivery status
- Mark as picked up, delivered, completed
- Link to original sale record

**Delivery Status Flow:**
```
pending → picked_up → delivered → completed
```

---

### 6. Financial Management

#### A. Finances Overview

**Purpose:** Dashboard for superusers to see financial health.

**Displays:**
- Pending cash by source (store, mensajero, forza)
- Recent deposits
- Monthly expenses
- Bank account balances
- Cash flow alerts

**Alerts:**
- 🟡 Warning: Cash pending > 7 days
- 🔴 Urgent: Cash pending > 14 days

#### B. Bank Accounts

**Purpose:** Centralized bank account management for tracking revenue and expenses.

**Access:** Superuser-only (Mom/Michelle). Employees cannot access bank accounts.

**Accounts Setup:**
- **Bibanking QTZ** (business, Q) - Forza deposits, card payments
- **Bibanking USD** (business, $) - USD transactions
- **BI Personal** (personal, Q) - Client transfers, employee deposits
- **BI Credit Card** (personal, Q) - Meta ads expenses

**Features:**
- Add/edit/delete accounts
- QTZ/USD currency support
- Business/personal type
- Current balance tracking
- Last 4 digits (security)
- Manual reconciliation (weekly recommended)
- Active/inactive toggle
- Notes field

**Balance Tracking:**
```dart
// Weekly manual update
await _service.updateBalance(accountId, newBalance);
// Updates: currentBalance, lastReconciled, updatedAt
```

#### C. Deposits

**Purpose:** Record cash deposits with photo proof and employee expense tracking.

**Workflow:**
1. Select source (store/mensajero/forza)
2. Enter cash received amount
3. Add employee expenses paid from cash (optional):
   - Category: "Suministros de tienda" (only category employee can use)
   - Amount
   - Description
4. System calculates net deposit (received - expenses)
5. Select bank account destination (QTZ accounts only)
6. Upload comprobante photo
7. Add notes
8. Create deposit

**What Happens:**
```dart
// 1. Create expense records (if any)
for (expense in expenses) {
  await _firestore.collection('expenses').add({
    ...expense,
    category: 'Suministros de tienda',  // Only category employee can use
    paymentSource: 'efectivo',
    status: 'pending_approval',         // Needs superuser approval
    depositId: depositId,               // Link to deposit
  });
}

// 2. Create deposit record
await _firestore.collection('deposits').add({
  cashReceived: 500,
  expenses: 50,
  amount: 450,               // Net deposit
  source: 'store',
  destinationAccount: 'biPersonalQTZ',
  comprobanteUrl: storageUrl,
  expenseIds: [expenseId1, expenseId2],
  saleIds: linkedSaleIds,
});

// 3. Update pending cash (deduct by cashReceived, not net)
await _firestore.collection('pendingCash').doc('store').update({
  amount: FieldValue.increment(-500),  // Full amount received
});

// 4. Link sales to deposit
for (saleId in saleIds) {
  await _firestore.collection('sales').doc(saleId).update({
    depositId: depositId,
  });
}
```

**Employee Cash Expense Tracking:**
- Example: Employee collected Q500, spent Q50 on "Suministros de tienda" → deposits Q450
- Employee can ONLY record "Suministros de tienda" expenses from collected cash
- Expenses status: 'pending_approval' (REQUIRES superuser approval)
- Linked to deposit for reconciliation
- Net deposit amount reflects cash actually deposited

**Cleanup Function:**
```dart
// Periodically verify saleIds still exist
// Remove orphaned references from pendingCash
```

#### D. Expenses

**Purpose:** Track all business expenses with approval workflow.

**Expense Types:**
- **Operativo** (Operational) - Core business expenses
- **No Operativo** (Non-operational) - One-time, non-recurring

**Categories:**
- Salarios (Salaries)
- Inventarios (Inventory purchases)
- Suministros de tienda (Store supplies)
- Publicidad y marketing (Advertising)
- Servicios (Utilities, services)
- Otros (Other)

**Workflow:**

**For Superuser (Mom/Michelle):**
1. Create expense (any category)
2. Select category + type (operativo/no_operativo)
3. Enter amount + description
4. Upload receipt photo (optional)
5. Select payment source (bank account or 'efectivo')
6. Status: 'approved' (no approval needed for superuser)

**For Employee:**
1. Can ONLY submit "Suministros de tienda" expenses
2. Can ONLY use 'efectivo' (from collected cash before deposit)
3. Enter amount + description
4. Status: 'pending_approval'
5. Superuser reviews and approves/rejects
6. If approved → Status: 'approved'

**Payment Sources:**
- Bank account ID (e.g., 'biPersonalQTZ') - **Superuser only**
- 'efectivo' (cash on hand) - Superuser or employee (during deposit)

**Filters:**
- By type (operativo/no_operativo/todos)
- By status (pending/approved/rejected/todos)

---

### 7. Reports & Analytics

**Purpose:** Business intelligence and data-driven decision making.

**4 Report Tabs:**

#### Tab 1: Ventas (Sales)

**Metrics:**
- Total revenue
- Total sales count
- Average ticket size
- Revenue breakdown by:
  - Payment method (efectivo/transferencia/tarjeta)
  - Sale type (kiosko/delivery)
  - Delivery method (mensajero/forza)
  - Bank account (for transferencia/tarjeta)

**Visualizations:**
- Pie chart: Revenue by payment method
- Bar chart: Sales by day
- Line chart: Revenue trend over time

**Filters:**
- Date range (presets: today, this week, this month, this year, custom)
- Payment method
- Sale type
- Category
- Product

#### Tab 2: Productos (Product Performance)

**Metrics:**
- Best sellers (by quantity and revenue)
- Revenue per product
- Average price
- Stock status

**Table Columns:**
- Product name
- Category
- Units sold
- Revenue
- Average price
- Current stock

**Sorting:**
- By revenue (default)
- By quantity
- By stock

#### Tab 3: Finanzas (Financial Summary)

**Metrics:**
- Total revenue (all sources)
- Total expenses (operativo + no_operativo)
- Net profit (revenue - expenses)
- Profit margin percentage
- Pending cash by source
- Revenue by bank account
- Expenses by payment source

**Visualizations:**
- Pie chart: Revenue by bank account
- Pie chart: Expenses by category
- Bar chart: Revenue vs Expenses comparison
- Line chart: Cash flow over time

**Bank Account Breakdown:**
```dart
// Revenue side (sales with transferencia/tarjeta)
revenueByAccount: {
  'biPersonalQTZ': 1500,
  'bibankingQTZ': 800
}

// Expense side (expenses paid from each source)
expensesByAccount: {
  'biPersonalQTZ': 200,
  'bibankingQTZ': 150,
  'efectivo': 100
}

// Net per account
netByAccount = revenueByAccount - expensesByAccount
```

#### Tab 4: Gastos (Expenses)

**Metrics:**
- Total expenses
- Operativo vs No Operativo breakdown
- Expenses by category
- Expenses by payment source

**Table:**
- Date
- Category
- Description
- Amount
- Payment source
- Status

**Filters:**
- Date range
- Expense type
- Category

**Export Options (Future):**
- Export to Excel
- Export to PDF
- Export to CSV

---

### 8. Barcode Scanning

**Hardware:** Physical USB barcode scanners (acts as keyboard input).

**Implementation Pattern:**
```dart
TextField(
  controller: _barcodeController,
  focusNode: _barcodeFocusNode,
  autofocus: true,
  onSubmitted: (barcode) async {
    if (barcode.trim().isEmpty) return;
    
    final product = await _firestore
      .collection('products')
      .doc(barcode)
      .get();
    
    if (product.exists) {
      _addToCart(product.data()!);
    } else {
      _showProductNotFoundDialog(barcode);
    }
    
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  },
)
```

**Barcode Format:** 13-digit numeric string (EAN-13)

**Usage Contexts:**
- Recepciones (shipment receipt)
- Movimientos (stock transfers)
- Ventas (register sale)
- Product search

---

## Core Business Rules

### Data Integrity Rules (Enforced by Code)

**Stock Management:**
1. Stock can **never** go below 0 (validation prevents overselling)
2. Stock deduction happens atomically with sale creation (Firestore batch)
3. Transfer "Send" deducts from origin, "Receive" adds to destination (two-step)
4. Shipment completion adds to warehouse stock only (never store directly)
5. Delivery sales deduct from origin location only after payment

**Sales & Deposits:**
1. Sales **cannot be edited** after being linked to a deposit (immutable)
2. Deposit **must** deduct full `cashReceived` from pendingCash (not net amount)
3. Delivery cannot be marked "completed" without payment verification
4. Bank transfers/card payments require superuser approval before completion
5. All cash sales **must** be linked to a deposit (no loose cash)

**Expenses:**
1. Employees can **only** create "Suministros de tienda" expenses from efectivo
2. Employee expenses **require** superuser approval (status: pending_approval)
3. Superuser expenses from bank accounts are auto-approved
4. Approved expenses **cannot be modified** (delete + recreate instead)
5. Expenses from efectivo **must** be linked to a deposit

**Financial:**
1. Only superusers can view/edit bank accounts
2. Only superusers can edit `costPrice` (profit calculations)
3. Bank account balances are manually reconciled (not auto-calculated)
4. Pending cash is calculated from linked sales (not editable directly)

**Product & Category:**
1. Barcode is immutable (document ID, cannot change)
2. Category deletion blocked if products reference it, unless authorized by superuser
3. Price inheritance: product.priceOverride ?? category.defaultPrice
4. Bulk pricing applies only to CUA-2030 and CUA-1530 (tiered: 2-4, 5+)

### Data Consistency & Transaction Strategy

**When to Use Firestore Transactions:**
- Stock adjustments with validation (read-modify-write with contention)
- Balance updates with race condition risk
- NOT used currently (batch operations sufficient for our scale)

**When to Use Batch Writes (Current Standard):**
- ✅ Sale creation + stock deduction + pending cash update
- ✅ Deposit creation + expense linking + pending cash deduction
- ✅ Movement send/receive + stock updates
- ✅ Shipment completion + bulk stock increments

**Batch Operation Pattern:**
```dart
final batch = FirebaseFirestore.instance.batch();

// All operations in batch
batch.set(saleRef, saleData);
batch.update(productRef, {'stockStore': FieldValue.increment(-qty)});
batch.update(pendingCashRef, {'amount': FieldValue.increment(total)});

// Atomic commit
await batch.commit();
```

**Handling Failures:**
- If batch fails → entire operation rolls back (all-or-nothing)
- If internet drops mid-operation → Firestore queues locally, retries on reconnect
- If document doesn't exist → fail fast with user-friendly error
- No partial states possible (Firestore guarantees atomicity)

**Race Condition Prevention:**
- `FieldValue.increment()` is atomic (server-side calculation)
- Stock validation happens before batch commit
- Concurrent sales for same product: last-write-wins OK (qty check prevents negative)
- Pending cash updates use increment (additive, no conflicts)

---

## User Roles & Permissions

### Role Definitions

#### Superuser (Mom, Michelle)
**Full System Access:**
- ✅ All features
- ✅ View finances & expenses
- ✅ Create expenses from bank accounts (most expenses)
- ✅ Approve/deny expenses
- ✅ Confirm deposits
- ✅ View profit/loss reports
- ✅ Manage bank accounts
- ✅ User management (future)
- ✅ Bulk delete operations

**Navigation Visibility:**
- Inicio, Catálogo, Inventario, Ventas, **Finanzas**, Configuración

#### Employee (Marta - Main Employee)
**Operational Access:**
- ✅ Modify products & categories
- ✅ Register sales (kiosko + delivery)
- ✅ Report deposits (cash from sales)
- ✅ Record "Suministros de tienda" expenses from cash (requires superuser approval)
- ✅ Request stock transfers
- ✅ Receive shipments
- ❌ NO finance access (cannot view/manage bank accounts)
- ❌ NO expense approval
- ❌ Cannot make other types of expenses

**Navigation Visibility:**
- Inicio, Catálogo, Inventario, Ventas, Configuración

#### Employee Kiosko (Temporary Vacationist)
**Limited Access:**
- ✅ Register store sales only
- ✅ View products & stock
- ✅ Make stock requests
- ❌ NO inventory management
- ❌ NO delivery sales
- ❌ NO finance access
- Permissions modifiable by superuser

#### Clarita (Warehouse Staff)
**Warehouse Access:**
- ✅ Send stock from warehouse to store
- ✅ Fulfill stock requests
- ✅ Receive shipments
- ❌ NO sales registration
- ❌ NO finance access

#### Sergio (Delivery Driver/Messenger)
**Delivery Access:**
- ✅ View assigned deliveries
- ✅ Update delivery status (picked_up → delivered)
- ✅ Report deposits (cash from deliveries)
- ❌ NO sales creation
- ❌ NO inventory access

### Permission Implementation

**Current (Phase 1-2):**
```dart
// services/auth_service.dart
static const List<String> _superuserUids = [
  '9QFhlKjJMkXMvrB0ISh1rghfPAl1',  // Valeria
  'yMnQBCQrtpblH3yTHd05XLVloZu2'   // Michelle
];

static bool get isSuperuser => _superuserUids.contains(currentUser?.uid);
```

**Future (Phase 3 - User Management):**
```typescript
// Firestore: users/{uid}
{
  uid: string,
  email: string,
  displayName: string,
  role: 'superuser' | 'employee' | 'employee_kiosko' | 'warehouse' | 'messenger',
  permissions: {
    viewFinances: boolean,
    approveExpenses: boolean,
    manageUsers: boolean,
    registerSales: boolean,
    manageInventory: boolean,
    viewReports: boolean
  },
  isActive: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**UI Conditional Rendering:**
```dart
// Navigation visibility
List<NavigationGroup> get _visibleNavGroups {
  if (AuthService.isSuperuser) {
    return _navGroups;  // All groups
  } else {
    return _navGroups.where((g) => !g.requiresSuperuser).toList();
  }
}

// Feature access
if (AuthService.isSuperuser) {
  ElevatedButton(
    onPressed: _approveExpense,
    child: Text('Aprobar Gasto'),
  )
}
```

---

## Development Guidelines

### Spanish UI, English Code

**UI Text:** Always Spanish (Guatemalan dialect)
```dart
Text('Agregar Producto')
Text('Confirmar Recepción')
Text('Trasladar Inventario')
```

**Code:** English variable/function names
```dart
void _createDeposit() { }
final cartItems = _getCartItems();
String _selectedPaymentMethod = 'efectivo';
```

### Code Conventions

**Naming:**
- Classes: `PascalCase` (ProductsListScreen)
- Functions: `_camelCase` (private), `camelCase` (public)
- Variables: `_camelCase` (private), `camelCase` (public)
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE`

**File Organization:**
```dart
// 1. Imports (Flutter → Firebase → App)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xepi_imgadmin/config/app_theme.dart';

// 2. Class definition
class MyScreen extends StatefulWidget { }

// 3. State class
class _MyScreenState extends State<MyScreen> {
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Controllers
  final TextEditingController _controller = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _data = [];
  
  // Lifecycle
  @override
  void initState() { }
  
  @override
  void dispose() { }
  
  // Build method
  @override
  Widget build(BuildContext context) { }
  
  // Helper methods (alphabetical)
  Future<void> _loadData() { }
  Widget _buildCard() { }
}
```

### Error Handling

**Always show user-friendly messages:**
```dart
try {
  await _firestore.collection('products').add(data);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.white),
          SizedBox(width: AppTheme.spacingM),
          Text('Producto agregado exitosamente'),
        ],
      ),
      backgroundColor: AppTheme.success,
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error al agregar producto: $e'),
      backgroundColor: AppTheme.danger,
    ),
  );
}
```

### Loading States

**Always show loading indicators:**
```dart
bool _isLoading = false;

Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    // Load data
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  // ... rest of UI
}
```

### Firestore Best Practices

**Use StreamBuilder for real-time data:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('products').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Error');
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final products = snapshot.data!.docs;
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index].data() as Map<String, dynamic>;
        return _buildProductCard(product);
      },
    );
  },
)
```

**Batch writes for multiple updates:**
```dart
final batch = _firestore.batch();

for (var item in items) {
  final ref = _firestore.collection('products').doc(item.barcode);
  batch.update(ref, {
    'stockWarehouse': FieldValue.increment(item.quantity),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

await batch.commit();
```

**Transaction for atomic operations:**
```dart
await _firestore.runTransaction((transaction) async {
  // Read phase
  final productDoc = await transaction.get(productRef);
  final currentStock = productDoc.data()!['stockStore'] as int;
  
  // Validation
  if (currentStock < quantity) {
    throw Exception('Stock insuficiente');
  }
  
  // Write phase
  transaction.update(productRef, {
    'stockStore': currentStock - quantity,
  });
});
```

### Testing Checklist

**Before committing:**
- [ ] Barcode scanner works (USB device)
- [ ] Loading states show during async operations
- [ ] Error messages are user-friendly (Spanish)
- [ ] Success feedback confirms action completed
- [ ] Real-time updates work (test on 2 browser tabs)
- [ ] No console errors
- [ ] Follows design system (colors, spacing, typography)

---

## Phase Implementation

### Phase 1: Products & Categories Management ✅ COMPLETE

**Timeline:** Months 1-2

**Deliverables:**
1. ✅ Dashboard with stats and quick actions
2. ✅ Products list (3 views: cards/table/list)
3. ✅ Product detail with image gallery
4. ✅ Add product with barcode scanning
5. ✅ Categories list with nested structure
6. ✅ Category detail with product reordering
7. ✅ Bulk pricing editor for cuadros
8. ✅ Settings screen (placeholder)
9. ✅ Authentication with role-based access

**Migration:**
- ✅ 1,066 products imported from Excel
- ✅ 24 categories created
- ✅ Images linked from Storage
- ✅ Temas collection populated

**Success Criteria:**
- ✅ All products in Firestore with accurate data
- ✅ Barcode scanning works (USB scanner tested)
- ✅ Categories properly structured with pricing inheritance
- ✅ Employee can search/edit products easily

---

### Phase 2: Inventory Management 🟡 IN PROGRESS (50%)

**Timeline:** Months 2-3

**Phase 2A: Inventory Operations ✅ COMPLETE**

**Deliverables:**
1. ✅ Recepciones - Shipment receipt screen
   - ✅ Scanner integration working
   - ✅ Excel upload for bulk import
   - ✅ History/detail screens
   - ✅ Complete → updates warehouse stock
   - ✅ Cancel → doesn't affect stock

2. ✅ Movimientos - Stock transfers
   - ✅ Two-step workflow (send → receive)
   - ✅ Origin/destination selection
   - ✅ Stock validation
   - ✅ Edit/delete/undo operations
   - ✅ History/detail screens

**Phase 2B: Sales & Orders 🟡 IN PROGRESS**

**Status:**
- ✅ Register sale screen (UI + backend complete)
- ✅ Sales history with filters
- ✅ Orders history (delivery orders)
- ✅ Sale detail screen
- ✅ Payment method integration (bank accounts)
- ✅ Bulk pricing auto-calculation
- ✅ Stock deduction on sale creation
- ✅ Pending cash tracking

**Remaining:**
- ⏳ Order detail screen enhancements
- ⏳ Delivery status updates (mensajero workflow)
- ⏳ Payment verification workflow (superuser approval)

**Success Criteria:**
- ✅ Shipment receipt replaces Excel COUNTIF
- ✅ Stock transfers work smoothly (warehouse ↔ store)
- ✅ All sales recorded accurately (store + delivery)
- ⏳ Order status progression works end-to-end

---

### Phase 3: Financial Management 🟡 IN PROGRESS (75%)

**Timeline:** Month 4

**Status:**
- ✅ Finances overview screen
- ✅ Bank accounts management (CRUD, QTZ/USD, balance tracking)
- ✅ Deposits with comprobante photos
- ✅ Employee cash expense tracking (before deposit)
- ✅ Expenses list with filters
- ✅ Expense categories management
- ✅ Reports screen with 4 tabs:
  - ✅ Ventas (sales analytics)
  - ✅ Productos (product performance)
  - ✅ Finanzas (financial summary with bank account breakdowns)
  - ✅ Gastos (expense analysis)
- ✅ Date range filters with presets
- ✅ Interactive charts (fl_chart)
- ✅ Dynamic tables with sorting

**Remaining:**
- ⏳ Export functionality (Excel, PDF, CSV)
- ⏳ More advanced analytics (cohort analysis, forecasting)

**Success Criteria:**
- ✅ All cash accounted for (no missing money)
- ✅ Mom can see profit/loss monthly
- ✅ Deposit alerts prevent cash drawer buildup
- ✅ Business decisions are data-driven (reports show trends)
- ✅ Bank account breakdowns show revenue and expenses per account
- ✅ Employee expenses paid from collected cash are tracked correctly

---

### Phase 4: User Management & Permissions ⏳ PLANNED

**Timeline:** Month 5

**Features:**
1. User creation/editing
2. Role assignment (5 role types)
3. Granular permissions
4. Audit logs (who did what, when)
5. Activity tracking
6. User management screen (superuser only)

**User Roles:**
- Superuser (Mom, Michelle)
- Employee (Marta)
- Employee Kiosko (Temporary)
- Warehouse (Clarita)
- Messenger (Sergio)

**Permissions Matrix:**
| Permission | Superuser | Employee | Kiosko | Warehouse | Messenger |
|------------|-----------|----------|--------|-----------|-----------|
| View Finances | ✅ | ❌ | ❌ | ❌ | ❌ |
| Approve Expenses | ✅ | ❌ | ❌ | ❌ | ❌ |
| Register Sales | ✅ | ✅ | ✅ | ❌ | ❌ |
| Manage Inventory | ✅ | ✅ | ❌ | ✅ | ❌ |
| View Reports | ✅ | ❌ | ❌ | ❌ | ❌ |
| Update Delivery Status | ✅ | ✅ | ❌ | ❌ | ✅ |
| Manage Users | ✅ | ❌ | ❌ | ❌ | ❌ |

---

### Phase 5: Client-Facing App ⏳ FUTURE

**Timeline:** Month 6+

**Features:**
1. Public product browsing (out-of-stock hidden)
2. Category navigation
3. Product detail pages with images
4. Shopping cart (persistent)
5. Search & filters (name, tema, category)
6. WhatsApp integration (send cart)
7. Direct product URLs
8. Footer with business info

**Technology:**
- Same Flutter codebase
- Separate route/subdomain (`shop.xepi.com`)
- Public Firestore read access
- No authentication required

---

## Key Business Logic

### Price Calculation

```dart
// 1. Check for manual override
if (product.priceOverride != null) {
  return product.priceOverride;
}

// 2. Fallback to category default
final category = await _getCategoryByCode(product.categoryCode);
double basePrice = category.defaultPrice;

// 3. Apply bulk pricing (cuadros 20x30, 15x30 only)
if (categoryCode == 'CUA-2030' || categoryCode == 'CUA-1530') {
  final totalBulkQty = _getBulkEligibleQuantity();  // Total in cart
  
  if (totalBulkQty >= 5 && category.bulkPricing?.qty5Plus != null) {
    return category.bulkPricing.qty5Plus;  // e.g., Q25
  } else if (totalBulkQty >= 2 && category.bulkPricing?.qty2 != null) {
    return category.bulkPricing.qty2;      // e.g., Q30
  }
}

return basePrice;  // e.g., Q35
```

**Example:**
- 1x Cuadro Coca Cola 20x30 = Q35
- 2x Cuadro Coca Cola 20x30 = Q30 each = Q60 total
- 5x Cuadro Coca Cola 20x30 = Q25 each = Q125 total
- 3x Cuadro Coca Cola 20x30 + 2x Cuadro Vintage 20x30 = Q25 each = Q125 total (bulk qty = 5)

### Stock Status Colors

```dart
final totalStock = product.stockWarehouse + product.stockStore;

Color getStockColor(int stock) {
  if (stock == 0) return Colors.grey;      // Out of stock
  if (stock < 3) return Colors.red;        // Critical (🔴)
  if (stock < 10) return Colors.yellow;    // Low (🟡)
  return Colors.green;                     // Healthy (🟢)
}
```

### Cash Flow Tracking

**When Cash Sale Created:**
```dart
if (paymentMethod == 'efectivo') {
  final source = saleLocation == 'store' ? 'store'
    : deliveryMethod == 'mensajero' ? 'mensajero'
    : 'forza';
  
  // Add to pending cash
  await _firestore.collection('pendingCash').doc(source).set({
    'amount': FieldValue.increment(saleTotal),
    'saleIds': FieldValue.arrayUnion([saleId]),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

**When Deposit Created:**
```dart
// Employee collected Q500, spent Q50 on "Suministros de tienda" → deposits Q450

// 1. Create expense records
for (expense in expenses) {
  await _firestore.collection('expenses').add({
    amount: 50,
    category: 'Suministros de tienda',
    paymentSource: 'efectivo',
    status: 'pending_approval',  // Needs superuser approval
    depositId: depositId,
  });
}

// 2. Create deposit
await _firestore.collection('deposits').add({
  cashReceived: 500,
  expenses: 50,
  amount: 450,              // Net deposit
  source: 'store',
  destinationAccount: 'biPersonalQTZ',
  comprobanteUrl: url,
  expenseIds: [expenseId1],
  saleIds: linkedSaleIds,
});

// 3. Update pending cash (deduct cashReceived, not net deposit)
await _firestore.collection('pendingCash').doc('store').update({
  amount: FieldValue.increment(-500),  // Full amount received, not net
  'saleIds': FieldValue.arrayRemove(linkedSaleIds),
});

// 4. Link sales to deposit
for (saleId in saleIds) {
  await _firestore.collection('sales').doc(saleId).update({
    depositId: depositId,
  });
}
```

**Goal:** Every quetzal tracked from sale → cash collection → deposit → bank account.

---

## Common Development Patterns

### Loading + Error + Success Pattern

```dart
bool _isLoading = false;
List<Map<String, dynamic>> _data = [];

Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final snapshot = await _firestore.collection('products').get();
    
    setState(() {
      _data = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}
```

### Barcode Scanner Pattern

```dart
final TextEditingController _barcodeController = TextEditingController();
final FocusNode _barcodeFocusNode = FocusNode();

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _barcodeFocusNode.requestFocus();
  });
}

Widget build(BuildContext context) {
  return TextField(
    controller: _barcodeController,
    focusNode: _barcodeFocusNode,
    autofocus: true,
    decoration: InputDecoration(
      labelText: 'Código de barras',
      prefixIcon: Icon(Icons.qr_code_2_rounded),
    ),
    onSubmitted: (barcode) async {
      if (barcode.trim().isEmpty) return;
      
      await _handleBarcodeScanned(barcode.trim());
      
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    },
  );
}
```

### Form Validation Pattern

```dart
final _formKey = GlobalKey<FormState>();

Widget build(BuildContext context) {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        TextFormField(
          decoration: InputDecoration(labelText: 'Nombre'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo requerido';
            }
            return null;
          },
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _saveData();
            }
          },
          child: Text('Guardar'),
        ),
      ],
    ),
  );
}
```

### Debounced Search Pattern

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(const Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

---

## Success Metrics & KPIs

### Phase 1 Success (Products Database) ✅
- ✅ All ~1,066 products in Firestore with accurate data
- ✅ Employee can search/edit products easily
- ✅ Barcode scanning works (USB scanner tested)
- ✅ Categories properly structured with pricing inheritance

### Phase 2 Success (Inventory Management) 🟡
- ✅ Shipment receipt replaces Excel COUNTIF workflow
- ✅ Stock transfers work smoothly (warehouse ↔ store)
- ✅ All sales recorded accurately (store + delivery)
- ⏳ Order status progression working end-to-end

### Phase 3 Success (Financial Management) 🟡
- ✅ All cash accounted for (no missing money)
- ✅ Mom can see profit/loss monthly
- ✅ Deposit alerts prevent cash drawer buildup
- ✅ Business decisions are data-driven (reports show trends)
- ⏳ System ROI positive (time saved + better decisions)

### Final Success Criteria ⏳
- ⏳ Inventory accurate within 2% (physical vs system)
- ✅ All sales tracked (no "off the books" transactions)
- ✅ Employee saves 5+ hours/week (vs Excel)
- ⏳ Mom has clear financial picture monthly
- ✅ Data shows which products to stock/discontinue
- ✅ Cash reconciliation happens automatically

---

## Non-Goals (Scope Protection)

**Explicitly Out of Scope:**

❌ **Not Complex Accounting Features**  
   - XEPI Admin IS Michelle's complete accounting system
   - Sales + Expenses tracking covers all her needs (simple transactions only)
   - No general ledger, no double-entry bookkeeping
   - No tax filing automation (manual process is acceptable)

❌ **Not FEL Integration**  
   - Legal invoicing (FEL) not planned
   - Current NIT field is manual entry only
   - No automated SAT reporting (not needed)

❌ **Not Multi-Branch (Yet)**  
   - System designed for 1 warehouse + 1 store
   - Future expansion would require architecture changes

❌ **Not Real-Time Collaboration**  
   - No live cursors, no conflict resolution UI
   - Last-write-wins is acceptable for our use case

❌ **Not a CRM**  
   - Customer data is minimal (name, phone for deliveries)
   - No customer history (future), loyalty programs, or marketing automation

❌ **Not Offline-First**  
   - Requires internet connection (Firebase dependency)
   - No local SQLite cache or sync mechanism
   - Acceptable for fixed-location use (store has WiFi)

❌ **Not a Wholesale/B2B System**  
   - No bulk order management for resellers
   - No tiered pricing by customer type
   - Retail-focused only

---

## System Risks & Future Improvements

### Known Risks

**1. Barcode as Document ID**
- **Risk:** If barcode changes, entire document must be recreated
- **Impact:** Medium - rare in practice, but painful when it happens
- **Mitigation:** Make barcode immutable policy, educate users
- **Future:** Use auto-generated IDs, store barcode as field

**2. Manual Balance Reconciliation**
- **Risk:** Bank account balances can drift from reality
- **Impact:** Low - weekly reconciliation catches issues
- **Mitigation:** Clear UI prompts for reconciliation
- **Future:** Bank API integration for auto-sync

**3. No Audit Logs**
- **Risk:** Can't track who changed what, when
- **Impact:** Medium - disputes require manual investigation
- **Mitigation:** createdBy/updatedBy fields capture basics
- **Future:** Full audit log collection with changesets

**4. Hardcoded Superuser UIDs**
- **Risk:** Adding/removing superusers requires code deploy
- **Impact:** Low - role changes are infrequent
- **Mitigation:** Clear instructions for developer
- **Future:** Dynamic role management (Phase 4)

**5. In-Memory Report Filtering**
- **Risk:** Slow performance if data volume explodes
- **Impact:** Low - current scale is fine, growth is gradual
- **Mitigation:** Pagination implemented for lists
- **Future:** Backend aggregation, materialized views

**6. No Automated Backups Verification**
- **Risk:** Firebase backups exist but never tested for restore
- **Impact:** High - data loss could be catastrophic
- **Mitigation:** See Backup & Recovery Plan below
- **Future:** Quarterly restore drills

### Future Improvements (Backlog)

**High Priority:**
- ⚡ Audit log implementation (who changed what)
- ⚡ Predictive inventory ("restock alerts based on sales velocity")
- ⚡ Export to Excel/CSV (reports screen)

**Medium Priority:**
- 💡 Email notifications (low stock, overdue deposits)
- 💡 WhatsApp API integration (send order confirmations)
- 💡 FEL integration for legal invoicing

**Low Priority:**
- 🔮 Mobile app (native iOS/Android)
- 🔮 Advanced analytics (cohort analysis, forecasting)
- 🔮 Offline mode with sync

---

## Deployment

### Backup & Recovery Plan

**Automatic Backups (Firebase):**
- Firestore: Automatic daily backups (retained 7 days)
- Storage: Automatic versioning enabled
- Authentication: User list exportable via Firebase Console

**Manual Export Schedule:**
- **Monthly:** Export critical collections to CSV
  - Products (barcode, name, stock levels)
  - Sales (date, total, payment method)
  - Deposits (date, amount, source)
- **Responsibility:** Valeria (developer)
- **Storage:** Google Drive backup folder

**Recovery Procedures:**

**Scenario 1: Accidental Delete**
- Firestore: Restore from automatic backup (Firebase Console)
- Time frame: Last 7 days recoverable

**Scenario 2: Data Corruption**
- Restore from monthly CSV export
- Re-import using migration scripts (archive/migration_scripts/)

**Scenario 3: Firebase Project Compromised**
- Create new Firebase project
- Restore from CSV exports
- Update firebase_options.dart with new config
- Redeploy

**Testing:**
- ⏳ **TODO:** Quarterly restore drill (test CSV import on staging project)
- ⏳ **TODO:** Document exact restore commands

**Critical Data Priority:**
1. Sales records (revenue data)
2. Product inventory (business continuity)
3. Deposits (financial reconciliation)
4. Expenses (tax records)
5. Images (recreatable but valuable)

### Development

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Edge
flutter run -d edge
```

### Production Build

```bash
# Build for web
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes

# Deploy Storage rules
firebase deploy --only storage
```

### Environment Configuration

**Files to copy from examples:**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp web/firebase-config.js.example web/firebase-config.js
```

**Edit with real credentials:**
- `firebase_options.dart` - Flutter Firebase config
- `firebase-config.js` - Web Firebase config

**Never commit:**
- `serviceAccountKey.json`
- `.env`
- `lib/firebase_options.dart`
- `web/firebase-config.js`

---

## Migration Scripts

Located in `archive/migration_scripts/`

### Python Environment

```bash
# Create virtual environment
python -m venv venv

# Activate (macOS/Linux)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Scripts Overview

1. **import_products.py** - Excel → Firestore products
2. **import_categories.py** - Excel → Firestore categories
3. **upload_images.py** - Bulk upload images to Storage
4. **migrate_temas.py** - Create temas collection
5. **add_display_order.py** - Add displayOrder to existing products
6. **init_locations.py** - Create locations collection
7. **setup_locations.py** - Initialize warehouse/store metadata
8. **cleanup_pending_cash.py** - Remove orphaned sale references
9. **fix_orphaned_sales.py** - Fix sales without valid depositId
10. **fix_completed_sales.py** - Update legacy sales format

---

## Troubleshooting

### Common Issues

**Issue:** Barcode scanner not working
- **Solution:** Check USB connection, ensure TextField has autofocus=true

**Issue:** Firestore permission denied
- **Solution:** Check firestore.rules, verify user is authenticated

**Issue:** Images not loading
- **Solution:** Check Storage rules, verify URLs are correct

**Issue:** Bulk pricing not applying
- **Solution:** Verify categoryCode is 'CUA-2030' or 'CUA-1530', check bulkPricing field exists

**Issue:** Pending cash not updating
- **Solution:** Check saleId still exists, run cleanup script

**Issue:** Real-time updates not working
- **Solution:** Use StreamBuilder, check Firestore listeners

---

## Future Enhancements

### Short Term (Next 3 months)
- ⏳ Export reports to Excel/PDF
- ⏳ Advanced search (fuzzy matching, typo tolerance)
- ⏳ Bulk product editing
- ⏳ Product import/export via Excel
- ⏳ Automated low stock alerts (push notifications)
- ⏳ Delivery tracking with GPS (mensajero app)

### Medium Term (6-12 months)
- ⏳ Client-facing e-commerce app (halfway built)
- ⏳ WhatsApp Business API integration
- ⏳ Automated WhatsApp order parsing
- ⏳ Inventory forecasting (AI-powered)
- ⏳ Customer database with purchase history
- ⏳ Loyalty program
- ⏳ Multi-location support (additional stores)

### Long Term (12+ months)
- ⏳ Mobile app (iOS/Android) for employees
- ⏳ Supplier management portal
- ⏳ Barcode label printing
- ⏳ Advanced analytics (predictive modeling)
- ⏳ Multi-currency support (USD, EUR)

---

## Contact & Support

**Project Lead:** Valeria (Superuser)
**Email:** [Contact via GitHub]
**Repository:** Private (xepi_imgadmin)

**Documentation Last Updated:** February 18, 2026

---

*This documentation covers the complete XEPI Admin System as of Phase 2-3 completion. All implementations, data models, and architectural decisions are accurately reflected from the actual codebase.*
