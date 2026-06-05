# Known Issues & Tech Debt

Exhaustive list of concrete problems found in the June 2026 audit, with `file:line` where known. The structural themes are covered in [ARCHITECTURE.md](ARCHITECTURE.md) / [ROADMAP.md](ROADMAP.md); this is the itemized backlog so nothing gets lost between sessions.

Severity: 🔴 data integrity · 🟠 correctness/UX · 🟡 debt/cleanup

---

## 🔴 Data integrity (P0)
- ✅ **Stock race condition** — FIXED 2026-06-03. `register_sale_screen.dart` now uses `runTransaction` instead of `batch` for sale creation. All reads (live stock validation) happen before all writes within the transaction, so concurrent sales cannot oversell.
- ✅ **`?? 'admin'` auth fallback** — FIXED 2026-06-03. Only instance was `finances_screen.dart:653`. Replaced with a hard guard (`if (currentUser == null) return;`).
- 🟡 **Hardcoded superuser UIDs** — `auth_service.dart:7` still uses hardcoded list. `firestore.rules` updated (2026-06-03) to use `isSuperuser() || isKnownAdminUid()` as non-breaking bridge. Full removal: create `users/{uid}` docs with `role: 'superuser'`, update `auth_service.dart` to do async Firestore lookup, then remove `isKnownAdminUid()`. See [PERMISSIONS.md](PERMISSIONS.md).
- ✅ **Potential double stock-deduction across screens** — FIXED 2026-06-04. Both `orders_history_screen` and `sale_detail_screen` now delegate to `SalesRepository.updateDeliveryStatus()` which uses `runTransaction`. The logic is in one place and fully atomic.

## 🟠 Correctness / broken features
- ✅ **`orders_history_screen.dart:441`** — FIXED 2026-06-03. The `if (newStatus == 'picked_up')` branch built the updates map but never wrote it. Added `await saleRef.update(updates)` in that branch.
- ✅ **`product_detail_screen.dart:2389`** — FIXED 2026-06-04. `_buildStockAdjuster` `−`/`+` buttons updated `controller.text` without calling `setState`, so `currentAdjustment` never refreshed between presses. Both buttons now call `setState()`.
- ✅ **`category_detail_screen.dart:977`** — FIXED 2026-06-04. Product cards in the grid now navigate to `ProductDetailScreen` on tap (wrapped in `InkWell` inside the `Card`).
- ✅ **`category_detail_screen.dart:403`** — FIXED 2026-06-04. Removed a confusing `// TODO what does this modify??` comment — the `Text('Nombre', ...)` widget is a plain read-only label, nothing to fix.
- 🟡 **`category_detail_screen.dart:369`** — bulk pricing "edit quantities" deferred. The quantity thresholds (`qty2`, `qty5Plus`) are hardcoded keys in the data model. Allowing them to be user-editable requires a schema change. Owner decision before implementing.
- ✅ **`dashboard_screen.dart:240,273`** — FIXED 2026-06-04. "Registrar Venta" now navigates to `RegisterSaleScreen`; "Recibir Envío" navigates to `ShipmentHistoryScreen`.
- ✅ **`settings_screen.dart:253,414`** — FIXED 2026-06-04. Profile (name, email) now loads from `AuthService.currentUser`. WhatsApp loads from `users/{uid}`. Product/category counts are live Firestore queries. Save writes `displayName` to Firebase Auth + `whatsapp` to Firestore (merge). Password change uses `reauthenticateWithCredential` + `updatePassword` with proper validation and error display.
- ✅ **`add_product_screen.dart:225`** — FIXED 2026-06-04. "Escanear" button now focuses the barcode `TextFormField` via `FocusNode.requestFocus()` so USB scanner input lands in the right field. Relabeled "Enfocar escáner". Camera-based scanning remains P3 (needs `mobile_scanner` package decision).
- ✅ **`storage.rules` admin UID mismatch** — FIXED 2026-06-04. Re-audit found Michelle's UID (`yMnQBCQrtpblH3yTHd05XLVloZu2`) was missing from all storage write rules, so she could not upload product images. Added to all four `allow write` blocks. Kiosk employee UID retained (intentional — needed for legacy image system).
- ✅ **`sales_history_screen.dart:541–548`** — FIXED 2026-06-04. `_buildSaleCard()` used hard `as String` / `as bool` / `as num` casts on `paymentMethod`, `total`, `paymentVerified`, `status`. Any sale document with a missing field would crash the entire list. All four changed to nullable casts with safe defaults.
- ✅ **`expenses_list_screen.dart:359–360`** — FIXED 2026-06-04. Bank account dropdown used hard `as String` casts on `accountName` and `last4Digits`. Changed to nullable casts with `'Cuenta'` / `'****'` fallbacks.
- ✅ **`expenses_list_screen.dart:405`** — FIXED 2026-06-04. `createdBy: AuthService.currentUser?.uid ?? 'unknown'` would write `'unknown'` to the audit trail if user was null. Replaced with a null guard (`if (uid == null) return;`) that aborts the write instead.
- ✅ **`expenses_service.dart:85` / `finance_repository.dart:106`** — FIXED 2026-06-04. `approveExpense(id, approvedBy)` and `rejectExpense(id, approvedBy)` accepted a caller-supplied UID, allowing the audit trail to be forged. Both methods now derive the UID from `FirebaseAuth.instance.currentUser` internally and throw if unauthenticated.
- ✅ **`sales_history_screen.dart:_quickUpdateDeliveryStatus`** — FIXED 2026-06-05. Third screen doing delivery status updates via batch (not transaction), duplicating the same stock-deduction race fixed in `orders_history_screen` and `sale_detail_screen`. Replaced with delegation to `SalesRepository.instance.updateDeliveryStatus()`. `'completed'` status (no stock/cash implications) remains as a direct update.
- ✅ **`expenses_list_screen.dart:74,210,228,262`** — FIXED 2026-06-05. Remaining hard casts on `amount` (fold total + row display), `category`, and `description` fields changed to nullable casts with safe defaults. `as double` on `amount` also corrected to `as num?` (Firestore may return int).
- ✅ **`register_sale_screen.dart:1504–1506`** — FIXED 2026-06-05. Bank account dropdown in payment method selector used hard `as String` casts on `accountName`, `bankName`, `last4Digits`. Would crash checkout if any account document had a missing field. Changed to nullable casts with fallbacks.
- ✅ **`admin_login.dart`** — FIXED 2026-06-05. `_emailController` and `_passwordController` were class-level `State` fields with no `dispose()` override — confirmed memory leak. Added `dispose()`.
- **N+1 query** — `reports_service.dart:113-119` loops categories and fetches `subcategories` per category. Fine at current scale, but batch/denormalize if categories grow.

