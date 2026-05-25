import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 5000 },
  fullyParallel: true,
  use: {
    headless: true,
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true,
    baseURL: process.env.ADMIN_BASE_URL || 'http://localhost:3000',
    actionTimeout: 10000,
    trace: 'on-first-retry',
  },
};

export default config;
