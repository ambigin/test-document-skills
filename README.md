# Test Document Skills

A comprehensive collection of AI-powered skills for generating production-ready test documentation and QA artifacts. This repository contains reusable skills integrated with GitHub Copilot that accelerate QA workflows by automating the creation of structured test cases, test data, performance test plans, security assessments, and bug reports.

## Overview

Test Document Skills provides seven specialized skills designed to help QA engineers, developers, and product teams generate comprehensive, execution-ready test documentation in minutes instead of hours. All outputs are delivered in markdown table format, ready to copy-paste into Postman, Jira, Excel, or your preferred testing tools.

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

**Output**: Single markdown table, copy-paste ready for Postman or Jira

**Triggers**: "Generate test cases for this endpoint", "Write API tests for X", "QA this API"

---

### 2. **Test Case Generator** (`test-case-generator`)
Generates comprehensive functional test case documents from Jira tickets and acceptance criteria:
- Maps acceptance criteria to executable test scenarios
- Covers positive, negative, and edge cases
- Includes preconditions, steps, and expected results
- Supports multiple tickets with separate test matrices

**Output**: Markdown table format, suitable for Excel or Jira

**Triggers**: "Create test cases for X", "Generate test cases from this Jira ticket", "Design test scenarios for this feature"

---

### 3. **Test Data Generator** (`test-data-generator`)
Generates comprehensive, Excel-ready test data documents for data validation and QA:
- Covers all data quality categories (valid, boundary, invalid, edge cases)
- Domain-aware field coverage (registration, checkout, ETL, onboarding)
- Includes validation rules and field constraints
- 50+ rows per output for thorough coverage

**Output**: Markdown table, directly importable to Excel

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

**Output**: Executable markdown table (no exploit code required; uses browser UI, DevTools, or Burp Suite)

**Triggers**: "Generate security test cases for X", "Security QA this feature", "OWASP test this screen"

---

### 5. **Bug Report Generator** (`bug-report-generator`)
Transforms unstructured QA observations into developer-ready bug reports:
- Structured format with title, reproduction steps, and environment
- Automatic root cause hypothesis generation
- Impact assessment & priority guidance
- Clear suggested fix direction

**Output**: Complete, actionable bug report

**Triggers**: Used when raw QA observations need professional formatting

---

### 6. **Performance Testing** (`performance-testing`)
Generates complete, execution-ready performance and load test suites:
- Load, stress, spike, and soak/endurance testing scenarios
- Scalability and concurrency/contention tests
- Recovery and failover testing
- Hard SLA pass/fail boundaries
- Tool-ready config stubs for k6, JMeter, Gatling, Locust, and Artillery

**Output**: Markdown table with traffic profiles and script templates

**Triggers**: "Design a load test for X", "Performance test this endpoint", "Stress test plan for Y"

---

### 7. **Usability Test Case Generator** (`usability-test-case-generator`)
Generates task-based usability test scenarios for user research:
- Designed for moderated or unmoderated testing
- Real user workflow validation
- UX heuristics & success metrics
- Measures task completion and user satisfaction (SUS scores)

**Output**: Markdown table, execution-ready for user testing

**Triggers**: "Create usability test cases for X", "Usability testing script for this flow", "Task scenarios for user testing"

---

## Project Structure

```
Test Document Skills/
├── README.md                                    # This file
rules
└── .claude/
    └── skills/
        ├── api-test-case-generator/SKILL.md     # API testing skill
        ├── test-case-generator/SKILL.md          # Functional testing skill
        ├── test-data-generator/SKILL.md          # Test data skill
        ├── security-test-case-generator/SKILL.md # Security testing skill
        ├── bug-report-generator/SKILL.md         # Bug reporting skill
        ├── performance-testing/SKILL.md          # Performance testing skill
        └── usability-test-case-generator/SKILL.md# Usability testing skill
```

## How to Use

### Prerequisites
- GitHub Copilot Chat integrated in your IDE (VS Code, JetBrains, etc.)
- This repository is cloned or accessible in your workspace

### Basic Workflow

1. **Activate a Skill**: Ask Copilot to perform a task that matches a skill's trigger (e.g., "Generate test cases for this API endpoint")

2. **Provide Context**: Copilot will ask clarifying questions if needed. Provide:
   - API spec, Jira ticket, feature description, or raw observation
   - Acceptance criteria, requirements, or test focus
   - Any screenshots, logs, or additional evidence

3. **Receive Output**: Get a production-ready markdown table covering all test scenarios

4. **Copy & Use**: Paste the output directly into:
   - **Postman** (API test cases)
   - **Jira** (test case tracking)
   - **Excel** (test data & general documentation)
   - **Your test management tool**

### Example: Generate API Test Cases

```
You: Generate test cases for this endpoint:
POST /api/users/register
Headers: Content-Type: application/json
Body: { email, password, name, dob }
Response: 201 Created or 400 Bad Request
Auth: Public (no auth required)

Copilot: [Gathers info, generates 15+ test scenarios covering auth, validation, edge cases, security, and performance]
```

## Output Formats

All skills produce **markdown tables** designed for easy consumption:

- **Markdown tables**: Copy directly into documentation or wiki platforms
- **Excel import**: All tables are Excel-compatible
- **Jira format**: Paste into Jira descriptions or custom fields
- **Postman import**: API test cases can populate Postman Collections

## Key Features

✅ **Production-ready**: Every output is execution-ready with minimal tweaks  
✅ **Comprehensive coverage**: Covers functional, non-functional, security, and edge cases  
✅ **Domain-aware**: Tailors outputs to your system (banking, e-commerce, healthcare, etc.)  
✅ **Tool-agnostic**: Works with Postman, Jira, Excel, k6, JMeter, Gatling, and more  
✅ **Contextual**: Asks smart questions if inputs are missing; makes reasonable assumptions otherwise  
✅ **Fast**: Generates hours of QA work in minutes  

## Integration with GitHub Copilot

These skills are designed to work seamlessly with GitHub Copilot Chat. The `.claude/skills/` directory structure allows Copilot to discover and invoke the appropriate skill based on your request.

### Skill Discovery
Copilot automatically:
- Detects skill names and descriptions from SKILL.md frontmatter
- Suggests relevant skills based on your message intent
- Routes requests to the most appropriate skill handler

## Contributing

To extend this repository with new skills:

1. Create a new directory under `.claude/skills/skill-name/`
2. Add a `SKILL.md` file with:
   - YAML frontmatter (name, description)
   - Clear purpose and workflow
   - Input validation rules
   - Output format specifications
3. Update this README with the new skill

## Support

For questions or issues:
- Review the individual SKILL.md files for detailed documentation
- Refer to Copilot's built-in help for integration issues

---

**Last Updated**: June 2026  
**Skills Available**: 7 (API Testing, Functional Testing, Test Data, Security, Bug Reports, Performance, Usability)
