---
name: usability-test-case-generator
description: >
  Generates comprehensive Usability Test Case Documents (task-based scenarios for moderated or
  unmoderated user testing) in markdown table format, from a Jira ticket, feature spec, design
  file, or user flow description. Use when the user asks to generate usability test cases, build
  a usability testing plan or script, design task scenarios for user research, or validate UX
  heuristics for a feature. Trigger for "create usability test cases for X", "usability testing
  script for this flow", "task scenarios for user testing", "usability study plan from this Jira
  ticket", or "test the usability of this feature." Distinct from functional/QA test case
  generation (pass/fail vs. acceptance criteria) — this assesses how real users experience,
  navigate, and succeed or struggle with a flow. Trigger on mentions of usability testing, user
  research, task success, UX heuristics, SUS scores, or moderated/unmoderated sessions.
---

# Usability Test Case Document Generation Skill

## Purpose

Generate a comprehensive Usability Test Case Document in markdown table format, designed to be run with real users (moderated or unmoderated) to evaluate how easily they can understand, navigate, and complete tasks within a feature or flow — not whether the system functionally works.

## How This Differs From Functional/QA Test Cases

| Functional Test Cases | Usability Test Cases |
|---|---|
| Verify the system behaves correctly against acceptance criteria | Verify a real user can understand and complete a task without confusion |
| Pass/Fail based on expected output | Task Success rated on a scale (Success / Success with difficulty / Failure), plus qualitative observation |
| Written for QA engineers or automation | Written for moderators running sessions with participants, or for unmoderated tools (e.g. UserTesting, Maze) |
| Focus: correctness, edge cases, security | Focus: discoverability, clarity, cognitive load, error recovery, satisfaction, accessibility |
| Inputs: exact data values | Inputs: realistic scenario framing (a "story" the participant is given, not literal steps) |

If the user actually wants functional/QA test cases (pass/fail against acceptance criteria), point them to a functional test case generator instead and confirm before proceeding.

## Workflow: Three Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

> See [PHASE1_GUIDE.md](../shared/PHASE1_GUIDE.md) for common validation rules, multi-item detection, inference flagging, and file path conventions.

Before generating any output, you MUST validate the following. If any item is missing or unclear, ask the specified question and wait for the user's answer.

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Feature / Jira Ticket | Yes | Must include title, description, and ticket ID (or feature name if no ticket) | "Please provide the Jira ticket ID and title, or a description of the feature/flow being tested." |
| User Flow / Tasks Involved | Yes | The sequence of screens or actions a user would take | "What are the key tasks a user needs to accomplish in this flow? (e.g. 'find and apply a discount code', 'update billing address')" |
| Target User / Persona | Yes | Who is being tested — new vs. returning user, technical proficiency, role | "Who is the target participant for this test? (e.g. first-time user, power user, accessibility-focused participant)" |
| Testing Mode | Yes | Moderated (live, with facilitator) vs. Unmoderated (self-guided, e.g. via UserTesting/Maze) | "Will this be moderated (live facilitator) or unmoderated (self-guided) testing?" |
| Success Criteria / Goals | Yes | What "success" looks like for each task — should be observable, not just functional | "What does success look like for each task? (e.g. completed without help, completed in under X minutes, found the feature without searching)" |
| Known UX Risks or Heuristics to Probe | Detect | Note if the user flags specific concerns (e.g. "we're worried about the checkout flow being confusing") | Not required; proceed with general heuristic coverage if not specified |
| Multiple Flows/Features | Detect | Scan input for multiple distinct flows or features | "I detected multiple flows/features. Do you want: (A) One test plan covering all flows, or (B) Separate test case documents per flow?" |
| Screenshots / Prototype Link | Detect | Note whether a design file, prototype, or staging link exists | Not required; proceed with TBD if missing |

**Mandatory Rule:** If all required items are clearly present in the user's message, proceed directly to Phase 2. Flag inferred values in the Comments column rather than asking for confirmation.

