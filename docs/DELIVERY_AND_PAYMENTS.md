# Delivery & Payment Rules

Status: current business reality, captured June 2026. Source: owner (Valeria).
This is the non-obvious business logic behind delivery pricing and payment. It explains why fully-automated website checkout is not trivial and must be designed deliberately.

---

## 1. Delivery providers

| Provider | Who | Delivery price | Notes |
|----------|-----|----------------|-------|
| **Mensajero** | Sergio (internal courier) | **Q25–Q35, varies by location** | Price requires human judgment based on the destination. This is the main reason web checkout can't fully auto-calculate delivery today. |
| **Forza** | Third-party logistics | **Q35 flat** | Adds a **5% surcharge if the customer pays at delivery** (Forza charges this). |

---

## 2. Payment options per provider

### Mensajero (Sergio)
- **Option A — pay full in cash at delivery**: customer pays product + delivery in cash on arrival. No surcharge.
- **Option B — transfer product amount beforehand**: customer transfers the product total in advance, then pays the delivery price in cash at delivery.

### Forza
- **Option A — pay at delivery**: customer pays at delivery, but Forza adds **+5%**.
- **Option B — transfer product amount beforehand**: customer transfers the product total in advance, then pays the **Q35 delivery in cash** at delivery. (Preferred.)
- **Option C — transfer everything including delivery**: possible, but **not the preferred option**.

---

## 3. Payment methods (current + planned)

| Method | Status | Proof required? | Notes |
|--------|--------|-----------------|-------|
| Cash (efectivo) | Live | No | Pools into `pendingCash[source]`; deposited later. |
| Transfer (transferencia) | Live | **Yes — screenshot/voucher** | Goes to a bank account. Requires admin verification (this is why `pending_approval` exists). |
| Card at POS (tarjeta) | Live | — | In-store card. |
| **VisaLink** | **Planned** | **Yes — voucher** | A payment link generated **per sale with the exact amount**; customer pays by card via the link. Requires per-sale link generation. |

**Proof-of-payment requirement**: transfers and VisaLink payments require a **screenshot/voucher image attached to the sale**. The admin verifies the proof before the sale is approved. Any future web-checkout flow must capture and store this image.

---

## 4. Why website checkout is not trivial (open design area)

The owner wants customers to **buy directly through the website** eventually. Blockers to design around:

1. **Variable mensajero pricing (Q25–35 by location)** — can't be a fixed number; needs either a zone/price table or a "we'll confirm delivery price" step.
2. **Forza 5% pay-at-delivery surcharge** — must be conditionally added based on the customer's payment choice.
3. **VisaLink per-sale link generation** — needs to generate a correct-amount link at checkout time.
4. **Voucher capture** — transfer/VisaLink need the customer to upload proof.
5. **Cultural**: many Guatemalan customers prefer talking to a person over self-checkout. The current model (catalog → WhatsApp handoff → employee logs the sale) reflects this.

### Current model (live)
Client app = **catalog**. Customer selects products → an auto-generated WhatsApp message (via WhatsApp API) is sent with the selected products → human coordinates delivery + payment → **employee logs the sale** in the admin system.

### Future model (wanted, not yet designed)
Allow direct purchase on the site. **This needs a dedicated design session** — see open questions above. Until then, the separate `orders` collection / `order_detail_screen.dart` stays legacy (do not build on it, do not delete it).

---

## 5. Implications for the data model

When web checkout is designed, a Sale (or Order) will need to capture:
- `deliveryProvider`: 'mensajero' | 'forza'
- `deliveryPrice`: number (variable for mensajero)
- `deliveryPaymentTiming`: 'at_delivery' | 'transfer_advance' | 'transfer_all'
- `forzaSurcharge`: number (5% when Forza + pay-at-delivery)
- `paymentProof`: image URL (required for transfer / VisaLink)
- `visaLinkUrl`: string (when VisaLink is used)

These do not all exist today. Treat this section as the spec for that future work.
