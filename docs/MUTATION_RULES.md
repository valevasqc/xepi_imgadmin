# Mutation Rules

The safety rail. **Read this before changing any code that writes to `products`, `sales`, `pendingCash`, `deposits`, `expenses`, `shipments`, or `movements`.** It defines what writes are allowed and what side effects MUST accompany them. Pair with [STATE_MACHINES.md](STATE_MACHINES.md) (transitions) and [DATA_MODEL.md](DATA_MODEL.md) (fields).

Golden rule: **money and stock only change through the flows below.** Never patch a number directly to "fix" a symptom — find the flow that owns it.

---

## Global rules
- Every write requires an authenticated user. `createdBy` = real `auth.uid`, never a fallback string (`?? 'admin'` is a bug).
- Validate before write: amounts > 0, stock never < 0, totals match item sums.
- Money/stock mutations that span multiple documents must be **atomic** (transaction or batch), and the critical ones go through Cloud Functions (`deductStock`, `approvePayment`, `processDeposit`).
- Every admin mutation (approve, void, balance edit, permission change) writes an **audit** record.

---

## Stock (`products.stockStore`, `products.stockWarehouse`)
Stock changes ONLY via these events, each with its required side effect:

| Event | Allowed change | Required side effect |
|-------|---------------|----------------------|
| Shipment completed | `stockWarehouse += qty` | shipment.status → completed; atomic over all items |
| Movement sent | `origin -= qty` | movement.status → sent |
| Movement received | `destination += qty` | movement.status → received |
| Kiosko sale | `stockStore -= qty` | only after sale approved; never below 0 |
| Delivery sale delivered | `deductFrom -= qty` | sale.stockStatus → completed; only on `delivered` |
| Stock adjustment | `±qty` | requires `reason` code + audit record |

- **Never** deduct the same sale's stock twice (the current double-deduct risk across screens).
- Deduction must be a **transaction**: re-read stock, check ≥ qty, then write. (`deductStock` Function.)
- Reverting a delivery restores stock.

## Cash (`pendingCash[source]`)
| Event | Change | Notes |
|-------|--------|-------|
| Cash sale (kiosko) approved | `pendingCash['store'].amount += total`, push saleId | source = 'store' |
| Cash delivery delivered | `pendingCash[deliveryMethod].amount += total`, push saleId | source = 'mensajero'/'forza' |
| Deposit created | `pendingCash[source].amount -= cashReceived`, drop saleIds | **reduce by cashReceived, NOT net amount** |
| Deposit deleted | restore `pendingCash` by cashReceived | |

## Deposits
- `amount` MUST equal `cashReceived − expenses`. Validate in `processDeposit` Function.
- Linked sales get `depositId` set; expenses get linked via `expenseIds`.
- Atomic: reduce pendingCash + create deposit + link sales in one transaction.

## Sales
- `status` transitions only as in [STATE_MACHINES.md](STATE_MACHINES.md).
- transfer/tarjeta sales start `pending_approval` + `paymentVerified=false` and require a proof image before approval.
- Only a user with `sales.approve` can move to `approved` (server-checked).
- Delete = **soft-delete** (status → void) by default; hard delete is admin-only and must restore stock/cash side effects first. See [OPERATIONS.md](OPERATIONS.md).

## Expenses
- Employee-created → `pending_approval`. Only `expenses.approve` users move to `approved`/`rejected`.
- Only `approved` expenses count in totals.

## Bank accounts
- `currentBalance` changes only via approved transfer/card sales (credit) or deposits (credit). Admin-only.