### PHASE 2: Generate and Write Table (Only After Phase 1 Completes)

Build all rows following the structure and rules below. **Do NOT echo the table to chat.**
Write directly to a temp file in the session scratchpad directory using the Write tool — never use `/tmp/` or other system temp paths. Confirm with: "✓ N scenarios written — running converter..."

### PHASE 3: Convert Markdown Table to XLSX (Only After Phase 2 Completes)

1. Call the shared converter script — do **not** write ad-hoc openpyxl code for this step:
   ```bash
   python3 .claude/skills/shared/md_table_to_xlsx.py <scratchpad>/usability-tests-<feature-slug>.md <output>/<feature-slug>-usability-tests.xlsx
   ```
   Replace `<scratchpad>` with the session scratchpad path from your system context. For `<output>`, use `/mnt/user-data/outputs` on Claude.ai or `./outputs` when running locally.
   This is the same shared script all test-generation skills call — never copy it into this
   skill's own folder.
2. Confirm the script printed `"status": "success"`. If it errors, check that the temp file
   contains valid pipe-delimited markdown table syntax, fix if needed, and re-run.
3. Tell the user the full output path and confirm the file is ready to open in Excel or import into Google Sheets. State the path in a single line — no preamble, no trailing summary.

## Table Structure and Column Rules

**Exactly 15 columns, in this order:**

| Test Case ID | Task Scenario | Participant Instructions | Persona / User Type | Prerequisites | Success Criteria | UX Focus Area | Observed Behavior | Task Success Rating | Severity (if issue found) | Time on Task | Participant Quote / Feedback | Comments | References | Screenshot / Evidence |

**One row per task scenario. For multi-line content within a cell (e.g. multiple success criteria), use `\n` — the shared converter renders these as line breaks in Excel.**

## Column Format Reference

| Column | Format Rule | Examples | Default/Placeholder |
|--------|-------------|----------|---------------------|
| Test Case ID | UT-\<JIRA-ID\>-\<NNN\> where NNN is 001, 002, etc. | UT-PROJ-456-001 | N/A (required) |
| Task Scenario | A short label naming the task being evaluated | "Resetting a forgotten password" | N/A (required) |
| Participant Instructions | Written as a realistic scenario/story given to the participant — NOT step-by-step UI instructions. Should not reveal the path to success. | "You forgot your password and need to get back into your account. Show me what you'd do." | N/A (required) |
| Persona / User Type | Which target persona this scenario is run with | "First-time user, low technical proficiency" | "General user" if unspecified |
| Prerequisites | Setup needed before the session (test account state, prototype link, seeded data) | "Test account exists with a known but unrevealed password" | "None" if not applicable |
| Success Criteria | Observable, specific definition of success for this task — avoid functional pass/fail phrasing | "Participant locates reset flow without prompting and receives confirmation screen within 2 minutes" | N/A (required) |
| UX Focus Area | One or more heuristics/dimensions this task probes; pick from: Discoverability, Navigation/IA, Clarity of Language, Error Recovery, Feedback/System Status, Cognitive Load, Accessibility, Trust/Confidence, Satisfaction, Efficiency | "Discoverability, Error Recovery" | N/A (required) |
| Observed Behavior | (leave blank for initial generation; filled in during/after session) | (empty until session is run) | "TBD" (placeholder) |
| Task Success Rating | Exactly one of: `Not Run` \| `Success` \| `Success with Difficulty` \| `Failure` \| `Abandoned` | "Not Run" | "Not Run" (default) |
| Severity (if issue found) | Exactly one of: `N/A` \| `Low` \| `Medium` \| `High` \| `Critical` — rate the UX impact if an issue is observed, not before | "N/A" until observed | "N/A" (placeholder) |
| Time on Task | Actual or target time; leave as target until session is run | "Target: under 2 min" or actual "1m 47s" | "TBD" |
| Participant Quote / Feedback | Leave blank for initial generation; capture verbatim (short) participant reactions during sessions | "\"I expected this to be under Settings, not Profile.\"" | (empty until session run) |
| Comments | Notes about the task; include inferred assumptions, moderator guidance, or probing follow-up questions | "Ask follow-up: 'What did you expect to happen here?' if hesitation observed" | (optional; use only if needed) |
| References | Links to related Jira ticket, design file, prototype, or heuristic framework cited | "PROJ-456, Figma link, Nielsen Heuristic #1" | (optional; leave blank if none) |
| Screenshot / Evidence | Filename, link, or placeholder for design reference or session recording | "prototype-flow-01.png" or "TBD" or "Not attached - checkout mockup" | "TBD" (if none provided) |

