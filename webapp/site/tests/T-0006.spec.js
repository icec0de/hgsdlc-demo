const { test, expect } = require('@playwright/test');

test('T-0006: Gallery cards displayed', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN two illustration cards are displayed with the captions
  // "Автопарк и коммерческий транспорт" and "Сельхозтехника",
  // and each card contains a visible image of the corresponding machinery
  const fleetCard = page.getByText('Автопарк и коммерческий транспорт', { exact: true });
  await expect(fleetCard).toBeVisible();
  const agriCard = page.getByText('Сельхозтехника', { exact: true });
  await expect(agriCard).toBeVisible();

  const fleetImage = fleetCard
    .locator('xpath=ancestor::*[self::section or self::div or self::article or self::li][1]')
    .locator('img, svg');
  await expect(fleetImage.first()).toBeVisible();

  const agriImage = agriCard
    .locator('xpath=ancestor::*[self::section or self::div or self::article or self::li][1]')
    .locator('img, svg');
  await expect(agriImage.first()).toBeVisible();
});

test('T-0006: Predictable payments card removed', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN no card with the caption "Предсказуемые платежи" is displayed,
  // and the text does not appear anywhere on the page
  await expect(page.getByText('Предсказуемые платежи')).toHaveCount(0);
});

test('T-0006: Hero content displayed', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN the hero heading and the lead paragraph are displayed
  await expect(
    page.getByRole('heading', {
      name: 'Лизинговые решения для автомобильной и агропромышленной отраслей',
    })
  ).toBeVisible();
  const lead = page.getByText('лизинг', { exact: false }).first();
  await expect(lead).toBeVisible();
});

test('T-0006: Hero lead free of predictable payments', async ({ page }) => {
  await page.goto('/');
  // WHEN the page is loaded
  // THEN the lead paragraph does not contain the phrase "предсказуемые платежи"
  const heading = page.getByRole('heading', {
    name: 'Лизинговые решения для автомобильной и агропромышленной отраслей',
  });
  await expect(heading).toBeVisible();
  const leadText = await page
    .getByRole('heading', {
      name: 'Лизинговые решения для автомобильной и агропромышленной отраслей',
    })
    .locator('xpath=following-sibling::*[1]')
    .innerText();
  expect(leadText.toLowerCase()).not.toContain('предсказуемые платежи');
});