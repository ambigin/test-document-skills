---
name: performance-test-case-generator
description: >
  Generates a complete, execution-ready performance/load test suite as an XLSX workbook —
  covering load, stress, spike, soak/endurance, scalability, concurrency/contention, and recovery/
  failover testing — with script-ready traffic profiles, hard SLA pass/fail boundaries, and
  copy-paste tool config stubs (k6, JMeter, Gatling, Locust, Artillery). Use whenever the user
  wants a load test plan, performance test suite, capacity planning tests, SLA validation tests,
  or stress/spike/soak scenarios for an API, service, background job, or user journey — even if
  they only describe the system and traffic without saying "performance testing." Trigger for
  "design a load test for X", "performance test this endpoint", "stress test plan", "capacity
  test before scaling", "soak test this service", or "write k6/JMeter/Gatling scripts for this
  journey." Distinct from functional API tests (single request/response correctness) and
  usability tests (human task success) — this is about system behavior under load.
---

# Performance Test Case Generator Skill

## Purpose

Act as a Senior Performance Engineer and QA Architect and generate a complete, execution-ready performance test suite for the system component or user journey described — covering all performance testing types, bottleneck identification, and measurable acceptance criteria a team would need before a release or scaling event. Output is an XLSX workbook produced by the bundled converter script (`md_table_to_xlsx.py`).

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs

> **Read [references/PHASE1_GUIDE.md](references/PHASE1_GUIDE.md) before starting Phase 1.** It covers project context (`PROJECT_CONTEXT.md`), when to ask vs. infer, multi-item handling, assumption flagging, table formatting rules, and converter error recovery.

Before generating any output, you MUST gather the following. If an item is missing, **do not block on it** — infer a reasonable value and flag the assumption in that row's Notes column as `(assumed — verify)`. Only stop and ask if the target component/journey itself is unspecified, or if there is no usable signal for baseline/peak traffic at all (you cannot script a traffic profile from nothing).

| Item | Required to Proceed? | If Missing |
|------|----------------------|------------|
| Target Component / Journey | Yes — ask if absent | "What component, endpoint, background job, or user journey is this testing? (e.g. 'Checkout API', 'End-of-month payroll job')" |
| Baseline Traffic | Yes, or at least one of baseline/peak — ask if both absent | "What's normal operating load — concurrent users, RPS, or jobs/hour?" |
| Peak Traffic | Yes, or at least one of baseline/peak — ask if both absent | "What's the maximum anticipated load, and during what event (e.g. flash sale, month-end)?" |
| Tech Stack / Infra | No | Infer a generic stack from context; flag inferred components in Notes |
| SLA Targets | No | Infer industry-standard SLAs for the component type (e.g. p95 < 500ms for synchronous APIs); flag `(assumed — verify)` |
| Preferred Tool | No | Recommend best fit for the tech stack (e.g. k6 for modern HTTP APIs, JMeter for legacy/enterprise, Locust for Python-heavy teams) and state the rationale in Notes |
| Jira / Docs Link | No | Use "None" in Linked Requirement column |
| Multiple Components/Journeys Detected | Detect | "I see multiple components/journeys here. One combined suite, or a separate table per component?" |

Once the target and at least one traffic figure (baseline or peak) are known, proceed to Phase 2 — infer the rest rather than stalling on a fully complete spec.

### PHASE 2: Generate and Write the Test Suite

Build all rows per the structure below. **Do NOT echo the table to chat.** Write directly to a temp file in the session scratchpad directory (or the system temp directory if your environment has no scratchpad) — never inside the user's project. Confirm with: "✓ N test cases written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX

