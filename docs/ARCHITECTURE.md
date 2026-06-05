# Architecture

Target architecture and conventions. The current code works but is built on monolithic StatefulWidgets with direct Firestore calls, no models, and magic strings. This is where we're moving it.

---

## Stack decision
**Stay Flutter + Firebase/GCP.** The problems are code architecture, not the database. Do NOT migrate to Supabase/Cloud SQL — see [DECISIONS.md](DECISIONS.md) ADR-001. Add Firebase Cloud Functions for the operations that need real server-side transactions.

| Layer | Keep | Add |
|-------|------|-----|
| Frontend | Flutter | GoRouter |
| State | — | Riverpod |
| Database | Firestore | Cloud Functions for critical ops |
| Auth | Firebase Auth | role + permissions in `users` |
| Storage | Firebase Storage | — |

---

## Target layout

```
lib/
├── constants/      enums + Firestore collection names + permission catalog
│   payment_method.dart, sale_type.dart, delivery_method.dart,
│   stock_location.dart, status_enums.dart, collections.dart, permissions.dart
├── models/         typed entities w/ fromFirestore()/toMap()
│   sale, product, order, expense, deposit, bank_account, shipment, movement
├── repositories/   ALL Firestore access. Screens never touch FirebaseFirestore directly.
│   sales_repository, products_repository, inventory_repository,
│   finance_repository, auth_repository
├── providers/      Riverpod: state + business logic
│   auth_provider, products_provider, sales_provider, finance_provider
├── screens/        thin: read providers, call methods, render. No file > 400 lines.
├── widgets/        reusable UI (extracted from god files)
├── config/         app_theme.dart (keep), router.dart (GoRouter)
└── (functions/)    separate Firebase Functions project: deductStock, approvePayment, processDeposit
```

---

## Conventions

### Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Files | snake_case | `sale_repository.dart` |
| Classes | PascalCase | `SaleRepository` |
| Methods | camelCase | `getActiveSales()` |
| Private | _camelCase | `_mapDocToSale()` |
| Enums | PascalCase / camelCase values | `PaymentMethod.efectivo` |
| Firestore collections | camelCase strings via `Collections.*` | `'bankAccounts'` |
| Booleans | is/has prefix | `isActive`, `paymentVerified` |

UI in **Spanish**, code in **English** (existing convention — keep).

### Error handling strategy
- Repositories: no try/catch — let errors propagate.
- Providers: catch, expose `AsyncError` state.
- Screens: watch provider state, show error UI (not just a SnackBar).
- Cloud Functions: return structured `{ code, message }`.
- Critical failures (stock/deposit): blocking dialog, not a dismissable snackbar.
- All errors log to **Crashlytics**.

### Data validation
- `Sale.total` > 0 and matches item sum.
- `Expense.amount` > 0 and under a sane max.
- Stock never < 0 (enforce server-side in `deductStock`).
- `Deposit.amount` == `cashReceived − expenses` (validate in Function).

### Performance (current scale: ~600 products, ~50–100 sales/day)
Firestore is fine for years. Fixes: add composite indexes for common filtered queries (sales by date+type, expenses by status+date); paginate list screens (limit 25); stop fetching 100 docs to filter client-side; share data via providers instead of per-screen fetches.

### Offline
Enable Firestore persistence in `main.dart` (`persistenceEnabled: true`). Free resilience to brief disconnects. Does not solve concurrent-write stock races — that's what `deductStock` (transaction) is for.

---

## Critical invariants (never break)
1. Shipment completion increments warehouse stock atomically.
2. Movement: sent = −origin, received = +destination; cancel restores.
3. Sales must not double-deduct stock across screens.
4. `pendingCash` reduced by **cashReceived**, not net deposit amount.
5. Legacy admin dashboard (`admin_dashboard_legacy.dart`) is **protected — never delete** until migration. See [AGENTS.md](../AGENTS.md).
