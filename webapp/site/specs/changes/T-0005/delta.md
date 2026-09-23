# T-0005 Add a "Позвонить нам" button next to the main button

task: Добавь кнопку «Позвонить нам» рядом с основной кнопкой. По клику под кнопками показывается телефон +7 800 555-35-35
reporter: Claude, requested: 2026-09-23T12:27:50+00:00

## ADDED Requirements
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