1. Call the bundled converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/md_table_to_xlsx.py" "<scratchpad>/perf-tests-<component-slug>.md" "<output>/<component-slug>-perf-tests.xlsx"
   ```
   The script is in `scripts/` next to this SKILL.md; if the command's path wasn't filled in with this skill's folder, use that folder's full path. If `python3` fails or isn't found (on Windows it's often a Microsoft Store placeholder that prints "Python was not found"), use `python` or `py -3` instead. The script needs `openpyxl`.
   Replace `<scratchpad>` with the temp directory from Phase 2. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
2. Confirm the script printed `"status": "success"` with no `warnings` — a warning means cells or lines were dropped, so fix the temp file (see PHASE1_GUIDE.md → Standard Converter Error Recovery) and re-run. If it errors, check that the temp file
   contains valid pipe-delimited markdown table syntax, fix if needed, and re-run.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. State the path in a single line — no preamble, no trailing summary.

## Coverage Requirements — All 7 Performance Test Types

1. **Load (LOAD)** — Simulate expected peak load to verify the system meets SLA targets under normal maximum operating conditions. Ramp up gradually. Measure p50, p90, p95, p99 response times, error rate, and throughput at steady state.
2. **Stress (STRESS)** — Push load beyond peak until the system degrades or fails. Identify the breaking point, the failure mode (graceful degradation vs. hard crash vs. cascading failure), and recovery behavior after load is removed.
3. **Spike (SPIKE)** — Inject a sudden, extreme traffic burst with near-zero ramp time (flash sale, viral event, batch trigger). Measure auto-scaling response latency, request queuing depth, and whether the system recovers or enters a degraded state post-spike.
4. **Soak / endurance (SOAK)** — Sustained moderate load (60–80% of peak) over an extended duration (minimum 2 hours in test; extrapolate to 24-hour and 7-day projections). Monitor for memory leaks, connection pool exhaustion, log growth, GC pressure, and response time drift.
5. **Scalability (SCALE)** — Incrementally increase load in fixed steps (e.g. +20% every 5 min) and measure how throughput, latency, and resource utilization scale. Identify linear vs. sub-linear scaling or a hard ceiling, and at which step.
6. **Concurrency & contention (CONCUR)** — Multiple users simultaneously accessing the same shared resource (same record, queue, cache key) to surface race conditions, deadlocks, DB lock contention, and optimistic locking failures.
7. **Recovery & failover (RECOVER)** — Introduce infrastructure-level failures under load (kill a node, exhaust DB connections, saturate a queue). Measure time-to-recovery, data integrity post-failure, and whether circuit breakers and fallbacks activate correctly.

**Minimum row counts:** 2 LOAD rows (one baseline traffic, one peak traffic); 1 STRESS; 1 SPIKE; 1 SOAK; 1 SCALE; 1 CONCUR; 1 RECOVER. Generate more if component complexity warrants it.

**Tech-stack coverage rule:** Every component or sub-system named in the tech stack (DB, cache, queue, CDN, etc.) must appear as a monitored bottleneck in at least one row — no component goes unmonitored.

**Auto-scaling rule:** Where auto-scaling is part of the infra, always include a dedicated assertion in Acceptance Criteria for scaling response latency (e.g. "New instances healthy within 90s of spike onset").

**Stateful/stateless rule:** If a scenario applies differently to a stateful vs. stateless component, document both behaviors in the Notes column rather than picking one.

## Table Structure — Exactly 14 Columns, In This Order

| Test Case ID | Test Type | Priority | Objective | Traffic Profile | Data Profile | Tool & Config Snippet | Bottlenecks to Monitor | Acceptance Criteria / SLA | Failure Indicators | Expected Failure Mode | Post-Test Validation | Notes | Linked Requirement |

## Column Rules

| Column | Rule |
|---|---|
| Test Case ID | `PERF-[COMPONENT ABBREVIATION]-[NNN]`, e.g. `PERF-PAY-001`, `PERF-LOGIN-003` |
| Test Type | Exactly one of: `LOAD` \| `STRESS` \| `SPIKE` \| `SOAK` \| `SCALE` \| `CONCUR` \| `RECOVER` |
| Priority | `P1` (must pass before release) / `P2` (must pass before scaling event/capacity change) / `P3` (investigate; fix before next major release) |
| Objective | One sentence: what this scenario is designed to prove or disprove |
| Traffic Profile | Script-ready and exact: start VU/RPS · ramp duration · target VU/RPS · hold duration · ramp-down · think time. E.g. "Ramp 0 to 5,000 VU over 5 min; hold 30 min; ramp down 5 min; think time 1–3s random" (semicolon-separated steps) |
| Data Profile | Volume and type of test data required, e.g. "10,000 unique user accounts, pre-seeded payroll records for 500 companies" |
| Tool & Config Snippet | Recommended tool + minimal script stub (about 25 lines max — Excel can't display a taller row) defining the traffic shape (ramp function, VU count, duration), copy-paste ready. Keep it in the one cell: write line breaks as `\n`, write any pipe in the code as `\|`, and don't use triple-backtick fences |
| Bottlenecks to Monitor | Pipe-separated: `Metric — Layer — Observation Tool`, e.g. `DB CPU % — Database — AWS CloudWatch \| Heap usage — Application — Datadog` |
| Acceptance Criteria / SLA | Hard pass/fail boundaries, not targets, pipe-separated: `p95 < Xms \| p99 < Xms \| Error rate < X% \| Throughput ≥ X RPS` (plus scaling-latency assertion if autoscaling applies) |
| Failure Indicators | Specific signals indicating failure before SLA thresholds are formally breached, e.g. "Connection pool queue depth > 50", "GC pause > 500ms", "Auto-scaler lag > 90s" |
| Expected Failure Mode | **For STRESS / SPIKE / RECOVER, this must always be populated — never "N/A."** Describe the anticipated degradation pattern, e.g. "Graceful 503 with Retry-After header" or "Queue backlog accumulates, processing lag increases linearly" |
| Post-Test Validation | Semicolon-separated steps to confirm system health post-test, e.g. "Verify no orphaned DB connections remain; confirm all queued jobs processed to completion; check memory returns to baseline within 5 min" |
| Notes | **Never blank.** Scenario rationale, infra-specific risks, scaling assumptions, bottleneck hypotheses, stateful/stateless distinctions, assumption flag `(assumed — verify)`, or follow-up pointer |
| Linked Requirement | Jira ticket ID, SLA document reference, architecture diagram link, or "None" |

## Formatting Rules (Mandatory)

- Separate multiple items within Bottlenecks to Monitor and Acceptance Criteria / SLA cells with an escaped pipe, `\|` — a bare `|` would start a new cell.
- Semicolons separate steps within multi-step cells (Traffic Profile, Post-Test Validation).
- Tool script stubs: in a single cell, with line breaks written as `\n`, any pipe escaped as `\|`, and no triple-backtick fences.
- `—` (em dash) is the placeholder for cells requiring post-execution data — never leave a cell truly blank.
- No nested tables, merged cells, or markdown formatting (bold, bullets) inside cells.
- Do not truncate output — generate every row before writing the temp file.

## Self-Check Before Finalizing

Before writing the temp file, verify:
- [ ] Minimum row counts per test type are met (2 LOAD, 1 each of STRESS/SPIKE/SOAK/SCALE/CONCUR/RECOVER)
- [ ] Every component in the tech stack appears as a monitored bottleneck somewhere
- [ ] Every STRESS, SPIKE, and RECOVER row has a populated, non-"N/A" Expected Failure Mode
- [ ] If autoscaling is part of the infra, at least one Acceptance Criteria cell asserts scaling response latency
- [ ] No Notes cell is blank
- [ ] Acceptance Criteria are hard pass/fail boundaries, not vague targets
- [ ] All assumed/inferred values are flagged `(assumed — verify)` in Notes
- [ ] Traffic Profiles are script-ready (ramp/hold/ramp-down/think-time all specified, not just a peak number)
- [ ] Every row is on a single line, and pipes inside cells are escaped as `\|`

