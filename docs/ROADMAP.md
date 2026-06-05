# Roadmap

Prioritized by impact vs. effort. Update status as items ship. Derived from the June 2026 full-system audit.

Status key: ⬜ not started · 🟡 in progress · ✅ done

---

## P0 — Data integrity (data corruption risk now)
- ✅ Fix stock race condition: `register_sale_screen.dart` now uses `runTransaction` — reads live stock and writes atomically (2026-06-03)
- ✅ Fix `orders_history_screen.dart` broken sub-feature: `picked_up` branch now writes to Firestore (2026-06-03)
- ✅ Replace `?? 'admin'` auth fallback: `finances_screen.dart:653` now guards with hard return (2026-06-03)

## P1 — Foundation
- ✅ Constants/enums (`lib/constants/`) — 6 files, all enums + Collections class, barrel export (2026-06-03)
- ✅ 8 typed model classes (`lib/models/`) — Sale, Product, Expense, Deposit, BankAccount, Shipment, Movement, Order with `fromFirestore()`/`toMap()` (2026-06-03)
- 🟡 Repository layer — 4 repositories created (`SalesRepository`, `FinanceRepository`, `ProductsRepository`, `InventoryRepository`). Wired up: `orders_history_screen` (delivery status updates now transactional), `finances_screen` (expense + category writes). Remaining: ~20 screens still call Firestore directly — migrate incrementally per screen during P3 god-file breakup
- 🟡 Role + `permissions` map in Firestore; rules use it (remove hardcoded UIDs) — firestore.rules updated to use `isSuperuser() || isKnownAdminUid()` (non-breaking bridge). Full removal requires user documents in Firestore with `role: 'superuser'`. See [PERMISSIONS.md](PERMISSIONS.md)
- ✅ In-repo documentation set (this `docs/` folder, incl. MUTATION_RULES, TEST_PLAN, OPERATIONS)
- ⬜ Stock adjustments / shrinkage (reason codes + audit) — *confirmed in scope*
- ⬜ Soft-delete (void) default + admin hard-delete escape hatch — see [OPERATIONS.md](OPERATIONS.md)
- ⬜ Minimal defective-return path (returns are rare, defective-only — not a full system)

## Pre-go-live (not urgent — prod currently holds only test data)
- ⬜ Staging/dev Firebase project separate from prod
- ⬜ Seed script for staging ([OPERATIONS.md](OPERATIONS.md))
- ⬜ Backup + tested restore procedure ([OPERATIONS.md](OPERATIONS.md))

## P2 — Security & missing features
- ⬜ Cloud Functions: `deductStock`, `approvePayment`, `processDeposit`
- ⬜ User management screen (role template + per-user permission toggles)
- ⬜ Firestore offline persistence (`main.dart`)
- ⬜ Firebase Crashlytics
- ⬜ Settings screen actually saves to Firestore
- ⬜ Low stock report / indicator
- ⬜ Cash drawer / shift open-close accountability
- ⬜ Product search strategy (~600 products)
- ⬜ Decide `notifications` collection purpose (or remove)

## P3 — Architecture
- ⬜ Riverpod providers for shared data (products, pendingCash, bank accounts)
- ⬜ Break up god files — `product_detail_screen.dart` first (3,044 lines)
- ⬜ GoRouter navigation
- ⬜ Audit log collection + viewer

## P4 — Polish & Phase 2
- ⬜ Supplier management
- ⬜ Cost-based price suggestions (uses `costPrice`)
- ⬜ Legacy image migration → then delete `admin_dashboard_legacy.dart`
- ⬜ Unit tests (models + business logic)
- ⬜ **Web checkout design** (delivery pricing, VisaLink, voucher capture) — needs a dedicated session, see [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md)
- ⬜ Client app read contract + scoped public Firestore rules
- ⬜ Image management at scale

---

## Effort estimate
- P0 alone: 2–3 days
- P0–P1: 1–2 weeks
- P0–P3: 4–6 weeks
