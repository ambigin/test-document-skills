---
name: backend-e2e-test-case-generator
description: >
  Generates Backend E2E Test Case Documents as an XLSX spreadsheet covering API-to-DB
  data contract validation, payload persistence verification, service-layer business rule
  testing, and full scenario coverage (positive, negative, boundary, null, type contract,
  persistence, business rule). Requires an affected endpoint and optionally an API contract
  and MCP database connection for schema-cited assertions. Use this skill when the user asks
  to generate backend test cases, API-to-DB validation tests, data contract tests, or E2E
  backend tests for a specific feature or endpoint. Trigger for: "backend test cases for
  this endpoint", "API to DB validation", "data contract tests", "E2E backend tests for
  [feature]", "persistence test cases".
---

# Backend E2E Test Case Generator

## Purpose

Generate a Backend E2E Test Case Document that validates the full API → Service → DB
chain for a specific feature or endpoint. Each test case produces a cited DB assertion —
not just "verify the data persisted" but the exact table, column, expected value, and
the SQL query that confirms it.

This skill is **not** for functional UI behavior — use `test-case-generator` for that.
This skill focuses on data contracts, persistence correctness, service-layer transformations,
and type compatibility between API and DB layers.

---

## Workflow: Four Phases (Always Follow This Order)

---

### PHASE 0: Context Gathering (Always Run First)

Gather all available context before asking the user anything. Record every fact with its
source — MCP facts cited as `[DB: MCP <engine> <date>]`, API facts as `[API: <source> <date>]`.

#### Step 1 — Read PROJECT_CONTEXT.md
Check for `PROJECT_CONTEXT.md` in the current working directory, then at the repository root.
If found, read it fully. Its contents are ground truth — do not ask questions already answered
there, including business logic rules, layer mapping, and field transformation rules.

#### Step 2 — Identify Feature and Affected Endpoints
The user must have stated a feature name, ticket ID, or description. From that:
1. Note the feature scope — this constrains which endpoints and tables are in scope.
2. If an API contract is available (next step), use it to identify the affected endpoints
   rather than asking the user to list them. Present the shortlist for confirmation.
3. Do not generate test cases for endpoints outside the stated feature scope.

#### Step 3 — Fetch API Contract
Check for an API contract in this order:
1. Swagger / OpenAPI URL in PROJECT_CONTEXT.md or user message → `WebFetch` and parse
   endpoint schemas (request body fields + types, response fields + types, required/optional,
   enums, maxLength, pattern constraints)
2. Postman collection JSON → parse requests and example payloads
3. Docs page URL (Confluence, Notion, internal wiki) → `WebFetch` and extract definitions
4. None found → note that API layer checks will be generic

Record all parsed schemas with `[API: <source> <date>]`.

#### Step 4 — Detect MCP Database Connection
Check whether an MCP database tool is available in the session. If connected:

1. Auto-detect DB engine and version.
2. For each endpoint identified in Step 2, trace DB dependencies:
   - Tables written to or read from (infer from resource name + PROJECT_CONTEXT layer mapping)
   - Column names, data types, nullability, default values, constraints
   - Triggers on those tables and their ENABLED/DISABLED state
   - FK constraints and their ENABLED/DISABLED state
   - Sequences used for ID generation
   - Stored procedures called by the service layer (from PROJECT_CONTEXT if not in DB metadata)
3. Cross-reference API field types against DB column types — flag any mismatch immediately:
   e.g. API `string` → DB `NUMBER`, API no maxLength → DB `VARCHAR(10)`.
4. Record all findings with `[DB: MCP <engine> <date>]`.
5. Do NOT ask the user about tables, columns, or types — MCP has those facts.

If MCP is not connected, use DDL / schema export from PROJECT_CONTEXT.md.
If neither is available, set **Generic Mode** and continue.

#### Step 5 — Set Context Mode

| Context Available | Mode |
|---|---|
| MCP connected + API contract found | **Full Mode** — all assertions are schema-cited |
| MCP connected, no API contract | **DB-Full Mode** — DB assertions cited, API layer generic |
| No MCP, API contract found | **API-Full Mode** — API layer cited, DB assertions use PROJECT_CONTEXT schema |
| Neither MCP nor API contract | **Generic Mode** — generic template rows with warning |

In **Generic Mode**, generate the standard generic test cases from the Generic Fallback
section below, then display this warning before Phase 1:

