# T-0006 validation

verdict: **passed** · tests 8/8 passed · validated 2026-09-23T13:11:10Z

Principles from specs/governance.md, checked by the framework (not by the AI).

| id | principle | result | evidence |
|---|---|---|---|
| G-01 | The page is always in Russian: `<html lang="ru">`, all visible text in Russian (brand names may stay in Latin script). | ✅ pass | governance test passed: lang="ru", visible text is Russian |
| G-02 | No external frameworks, scripts or stylesheets: plain HTML/CSS/JS served from the repository. | ✅ pass | no <script>/<link> pointing to another host |
| G-03 | Every scenario of the task's delta spec has an automated test, and it passes. | ✅ pass | 4/4 scenarios have a passing test in tests/T-0006.spec.js |
| G-04 | Existing behaviour keeps working. | ✅ pass | 3/3 tests of earlier tasks pass |
| G-05 | Spec before code: the delta spec is written before implementation and merged into the master spec after it. | ✅ pass | delta spec specs/changes/T-0006/delta.md present before merge |

## Tests

- ✅ T-0005: Phone button displayed next to main button (T-0005.spec.js)
- ✅ T-0005: Phone number shown after click (T-0005.spec.js)
- ✅ T-0005: Phone number hidden before click (T-0005.spec.js)
- ✅ T-0006: Gallery cards displayed (T-0006.spec.js)
- ✅ T-0006: Predictable payments card removed (T-0006.spec.js)
- ✅ T-0006: Hero content displayed (T-0006.spec.js)
- ✅ T-0006: Hero lead free of predictable payments (T-0006.spec.js)
- ✅ G-01: page language is Russian (governance.spec.js)
