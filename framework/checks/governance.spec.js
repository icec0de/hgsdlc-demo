// G-01: the page is always in Russian
const { test, expect } = require('@playwright/test');

test('G-01: page language is Russian', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('lang', /^ru/i);
  const text = await page.locator('body').innerText();
  const cyr = (text.match(/[а-яё]/gi) || []).length;
  const lat = (text.match(/[a-z]/gi) || []).length;
  const share = cyr / Math.max(1, cyr + lat);
  expect(share, `Cyrillic share of visible letters is ${(share * 100).toFixed(0)}%`).toBeGreaterThanOrEqual(0.8);
});
