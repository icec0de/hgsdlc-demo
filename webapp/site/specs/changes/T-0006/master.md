# Web app - master spec

last increment: T-0006

## Requirements
### Requirement: Brand header
The page SHALL display a header at the top of the page containing a logo, the brand name "Supercompany", and the tagline "Финансы для колёс и полей".
#### Scenario: Header displayed
- WHEN the page is loaded
- THEN a header is shown at the top of the page with a logo, the brand name "Supercompany", and the tagline "Финансы для колёс и полей"

### Requirement: Hero section
The page SHALL display a hero section with the heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and an introductory lead paragraph about leasing offers for vehicles and agricultural machinery. The lead paragraph SHALL NOT mention predictable payments (the phrase "предсказуемые платежи" in any form, including "предсказуемые ежемесячные платежи", must not appear).
#### Scenario: Hero content displayed
- WHEN the page is loaded
- THEN the hero heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and the lead paragraph are displayed
#### Scenario: Hero lead free of predictable payments
- WHEN the page is loaded
- THEN the lead paragraph does not contain the phrase "предсказуемые платежи" (including "предсказуемые ежемесячные платежи")

### Requirement: Illustration gallery
The page SHALL display a gallery of two illustration cards with the captions "Автопарк и коммерческий транспорт" and "Сельхозтехника". Each card SHALL contain a visible image (illustration) of the corresponding machinery. The page SHALL NOT display any card, caption, or other text about "Предсказуемые платежи".
#### Scenario: Gallery cards displayed
- WHEN the page is loaded
- THEN two illustration cards are displayed with the captions "Автопарк и коммерческий транспорт" and "Сельхозтехника", and each card contains a visible image (an `<img>` element or an inline SVG) of the corresponding machinery
#### Scenario: Predictable payments card removed
- WHEN the page is loaded
- THEN no card with the caption "Предсказуемые платежи" is displayed, and the text "Предсказуемые платежи" does not appear anywhere on the page

### Requirement: Order action
The page SHALL display an order button labelled "Заказать сейчас"; when the user clicks it, the page SHALL display the message "Спасибо! Ваш заказ уже в пути.".
#### Scenario: Order button displayed
- WHEN the page is loaded
- THEN a button labelled "Заказать сейчас" is displayed
#### Scenario: Order confirmation message
- WHEN the user clicks the "Заказать сейчас" button
- THEN the message "Спасибо! Ваш заказ уже в пути." appears on the page

### Requirement: Phone call action
The page SHALL display a button labelled "Позвонить нам" next to the "Заказать сейчас" button. When the user clicks the "Позвонить нам" button, the page SHALL display the phone number "+7 800 555-35-35" below the buttons.
#### Scenario: Phone button displayed next to main button
- WHEN the page is loaded
- THEN a button labelled "Позвонить нам" is displayed next to the "Заказать сейчас" button
#### Scenario: Phone number shown after click
- WHEN the user clicks the "Позвонить нам" button
- THEN the text "+7 800 555-35-35" appears on the page below the buttons
#### Scenario: Phone number hidden before click
- WHEN the page is loaded
- THEN the text "+7 800 555-35-35" is not displayed on the page

### Requirement: Footer
The page SHALL display a small footer at the bottom of the page containing the text "© 2026 Supercompany".
#### Scenario: Small footer displayed at page bottom
- WHEN the page is loaded
- THEN a small footer is shown at the bottom of the page with the text "© 2026 Supercompany"

## Increments
- T-0000 baseline: added Brand header, Hero section, Illustration gallery, Order action, Footer
- T-0004 Add a small footer: modified Footer
- T-0005 Add a "Позвонить нам" button next to the main button: added Phone call action
- T-0006 Fleet and agricultural machinery images without predictable payments: modified Illustration gallery, Hero section
