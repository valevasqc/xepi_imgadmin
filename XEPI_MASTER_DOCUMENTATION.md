# XEPI Master Documentation

Version 1.0  
Date: April 8, 2026  
Status: Master source-of-truth document

> **Note (June 2026):** This document is the **business/product overview** — the "why." For **implementation truth** (data model, mutation rules, permissions, architecture, roadmap, decisions), the current authoritative source is the `docs/` folder, indexed from `AGENTS.md` and `CLAUDE.md`. Where this April overview and the June `docs/` differ on *how the system is built*, the June docs win.

---

## 1. Purpose of this document

This document replaces the older project documentation and should be treated as the main source of truth for understanding the XEPI software project.

It is written so that someone with no prior knowledge of XEPI should be able to read it and understand:

- what the business does
- how the business currently operates
- what problems the software is meant to solve
- what the admin system and client app are supposed to do
- what is in scope for the MVP and what is not
- what the current implementation status is
- what the known gaps, risks, and ambiguities are

This document is intentionally broader than technical notes. It combines business context, product vision, operational workflows, system boundaries, and implementation reality.

When older documents conflict with this one, this document should be treated as the canonical reference.

---

## 2. Executive summary

XEPI is a Guatemalan retail business that sells decorative products and gift-type items, including cuadros de latón, decorative accessories, toys, miniature houses, music boxes, puzzles, and airplanes. The business operates with one warehouse and one physical store location and also sells through delivery channels.

The main software goal is to give XEPI one internal system that controls products, inventory, sales, deliveries, cash, deposits, expenses, and reports. The software is not being built as a full ERP or a full accounting platform. It is meant to be a practical business-control system that helps the owner and staff know:

- what stock exists
- where stock is located
- what has been received
- what has been transferred
- what has been sold
- what cash is still pending deposit
- what has been deposited and to which bank account
- what expenses were made
- what the business is earning and spending

There are two related but separate software projects:

1. **XEPI Admin**: the internal operations system used by staff and management.
2. **XEPI Client App / Catalog**: the public-facing browsing and shopping experience that lets customers view products, build a cart, and send an order to WhatsApp.

The admin project is the foundation. Without reliable admin-side product and stock control, the client app cannot correctly decide which products should be visible to customers.

For planning purposes, the most important idea is this:

**Inventory is the base system.** Shipments, stock transfers, and sales must update inventory correctly. Once sales exist, cash tracking and deposit proof become necessary. Once those exist, reports become meaningful. That dependency order is central to the entire project.

---

## 3. Business overview

### 3.1 What XEPI does

XEPI is a retail business in Guatemala focused mainly on decorative products and gift-oriented merchandise. Its catalog includes both high-volume products and more varied product families.

Known product groups include:

- cuadros de latón
- decorative accessories
- educational toys
- miniature houses
- music boxes
- puzzles
- airplanes

A large portion of the catalog appears to be image-based decorative products with many variations, especially in cuadros de latón. Other categories have more varied item attributes such as color, size, or individual pricing.

### 3.2 Business operating model

XEPI currently operates around:

- **one warehouse** as the main receiving and storage location
- **one physical store / kiosko** where in-person sales happen
- **delivery sales**, fulfilled either by an internal messenger or a third-party delivery method such as Forza

### 3.3 Sales channels

The business currently sells through three practical channels:

1. **Kiosko / in-store sales**
2. **Delivery sales handled internally or operationally by staff**
3. **Customer inquiries and orders initiated through WhatsApp and social channels**

The long-term public shopping flow is not a traditional full e-commerce checkout. The intended client experience is lightweight: customers browse products, build a cart, and hand off the order through WhatsApp.

### 3.4 Key people and roles in the business

The following roles are relevant to the system design:

- **Michelle / Mom / Superuser**: business owner and primary financial authority
- **Marta**: main employee, involved in day-to-day operations and sales
- **Clarita**: warehouse-oriented operations
- **Sergio**: messenger / delivery role
- **Temporary kiosko employee**: limited store-sale role during busy periods
- **Valeria**: project owner / developer / technical lead

These business roles matter because the system is eventually expected to support different permissions and responsibilities, even though dynamic role management is not yet the MVP priority.

---

## 4. Current business process before full system adoption

Before the new system is fully reliable, XEPI has depended on a mix of manual and fragmented workflows.

### 4.1 Inventory tracking

Inventory has historically been tracked with Excel, including manual counting and formula-based workflows such as COUNTIF. This is slow, fragile, and difficult to audit.

