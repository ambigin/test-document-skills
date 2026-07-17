---
name: bug-report-generator
description: >
  Generates a complete, developer-ready bug report from unstructured QA observations, logs, and
  evidence. Use this skill when the user needs a structured bug report with title, reproduction
  steps, environment, severity/priority, root cause hypothesis, and suggested fix guidance.
  Trigger for requests like "write a bug report for this", "turn this observation into a bug
  report", "I found a bug, can you document it", or "create a Jira-ready bug report from these
  logs". If the user pastes a raw bug observation, console error, stack trace, or screen
  recording description and wants it turned into something a developer can act on, use this
  skill.
---

# Bug Report Generation Skill

## Purpose

Act as a Senior QA Engineer with 10+ years of experience writing developer-ready bug reports.
Transform a raw, unstructured observation into a complete, structured bug report that a developer
can act on immediately — with zero back-and-forth for clarification.

## Workflow: Two Phases (Always Follow This Order)

### PHASE 1: Validate Inputs (Ask Questions First)

Before generating any output, you MUST validate the following. If any item is missing or unclear,
ask the specified question and wait for the user's answer — unless the user has already supplied
enough detail to make a confident, flagged inference (see Mandatory Rule below).

| Item | Required? | Validation Rule | Question to Ask if Missing |
|------|-----------|-----------------|----------------------------|
| Raw Observation | Yes | Must describe what was seen, even informally — grammar/structure don't matter | "Please paste the raw observation, screen recording description, or note describing the bug." |
| Screenshot / Log | Detect | Note whether a screenshot, console error, stack trace, or network response was provided | Not required; proceed with "none provided" if missing |
| Linked Jira / Test Case | Detect | Note the Jira ticket ID or Test Case ID if this bug was found during a specific test run | Not required; proceed with "None" if missing |
| Multiple Distinct Bugs | Detect | Scan input for more than one distinct symptom or failure | "I detected what looks like multiple distinct bugs. Do you want: (A) One combined report, or (B) Separate numbered reports per bug?" |
| Environment Details | Detect | OS, browser, app/API version, test environment, user role | Not required; mark as "(assumed — please verify)" or "Unknown — needs investigation" if missing |

**Mandatory Rule:** Do NOT proceed to Phase 2 until the user confirms all required items are ready,
OR the available detail is sufficient to make a reasonable inference. When inferring, flag every
assumed field inline with "(assumed — please verify)" rather than asking — the goal is zero
back-and-forth, not interrogation. Only stop and ask when the raw observation itself is missing,
ambiguous between multiple bugs, or too thin to support any reasonable inference.

### PHASE 2: Generate the Bug Report (Only After Phase 1 Completes)

Generate exactly one structured bug report per distinct bug, using the format and rules below.
Do not generate the report until Phase 1 is complete.

## Report Structure and Field Rules

**Output this report exactly:**

```
Bug ID:        [Leave blank — to be assigned by Jira on creation]
Title:         [Component › Action › Symptom]

Severity:      [Critical / High / Medium / Low]
Priority:      [P1 / P2 / P3 / P4]
Frequency:     [Always / Intermittent (N of N attempts) / Once]
Status:        Open

Environment:
  - OS & version:         [e.g., Windows 11 22H2 / macOS 14.4 / Android 14]
  - Browser & version:    [e.g., Chrome 124.0.6367 / Safari 17.4 / N/A for native app]
  - App / API version:    [e.g., v2.3.1-staging / build #4821]
  - Test environment:     [Dev / Staging / UAT / Production]
  - User role / account:  [e.g., Admin user with MFA enabled / Guest checkout]

Steps to Reproduce:
  1. [Start from a clean, described state — e.g., "Log in as a standard user with a non-empty cart"]
  2.
  3.
  [Add as many steps as needed. Be explicit about clicks, inputs, and wait conditions.]

Expected Behavior:
  [What the system should do according to requirements, designs, or reasonable user expectation.]

Actual Behavior:
  [What the system actually does. Include exact error text, HTTP status codes, or visual symptoms verbatim.]

Impact:
  [Who is affected and how severely — e.g., "All users attempting checkout on mobile Safari are blocked from completing payment."]

Root Cause Hypothesis:
  [Your best-reasoned guess — e.g., "Race condition between the auth token refresh and the API call triggered on form submit. Token may expire mid-session without triggering a re-auth."]

Suggested Fix / Investigation Starting Point:
  [Point developers toward the most likely code area, config, or service — e.g., "Review the token refresh logic in auth.service.ts and the timing of the /submit-order API call."]

Workaround:
  [Describe any workaround available to end users or testers, or write "None identified."]

Regression Risk:
  [Does fixing this carry a risk of breaking adjacent functionality? Note related areas — e.g., "Changes to the auth flow may affect SSO login and password reset."]

Screenshots / Logs / Evidence:
  [Describe what is attached or paste console errors, stack traces, and network responses verbatim here.]

Linked Test Case:     [TC-ID or "None"]
Linked Jira Ticket:   [Epic / Story ID or "None"]
Reported By:          [Leave blank]
Reported Date:        [Leave blank — auto-filled on Jira creation]
```

## Field Format Reference

