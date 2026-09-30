# Performance Test Case Generator

Designs a performance and load test suite for an API, service, background job, or user journey — with script-ready traffic profiles, hard SLA pass/fail limits, and starter configs for common load tools — delivered as an Excel workbook.

## Use it when

- "Design a load test for our checkout API — 500 RPS normally, 3,000 RPS during flash sales."
- "Soak test plan for the end-of-month payroll job."
- "Write k6 scripts for the sign-up journey."

## What you get

`<component-slug>-perf-tests.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai).

Each row is one scenario, with 14 columns: Test Case ID, Test Type, Priority, Objective, Traffic Profile, Data Profile, Tool & Config Snippet, Bottlenecks to Monitor, Acceptance Criteria / SLA, Failure Indicators, Expected Failure Mode, Post-Test Validation, Notes, Linked Requirement.

Covers load, stress, spike, soak/endurance, scalability, concurrency/contention, and recovery/failover testing. Config snippets target k6, JMeter, Gatling, Locust, or Artillery, and every component in your stack (database, cache, queue, and so on) is monitored in at least one scenario.

## What Claude asks for

The component or journey under test, and at least one traffic figure (normal or peak load). Stack, SLA targets, and tool choice are inferred if missing and flagged `(assumed — verify)`.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/performance-test-case-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
