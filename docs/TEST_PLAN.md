# Test Plan

**Scope now: manual smoke-test checklist for the critical money/stock flows.** Automated tests are deferred until the code is testable (typed models + repositories + DI — see [ROADMAP.md](ROADMAP.md) P1/P3). Writing automated tests against today's monolithic widgets would mostly test mocks. When models/repositories land, add unit tests per [ARCHITECTURE.md](ARCHITECTURE.md).

Run this checklist after any change touching sales, stock, cash, deposits, or approvals — ideally on **staging** ([OPERATIONS.md](OPERATIONS.md)).

---

## Critical flows (must pass before shipping money/stock changes)

### Kiosko cash sale
- [ ] Create kiosko sale, paymentMethod=efectivo
- [ ] `stockStore` decremented by qty immediately
- [ ] `pendingCash['store'].amount` increased by total, saleId present
- [ ] status = approved

### Delivery cash sale
- [ ] Create delivery sale, efectivo, mensajero
- [ ] Stock NOT yet deducted; stockStatus = in_transit
- [ ] Mark picked_up → delivered
- [ ] On delivered: stock deducted, stockStatus = completed
- [ ] `pendingCash['mensajero']` increased by total

### Transfer sale + approval
- [ ] Create sale, transferencia, attach proof image
- [ ] status = pending_approval, paymentVerified = false, stock NOT deducted
- [ ] Non-admin cannot approve (button hidden AND Firestore write denied)
- [ ] Admin approves → approved, paymentVerified = true, stock deducted, bank balance updated

### Stock race (the known bug)
- [ ] Product with stock = 1
- [ ] Fire two near-simultaneous sales for it
- [ ] Exactly one succeeds; stock never goes negative (requires `deductStock` transaction)

### Deposit
- [ ] Create deposit: cashReceived=1000, expenses=150
- [ ] amount (net) = 850
- [ ] `pendingCash[source]` reduced by 1000 (cashReceived), NOT 850
- [ ] Linked sales get depositId
- [ ] Delete deposit → pendingCash restored by 1000

### Shipment receive
- [ ] Receive shipment with items → on complete, `stockWarehouse += qty` for each
- [ ] Cancel does not change stock

### Movement
- [ ] Create movement warehouse→store, send → warehouse −qty
- [ ] Receive → store +qty
- [ ] Cancel after send restores warehouse stock

### Expense approval
- [ ] Employee submits → pending_approval, not in totals
- [ ] Admin approves → counts in totals; reject → excluded

### Permissions
- [ ] kiosko user: sees POS, cannot see Finanzas/Reportes (UI) AND cannot read deposits (Firestore)
- [ ] warehouse user: can receive shipments, cannot register sales
- [ ] mensajero user: can update delivery status only

### Soft / hard delete
- [ ] Void a sale → record remains with status=void, side effects reversed
- [ ] Admin hard-delete → record gone, stock/cash reversed first
