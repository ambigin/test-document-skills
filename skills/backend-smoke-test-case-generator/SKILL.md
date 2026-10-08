---
name: backend-smoke-test-case-generator
description: >
  Generates Backend Smoke Test Case Documents as an XLSX spreadsheet covering API health,
  database connectivity, DB object existence, stored procedure executability, trigger state,
  FK constraint state, integration dependencies, and deployment verification checks.
  Use this skill when the user asks to generate backend smoke tests, create a smoke test
  checklist for a deployment, verify the system is alive after a release, or produce
  go/no-go checks for a backend service. Trigger for: "smoke tests for backend",
  "post-deployment smoke checks", "backend health verification", "go/no-go checklist".
---

# Backend Smoke Test Case Generator

## Purpose

Generate a Backend Smoke Test Case Document covering all layers a backend system must pass
for a deployment to be considered stable: API, database, DB objects, integrations, security,
and deployment metadata. Output is an XLSX workbook produced by the bundled converter.

A smoke test answers one question: **is the system alive and its dependencies wired correctly?**
It does not test business logic — that is the job of the backend E2E skill.

---

## Workflow: Four Phases (Always Follow This Order)

---

### PHASE 0: Context Gathering (Always Run First)

Gather all available context before asking the user anything. Run these steps in order and
record every finding — MCP facts are cited as `[DB: MCP]`, fetched API facts as `[API: <source>]`.

#### Step 1 — Read PROJECT_CONTEXT.md
Check for `PROJECT_CONTEXT.md` in the current working directory, then at the repository root.
If found, read it fully. Its contents are ground truth — do not ask questions already answered there.

#### Step 2 — Detect MCP Database Connection
Check whether an MCP database tool is available in the session (e.g. oracle-sqlcl, postgres MCP,
mysql MCP, or similar). If connected:

1. Detect DB engine and version from connection metadata or a version query.
2. Introspect the schema automatically:
   - Tables and row counts for critical tables
   - Views
   - Stored procedures and functions
   - Triggers and their ENABLED / DISABLED state — **flag any DISABLED triggers immediately**
   - Sequences / identity generators
   - FK constraints and their ENABLED / DISABLED state — **flag any DISABLED FK constraints**
   - Indexes on critical tables
   - Partitions for the current period (Oracle / Postgres partition tables only)
   - Scheduled jobs / tasks and their state
3. Record all findings with `[DB: MCP <engine> <date>]` as the reference.
4. Do NOT ask the user about DB objects — the MCP already has the facts.

If MCP is not connected, check PROJECT_CONTEXT.md for DB engine and schema export.
If neither is available, set **Generic Mode** (see below) and continue.

#### Step 3 — Detect API Contract
Check for an API contract in this order:
1. Swagger / OpenAPI URL in PROJECT_CONTEXT.md → `WebFetch` it and parse endpoints
2. Postman collection JSON in PROJECT_CONTEXT.md or provided by user → parse requests
3. Docs page URL (Confluence, Notion, internal wiki) → `WebFetch` and extract endpoint definitions
4. None found → note that API checks will be generic

Record all parsed endpoints with `[API: <source> <date>]` as the reference.

#### Step 4 — Set Context Mode
Based on what was gathered:

| Context Available | Mode |
|---|---|
| MCP connected + API contract found | **Full Mode** — all checks are schema-cited |
| MCP connected, no API contract | **DB-Full Mode** — DB checks cited, API checks generic |
| No MCP, API contract found | **API-Full Mode** — API checks cited, DB checks use PROJECT_CONTEXT schema |
| Neither MCP nor API contract | **Generic Mode** — all checks are generic templates with warning |

In **Generic Mode**, generate the standard generic smoke test cases listed in the
Generic Fallback section below, then display this warning before Phase 1:

> ⚠ **No API contract or DB connection found.** The test cases below are generic templates.
> Provide a Swagger/OpenAPI URL, Postman collection, or MCP database connection for
> schema-cited, accurate smoke tests specific to your system.

---

### PHASE 1: Scope Confirmation (Only After Phase 0 Completes)

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.**

Ask only what Phase 0 could not determine. Present MCP findings for user review rather than
asking open questions. Keep this phase to the minimum necessary.

**Standard Phase 1 questions (ask only what applies):**

1. **Scope** (Full/DB-Full Mode only): "I found [N] tables, [N] views, [N] procedures, [N] triggers
   ([X] disabled ⚠). Are all of these in scope for this smoke run, or should I focus on a subset?"

2. **Integration dependencies** (always ask — MCP cannot detect these):
   "Does this system have any of the following? (list what applies)
    - Message queue (Kafka, RabbitMQ, SQS)
    - Cache layer (Redis, Memcached)
    - Blob / object storage (S3, Azure Blob, GCS)
    - External APIs (payment gateway, email service, SMS provider, OAuth provider)"

3. **Write safety**: "Is write+rollback safe in this environment for smoke testing,
   or should all DB checks be read-only?"

4. **Deployment metadata**: "Do you have a health check endpoint (e.g. `GET /health`) and/or
   a version endpoint (e.g. `GET /version`)? Do you track DB migration versions in a table?"

5. **Missing dependencies** (Full/DB-Full Mode only): "Here are the DB dependencies I traced.
   Did I miss any tables, procedures, or triggers that must be verified?"

Do not ask about DB objects, table names, column names, triggers, or sequences —
those come from MCP or the schema export in PROJECT_CONTEXT.md.

---

### PHASE 2: Generate and Write Tables (Only After Phase 1 Completes)

Do not generate tables until Phase 1 is complete.

