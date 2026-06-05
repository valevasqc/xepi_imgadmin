# Permissions & Roles

Model: **role templates + editable per-user permission toggles.** The team has genuinely different jobs (kiosko, warehouse, mensajero) — a single flat "employee" role is wrong.

---

## Model

- A **role** pre-fills a sensible permission set (a template).
- Each **user document carries an explicit `permissions` map** the admin can toggle individually in the User Management screen.
- Picking a role applies its template; toggling any permission afterward keeps the user's custom set.

```
users/{uid}
  name, email, isActive
  role: 'admin' | 'kiosko' | 'warehouse' | 'mensajero' | 'custom'
  permissions: {
    'sales.create': true,
    'sales.viewAll': false,
    'sales.approve': false,
    'shipments.receive': true,
    'movements.manage': false,
    'expenses.submit': true,
    'finances.view': false,
    ...
  }
```

The catalog of all toggleable permissions lives in `lib/constants/permissions.dart`, grouped by module: `products.*`, `categories.*`, `shipments.*`, `movements.*`, `sales.*`, `orders.*`, `deliveries.*`, `expenses.*`, `finances.*`, `deposits.*`, `reports.*`, `users.*`, `settings.*`, `stock.adjust`, `cash.drawerOpenClose`.

---

## Default templates (starting points — all individually overridable)

**admin** — everything.

**kiosko** (store POS): `sales.create`, `sales.viewOwn`, `products.view`, `categories.view`, `expenses.submit`, `cash.drawerOpenClose`.

**warehouse**: `products.view`, `products.createEdit`, `shipments.view`, `shipments.receive`, `movements.manage`, `stock.adjust`, `expenses.submit`. No sales, finances, or deliveries.

**mensajero** (courier): `deliveries.viewAssigned`, `deliveries.updateStatus`, `deliveries.markCashReceived`. Nothing else.

---

## Full permission matrix (catalog)

Admin = all. "Employee baseline" is the broad default; per-archetype defaults are the lists above. Admin can toggle any capability per user.

| Feature | Admin | Employee baseline | Notes |
|---------|-------|-------------------|-------|
| Dashboard | ✓ | ✓ (limited) | employee sees today only |
| Products — view | ✓ | ✓ | |
| Products — create/edit | ✓ | ✓ | warehouse needs for new barcodes |
| Products — delete | ✓ | ✗ | |
| Categories — view | ✓ | ✓ | |
| Categories — edit | ✓ | ✗ | pricing is admin-only |
| Shipments — view/receive | ✓ | ✓ | warehouse |
| Shipments — cancel | ✓ | ✗ | |
| Movements — manage | ✓ | ✓ | |
| Movements — cancel | ✓ | ✗ | |
| Stock adjustments | ✓ | warehouse only | with reason code + audit |
| Register sale | ✓ | ✓ | kiosko |
| Sales — view all | ✓ | own only | |
| Sales — approve payment | ✓ | ✗ | transfer/card + voucher check |
| Sales — delete/void | ✓ | own pending only | soft-delete |
| Deliveries — update status | ✓ | ✓ | mensajero |
| Finances screen | ✓ | ✗ | |
| Bank accounts | ✓ | ✗ | |
| Deposits | ✓ | ✗ | |
| Expenses — submit | ✓ | ✓ | goes to pending |
| Expenses — add approved | ✓ | ✗ | |
| Expenses — approve/reject | ✓ | ✗ | |
| Expense categories | ✓ | ✗ | |
| Reports | ✓ | ✗ | |
| Settings | ✓ | ✗ | |
| User management | ✓ | ✗ | |

---

## Enforcement (three layers — all required)

1. **UI** — navigation and buttons read the current user's `permissions` map (via `authProvider`) to show/hide.
2. **Firestore rules** — security-critical gates checked server-side. To avoid a `get()` on the user doc per operation, mirror a compact set of high-security flags into **Firebase custom claims**, set by a Cloud Function whenever an admin changes a user's permissions. The full map stays in the user doc for UI.
3. **Cloud Functions** — the 3 critical operations (`deductStock`, `approvePayment`, `processDeposit`) re-check permissions server-side regardless of what the client sent.

> UI-only enforcement (today's state) is **not security** — a user who knows the Firestore path bypasses it. Layers 2 and 3 make it real.

## Migration note
Today, admin is hardcoded UIDs in `auth_service.dart` AND `firestore.rules` (two places). Target: move to `users/{uid}.role` + `permissions`, and rules read those. See [ROADMAP.md](ROADMAP.md) P1 #7.