### 4.2 Order handling

Orders and customer requests have often been handled through WhatsApp conversations. That makes it easy for information to get lost, repeated, or handled inconsistently.

### 4.3 Cash tracking

Cash from sales, deliveries, and other sources has not always been tied to a strong reconciliation flow. This creates risk around missing money, unclear responsibility, and weak visibility into what has or has not been deposited.

### 4.4 Reporting and decisions

Without a unified system, the business has limited visibility into:

- best sellers
- slow movers
- category performance
- real expenses
- pending cash
- bank-linked income and expenses
- profit and loss

In other words, the business has had data in fragments, but not a reliable operating picture.

---

## 5. Business problems the software must solve

The software exists to solve practical operating problems, not just to digitize information.

### 5.1 Inventory accuracy

The business needs to know, at any moment:

- how much stock exists for each product
- how much is in the warehouse
- how much is in the store
- what inventory is moving between locations
- what stock has been committed to delivery workflow

### 5.2 Operational control

The system must make it easy to perform normal operations while keeping clear records:

- receiving merchandise
- transferring stock
- creating sales
- tracking delivery progress
- tracking cash collected by different sources
- recording deposits with proof
- recording expenses

### 5.3 Financial visibility

The owner does not need a formal accounting platform with legal rigor, but does need a reliable business-control layer that shows:

- income
- expenses
- pending cash
- deposits
- bank-linked flows
- basic profitability and reporting

### 5.4 Business intelligence

The system should help the business answer questions like:

- what products sell most
- what categories move slowly
- what should be restocked
- what stock is dead
- what channels are producing revenue
- how much money is still pending deposit

---

## 6. Product vision

The target system is a practical internal operating system for XEPI.

It should allow a small team to run the business from one consistent source of truth instead of using a mix of spreadsheets, chat threads, and memory.

The intended result is not a highly abstract software platform. It is a working day-to-day business tool that improves control, speed, and trust in the data.

### 6.1 What success looks like

The system is successful when:

- inventory numbers are trusted
- receiving and transfers update stock correctly
- sales do not quietly break stock integrity
- cash from store, messenger, and delivery company is visible until deposited
- deposits are backed by proof
- expenses are recorded and attributable
- reports are useful enough for real business decisions
- the client app can safely rely on admin-side product and stock information

### 6.2 What the system is not

The system is **not** intended, at least in the MVP, to be:

- a full accounting platform
- a legal invoicing / FEL platform
- a multi-branch ERP
- a complex CRM
- a full e-commerce checkout and payment platform
- an advanced analytics suite

---

## 7. Two-project structure

The XEPI software vision is split into two connected but separate projects.

### 7.1 Project A: XEPI Admin

This is the internal system used by staff and management.

It is the operational backbone of the business and is the higher priority project.

Its responsibilities include:

- product and category management
- inventory tracking
- shipment receipt
- stock transfers
- sale registration
- delivery workflow control
- pending cash tracking
- deposit recording
- expense tracking
- bank account linkage
- business reports
- later: user roles and permissions

### 7.2 Project B: XEPI Client App / Product Catalog

This is the customer-facing browsing and shopping experience.

Its intended responsibilities include:

- displaying active products
- browsing by category and subcategory
- product detail pages
- search and filters
- persistent local cart
- WhatsApp handoff for checkout or order submission

This app is intentionally lightweight. It is not the system of record for inventory, orders, or finance.

### 7.3 Relationship between the two projects

The client app depends on the admin project for reliable product visibility and stock logic.

That means:

- the admin project owns product activation and inventory truth
- the client app should read from that source of truth
- if admin stock is unreliable, client visibility will be wrong
- if client visibility rules are unclear, customers may see unavailable products

For this reason, the admin project is the foundation, even though the client app is already partly built.

### 7.4 Current technology context

The current project context is:

- admin built as a Flutter web application
- client catalog built as a separate Flutter web application
- Firebase used for authentication, database, storage, and hosting
- Firestore used as the core operational data store
- Spanish UI with English code conventions
- physical USB barcode scanners treated as an important operational input device
- Guatemalan quetzales used as the main business currency

The technology stack matters because the system is optimized for a small internal business team, not for large-scale enterprise traffic or a full custom backend.

---

## 8. Business scope and non-goals

### 8.1 In-scope for the MVP

The MVP should cover the business-critical workflows required to operate reliably.

These include:

