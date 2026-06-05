# CLAUDE.md — XEPI Admin

Flutter + Firebase/GCP. Spanish UI, English code. This is a business-control system (not an ERP, not a checkout app). **Inventory is the base system** — stock/cash correctness comes before every other concern.

---

## Documentation map

All project truth lives in `docs/`. Read what's relevant before touching code — the docs are the contract.

| File | When to read it |
|------|----------------|
| `docs/ROADMAP.md` | Any session — shows what's done, what's next |
| `docs/MUTATION_RULES.md` | **Before any money/stock write** |
| `docs/KNOWN_ISSUES.md` | Itemized bugs with `file:line` |
| `docs/STATE_MACHINES.md` | Before changing sale/order/movement/expense flows |
| `docs/DATA_MODEL.md` | Before adding/changing Firestore fields |
| `docs/PERMISSIONS.md` | Before touching auth, roles, or access control |
| `docs/ARCHITECTURE.md` | Before adding new files or patterns |
| `docs/DELIVERY_AND_PAYMENTS.md` | Before touching delivery/payment logic |
| `docs/DECISIONS.md` | Before relitigating any architectural call |
| `docs/GO_LIVE_CHECKLIST.md` | Before any production data enters the system |
| `docs/TEST_PLAN.md` | Before marking a money/stock change done |
| `docs/OPERATIONS.md` | Environments, delete behavior, recovery |
| `XEPI_MASTER_DOCUMENTATION.md` | Business "why" — scope, glossary, vision |

Hard rules and invariants live in `AGENTS.md` (always read by Claude Code).

---

## Workflows

### Fixing a specific bug
1. Check `docs/KNOWN_ISSUES.md` for `file:line`. Read surrounding code in full.
2. If it touches money or stock, read `docs/MUTATION_RULES.md` and trace every read/write path first.
3. Make a surgical edit. Don't clean unrelated code in the same change.
4. If the fix changes a flow, verify against `docs/TEST_PLAN.md`.
5. Update `docs/KNOWN_ISSUES.md` (mark resolved) and `docs/ROADMAP.md` if it was a tracked item.

### Working through the roadmap
1. Open `docs/ROADMAP.md`. Pick the lowest-priority unchecked item (P0 → P1 → P2 → …).
2. Don't skip ahead to refactors or UI improvements while P0/P1 items are open — correctness first.
3. Follow the bug-fixing workflow above for each item.
4. Tick the checkbox and add an ADR to `docs/DECISIONS.md` if you made an architectural choice.

### Adding a new feature or screen
1. Check `docs/ROADMAP.md` — is this in scope? Is there a blocking P0/P1 item first?
2. Read `docs/DATA_MODEL.md` — does the data already exist, or do you need new fields?
3. Read `docs/PERMISSIONS.md` — which roles can access this feature? Wire permissions from the start.
4. Read `docs/ARCHITECTURE.md` for the target layer (no direct Firestore in screens; use repositories).
5. Follow existing screen/widget patterns. Match the AppTheme. Spanish labels.
6. If the feature touches money or stock, it needs a Cloud Function — don't do it client-side only.
7. Add the new screen/feature to `docs/DATA_MODEL.md` if it introduces new fields.

### Architectural work (models, repos, refactors)
1. Read `docs/ARCHITECTURE.md` for the target structure.
2. Order matters: constants/enums → models → repositories → providers → thin screens. Don't skip steps.
3. When breaking up a large screen, extract `_build*` methods into widget classes first. Don't rewrite logic during a structural refactor.
4. If you're consolidating duplicated business logic, document the duplication clearly in comments or an ADR before touching it.
5. No screen file should exceed ~400 lines. No business logic inside State classes.

### Planning or designing something new
1. Read the relevant docs (state machines, data model, delivery/payments if applicable).
2. Check `docs/DECISIONS.md` — has this been decided already?
3. If the design involves money, stock, or permissions, it needs all 3 enforcement layers (UI + Firestore rules + Cloud Functions). Don't design around one layer only.
4. Write decisions to `docs/DECISIONS.md` with a date. Write new data shapes to `docs/DATA_MODEL.md`.

---

## Current P0 priorities
See `docs/ROADMAP.md` for the full list and status. The critical three:
1. Stock race condition → `deductStock` Firestore transaction / Cloud Function
2. Remove `?? 'admin'` auth fallback — hard guard required
3. `orders_history_screen.dart:441` — broken sub-feature in the live delivery list

---

## Operational notes
- **Don't commit** unless the user explicitly asks.
- **Don't run on prod data** until `docs/GO_LIVE_CHECKLIST.md` is satisfied. Current Firebase project (`xepi-f5c22`) is test data only.
- `admin_dashboard_legacy.dart` is **protected** — never delete it (see `AGENTS.md`).

## Commands
```
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```
