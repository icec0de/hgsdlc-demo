# T-0005 validation

verdict: **passed** · tests 4/4 passed · validated 2026-09-23T12:31:14Z

Principles from specs/governance.md, checked by the framework (not by the AI).

| id | principle | result | evidence |
|---|---|---|---|
| G-01 | The page is always in Russian: `<html lang="ru">`, all visible text in Russian (brand names may stay in Latin script). | ✅ pass | governance test passed: lang="ru", visible text is Russian |
| G-02 | No external frameworks, scripts or stylesheets: plain HTML/CSS/JS served from the repository. | ✅ pass | no <script>/<link> pointing to another host |
| G-03 | Every scenario of the task's delta spec has an automated test, and it passes. | ✅ pass | 3/3 scenarios have a passing test in tests/T-0005.spec.js |
| G-04 | Existing behaviour keeps working. | ✅ pass | no earlier tests yet |
| G-05 | Spec before code: the delta spec is written before implementation and merged into the master spec after it. | ✅ pass | delta spec specs/changes/T-0005/delta.md present before merge |

## Tests

- ✅ T-0005: Phone button displayed next to main button (T-0005.spec.js)
- ✅ T-0005: Phone number shown after click (T-0005.spec.js)
- ✅ T-0005: Phone number hidden before click (T-0005.spec.js)
- ✅ G-01: page language is Russian (governance.spec.js)
