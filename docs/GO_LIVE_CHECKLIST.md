# Go-Live Checklist

Answers ONE question: **what must be true before real money/customer data enters production?**

This is a hard gate, separate from [ROADMAP.md](ROADMAP.md) (what to build) and [TEST_PLAN.md](TEST_PLAN.md) (how to verify). Prod (`xepi-f5c22`) currently holds only test data — none of this is urgent yet, but ALL of it must be checked off before the first real sale.

---

## Data integrity (non-negotiable)
- [ ] `deductStock` Cloud Function live; stock deduction is a transaction; stock can never go negative
- [ ] `approvePayment` Cloud Function live; only `sales.approve` users can approve; updates bank balance atomically
- [ ] `processDeposit` Cloud Function live; validates `amount == cashReceived − expenses`; reduces pendingCash by `cashReceived`
- [ ] No money/stock mutation happens outside an owned flow ([MUTATION_RULES.md](MUTATION_RULES.md))
- [ ] No `?? 'admin'` (or any fake-user) fallback anywhere; `createdBy` is always a real uid

## Security
- [ ] Superuser UIDs removed from source and `firestore.rules`; replaced by `users/{uid}.role` + permissions
- [ ] Permission enforcement in Firestore rules + Cloud Functions (not UI-only) — see [PERMISSIONS.md](PERMISSIONS.md)
- [ ] `products`/`categories` public read scoped to `isActive == true`; no `costPrice`/`stockWarehouse`/`warehouseCode` exposed
- [ ] Firebase Crashlytics enabled (error visibility)

## Environments & data safety
- [ ] Separate staging project exists; schema/migration changes tested there first ([OPERATIONS.md](OPERATIONS.md))
- [ ] Firestore scheduled daily export (backup) enabled
- [ ] Restore from export tested at least once
- [ ] Firebase Storage bucket versioning enabled (product/proof images)

## Workflow correctness
- [ ] All 🔴 items in [KNOWN_ISSUES.md](KNOWN_ISSUES.md) resolved
- [ ] One canonical delivery model; no business rule implemented 3 different ways
- [ ] Soft-delete (void) default; hard delete admin-only and logged
- [ ] Every critical flow in [TEST_PLAN.md](TEST_PLAN.md) passes on staging

## If web checkout is part of go-live (currently deferred)
- [ ] Delivery pricing logic resolved (mensajero variable, Forza +5%) — [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md)
- [ ] Voucher/proof capture + admin verification working for transfer/VisaLink
- [ ] VisaLink per-sale link generation working
