# Operations

Environments, seed data, backup & recovery, and delete behavior. Bundled here to avoid tiny scattered files.

---

## Environments

| Env | Firebase project | Data | Status |
|-----|-----------------|------|--------|
| Production | `xepi-f5c22` | Currently **test data only** (not live yet) | active dev target |
| Staging/dev | *to create* | Seeded test data | not set up |

**Current reality**: there is no live customer/money data yet — it's all testing. So a separate staging project is **not urgent**, but it IS required **before go-live** so that future changes are tested without risking real records. When created:
- separate Firebase project, same schema + rules
- point a `--dart-define=ENV=staging` build flavor at it
- never test schema/migration changes against prod once prod holds real data

---

## Seed data

Purpose: populate a staging (or fresh) project with realistic sample data to test flows.

Seed set should include:
- a few categories + subcategories (incl. a bulk-eligible "cuadros" code like LAT-2030)
- ~20 products spanning categories, with stock in both locations
- one bank account per currency
- a couple of expense categories
- sample sales (one kiosko cash, one delivery, one pending transfer)

Implementation: a Node script under `scripts/seed/` using the Firebase Admin SDK, or a callable Function guarded to non-prod. Build alongside staging setup (ROADMAP P1).

---

## Backup & recovery

> Matters once prod holds real data. Stub now, finalize before go-live.

- **Backups**: enable Firestore scheduled daily exports to a Cloud Storage bucket (Firebase console → Firestore → Backups / `gcloud firestore export`).
- **Restore**: `gcloud firestore import gs://<bucket>/<export>` into the target project. Test the restore once so it's not first-attempted during an incident.
- **Storage**: product/proof images in Firebase Storage — enable bucket versioning.

---

## Delete behavior (soft + hard)

Default is **soft-delete**; hard delete is an admin-only escape hatch.

| Action | Who | Effect |
|--------|-----|--------|
| Void (soft) | per permissions | record kept, `status` → 'void'/'cancelled', side effects (stock/cash) reversed, stays in audit trail |
| Hard delete | admin only | record removed entirely — **must reverse stock/cash side effects first**, and write an audit entry of what was deleted |

Rationale: money records should keep a trail by default (find errors, answer "why did this change"). Hard delete exists for genuine mistakes/test cleanup but is logged.

---

## Recovery from a bad mutation
If stock or cash drifts:
1. Check the `audit` collection for the offending action.
2. Do NOT hand-patch the number — reverse via the owning flow (void the sale, delete the deposit, etc.) so all linked side effects unwind together. See [MUTATION_RULES.md](MUTATION_RULES.md).
3. If data is corrupted beyond flow-level repair, restore from the latest export into staging, verify, then targeted-fix prod.