## Test Case Coverage Rules (Mandatory)

You must generate between 5 and 15 task scenarios per flow/feature (fewer, deeper scenarios are preferred over many shallow ones — usability sessions are typically time-boxed to 30-60 minutes per participant, and 5-8 tasks is often the realistic ceiling). Ensure coverage across:

- **Always include:** At least 1 first-touch/discoverability task (can the user find the entry point unaided), 1 core happy-path task completion, 1 error-recovery task (user makes a mistake or hits an error state and must recover)
- **If the flow involves forms, multi-step processes, or irreversible actions:** Include at least 1 task probing confirmation/trust (does the user feel confident the action succeeded or understand consequences before committing)
- **If the flow has any visual hierarchy, dense content, or competing CTAs:** Include at least 1 task probing cognitive load or visual clarity
- **If accessibility was flagged as a concern, or the target persona includes assistive-tech users:** Include at least 1 accessibility-focused task (keyboard navigation, screen reader, color contrast dependent action)
- **Coverage rule:** At least 1 task scenario per major flow/screen identified in Phase 1
- **End-of-session addition:** Always add one final row of type "Post-Task Survey" capturing overall satisfaction (e.g. SEQ or SUS-style question) rather than a specific task — use the same table structure, with Task Scenario = "Overall flow satisfaction" and Participant Instructions describing the survey prompt

## Writing Good Participant Instructions (Critical)

Participant instructions are the most failure-prone part of this document. Common mistakes to avoid:

- **Don't reveal the path.** Bad: "Click on Settings, then Security, then Reset Password." Good: "You forgot your password and need to get back into your account."
- **Don't use the feature's internal name if a real user wouldn't know it.** Bad: "Use the Bulk Action Drawer to archive 3 items." Good: "You have a few old messages you want to get rid of. Go ahead and do that."
- **Frame as a goal or motivation, not a UI action.** This keeps the test measuring usability rather than just observing compliance with instructions.
- **Keep it short.** One to three sentences. Long instructions do the user's thinking for them.

## Error Handling & Edge Cases

### Handling Incomplete or Conflicting Success Criteria
If success criteria are unclear or conflict after Phase 1:
- List the conflicts explicitly
- Ask the user: "Should I infer reasonable success criteria and proceed (flagging assumptions in Comments), or do you want to clarify first?"
- Only proceed if the user agrees; flag all inferred details in the Comments column

### Handling Screenshots / Prototypes
- If a design file or prototype link is provided: use it in the "Screenshot / Evidence" cell
- If none provided: use "TBD"
- If described but not attached: use "Not attached - [description]"

### Handling Multiple Flows/Features
- Default behavior: process only the primary flow
- If multiple distinct flows are detected: ask the user to choose (one document vs. separate documents per flow)

### Handling Moderated vs. Unmoderated Mode
- **Moderated:** Comments column may include moderator probing questions and think-aloud prompts ("Ask: 'What are you thinking right now?'")
- **Unmoderated:** Participant Instructions must be fully self-contained (no moderator available to clarify), and Comments should flag any step at risk of confusing a participant with no one to ask

