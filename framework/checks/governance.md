# Governance principles

Every task is validated against these principles. The framework records the
result per task in specs/changes/<task>/validation.md.

| id | principle | how it is checked |
|---|---|---|
| G-01 | The page is always in Russian: `<html lang="ru">`, all visible text in Russian (brand names may stay in Latin script). | automated: governance test (lang attribute, share of Cyrillic letters in visible text >= 80%) |
| G-02 | No external frameworks, scripts or stylesheets: plain HTML/CSS/JS served from the repository. | automated: no `<script src>` / `<link href>` pointing to another host |
| G-03 | Every scenario of the task's delta spec has an automated test, and it passes. | automated: each `#### Scenario:` of the delta has a passing test titled `<task id>: <scenario>` |
| G-04 | Existing behaviour keeps working. | automated: all tests of earlier tasks pass (regression) |
| G-05 | Spec before code: the delta spec is written before implementation and merged into the master spec after it. | automated: delta spec present at validation; master names the task after merge |
