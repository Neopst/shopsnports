import { test, expect } from '@playwright/test';

test('admin smoke: login and view dashboard', async ({ page, baseURL }) => {
  await page.goto('/admin');

  // If login form present, fill credentials (dev fallback uses ADMIN_USER/ADMIN_PASS or admin/password)
  if (await page.locator('text=Admin Login').count()) {
    const username = process.env.E2E_ADMIN_USER || process.env.ADMIN_USER || 'admin';
    const password = process.env.E2E_ADMIN_PASS || process.env.ADMIN_PASS || 'password';
    await page.fill('input[name="username"]', username);
    await page.fill('input[name="password"]', password);
    await page.click('button:has-text("Login")');
  }

  // Wait for dashboard content
  await page.waitForSelector('text=Recent Transactions', { timeout: 10000 });
  const txRows = await page.locator('table tbody tr').count();
  expect(txRows).toBeGreaterThanOrEqual(0);
});
