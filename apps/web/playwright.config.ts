import { defineConfig, devices } from "@playwright/test";

const BASE_URL = process.env.BASE_URL ?? "http://localhost:5175";
const IS_LOCAL = BASE_URL.includes("localhost");

export default defineConfig({
  testDir: "./e2e/tests",
  fullyParallel: false, // tests share session state — run sequentially
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "github" : "list",

  use: {
    baseURL: BASE_URL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    storageState: "e2e/.auth/storageState.json",
  },

  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],

  // Only start the dev server when running locally.
  ...(IS_LOCAL
    ? {
        webServer: {
          command: "pnpm dev",
          url: "http://localhost:5175",
          reuseExistingServer: !process.env.CI,
          timeout: 120_000,
        },
      }
    : {}),

  globalSetup: "./e2e/global-setup.ts",
  globalTeardown: "./e2e/global-teardown.ts",
});