## 🟡 Debt / cleanup
- **No typed models** — everything is `Map<String, dynamic>`; unsafe casts everywhere. Fix: P1 models.
- **Direct Firestore in screens** — `FirebaseFirestore.instance` called in 230+ places. Fix: repositories.
- **Magic strings** — `'efectivo'`, `'pending'`, `'mensajero'`, `'store'`, etc., ~300+ occurrences. Fix: enums.
- **Doc-id field inconsistency** — `saleId`, `orderId`, `expenseId`, and generic `id` all used for `doc.id`. e.g. `sales_history_screen.dart:44` (`saleId`), `orders_history_screen.dart:44` (`orderId` "for compatibility"), `bank_accounts_service.dart` (`id`). Standardize to one (`id`) in models.
- **Controller disposal** — ~16 screens use controllers, only ~11 override `dispose()`. Audit the gap for leaks.
- **Inconsistent service patterns** — some services static (`ExpensesService`), some instance (`BankAccountsService`). Standardize.
- **Silent failures** — `catch (e) { /* silent */ }` defaulting to empty lists (e.g. expenses/bank account loads). Fix per error-handling strategy in [ARCHITECTURE.md](ARCHITECTURE.md).
- **God files** — `product_detail_screen.dart` (~3,044), `reports_screen.dart` (~2,172), `sale_detail_screen.dart` (~1,601), `register_sale_screen.dart` (~1,565), `movement_detail_screen.dart` (~1,138), `sales_history_screen.dart` (~1,051), `main_layout.dart` (~552). Target < 400.
- **No input validation** — amounts, barcodes, etc. unvalidated before write.
- **`notifications` collection** — referenced in rules, undefined purpose. Decide or remove.
- **Two image systems** — legacy Realtime DB (`admin_dashboard_legacy.dart`, protected) vs new Firestore/Storage. Migrate then retire (P4).

---

## Coverage note
Major structural issues + all 🔴 items are reflected in [ROADMAP.md](ROADMAP.md). The 🟠/🟡 items here are the long tail captured for completeness — address opportunistically while doing the P1–P3 refactors, not as standalone tasks.
