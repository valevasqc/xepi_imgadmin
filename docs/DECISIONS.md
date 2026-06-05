# Decision Log (ADRs)

One short entry per architectural decision, newest first. Add a line whenever "we chose X over Y" — so future sessions don't re-litigate settled calls.

---

## ADR-006 — Web checkout deferred; client app stays catalog + WhatsApp
**Date:** 2026-06-03 · **Status:** Deferred (future design session)
Direct website purchase is wanted but blocked on delivery-pricing logic (variable mensajero pricing, Forza 5% surcharge, VisaLink per-sale links, voucher capture). Until designed, the live model is: client app = catalog → WhatsApp handoff → employee logs the sale. The separate `orders` collection stays legacy. Full detail in [DELIVERY_AND_PAYMENTS.md](DELIVERY_AND_PAYMENTS.md).

## ADR-008 — External review (GPT) incorporated selectively
**Date:** 2026-06-03 · **Status:** Accepted (partial)
A second-opinion review largely validated the existing direction. **Accepted**: (1) dedicated `GO_LIVE_CHECKLIST.md` separate from roadmap/test plan; (2) note on master doc that implementation truth lives in `docs/`; (3) tighten `sales` data model — explicit `paymentProof`, plus open questions on `tarjeta` approval, delivery-fee representation, and `notifications`; (4) enumerated `KNOWN_ISSUES.md` so the long-tail bugs aren't lost. **Pushed back / already covered**: "build domain layer before refactoring screens" (already the roadmap order — P1 models/repos/functions precede P3 god-file breakup); audit log timing — kept tied to Cloud Functions (lands with P2, not pulled earlier as its own track); automated tests stay deferred (manual checklist is the gate) — agreed, no change. Core message ("enforce the rules in code, don't implement around them") matches [MUTATION_RULES.md](MUTATION_RULES.md) intent.

## ADR-007 — Returns minimal, soft+hard delete, staging before go-live
**Date:** 2026-06-03 · **Status:** Accepted
- **Returns**: business does not do returns except rare defective product → minimal "defective return" path only, not a full returns system.
- **Delete**: soft-delete (void) by default for money records; hard delete available as admin-only escape hatch (logged). See [OPERATIONS.md](OPERATIONS.md).
- **Staging**: accepted, but de-urgent — prod currently holds only test data (not live). Staging required before go-live.
- Added docs: [MUTATION_RULES.md](MUTATION_RULES.md), [TEST_PLAN.md](TEST_PLAN.md) (manual checklist; automated tests deferred), [OPERATIONS.md](OPERATIONS.md) (envs/seed/recovery). Matches the doc standard from the owner's other project (seed, mutation rules, recovery, test plan, ADR).

## ADR-005 — Stock adjustments in scope
**Date:** 2026-06-03 · **Status:** Accepted
Owner confirmed stock adjustments/shrinkage as in-scope (P1) — required for trusted inventory (breakage/theft/miscount need a home with reason codes + audit). Superseded the "pending" parts by [ADR-007](#adr-007--returns-minimal-softhard-delete-staging-before-go-live).

## ADR-004 — In-repo documentation set
**Date:** 2026-06-03 · **Status:** Accepted
Docs were fragmenting (master doc, AGENTS, copilot, archive, ephemeral plan). Chose a single in-repo `docs/` set with one responsibility per file, indexed from [AGENTS.md](../AGENTS.md). Not "more docs" — the right docs, in the repo, read at session start.

## ADR-003 — Editable per-user permissions (role templates + toggles)
**Date:** 2026-06-03 · **Status:** Accepted
Kiosko/warehouse/mensajero work differently; a flat employee role is wrong. Roles act as templates; each user has an explicit editable `permissions` map. Enforced in 3 layers (UI, Firestore rules via custom claims, Cloud Functions). See [PERMISSIONS.md](PERMISSIONS.md).

## ADR-002 — Legacy admin dashboard is protected
**Date:** 2026-06-03 · **Status:** Accepted
`admin_dashboard_legacy.dart` (Realtime DB image system) must NOT be deleted until the new Firestore/Storage image system fully replaces it via a verified migration. Owner actively maintains it.

## ADR-001 — Stay on Firestore, do not migrate to SQL
**Date:** 2026-06-03 · **Status:** Accepted
Considered Supabase/Cloud SQL (Postgres) for real transactions and richer queries. Rejected: the real problems are code architecture (no models, magic strings, race conditions), not Firestore. Migration would lose real-time listeners and require rewriting every query. Instead, add Cloud Functions for the 3 operations needing true server-side transactions.