1. product and category control
2. inventory as a trusted base
3. shipment receipt into warehouse stock
4. stock transfers between warehouse and store
5. sale registration for kiosko and delivery
6. payment-state handling and approval where needed
7. pending cash tracking
8. deposit recording with proof
9. expense tracking
10. useful basic reporting
11. client-side visibility driven by trustworthy admin data

### 8.2 Explicitly lower priority or post-MVP

The following are useful, but not required for the first reliable business version:

- advanced or highly dynamic analytics
- export-heavy reporting features
- sophisticated notifications
- formalized multi-user RBAC system
- public checkout with integrated payment processing
- deep accounting functionality
- legal invoicing features

### 8.3 Scope guardrails

To prevent the project from becoming vague or too large, the following principles should hold:

- operational correctness is more important than polish
- core stock and cash integrity matter more than extra dashboards
- reports only matter if the underlying data is trustworthy
- user management should come after core workflows work for the superuser flow
- the client app should stay simple unless the admin side is dependable

---

## 9. Core system concepts

This section defines the main concepts the project revolves around.

### 9.1 Product

A product is an individual sellable item identified by barcode. A product belongs to a category/subcategory structure, can have images, can have price logic, and has stock values in business locations.

### 9.2 Category and subcategory

Categories organize the catalog, define display structure, and may also define default pricing and bulk pricing behavior.

### 9.3 Locations

The system currently plans around two physical inventory locations:

- warehouse
- store / kiosko

### 9.4 Inventory stock

The essential stock model is location-based stock, especially:

- warehouse stock
- store stock

These are the main business stock values that must remain correct.

### 9.5 Shipment / receipt

A shipment or receipt is an inbound inventory event. It represents merchandise being received and added into warehouse stock.

### 9.6 Movement / transfer

A movement is an internal inventory transfer between locations, mainly warehouse to store and potentially vice versa.

### 9.7 Sale

A sale is the core outbound business event. It can be an in-store sale or a delivery sale. Sales affect stock and may also affect pending cash, deposits, and reports.

### 9.8 Delivery sale

A delivery sale is a sale that includes customer delivery details and a delivery lifecycle. In the current implementation, delivery workflow is modeled canonically through the **sales** system, not through a separate actively used orders system.

### 9.9 Pending cash

Pending cash represents collected cash that has not yet been fully reconciled through a deposit. It is tracked by source, such as:

- store
- messenger
- Forza

### 9.10 Deposit

A deposit is the business record that certain cash has been taken from pending state and deposited into a bank account, with proof and linked sale context.

### 9.11 Expense

An expense is money spent by the business. The system needs to record amount, category, source, and timing. It is not intended to become full bookkeeping, but it should be reliable enough for business control.

### 9.12 Bank account

A bank account is a destination or source used for transfers, deposits, or expense tracking. Bank accounts matter for reconciliation and reporting.

### 9.13 Report

A report is not raw data dump. It is a business-facing summary meant to help answer operational or financial questions.

---

## 10. Canonical business processes

This section explains the intended day-to-day workflows.

### 10.1 Product and catalog management

The business needs a maintained product catalog where staff can:

- create products
- edit products
- assign categories and subcategories
- upload and manage images
- set or inherit pricing
- activate or deactivate visibility
- maintain internal identifiers such as warehouse code

This workflow is foundational because every later workflow depends on a clean catalog.

### 10.2 Shipment receipt

When merchandise arrives:

1. staff records the incoming products
2. quantities are confirmed, often with barcode scanning
3. the system adds that quantity to warehouse stock
4. a shipment record is saved for traceability

This workflow replaces unreliable spreadsheet-based receiving.

### 10.3 Stock transfers between warehouse and store

When the store needs merchandise from the warehouse:

1. a transfer is created
2. stock leaves the origin location
3. stock is later received at the destination location
4. the movement is recorded for traceability

This workflow exists so that the system can distinguish between stock sitting in the warehouse and stock available in the store.

### 10.4 Kiosko sale workflow

For an in-store sale:

1. staff adds products to a cart or sale record
2. the system checks stock
3. the payment method is recorded
4. stock is deducted from the chosen location, usually store stock
5. cash and financial side effects are recorded according to payment type

### 10.5 Delivery sale workflow

For a delivery sale:

1. staff records products and customer information
2. a delivery method is selected
3. the payment method is recorded
4. the system tracks the delivery lifecycle
5. stock is deducted at the correct stage according to the delivery logic
6. cash is tracked if the sale is paid in cash

### Canonical planning decision

For documentation and planning, the current live delivery model should be treated as **delivery sales inside the sales domain**, not a separate standalone orders domain.