1. Build all smoke test case rows following the Column Format Reference and Coverage Rules below.
2. **Do NOT echo the tables to chat.** Write all `## Sheet:` blocks to a temp file in the
   session scratchpad directory (never inside the user's project). The file must contain:
   - `## Sheet: Smoke Tests` — the main 10-column table
   - `## Sheet: Summary` — counts by Check Category
3. Confirm with a single line: "✓ N smoke test cases written — running converter..."

---

### PHASE 3: Convert to XLSX (Only After Phase 2 Completes)

1. Call the bundled converter:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/smoke-tests.md" "<output>/backend-smoke-tests.xlsx"
   ```
   `${CLAUDE_SKILL_DIR}` is not a real shell variable — replace it with the full path to this
   skill's folder. If `python3` fails, try `python` or `py -3`. The script needs `openpyxl`.
   Use `/mnt/user-data/outputs` on Claude.ai or `./outputs` locally for `<output>`.
2. Confirm the script printed `"status": "success"` with no `warnings`.
   If warnings appear, fix the temp file and re-run — do not hand-edit the XLSX.
3. State the output path in a single line.

---

## Column Format Reference

**Exactly 10 columns, in this order:**

| Test Case ID | Check Category | Component | Check Description | Verification Method | Expected Result | DB Query | Automation Candidate | References | Comments |

| Column | Format Rule | Examples |
|---|---|---|
| Test Case ID | `BSM-<NNN>` (001, 002, …) | `BSM-001` |
| Check Category | One of: `API Health` / `DB Connectivity` / `DB Object Existence` / `DB Executable` / `DB Integrity` / `Integration` / `Security & Config` / `Deployment` | `DB Object Existence` |
| Component | Specific thing being checked | `users table`, `USER_AUDIT_TRG`, `GET /health`, `Redis`, `USER_ID_SEQ` |
| Check Description | One sentence: what to verify and how | `Verify users table exists and is queryable with SELECT COUNT(*)` |
| Verification Method | `HTTP Request` / `MCP Query` / `Manual` | `MCP Query` |
| Expected Result | What must be true for this check to pass | `Row count ≥ 0, no ORA- error` |
| DB Query | SQL query that verifies this check (MCP-executable); `N/A` for non-DB checks | `SELECT COUNT(*) FROM users` |
| Automation Candidate | `Yes` / `No` / `Partial` (see rules below) | `Yes` |
| References | Cited source for this check | `[DB: MCP Oracle 19c 2026-10-06]` / `[API: Swagger /health]` / `[Generic: no context]` |
| Comments | Flags, assumptions, disabled-object warnings | `⚠ Trigger found DISABLED in MCP — verify after deployment` |

---

## Automation Candidate Rules

- `Yes`: check is fully deterministic — HTTP request or SQL query with a known expected result
- `No`: requires human judgment, manual login, or visual verification
- `Partial`: assertion is automatable but setup requires a manual step (e.g. seeding specific state)

Any row where References contains `[Generic: no context]` → `Partial` (schema unknown, verify first).

---

## Coverage Rules (Mandatory)

Generate at least one check per applicable category. In Full Mode, generate one check per
discovered object (one per table, one per trigger, one per procedure, etc.).

### API Health (include if API contract found or health endpoint known)
- Health check endpoint returns 200
- Auth / token issuance endpoint reachable
- Critical business endpoints return non-5xx status
- Unauthenticated request to protected endpoint returns 401

### DB Connectivity (always include)
- DB connection can be established (read query executes without error)
- Write + rollback executes without error (only if write-safe environment confirmed)

### DB Object Existence (include if MCP connected or schema provided)
- Each critical table exists and is queryable (`SELECT COUNT(*)`)
- Each view resolves without error
- Each sequence exists and is accessible
- Oracle-specific: synonyms resolve to their target objects

### DB Executable (include if procedures/functions found)
- Each stored procedure is callable with safe/dummy arguments without error
- Each function returns a result without error

### DB Integrity (include if MCP connected)
- Each trigger is in ENABLED state — **one row per trigger, flag DISABLED as ⚠**
- Each critical FK constraint is ENABLED — **flag DISABLED as ⚠**
- Partitions exist for current period (Oracle/Postgres partition tables only)
- Critical indexes exist on their target tables

### Integration (include if integration dependencies confirmed in Phase 1)
- Message queue: topic/queue accessible and consumer group registered
- Cache: PING / connectivity check succeeds
- Blob storage: bucket/container accessible and writable
- External API: reachability check (not a live transaction)

### Security & Config (always include)
- SSL/TLS certificate valid and not expiring within 30 days
- Critical environment variables present (presence check only, not value)
- CORS headers present on API responses

### Deployment (include if deployment metadata endpoints confirmed)
- Health check endpoint returns expected version or `"status": "ok"`
- App version matches expected release version
- DB migration version matches expected version for this release

---

## Generic Fallback Test Cases

When in Generic Mode (no MCP, no API contract), generate exactly these rows as a starting
template. Mark every References cell as `[Generic: no context]` and every Automation Candidate
as `Partial`.

1. Verify application health check endpoint responds with HTTP 200
2. Verify DB connection can be established (read query executes without error)
3. Verify critical API tables exist and have row count ≥ 0
4. Verify DB column names match API response field names (column field mapping)
5. Verify DB column data types match API response field data types
6. Verify row count in target table increases by 1 after a successful POST request
7. Verify unauthenticated request to a protected endpoint returns HTTP 401
8. Verify application returns HTTP 200 (not 500) for the primary business endpoint
9. Verify stored procedures execute without throwing an error
10. Verify all triggers are in ENABLED state after deployment

---

## Summary Sheet

`## Sheet: Summary` — two-column table: `Check Category` / `Count`.
Include a row per category that has at least one test case, plus a `Total` row.
Add a `Context Mode` row with the mode detected in Phase 0 (Full / DB-Full / API-Full / Generic).
