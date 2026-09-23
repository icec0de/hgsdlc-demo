const { test, expect } = require('@playwright/test');

test('T-0005: Phone button displayed next to main button', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN a button labelled "Позвонить нам" is displayed next to the "Заказать сейчас" button
  await expect(page.getByRole('button', { name: 'Заказать сейчас' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Позвонить нам' })).toBeVisible();
});

test('T-0005: Phone number shown after click', async ({ page }) => {
  await page.goto('/');
  // WHEN the user clicks the "Позвонить нам" button
  await page.getByRole('button', { name: 'Позвонить нам' }).click();
  // THEN the text "+7 800 555-35-35" appears on the page below the buttons
  await expect(page.getByText('+7 800 555-35-35')).toBeVisible();
});

test('T-0005: Phone number hidden before click', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN the text "+7 800 555-35-35" is not displayed on the page
  await expect(page.getByText('+7 800 555-35-35')).toBeHidden();
});