That means:

- the delivery workflow is conceptually part of sales
- the historical separate `orders` path is not the live model to plan around
- unless a deliberate redesign is chosen later, the planning baseline should treat delivery as a kind of sale

### 10.6 Payment handling

The system must support at least:

- efectivo
- transferencia
- tarjeta

Different payment methods create different business requirements:

- cash must eventually be deposited and reconciled
- transfer and card payments may require verification or approval
- bank account linkage matters for finance visibility

### 10.7 Pending cash and deposit workflow

When cash is collected:

1. the system records it as pending cash under the relevant source
2. that cash remains visible until a deposit is recorded
3. a deposit record captures proof, destination account, and linkage to sales
4. pending cash is reduced accordingly

This is one of the most important business-control workflows because it is how the business avoids losing track of physical money.

### 10.8 Expense workflow

The business needs to record expenses with at least:

- amount
- category
- type or business meaning
- payment source
- optional proof
- approval state where relevant

Expenses do not need full accounting rigor, but they do need consistent classification and inclusion in reports.

### 10.9 Reporting workflow

Reports exist so the business can use the data operationally. They should answer questions about:

- sales performance
- product performance
- expenses
- pending cash
- deposit activity
- simple profitability and revenue-versus-expense views

Reports are valuable only after the underlying stock, sales, and finance workflows are trustworthy.

### 10.10 Client shopping flow

The public client app should allow customers to:

1. browse active product categories
2. open subcategories and products
3. view product images and pricing
4. build a persistent cart locally
5. send the cart to WhatsApp as an order request or checkout handoff

The client app should remain lightweight. It is not the core admin/control system.

---

## 11. Admin-side requirements

The admin project is the system of record for XEPI operations.

### 11.1 Core admin modules

A complete MVP-capable admin system needs these modules:

- dashboard / operational overview
- products
- categories
- shipment receipt
- stock movements
- sales registration
- delivery tracking
- deposits
- expenses
- bank accounts
- reports
- settings / user framework

### 11.2 Admin-side business responsibilities

The admin system must be able to answer:

- what can be sold
- what is active/inactive
- where stock is located
- what stock changes happened and why
- who collected money
- what money is still pending deposit
- what bank account a payment or deposit belongs to
- how much the business sold, spent, and still needs to reconcile

### 11.3 Priority order inside the admin project

The dependency order for this system is:

1. **catalog and stock foundations**
2. **shipment receipt and stock transfers**
3. **sales and delivery flows**
4. **pending cash and deposit control**
5. **expense tracking**
6. **reports built on trustworthy data**
7. **user permissions and advanced features**

This priority order reflects business dependency, not just code organization.

---

## 12. Client-side requirements

The client app is a separate project and should be understood as a public product-browsing layer.

### 12.1 Core client capabilities

The client app should support:

- product browsing
- category and subcategory navigation
- product details
- product images
- search and filters
- local cart persistence
- WhatsApp handoff
- direct product links or URLs

### 12.2 What the client app should not own

The client app should not become the source of truth for:

- inventory mutations
- sales ledger logic
- deposits
- expenses
- bank reconciliation
- internal approvals

### 12.3 Dependency on admin-side truth

The client experience depends on reliable admin-side data for:

- product activeness
- category/subcategory visibility
- stock-based visibility rules
- pricing consistency
- image quality and product completeness

### 12.4 Desired visibility rule

From a business perspective, the client app should not show products that are unavailable for sale. That means the long-term desired visibility logic should reflect both activation state and actual sellable availability.

However, this is an area where the desired business rule and current implementation do not yet fully match.

---

## 13. MVP definition

The MVP is not "everything the system could eventually do." It is the smallest version that the business can trust to run core operations.

### 13.1 MVP must-have capabilities

The MVP should reliably support:

- product and category management
- warehouse and store stock tracking
- shipment receipt
- stock transfers
- kiosko sales
- delivery sales
- payment-state handling
- pending cash tracking
- deposit proof and reconciliation
- expense recording
- basic operational and financial reports

### 13.2 MVP success criteria

The MVP can be considered successful when:

- stock numbers are trusted enough for operations
- staff can receive and transfer stock without spreadsheet fallback
- sales consistently update inventory and finance records correctly
- cash does not disappear into unclear status
- deposits can be proven and traced
- expenses are visible in reports
- reports are useful for decision-making
- client-side product visibility can depend on admin data without obvious contradictions

### 13.3 Explicitly non-essential for MVP

