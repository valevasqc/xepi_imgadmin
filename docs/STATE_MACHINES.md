# State Machines

The complex flows, documented so future changes don't introduce regressions. Pair with [DATA_MODEL.md](DATA_MODEL.md).

---

## Sale lifecycle

```
CREATED
├─ efectivo + kiosko
│     → status=approved, stockStatus=completed
│     → stock deducted immediately from stockStore
│     → cash added to pendingCash['store']
│
├─ efectivo + delivery
│     → status=approved, stockStatus=in_transit  (stock NOT yet deducted)
│     → deliveryStatus: pending → picked_up → delivered
│           on "delivered": deduct stock, stockStatus=completed,
│                           add cash to pendingCash[deliveryMethod]
│     → [optional] cash_received
│
└─ transferencia / tarjeta (any saleType)
      → status=pending_approval, paymentVerified=false
      → requires proof image (transfer/VisaLink voucher) — see DELIVERY_AND_PAYMENTS.md
      → [ADMIN approves] → status=approved, paymentVerified=true, approvedAt set
            ├─ kiosko: deduct stock now
            └─ delivery: in_transit → same delivery flow as above
```

Key rules:
- Cash side effects always route to `pendingCash[source]` where source = 'store' (kiosko) or the deliveryMethod ('mensajero'/'forza').
- Stock for delivery is deducted on **delivered**, not on creation.
- Reverting a delivered delivery restores stock and removes the cash from pendingCash.

---

## Order lifecycle (legacy `orders` collection — non-canonical)

```
pending → preparing → ready → shipped → delivered → [_convertToSale] → completed
                                          ↓ cancel
                                       cancelled
```

`_convertToSale()` creates a `sales` doc (`saleType=delivery`, `deliveryStatus=delivered`, COD/efectivo) and deducts stock. **Currently legacy** — only revisit if/when web checkout is designed (see [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md) §4).

---

## Movement lifecycle

```
pending  (no stock moved)
  → sent       → origin stock −qty
      → received   → destination stock +qty
  ↓ cancel              ↓ cancel (must restore origin)
cancelled            cancelled
```

---

## Shipment lifecycle

```
in-progress (draft, scanning items)
  → completed   → each item: stockWarehouse +qty (atomic batch)
  ↓ cancel
cancelled
```

---

## Expense lifecycle

```
Employee submits → pending_approval
Admin adds directly → approved
pending_approval → [admin] → approved | rejected
```

Only `approved` expenses count in financial totals.