> ⚠ **No API contract or DB connection found.** The test cases below are generic templates.
> Provide a Swagger/OpenAPI URL or Postman collection for API context, and an MCP database
> connection or CREATE TABLE DDL for DB context, to get schema-cited, accurate test cases.

---

### PHASE 1: Scope Confirmation (Only After Phase 0 Completes)

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.**

Ask only what Phase 0 could not determine. Present findings for user review.

**Standard Phase 1 questions (ask only what applies):**

1. **Endpoint confirmation** (Full / API-Full Mode): "For [feature name], I found these
   endpoints likely in scope: [list]. Are these correct? Any others to include?"

2. **DB dependency review** (Full / DB-Full Mode): "Here are the DB dependencies I traced
   for [endpoint]: [tables, triggers, constraints, sequences]. Did I miss any?"

3. **Business rules** (when not in PROJECT_CONTEXT.md): "Are there any field transformations
   or business rules I should know about for this feature?
   e.g. status uppercased before DB insert, soft delete sets deleted_at, audit trail written."

4. **Acceptance criteria** (if available): "Do you have acceptance criteria for this feature?
   Paste them in any format — I'll map each AC to at least one test case."

5. **Write safety**: "Is it safe to run INSERT/UPDATE/DELETE operations in this environment,
   or should test cases assume a read-only or rollback-only context?"

Do not ask about tables, columns, data types, or API schemas — those come from MCP or the
fetched API contract. If ACs are not provided, infer test scenarios from the endpoint schema
and business rules and flag all inferred scenarios with `(inferred — verify)` in Comments.

---

### PHASE 2: Generate and Write Tables (Only After Phase 1 Completes)

Do not generate tables until Phase 1 is complete.

