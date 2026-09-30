# Usability Test Case Generator

Builds a task-based usability test plan for moderated or unmoderated sessions with real users — measuring how easily people find, understand, and complete tasks, not whether the feature works — delivered as an Excel workbook.

## Use it when

- "Create usability test cases for our new checkout flow — first-time shoppers, moderated sessions."
- "Task scenarios for unmoderated testing of the billing address update."
- "Usability study plan from this Jira ticket."

For functional pass/fail test cases, use `test-case-generator`.

## What you get

`<feature-slug>-usability-tests.xlsx`, saved to `./outputs/` locally (`/mnt/user-data/outputs/` on Claude.ai).

Each row is one task scenario, with 15 columns: Test Case ID, Task Scenario, Participant Instructions, Persona / User Type, Prerequisites, Success Criteria, UX Focus Area, Observed Behavior, Task Success Rating, Severity (if issue found), Time on Task, Participant Quote / Feedback, Comments, References, Screenshot / Evidence.

It generates 5–15 scenarios: always a discoverability task, a core happy-path task, and an error-recovery task, plus a closing satisfaction-survey row. Participant instructions are written as realistic goals that don't give away the path. Session columns (Observed Behavior, Time on Task, participant quotes) are left for the moderator to fill in.

## What Claude asks for

The feature or ticket, the key tasks, the target participant, whether sessions are moderated or unmoderated, and what success looks like for each task.

## Requirements

Python 3.8 or later with `openpyxl` (`pip install openpyxl`). The bundled converter uses it to build the workbook.

## Install

Copy this folder into `~/.claude/skills/` (available in all your projects) or into `<your-project>/.claude/skills/` (shared with your team through that repo). Then describe your task, or run `/usability-test-case-generator`.

## Optional: project context

Copy `assets/PROJECT_CONTEXT.md` to the root of the project you're testing and fill it in. The skill reads it before asking questions, so you don't have to repeat product details, user roles, or domain terms each time.

## Files

| Path | What it is |
|---|---|
| `SKILL.md` | The instructions Claude follows |
| `references/PHASE1_GUIDE.md` | Rules shared by all the QA skills: project context, when to ask vs. infer, table formatting, converter errors |
| `scripts/md_table_to_xlsx.py` | Converts the generated markdown table into the `.xlsx` workbook |
| `assets/PROJECT_CONTEXT.md` | Blank project-context template |
