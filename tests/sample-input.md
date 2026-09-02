## Sheet: Test Cases

| Test Case ID | Test Case Name | Test Steps | Expected Result | Status |
|---|---|---|---|---|
| TC-001 | Happy path login | 1. Open /login\n2. Enter valid email\n3. Enter valid password\n4. Click Submit | User is redirected to dashboard | Not Executed |
| TC-002 | Login with wrong password | 1. Open /login\n2. Enter valid email\n3. Enter wrong password\n4. Click Submit | Error message "Invalid credentials" shown | Not Executed |
| TC-003 | Login with empty email | 1. Open /login\n2. Leave email blank\n3. Enter any password\n4. Click Submit | Inline validation error on email field | Not Executed |

## Sheet: Summary

| Category | Count |
|---|---|
| Total Test Cases | 3 |
| Positive Flow | 1 |
| Negative Flow | 2 |

| Acceptance Criterion | Covered By |
|---|---|
| User can log in with valid credentials | TC-001 |
| Invalid credentials show an error | TC-002 |
| Empty email is rejected client-side | TC-003 |