These items are helpful but not blocking:

- advanced analytics
- highly dynamic reporting
- export-heavy reporting features
- sophisticated user management
- notification systems
- deep accounting features

---

## 14. Planning assumptions that should guide future work

This section describes the assumptions that should be used when planning the ideal system.

### 14.1 Plan from scratch, compare against reality later

The planning approach should assume no existing code and define the ideal system cleanly. After that, the current implementation can be compared against the ideal and adjusted accordingly.

### 14.2 The current codebase should not automatically be treated as the design

Existing implementation choices are useful reference points, but they are not necessarily the correct architecture. Documentation and planning should define the desired system first.

### 14.3 Inventory integrity is the first dependency

If inventory logic is wrong, then transfers, sales, client visibility, and reports all become untrustworthy.

### 14.4 Financial tracking is business-control, not formal accounting

The project should track income, expenses, deposits, and bank-linked flows well enough for business control and reconciliation, without turning into a full accounting product.

### 14.5 Reports come after data integrity

Reports should be treated as outputs of correct workflows, not as a substitute for fixing workflow logic.

---

## 15. Current implementation status

This section summarizes the current state of the project based on the latest available project documents, your clarifications, and the code-state review.

### 15.1 Overall status

The project is **not starting from zero**.

A substantial part of the admin system already exists. However, the project should not yet be treated as fully production-ready because the main remaining problems are around integration quality, duplicated logic, unresolved legacy concepts, approval flows, and debugging confidence.

Older project documents described progress with conflicting completion percentages, so this document avoids treating those percentages as authoritative. Instead, it describes the project in qualitative terms: what is operational, what is partial, and what is still risky.

The client app is also partly built and functional as a browsing/cart/WhatsApp experience, but it still depends on better integration with admin-side truth.

### 15.2 Current status by area

| Area | Status | Notes |
|---|---|---|
| Products | Largely implemented | Core CRUD and catalog behavior exist |
| Categories | Largely implemented | Nested structure and pricing logic exist |
| Shipment receipt | Largely implemented | Core receiving flow exists |
| Stock transfers | Largely implemented | Core movement flow exists |
| Sales registration | Largely implemented | Kiosko and delivery sales exist |
| Delivery workflow | Functional but conceptually messy | Live model is sales-based, but legacy orders concepts remain |
| Deposits | Implemented but needs hardening | Important workflow exists, but reconciliation behavior needs confidence |
| Expenses | Partially complete | Expense recording exists; approval flow is incomplete/inconsistent |
| Reports | Basic reports exist | Advanced reports are not essential for MVP |
| Bank accounts | Implemented at basic business-control level | Supports linking and reporting use cases |
| User management | Not true MVP-complete | Current permission model is not final RBAC |
| Client integration | Partial | Public catalog/cart exists, but stock-aware visibility is not fully aligned |

### 15.3 Practical interpretation of current status

The current state should be described as:

- **strong partial implementation**
- **not a blank slate**
- **not yet cleanly unified**
- **needs a proper architectural and workflow plan to finish safely**

That means the main challenge is less about inventing features and more about making the whole system coherent and dependable.

---

## 16. Canonical implementation decisions to use as current truth

These are important because earlier documents and parts of the codebase do not all describe the same model.

### 16.1 Canonical delivery model

The live delivery workflow should currently be treated as a **sales-based workflow**.

In practice, delivery behavior is operating through the sales domain. The historical or separate `orders` concept exists in older documentation and some legacy code paths, but it is not the canonical live model to use as the baseline.

### 16.2 Separate orders model is not current source of truth

The separate orders collection/path should be treated as legacy or non-canonical unless a future redesign deliberately revives it.

### 16.3 In-transit stock is not a mature standalone product-stock model

Conceptually, the system may speak about stock in transit, but the live current model tracks delivery stock state through sale-level status rather than through a clean product-level in-transit inventory field.

### 16.4 Pending cash is a critical concept

Pending cash should represent cash that has been collected but not yet fully reconciled by deposit.

### 16.5 Client visibility rules are still incomplete

The business expectation is that customers should not see unavailable products, but the current implementation logic is not yet fully aligned with that goal.

---

## 17. Known gaps, contradictions, and risks

This is one of the most important sections in the document because it explains why planning work is still necessary even though a lot already exists.

### 17.1 Delivery workflow duplication

The system currently has evidence of duplicated or fragmented delivery logic across multiple places. This increases the risk that stock, status, or cash side effects behave differently depending on which path is used.

