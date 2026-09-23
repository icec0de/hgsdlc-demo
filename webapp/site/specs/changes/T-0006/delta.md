# T-0006 Fleet and agricultural machinery images without predictable payments

task: Я бы хотел, чтобы на экране сайта визитки были картинки для автопарка и коммерческого транспорта, а также для сельхозтехники. Я не хочу ничего про предсказуемые платежи
reporter: AA, requested: 2026-09-23T12:59:00.000Z

## MODIFIED Requirements
### Requirement: Illustration gallery
The page SHALL display a gallery of two illustration cards with the captions "Автопарк и коммерческий транспорт" and "Сельхозтехника". Each card SHALL contain a visible image (illustration) of the corresponding machinery. The page SHALL NOT display any card, caption, or other text about "Предсказуемые платежи".
#### Scenario: Gallery cards displayed
- WHEN the page is loaded
- THEN two illustration cards are displayed with the captions "Автопарк и коммерческий транспорт" and "Сельхозтехника", and each card contains a visible image (an `<img>` element or an inline SVG) of the corresponding machinery
#### Scenario: Predictable payments card removed
- WHEN the page is loaded
- THEN no card with the caption "Предсказуемые платежи" is displayed, and the text "Предсказуемые платежи" does not appear anywhere on the page

### Requirement: Hero section
The page SHALL display a hero section with the heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and an introductory lead paragraph about leasing offers for vehicles and agricultural machinery. The lead paragraph SHALL NOT mention predictable payments (the phrase "предсказуемые платежи" in any form, including "предсказуемые ежемесячные платежи", must not appear).
#### Scenario: Hero content displayed
- WHEN the page is loaded
- THEN the hero heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and the lead paragraph are displayed
#### Scenario: Hero lead free of predictable payments
- WHEN the page is loaded
- THEN the lead paragraph does not contain the phrase "предсказуемые платежи" (including "предсказуемые ежемесячные платежи")