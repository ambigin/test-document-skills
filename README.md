# Test Document Skills

A comprehensive collection of AI-powered skills for generating production-ready test documentation and QA artifacts. This repository contains reusable skills integrated with Claude Code and GitHub Copilot that accelerate QA workflows by automating the creation of structured test cases, test data, performance test plans, security assessments, and bug reports.

## Overview

Test Document Skills provides seven specialized skills designed to help QA engineers, developers, and product teams generate comprehensive, execution-ready test documentation in minutes instead of hours. Every skill follows a unified three-phase workflow:

1. **Phase 1 — Validate Inputs**: Gather required context, infer reasonable defaults, flag assumptions.
2. **Phase 2 — Generate Markdown Table**: Output a structured markdown table in chat, ready to paste into Jira, Confluence, or Excel. Also writes the table to a temp file.
3. **Phase 3 — Convert to XLSX**: Calls the shared `md_table_to_xlsx.py` converter to produce a downloadable `.xlsx` workbook from the markdown temp file.

This means every skill delivers **two artifacts**: a readable in-chat table and a downloadable Excel workbook.

## Skills Included

### 1. **API Test Case Generator** (`api-test-case-generator`)
Generates complete, execution-ready API test suites for REST and GraphQL endpoints covering:
- Authentication & authorization validation
- Request/response contract testing
- Business logic scenarios
- Error handling & edge cases
- Idempotency testing
- Rate limiting & performance
- Security payload validation

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Generate test cases for this endpoint", "Write API tests for X", "QA this API"

---

### 2. **Test Case Generator** (`test-case-generator`)
Generates comprehensive functional test case documents from Jira tickets and acceptance criteria:
- Maps acceptance criteria to executable test scenarios
- Covers positive, negative, and edge cases
- Includes preconditions, steps, and expected results
- Supports multiple tickets with separate test matrices
- Includes a Summary sheet with coverage mapping

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Create test cases for X", "Generate test cases from this Jira ticket", "Design test scenarios for this feature"

---

### 3. **Test Data Generator** (`test-data-generator`)
Generates comprehensive, Excel-ready test data documents for data validation and QA:
- Covers all data quality categories (valid, boundary, invalid, edge cases)
- Domain-aware field coverage (registration, checkout, ETL, onboarding)
- Includes validation rules and field constraints
- 50+ rows per output for thorough coverage

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Give me test data for X", "Help me test this form", "I need data to test my API"

---

### 4. **Security Test Case Generator** (`security-test-case-generator`)
Generates OWASP-aligned security test case suites for web features:
- Injection attack scenarios
- Authentication & session testing
- Access control & IDOR vulnerability checks
- Sensitive data exposure validation
- Business logic flaws
- File upload security
- CSRF, clickjacking, & security headers

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Generate security test cases for X", "Security QA this feature", "OWASP test this screen"

---

### 5. **Bug Report Generator** (`bug-report-generator`)
Transforms unstructured QA observations into developer-ready bug reports:
- Structured Section/Field/Value format covering all six report sections
- Automatic root cause hypothesis generation
- Impact assessment & priority guidance
- Clear suggested fix direction
- One sheet per bug for multi-bug workbooks

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Write a bug report for this", "Turn this observation into a bug report", "Create a Jira-ready bug report from these logs"

---

### 6. **Performance Test Case Generator** (`performance-test-case-generator`)
Generates complete, execution-ready performance and load test suites:
- Load, stress, spike, and soak/endurance testing scenarios
- Scalability and concurrency/contention tests
- Recovery and failover testing
- Hard SLA pass/fail boundaries
- Tool-ready config stubs for k6, JMeter, Gatling, Locust, and Artillery

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Design a load test for X", "Performance test this endpoint", "Stress test plan for Y"

---

### 7. **Usability Test Case Generator** (`usability-test-case-generator`)
Generates task-based usability test scenarios for user research:
- Designed for moderated or unmoderated testing
- Real user workflow validation
- UX heuristics & success metrics
- Measures task completion and user satisfaction (SUS scores)

**Output**: Markdown table (in chat) + XLSX workbook (via shared converter)

**Triggers**: "Create usability test cases for X", "Usability testing script for this flow", "Task scenarios for user testing"

---

## Project Structure

```
Test Document Skills/
├── README.md                                          # This file
├── qa_skills_documentation.md                         # Skills reference (Markdown format)
└── .claude/
    └── skills/
        ├── shared/
        │   └── md_table_to_xlsx.py                   # Shared markdown-to-XLSX converter
        ├── api-test-case-generator/SKILL.md           # API testing skill
        ├── test-case-generator/SKILL.md               # Functional testing skill
        ├── test-data-generator/SKILL.md               # Test data skill
        ├── security-test-case-generator/SKILL.md      # Security testing skill
        ├── bug-report-generator/SKILL.md              # Bug reporting skill
        ├── performance-test-case-generator/SKILL.md   # Performance testing skill
        └── usability-test-case-generator/SKILL.md    # Usability testing skill
```