| Field | Format Rule | Examples | Default/Placeholder |
|-------|-------------|----------|---------------------|
| Title | Component › Action › Symptom | "Checkout › Place Order › Payment spinner never resolves on slow 3G" | N/A (required) |
| Severity | Exactly one of: `Critical` \| `High` \| `Medium` \| `Low` — see taxonomy below | "High" | N/A (required) |
| Priority | Exactly one of: `P1` \| `P2` \| `P3` \| `P4` — see taxonomy below | "P2" | N/A (required) |
| Frequency | `Always` \| `Intermittent (N of N attempts)` \| `Once` | "Intermittent (3 of 5 attempts)" | N/A (required) |
| Environment fields | Use exact version strings when known | "Chrome 124.0.6367" | "(assumed — please verify)" if inferred; "Unknown — needs investigation" if not |
| Steps to Reproduce | Atomic, deterministic, numbered; one action per step | "1. Click 'Forgot Password'" | Append "(needs verification)" to any step that can't be made fully deterministic |
| Expected/Actual Behavior | Observable system states, not opinions | "the modal closes without saving form data" (not "it doesn't work") | (required) |
| Root Cause Hypothesis | A reasoned guess — never optional | "Race condition between token refresh and submit API call" | (required, even if uncertain) |
| Workaround | Concrete workaround or explicit absence | "Refresh the page and resubmit" | "None identified." |
| Screenshot / Evidence | Description, filename, or verbatim log/stack trace | "console error: TypeError at auth.service.ts:42" | "none provided" |
| Linked Test Case / Jira Ticket | ID or explicit "None" | "TC-104" | "None" |

Do not leave any field blank. Use "Not observed", "Not applicable", or "Unknown — needs
investigation" when data is genuinely unavailable.

## Severity Taxonomy

| Severity | Definition |
|----------|------------|
| Critical | System crash, data loss, security breach, complete feature failure with no workaround |
| High | Core functionality broken, workaround exists but is unreasonable for end users |
| Medium | Non-core functionality broken or degraded, reasonable workaround exists |
| Low | Cosmetic issue, minor UX inconsistency, no functional impact |

## Priority Taxonomy

| Priority | Definition |
|----------|------------|
| P1 | Block release / fix before any other work |
| P2 | Fix in current sprint |
| P3 | Fix in next sprint or upcoming release |
| P4 | Fix when capacity allows / backlog |

Severity and Priority are separate concerns — assign both independently. A Low-severity bug can
still be P1 (e.g., a cosmetic issue on the homepage of a launch-day release), and a Critical bug
found in an unreachable code path may not be P1.

## Frequency Taxonomy

| Frequency | Definition |
|-----------|------------|
| Always | 100% reproducible with the steps provided |
| Intermittent | Reproducible <100% of the time — note observed reproduction rate if known (e.g., "3 of 5 attempts") |
| Once | Observed once, could not reproduce — note exact conditions |

## Error Handling & Edge Cases

### Handling Missing or Ambiguous Observations
If the raw observation is too thin to support any reasonable inference after Phase 1:
- State explicitly what's missing (e.g., no described symptom, no indication of which feature)
- Ask the user for the missing detail before proceeding
- Only proceed once the user supplies it, or explicitly says "proceed with inference" — then flag
  every assumed field with "(assumed — please verify)"

### Handling Screenshots / Logs
- If attached or pasted: transcribe console errors, stack traces, and network responses verbatim
  into "Screenshots / Logs / Evidence"
- If described but not attached: use "Not attached - [description]"
- If unavailable: use "none provided"

### Handling Multiple Distinct Bugs
- Default behavior: if the observation clearly describes more than one distinct symptom or
  failure, ask the user whether they want one combined report or separate numbered reports
- If the user confirms separate reports: produce one full report per bug, clearly numbered
  ("Bug Report 1 of N", "Bug Report 2 of N")
- If the user confirms a combined report: document the primary symptom fully, and note secondary
  symptoms in "Comments"-equivalent context within Impact or Actual Behavior

## Example Invocation

**User Input:**
"On staging, when I try to check out with a saved card on mobile Safari, the payment spinner just spins forever and never resolves. Happened 3 times out of 3 tries. No console errors visible. This was found during TC-104."

**Your Response (Phase 1):**
"I have the raw observation, reproduction rate (3 of 3), and linked test case (TC-104). I don't
have a screenshot/log or full environment details (exact app version, OS version) — I'll mark
those as '(assumed — please verify)' / 'Unknown — needs investigation' where appropriate. Ready
to proceed?"

**After User Confirms (Phase 2):**
Generate the full bug report using the structure above, with Severity/Priority/Frequency assigned
per the taxonomies, Root Cause Hypothesis populated with a reasoned guess, and all environment
fields explicitly marked as assumed or unknown rather than left blank.

## Final Instructions

- Output only the completed bug report(s). Do not add a preamble, summary, or closing remarks once
  Phase 2 begins.
- If the raw observation contains multiple distinct bugs and the user has chosen separate reports,
  produce one per bug, clearly numbered (Bug Report 1 of N, Bug Report 2 of N).
- If steps cannot be made fully deterministic from the observation provided, write the best
  possible steps and append "(needs verification)" to each uncertain step.
- Flag any field where you had to make an assumption rather than omitting it silently.