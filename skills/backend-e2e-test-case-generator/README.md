# backend-e2e-test-case-generator

Generates a Backend E2E Test Case Document as an XLSX workbook. Covers the full
API → Service → DB chain for a specific feature or endpoint: data type contracts,
payload persistence, service-layer business rule validation, and full scenario coverage
(positive, negative, boundary, null, type contract, persistence, business rule).

## Output

| Sheet | Contents |
|---|---|
| Test Cases | 12-column table — one row per test case |
| Summary | Count by scenario type + context mode used |
| Coverage | AC → Test Case ID mapping (only when ACs provided) |

## Columns

`Test Case ID` · `Endpoint` · `Layer` · `Scenario Type` · `Preconditions` · `Request Payload` · `Expected API Response` · `DB Assertion` · `Business Rule Applied` · `Automation Candidate` · `References` · `Comments`

## Inputs (gathered automatically when available)

| Source | What it provides |
|---|---|
| MCP DB connection | Engine detection, table/column/type introspection, trigger state, FK state, sequences — auto-traced per endpoint |
| Swagger / OpenAPI URL | Request/response field names, types, required flags, enums, constraints |
| Postman collection | Request payloads and example responses |
| Docs page URL | Endpoint definitions from Confluence, Notion, or internal wiki |
| `PROJECT_CONTEXT.md` | Business logic rules, field transformations, layer mapping, AC format |
| Phase 1 questions | Endpoint confirmation, missing business rules, ACs, write safety |

## Context Modes

- **Full** — MCP + API contract: all assertions are schema-cited with `[DB: MCP]` and `[API: source]`
- **DB-Full** — MCP only: DB assertions cited, API layer generic
- **API-Full** — API contract only: API layer cited, DB assertions use PROJECT_CONTEXT schema
- **Generic** — no context: standard template rows with a warning prompt

## Scenario Types

`Positive` · `Negative` · `Boundary` · `Null` · `Type Contract` · `Persistence` · `Business Rule`

## Requirements

- Python 3.8+ with `openpyxl` (`pip install openpyxl`)
- Feature name or ticket ID (required — scopes which endpoints are generated)
- Optional: MCP database connection for auto-introspection
- Optional: Swagger/OpenAPI URL, Postman collection, or docs page for API contract