## Shared Converter Script

All seven skills use the same shared converter: `.claude/skills/shared/md_table_to_xlsx.py`.

**What it does:**
- Parses one or more pipe-delimited markdown tables from a `.md` file
- Supports multiple sheets via `## Sheet: <name>` headings before each table
- Writes a formatted `.xlsx` workbook using `openpyxl` (frozen header row, bold headers, alternating row colors, auto-width columns, wrapped text)
- Prints `{"status": "success", "file": "..."}` on success or `{"status": "error", "message": "..."}` on failure

**Usage:**
```bash
# Install dependency (one-time)
pip install openpyxl

# Single-table conversion
python .claude/skills/shared/md_table_to_xlsx.py input.md output.xlsx

# Multi-sheet (input.md contains ## Sheet: headings)
python .claude/skills/shared/md_table_to_xlsx.py multi-sheet.md output.xlsx
```

**Prerequisites:**
```bash
pip install openpyxl
```

## How to Use

### Prerequisites
- Claude Code CLI or GitHub Copilot Chat integrated in your IDE (VS Code, JetBrains, etc.)
- Python 3.10+ with `openpyxl` installed (`pip install openpyxl`)
- This repository cloned or accessible in your workspace

### Basic Workflow

1. **Activate a Skill**: Ask Claude to perform a task that matches a skill's trigger (e.g., "Generate test cases for this API endpoint")

2. **Provide Context**: Claude will ask clarifying questions if needed. Provide:
   - API spec, Jira ticket, feature description, or raw observation
   - Acceptance criteria, requirements, or test focus
   - Any screenshots, logs, or additional evidence

3. **Receive Markdown Table**: Get a production-ready markdown table in chat — copy-paste ready for Jira, Confluence, or Excel

4. **Receive XLSX Workbook**: The same content is automatically converted to a downloadable `.xlsx` file via `md_table_to_xlsx.py`

### Example: Generate API Test Cases

```
You: Generate test cases for this endpoint:
POST /api/users/register
Headers: Content-Type: application/json
Body: { email, password, name, dob }
Response: 201 Created or 400 Bad Request
Auth: Public (no auth required)

Claude: [Gathers info, generates 15+ test scenarios as a markdown table, then converts to XLSX]
```

## Output Formats

Every skill produces **both** of the following:

- **Markdown table** (in chat): Pipe-delimited, copy-paste ready for Jira descriptions, Confluence, or Excel import
- **XLSX workbook** (file output): Formatted spreadsheet with frozen header, auto-width columns, and alternating row colors — ready to open in Excel or Google Sheets

## Key Features

✅ **Unified output pattern**: Every skill produces a markdown table + XLSX workbook  
✅ **Production-ready**: Every output is execution-ready with minimal tweaks  
✅ **Comprehensive coverage**: Covers functional, non-functional, security, and edge cases  
✅ **Domain-aware**: Tailors outputs to your system (banking, e-commerce, healthcare, etc.)  
✅ **Tool-agnostic**: Works with Postman, Jira, Excel, k6, JMeter, Gatling, and more  
✅ **Contextual**: Asks smart questions if inputs are missing; makes reasonable assumptions otherwise  
✅ **Fast**: Generates hours of QA work in minutes  

## Integration with GitHub Copilot / Claude Code

These skills are designed to work seamlessly with Claude Code and GitHub Copilot Chat. The `.claude/skills/` directory structure allows the AI to discover and invoke the appropriate skill based on your request.

### Skill Discovery
Claude automatically:
- Detects skill names and descriptions from SKILL.md frontmatter
- Suggests relevant skills based on your message intent
- Routes requests to the most appropriate skill handler

## Contributing

To extend this repository with new skills:

1. Create a new directory under `.claude/skills/skill-name/`
2. Add a `SKILL.md` file with:
   - YAML frontmatter (name, description)
   - Clear purpose and workflow (three phases: Validate → Generate Markdown Table → Convert to XLSX)
   - Input validation rules
   - Table structure specifications
3. Phase 3 should always call `.claude/skills/shared/md_table_to_xlsx.py` — do not add skill-specific XLSX code
4. Update this README with the new skill

## License

[Add your license here]

## Support

For questions or issues:
- Review the individual SKILL.md files for detailed documentation
- Run `python .claude/skills/shared/md_table_to_xlsx.py --help` for converter usage
- [Add your contact or support channel here]

---

**Last Updated**: August 2026  
**Skills Available**: 7 (API Testing, Functional Testing, Test Data, Security, Bug Reports, Performance, Usability)
