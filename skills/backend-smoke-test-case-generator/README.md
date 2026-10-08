# backend-smoke-test-case-generator

Generates a Backend Smoke Test Case Document as an XLSX workbook. Covers API health, DB
connectivity, DB object existence, stored procedure executability, trigger state, FK constraint
state, integration dependencies, and deployment verification.

## Usage

Say any of the following to Claude to invoke this skill:

- "Generate backend smoke tests for my service"
- "Create a post-deployment smoke test checklist"
- "Backend health verification checks"
- "Go/no-go checklist for the backend deployment"

For the best output, have at least one of the following ready: an MCP database connection, a Swagger/OpenAPI URL, or a Postman collection. The skill works without them but produces generic template rows.

## Scope

This skill answers one question: **is the system alive and its dependencies wired correctly?**

It covers API reachability, DB connectivity, DB object existence (tables, views, procedures, triggers, FK constraints), integration dependencies, and deployment metadata. It does **not** test business logic, field transformations, or scenario coverage — use `backend-e2e-test-case-generator` for that.

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

## PROJECT_CONTEXT.md guidance

Copy `assets/PROJECT_CONTEXT.md` to your project root and fill in the sections below for the best results with this skill. The skill reads it automatically before Phase 1.

**Most useful sections for backend smoke testing:**

- **Product Background** — what the backend service does and who consumes it
- **Key Workflows & Features** — list the major modules/endpoints so the skill knows what exists
- **Domain Glossary** — project-specific terms used in table or endpoint names
- **Tech stack** — add a comment with framework, language/runtime, and DB engine
- **API Contract** — Postman collection path, OpenAPI/Swagger URL, base URL env var, and route prefix (e.g. `/api/v1`)
- **Authentication** — auth type (Bearer token, API key, OAuth), env var for the token, open endpoints (no auth required), app-to-app-only endpoints
- **Liveness / Health Check** — the endpoint used as a deployment probe (fast, read-only, no auth), and its expected status code
- **Database** — schema name, whether an MCP tool is available, and connection env vars
- **Critical Tables** — tables that must exist and return rows for the system to function (one row per table)
- **Critical Views** — views the application queries depend on
- **Stored Procedures / Functions** — named procedures/functions that must be executable
- **Triggers** — triggers whose existence must be verified (table + event)
- **FK / Constraint Checks** — foreign key relationships critical to data integrity
- **Integration Dependencies** — external services the backend calls, with their expected smoke check (e.g. `GET /health → 200`)
- **Key Endpoints (Smoke-Critical Subset)** — read-only endpoints covering each major module; smoke tests verify these return 200 and a non-empty body
- **Environment Notes** — write/rollback safety, required seed data, known flaky endpoints
