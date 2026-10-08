# backend-smoke-test-case-generator

Generates a Backend Smoke Test Case Document as an XLSX workbook. Covers API health, DB
connectivity, DB object existence, stored procedure executability, trigger state, FK constraint
state, integration dependencies, and deployment verification.

## Output

| Sheet | Contents |
|---|---|
| Smoke Tests | 10-column table — one row per check |
| Summary | Check count by category + context mode used |

## Columns

`Test Case ID` · `Check Category` · `Component` · `Check Description` · `Verification Method` · `Expected Result` · `DB Query` · `Automation Candidate` · `References` · `Comments`

## Inputs (gathered automatically when available)

| Source | What it provides |
|---|---|
| MCP DB connection | Engine detection, tables, views, procedures, triggers, FK constraints, sequences, partitions — auto-introspected |
| Swagger / OpenAPI URL | Endpoint health and auth checks |
| Postman collection | Endpoint reachability checks |
| `PROJECT_CONTEXT.md` | DB schema export, integration list, deployment endpoints |
| Phase 1 questions | Integration dependencies, write safety, deployment metadata (only what MCP can't detect) |

## Context Modes

- **Full** — MCP + API contract: all checks are schema-cited
- **DB-Full** — MCP only: DB checks cited, API checks generic
- **API-Full** — API contract only: API checks cited, DB checks use PROJECT_CONTEXT schema
- **Generic** — no context: standard template rows with a warning prompt

## Requirements

- Python 3.8+ with `openpyxl` (`pip install openpyxl`)
- Optional: MCP database connection for auto-introspection
- Optional: Swagger/OpenAPI URL or Postman collection for API checks

## Check Categories

`API Health` · `DB Connectivity` · `DB Object Existence` · `DB Executable` · `DB Integrity` · `Integration` · `Security & Config` · `Deployment`
