# Web app - master spec

last increment: T-0004

## Requirements
### Requirement: Brand header
The page SHALL display a header at the top of the page containing a logo, the brand name "Supercompany", and the tagline "Финансы для колёс и полей".
#### Scenario: Header displayed
- WHEN the page is loaded
- THEN a header is shown at the top of the page with a logo, the brand name "Supercompany", and the tagline "Финансы для колёс и полей"

### Requirement: Hero section
The page SHALL display a hero section with the heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and an introductory lead paragraph about leasing offers for vehicles and agricultural machinery.
#### Scenario: Hero content displayed
- WHEN the page is loaded
- THEN the hero heading "Лизинговые решения для автомобильной и агропромышленной отраслей" and the lead paragraph are displayed

### Requirement: Illustration gallery
The page SHALL display a gallery of three illustration cards with the captions "Автопарк и коммерческий транспорт", "Сельхозтехника", and "Предсказуемые платежи".
#### Scenario: Gallery cards displayed
- WHEN the page is loaded
- THEN three illustration cards are displayed with the captions "Автопарк и коммерческий транспорт", "Сельхозтехника", and "Предсказуемые платежи"

### Requirement: Order action
The page SHALL display an order button labelled "Заказать сейчас"; when the user clicks it, the page SHALL display the message "Спасибо! Ваш заказ уже в пути.".
#### Scenario: Order button displayed
- WHEN the page is loaded
- THEN a button labelled "Заказать сейчас" is displayed
#### Scenario: Order confirmation message
- WHEN the user clicks the "Заказать сейчас" button
- THEN the message "Спасибо! Ваш заказ уже в пути." appears on the page

### Requirement: Footer
The page SHALL display a small footer at the bottom of the page containing the text "© 2026 Supercompany".
#### Scenario: Small footer displayed at page bottom
- WHEN the page is loaded
- THEN a small footer is shown at the bottom of the page with the text "© 2026 Supercompany"

## Increments
- T-0000 baseline: added Brand header, Hero section, Illustration gallery, Order action, Footer
- T-0004 Add a small footer: modified Footer