### 17.2 Legacy order model versus live sales model

Older docs and some code paths still imply a separate order-to-sale lifecycle, while the live operational model is delivery sales inside the sales system. This can confuse planning, debugging, and future development unless one model is chosen and documented clearly.

### 17.3 Deposit reconciliation confidence

Deposit behavior is central to the business, so even small inconsistencies in how pending cash is reduced or restored matter a lot. This area requires special care because it affects real money and trust in the system.

### 17.4 Expense approval inconsistency

Expense recording exists, but the approval model is not fully unified. This means the business rule for which expenses require approval is not yet expressed as one clean, enforced workflow.

### 17.5 Client visibility mismatch

The desired business rule is that customers should not see products that are not truly available. The current client-side visibility logic is not yet strong enough to guarantee that.

### 17.6 User roles are not yet a mature authorization model

Current role handling is sufficient for early stages but is not the final permissions architecture. This is acceptable for MVP planning, but it should be treated honestly as temporary.

### 17.7 Debugging uncertainty

One of the real project risks is not only known bugs, but unknown gaps: places where logic may be incomplete, duplicated, or poorly integrated even if no issue has been reported yet.

---

## 18. Current needs of the business and project

The project currently needs more than code changes. It needs a clearer shared understanding.

### 18.1 Business needs

The business needs:

- trustworthy inventory
- trustworthy sales recording
- trustworthy cash and deposit tracking
- basic but useful reports
- a safe basis for the client app

### 18.2 Product/project needs

The project needs:

- a clean description of the ideal system
- a canonical workflow model
- a clear distinction between MVP and later features
- identification of current implementation against the ideal
- confidence about where the risky gaps are

### 18.3 Technical needs

The codebase needs:

- consolidation of duplicated business logic
- retirement or clear labeling of non-canonical legacy paths
- approval-flow cleanup
- better end-to-end validation
- structured debugging around inventory and money integrity

---

## 19. Release readiness definition

A reasonable production-readiness definition for XEPI should focus on trust, not feature count.

The system is ready to run the business only when the following are true:

### 19.1 Inventory integrity

- shipments update warehouse stock correctly
- transfers update origin and destination stock correctly
- sales deduct stock at the correct moment
- delivery workflow does not create duplicate or missing stock movements
- client visibility can rely on stock state

### 19.2 Money integrity

- cash sales create correct pending cash records
- deposits reduce pending cash correctly
- deposit proof is stored and attributable
- expenses are recorded consistently
- bank-linked flows are understandable

### 19.3 Workflow integrity

- there is one canonical delivery model
- critical business rules are not implemented three different ways
- staff can complete core workflows without fallback to spreadsheets or chat memory

### 19.4 Reporting usefulness

- reports are based on correct data
- the owner can understand revenue, expenses, pending cash, and product performance
- reports are useful enough to guide decisions, even if they are not advanced

---

## 20. Suggested roadmap after MVP

Once the core business-control MVP is stable, the likely next priorities are:

1. user and role management
2. client-app integration hardening
3. export functions where useful
4. better alerts and approval interfaces
5. improved analytics
6. long-term structural cleanup if needed

These should come after the core trust problems are solved, not before.

---

## 21. Glossary

**Admin system**: the internal XEPI operations platform.

**Client app**: the public browsing/cart/WhatsApp product catalog.

**Kiosko**: the physical store or in-person point-of-sale channel.

**Warehouse / Bodega**: the main storage location where merchandise arrives first.

**Transfer / Movement**: internal stock movement between locations.

**Shipment / Receipt**: inbound merchandise recording event.

**Delivery sale**: a sale that includes customer delivery handling.

**Pending cash**: collected cash not yet reconciled by deposit.

**Deposit**: the record of cash being taken from pending state and deposited into a bank account with proof.

**Expense**: business spending recorded for control and reporting.

**MVP**: the smallest trustworthy version of the system that the business can operate on.

---

## 22. Final summary

XEPI is building an internal business-control system, not just an app with many screens.

The software exists to give the business reliable control over products, stock, sales, cash, deposits, expenses, and reporting. The admin system is the operational core. The client app is a separate but dependent public-facing project. Inventory is the foundation, sales and delivery sit on top of inventory, cash/deposits sit on top of sales, and reports sit on top of all of that.

A large amount of work already exists, but the project still needs a strong canonical plan because the real remaining risk is integration quality and trustworthiness, not only missing features.

This document should now be used as the common baseline for future planning, architecture decisions, and gap analysis.
