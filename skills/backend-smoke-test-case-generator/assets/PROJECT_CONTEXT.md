# Project Context — Backend Smoke Tests

> **How to use this file**
> Copy this file to the root of the project you are testing and fill it in there.
> The backend-smoke-test-case-generator skill reads `PROJECT_CONTEXT.md` from the project
> root before asking any questions. Keep entries short — one sentence per item is enough.
> Delete sections that do not apply to your project.

---

## Product Background
<!-- What does this backend service do and who consumes it? 2–3 sentences max. -->


## Tech Stack
<!-- Framework, language, and runtime. e.g. "NestJS / TypeScript, Node 20" or "Django / Python 3.12". -->

- **Framework**:
- **Language / runtime**:
- **DB engine**:


## API Contract
<!-- Where is the API documented? Postman collection path, OpenAPI spec URL, or documentation file. -->

- **Postman collection**:
- **OpenAPI / Swagger**:
- **Base URL env var**: <!-- e.g. API_BASE_URL -->
- **Route prefix**: <!-- e.g. /core, /api/v1 — include in every path -->


## Authentication
<!-- How are requests authenticated? Bearer token, API key, OAuth, session cookie, etc. -->

- **Type**: <!-- e.g. Bearer token -->
- **Env var for token**: <!-- e.g. API_TOKEN -->
- **Open endpoints** (no auth required): <!-- list paths or "none" -->
- **App-to-app only endpoints**: <!-- list paths or "none" -->


## Liveness / Health Check
<!-- Which endpoint is safe to use as a deployment liveness probe? Should be fast, read-only, and require no auth. -->

- **Endpoint**:
- **Expected status**:


## Database
<!-- Connection details for the test environment. -->

- **Schema / database name**:
- **MCP tool available**: <!-- yes / no — and tool name if yes -->
- **Connection env vars**: <!-- e.g. DB_HOST, DB_PORT, DB_NAME, DB_USER -->


## Critical Tables
<!-- Tables that must exist and be queryable for the system to function.
     Smoke tests will verify these exist and return rows. -->

| Table | Purpose |
|-------|---------|
|  |  |


## Critical Views
<!-- Views that application queries depend on. Smoke tests will verify these are selectable. -->

| View | Used by |
|------|---------|
|  |  |


## Stored Procedures / Functions
<!-- Named procedures or functions that must be executable. "None" if not applicable. -->

| Name | Purpose |
|------|---------|
|  |  |


## Triggers
<!-- Triggers whose existence must be verified. "None" if not applicable. -->

| Trigger | Table | Event |
|---------|-------|-------|
|  |  |  |


## FK / Constraint Checks
<!-- Foreign key relationships or constraints that are critical to data integrity.
     Smoke tests will verify these are enforced. "None" if not applicable. -->

| Constraint | Table | References |
|------------|-------|------------|
|  |  |  |


## Integration Dependencies
<!-- External services the backend calls. Smoke tests will verify connectivity to each. -->

| Service | Purpose | Smoke check |
|---------|---------|-------------|
|  |  | <!-- e.g. "GET /health → 200" or "queue message enqueued" --> |


## Key Endpoints (Smoke-Critical Subset)
<!-- Read-only endpoints that cover each major module.
     Smoke tests verify these return 200 and a non-empty body. -->

| Module | Endpoint | Auth required | Purpose |
|--------|----------|---------------|---------|
|  |  |  |  |


## Environment Notes
<!-- Anything environment-specific that affects test execution or safety.
     e.g. write-safety, rollback strategy, known flaky endpoints, required seed data. -->

- **Write / rollback safe**:
- **Required seed data**:
- **Known flaky endpoints**:
- **Other**:
