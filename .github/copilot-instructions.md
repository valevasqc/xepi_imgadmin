# XEPI Admin Copilot Instructions

Use this file for the admin/internal project.
For full context, read `XEPI_MASTER_DOCUMENTATION.md`.

## What this project is
XEPI Admin is the internal business-control system for XEPI.
It manages products, categories, inventory, shipments, transfers, sales, delivery flow, pending cash, deposits, expenses, and reports.

## Protected rule
- The legacy admin dashboard must never be deleted.
- Do not remove or replace legacy dashboard code unless the user explicitly requests a controlled migration.

## Priority order
1. products and categories
2. inventory integrity
3. shipments
4. transfers
5. sales and delivery flow
6. pending cash and deposits
7. expenses and bank linkage
8. reports

## Canonical model
- Treat delivery as a sales-based workflow in `sales`.
- Treat the separate `orders` path as legacy or non-canonical.
- Inventory source of truth is `products.stockWarehouse` and `products.stockStore`.
- In-transit delivery state belongs to `sales.stockStatus`.

## Non-negotiable rules
- stock must not go negative
- shipments increase warehouse stock
- transfer send deducts origin and receive adds destination
- deposits must reconcile pending cash by `cashReceived`, not net deposit amount
- sales, deposits, and pending cash links must remain consistent
- reports are downstream and must not hide broken operational logic

## Style rules
- Spanish UI, English code.
- Keep the XEPI palette, typography, spacing, and visual style consistent.
- Use existing theme patterns instead of inventing new styles.

## Working style
- Prefer improving current code over rewriting from zero.
- Trace all stock and money mutation points before changing business logic.
- If logic is duplicated across screens, identify all copies before refactoring.
- If code and docs conflict, surface the mismatch explicitly.
