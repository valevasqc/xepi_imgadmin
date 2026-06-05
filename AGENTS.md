# AGENTS.md — XEPI Admin

Hard rules and invariants. Claude Code reads this automatically every session. For the operational guide and workflows, see `CLAUDE.md`. For all project docs, see `docs/`.

---

## What this project is not
- Not a full ERP or legal invoicing/FEL system
- Not a full accounting suite
- Not a client-facing checkout app

---

## Protected legacy rule
`admin_dashboard_legacy.dart` **must never be deleted or casually modified.** It runs the legacy image system (Firebase Realtime DB) that is still in active use. Only touch it if the user explicitly requests a controlled migration task.

---

## Canonical business model

- One warehouse (`stockWarehouse`), one store (`stockStore`).
- Sales: kiosko (immediate stock deduction) and delivery (stock deducted on `delivered`).
- Delivery uses mensajero or Forza. Cash pools per source: `pendingCash['store']`, `['mensajero']`, `['forza']`.
- **Delivery workflow lives inside `sales`**, not the separate `orders` collection. `orders_history_screen.dart` reads `sales` — it is the live delivery list. The `orders` collection is legacy/non-canonical unless explicitly revived.
- `sales.stockStatus` tracks delivery stock state. There is no product-level `stockInTransit` field.

---

## Critical invariants — never break these

**Shipments** — completion increments `stockWarehouse`. Must be atomic (batch/transaction).

**Movements** — `sent` decrements origin. `received` increments destination. Cancel must restore.

**Sales** — stock deducted at the right moment only (kiosko: on creation; delivery: on `delivered`). Never deducted twice. Payment method determines downstream cash/finance behavior.

**Pending cash** — `pendingCash[source].amount` increased by the sale total. Deposits reduce it by `cashReceived`, **not** by net deposit amount.

**Deposits** — `amount == cashReceived − expenses`. Linked sales get `depositId`. Atomic (Function).

**Expenses** — only `approved` expenses count in totals. Business-control tracking, not formal accounting.

**Reports** — downstream consumers of correct data. Never patch reports to hide upstream integrity problems.

---

## Coding rules

- Read `docs/MUTATION_RULES.md` before any money/stock write.
- When a change affects money or stock, trace every read/write path before editing.
- Prefer small, surgical edits over wide rewrites.
- If business logic is duplicated, document it before consolidating.
- If docs and code conflict, treat code as current behavior and surface the mismatch explicitly.
- Before proposing an architecture change, check whether the real issue is duplicated logic, legacy/orphan code, or weak integration — not a missing feature.

---

## Style rules

- Spanish UI, English code.
- Follow existing screen patterns and AppTheme conventions — palette, typography, spacing.
- No new styles, fonts, colors, or layout systems without a reason.