1. Build all test case rows following the Column Format Reference and Coverage Rules below.
2. **Do NOT echo the tables to chat.** Write all `## Sheet:` blocks to a temp file in the
   session scratchpad directory (never inside the user's project). The file must contain:
   - `## Sheet: Test Cases` — the main 12-column table
   - `## Sheet: Summary` — counts by Scenario Type and Check Category
   - `## Sheet: Coverage` — AC reference → Test Case ID mapping (if ACs were provided)
3. Confirm with a single line: "✓ N test cases written — running converter..."

---

### PHASE 3: Convert to XLSX (Only After Phase 2 Completes)

1. Call the bundled converter:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/backend-e2e-<feature>.md" "<output>/backend-e2e-<feature>.xlsx"
   ```
   `${CLAUDE_SKILL_DIR}` is not a real shell variable — replace it with the full path to this
   skill's folder. If `python3` fails, try `python` or `py -3`. The script needs `openpyxl`.
   Use `/mnt/user-data/outputs` on Claude.ai or `./outputs` locally for `<output>`.
2. Confirm the script printed `"status": "success"` with no `warnings`.
   If warnings appear, fix the temp file and re-run — do not hand-edit the XLSX.
3. State the output path in a single line.

---

## Column Format Reference

**Exactly 12 columns, in this order:**

| Test Case ID | Endpoint | Layer | Scenario Type | Preconditions | Request Payload | Expected API Response | DB Assertion | Business Rule Applied | Automation Candidate | References | Comments |

| Column | Format Rule | Examples |
|---|---|---|
| Test Case ID | `BE2E-<FEATURE>-<NNN>` (001, 002, …) | `BE2E-REG-001` |
| Endpoint | HTTP method + path | `POST /users` |
| Layer | `API` / `Service` / `DB` / `API→DB` | `API→DB` |
| Scenario Type | One of: `Positive` / `Negative` / `Boundary` / `Null` / `Type Contract` / `Persistence` / `Business Rule` | `Persistence` |
| Preconditions | DB state or setup required before test runs; `None` if not applicable | `User with email test@example.com does not exist in users table` |
| Request Payload | Exact fields and values sent; `N/A` for read operations | `{"email": "test@example.com", "status": "active", "phone": "9800000000"}` |
| Expected API Response | HTTP status code + key response fields; include error message for negative cases | `201 Created — {"id": <generated>, "email": "test@example.com"}` |
| DB Assertion | Table, column, expected value, and the SQL query that verifies it; `N/A` for API-only checks | `SELECT status FROM users WHERE email='test@example.com' → expected: 'ACTIVE'\nQUERY: SELECT status FROM users WHERE email = :email` |
| Business Rule Applied | The specific rule that drives this case; `N/A` if not rule-driven | `Service uppercases status before INSERT` |
| Automation Candidate | `Yes` / `No` / `Partial` (see rules below) | `Yes` |
| References | Cited sources for every fact in this row | `[API: Swagger POST /users 2026-10-06] [DB: MCP Oracle 2026-10-06]` |
| Comments | Flags, inferred assumptions, type mismatch warnings | `(inferred — verify) \| ⚠ API phone has no maxLength; DB VARCHAR(10)` |

Use `\n` (literal backslash-n) inside cells for multi-line content (e.g. DB Assertion with query on second line).

---

## Automation Candidate Rules

- `Yes`: assertion is fully deterministic — known payload, verifiable DB state with a SQL query, no external dependency
- `No`: involves human judgment, inferred business rule, third-party service, or email/notification delivery
- `Partial`: core DB assertion is automatable but test data setup requires a manual step

Any row where Comments contains `(inferred — verify)` or `[Generic: no context]` → `No` or `Partial`.
Any row where DB Assertion is a direct column-value check from a known payload → `Yes`.

---

## Coverage Rules (Mandatory)

Generate between 8 and 25 test cases per feature scope. Every endpoint confirmed in Phase 1
must have at least one row per Scenario Type that applies to it.

### Always include per endpoint:
- **Positive** — valid payload, all required fields present, DB state matches expected values
- **Negative** — invalid payload (wrong type, forbidden value, missing required field) → correct error response
- **Null** — null / empty string for each field that has a NOT NULL DB constraint or `required: true` in API schema
- **Boundary** — max length, min/max value for every field with a known constraint (from API schema or DB column definition)

### Include when applicable:
- **Type Contract** — one row per API field whose type differs from or is incompatible with its DB column type
  (string → number, no maxLength → VARCHAR(N), enum values not matching DB CHECK constraint)
- **Persistence** — for every write operation: verify each payload field persists to the correct DB column with the correct value
- **Business Rule** — one row per transformation rule in PROJECT_CONTEXT (uppercasing, enum mapping,
  auto-populated columns, soft delete, audit trail, computed fields)

### AC coverage:
If acceptance criteria were provided in Phase 1, every AC must be covered by at least one test case.
Record the mapping in the Coverage sheet.

### Type mismatch rule:
If a cross-reference between API schema and DB column types reveals a mismatch, generate a
dedicated `Type Contract` row, set Automation Candidate to `Yes`, and add a ⚠ flag in Comments.

---

## Generic Fallback Test Cases

When in Generic Mode (no MCP, no API contract), generate exactly these rows as a starting
template. Mark every References cell as `[Generic: no context]` and every Automation Candidate
as `Partial`. Feature/endpoint fields use `[specify endpoint]` and `[specify table]` as placeholders.

1. `Positive` — Valid payload with all required fields returns 200/201 and persists to DB
2. `Negative` — Missing required field in payload returns 400 with descriptive error
3. `Negative` — Invalid data type for a field returns 400 with descriptive error
4. `Null` — Null value for a required field returns 400 or DB constraint error
5. `Boundary` — Field value at maximum allowed length is accepted and persisted correctly
6. `Boundary` — Field value exceeding maximum allowed length is rejected with 400
7. `Type Contract` — API response field data types match corresponding DB column data types
8. `Persistence` — Row count in target table increases by 1 after successful POST
9. `Persistence` — All fields from request payload are present in the DB record with correct values
10. `Business Rule` — Auto-populated fields (e.g. created_at, created_by) are set by service, not required in payload
11. `Business Rule` — Soft delete sets deleted_at timestamp; record is not removed from table
12. `Negative` — Duplicate unique field (e.g. email) returns 409 Conflict

---

## Summary & Coverage Sheets

After the Test Cases sheet:

1. **Summary** (`## Sheet: Summary`) — two tables:
   - `Scenario Type` / `Count` — row per scenario type present
   - `Check Category` (API / DB / API→DB) / `Count`
   - Include `Context Mode` row (Full / DB-Full / API-Full / Generic)
   - Include `Total Test Cases` row

2. **Coverage** (`## Sheet: Coverage`) — `Acceptance Criterion` / `Covered By` mapping.
   Include only if ACs were provided in Phase 1. List each AC and the BE2E IDs that cover it.
   If no ACs were provided, omit this sheet entirely.
