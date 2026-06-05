# Data Model

Status: reflects current Firestore reality + agreed target. Single source of truth for collections and fields.
Inventory is the base system — everything downstream (cash, sales, reports, client visibility) depends on stock accuracy.

---

## Firestore collections

### `products` (doc ID = barcode)
| Field | Type | Notes |
|-------|------|-------|
| barcode | string | document ID; USB-scanner input or typed |
| name | string | display name |
| warehouseCode | string | internal human code (e.g. "COD-56"); SKU-like, not globally unique |
| categoryCode | string | → links to a Subcategory `code` (e.g. "LAT-2030") |
| primaryCategory, categoryName | string | denormalized category info |
| stockStore | int | stock at the store/kiosko |
| stockWarehouse | int | stock at the warehouse/bodega |
| priceOverride | float? | if set, overrides Subcategory.defaultPrice |
| costPrice | float? | for margin/cost tracking (Phase 2 pricing) |
| images | string[] | first = main image |
| color, width, height, size, notes | — | descriptive |
| temas | string[] | secondary tags/themes (NOT a second category) |
| isActive | bool | client-app visibility |

A product belongs to exactly ONE subcategory (one-to-one via `categoryCode`).

### `categories/{primaryCategory}` → subcollection `subcategories/{code}`
| Field | Type | Notes |
|-------|------|-------|
| code | string | e.g. "LAT-2030"; the family/category code, NOT a per-product SKU |
| name, subcategoryName | string | display |
| defaultPrice | float | inherited by products without priceOverride |
| bulkPricing | map | `{ qty2, qty5Plus }` — tiered "mayoreo" pricing |
| coverImageUrl, displayOrder, isActive | — | |

### `sales` (doc ID = auto)
| Field | Type | Notes |
|-------|------|-------|
| saleType | enum | 'kiosko' \| 'delivery' |
| status | enum | 'pending_approval' \| 'approved' |
| stockStatus | enum | 'completed' \| 'in_transit' |
| deliveryStatus | enum? | 'pending' \| 'picked_up' \| 'delivered' \| 'cash_received' (delivery only) |
| paymentMethod | enum | 'efectivo' \| 'transferencia' \| 'tarjeta' |
| paymentVerified | bool | transfers/cards start false until admin approves |
| deliveryMethod | enum? | 'mensajero' \| 'forza' (delivery only) |
| items | array | `{ barcode, name, qty, price, deductFrom }` |
| total, discount | number | discount is global per-sale, not per-item |
| destinationAccount | ref? | → bankAccounts (transfer/card) |
| depositId | ref? | → deposits (set after cash deposited) |
| paymentProof | string? | voucher/screenshot URL — required for transfer & VisaLink (see [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md)). May be missing in current code; add. |
| createdBy, approvedBy | ref | → users |

See [STATE_MACHINES.md](STATE_MACHINES.md) for the sale lifecycle and when stock/cash side effects fire.

### `orders` (doc ID = auto) — LEGACY / non-canonical
Separate COD pre-sale model. `order_detail_screen.dart` reads this and `_convertToSale()` turns it into a `sales` doc. **Currently legacy** — the live model is delivery-as-a-sale (see below). Do NOT build on or delete until the web-checkout decision is made. See [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md) §4.

> Naming trap: `orders_history_screen.dart` actually reads the **`sales`** collection — it is the live *delivery list* ("Envíos"), not the `orders` collection.

### `shipments` (inbound from supplier)
| Field | Notes |
|-------|-------|
| status | 'in-progress' \| 'completed' \| 'cancelled' |
| items | `{ barcode, productName, quantity, categoryCode }` |
| receivedBy, receivedByName | → user |
| supplierId | **MISSING — to add** (track which supplier) |

Completing a shipment **increments `stockWarehouse`** for each item.

### `movements` (internal warehouse ↔ store transfer)
| Field | Notes |
|-------|-------|
| status | 'pending' \| 'sent' \| 'received' \| 'cancelled' |
| origin, destination | 'warehouse' \| 'store' |
| items | `{ barcode, qty }` |

Two-phase: **sent** decrements origin stock; **received** increments destination stock.

### `expenses`
| Field | Notes |
|-------|-------|
| status | 'pending_approval' \| 'approved' \| 'rejected' |
| category | → expense_categories |
| type | 'operativo' \| 'no_operativo' |
| amount, description, paymentSource | |
| createdBy, approvedBy | → users |

### `expense_categories`
`{ name, type: 'operativo' | 'no_operativo' }`. Admin-managed.

### `deposits`
| Field | Notes |
|-------|-------|
| source | 'store' \| 'mensajero' \| 'forza' |
| cashReceived | original physical cash |
| expenses | total paid from that cash before depositing |
| amount | **net = cashReceived − expenses** |
| saleIds, expenseIds | linked records |
| destinationAccount | → bankAccounts |
| comprobanteUrl | proof image |
| depositedBy | → user |

**Invariant**: a deposit reduces `pendingCash` by **cashReceived**, not by net `amount`.

### `pendingCash` (doc per source)
`{ source: 'store'|'mensajero'|'forza', amount, saleIds[] }`. Cash collected but not yet deposited. Each source pools and deposits independently.

### `bankAccounts`
`{ bankName, accountName, accountType, currency: 'QTZ'|'USD', currentBalance, isActive, last4Digits }`. Admin-only.

### `users` (doc ID = Firebase UID) — target shape
`{ name, email, role: 'admin'|'kiosko'|'warehouse'|'mensajero'|'custom', permissions: map, isActive, createdAt }`. See [PERMISSIONS.md](PERMISSIONS.md). Currently roles are NOT in Firestore — admin is hardcoded UIDs (to migrate).

### `notifications`
Exists in security rules but purpose undefined. Decide use (low-stock alerts / approvals / client orders) or remove.

### `locations`
`{ type: 'warehouse'|'store', name, stockField: 'stockWarehouse'|'stockStore', displayOrder, isActive }`.

---

## Missing entities (to add)
- **Supplier** — `{ name, contact, leadTimeDays }`, linked from Shipment; basis for cost tracking.
- **Stock adjustment** — manual stock correction with reason code (breakage/theft/miscount) + audit. P1.
- **Audit log** — `{ userId, action, entityType, entityId, timestamp }`. Written by Cloud Functions.

## Open questions (decide before implementation spreads)
- **Does `tarjeta` always require admin approval?** Currently card sales go to `pending_approval` like transfers. POS card payments are terminal-verified — maybe they shouldn't need manual approval. Owner decision.
- **How is the delivery fee represented today vs. future checkout?** No explicit `deliveryPrice`/`deliveryProvider`/`deliveryPaymentTiming` fields yet — see [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md) §5.
- **`paymentProof`** — confirm it's captured for transfer/VisaLink sales (likely missing).
- **`notifications`** — real purpose, or remove?

## Stock side-effect summary
| Event | stockWarehouse | stockStore |
|-------|---------------|-----------|
| Shipment completed | +qty | — |
| Movement sent (from warehouse) | −qty | — |
| Movement received (to store) | — | +qty |
| Kiosko sale | — | −qty |
| Delivery sale (on delivered) | −qty (or store, per `deductFrom`) | — |
