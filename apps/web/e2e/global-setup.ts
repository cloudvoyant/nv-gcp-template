import { execSync } from "child_process";
import { chromium } from "@playwright/test";
import { loadPasswords, PERSONAS } from "./fixtures/auth";
import * as fs from "fs";

const STORAGE_STATE_P1 = "e2e/.auth/storageState.json";
const REPO_ROOT = new URL("../../../", import.meta.url).pathname;

async function loginAs(
  email: string,
  password: string,
  baseUrl: string,
  storageStatePath: string,
): Promise<void> {
  fs.mkdirSync("e2e/.auth", { recursive: true });
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto(`${baseUrl}/login`);

  // Wait until Kinde's hosted login page is loaded (redirected away from app)
  await page.waitForURL(/kinde\.com/, { timeout: 15_000 });

  // Capture page state for debugging — helps diagnose selector mismatches in CI
  await page.screenshot({ path: "e2e/.auth/kinde-login-debug.png" });
  console.log("Kinde page URL:", page.url());

  // Fill Kinde's hosted login form.
  // Kinde renders the email field as type="text" with name="email" or id="email".
  const emailInput = page
    .locator(
      'input[name="p_email"], input[name="email"], input[type="email"], input[id="email"], input[autocomplete="email"]',
    )
    .first();
  await emailInput.waitFor({ state: "visible", timeout: 15_000 });
  await emailInput.fill(email);

  // Try two-step flow (email → Continue → password). Falls back gracefully
  // if the "Continue" button isn't present (single-step form).
  const continueBtn = page.getByRole("button", { name: /continue/i });
  if (await continueBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
    await continueBtn.click();
  }

  const passwordInput = page
    .locator('input[name="p_password"], input[type="password"]')
    .first();
  await passwordInput.waitFor({ state: "visible", timeout: 15_000 });
  await passwordInput.fill(password);
  await page.getByRole("button", { name: /sign in|continue|log in/i }).click();

  // Wait for redirect back to app. 60s for Cloud Run cold starts.
  await page.waitForURL(`${baseUrl}/**`, {
    waitUntil: "load",
    timeout: 60_000,
  });

  await context.storageState({ path: storageStatePath });
  await browser.close();
  console.log(`Session saved for ${email} → ${storageStatePath}`);
}

async function seedUploadViaApi(
  baseUrl: string,
  cookieName: string,
  cookieValue: string,
): Promise<void> {
  const cdnBasePath = `https://storage.googleapis.com/placeholder-bucket/e2e/test-upload`;
  const srcset = `${cdnBasePath}-small.webp 400w, ${cdnBasePath}-medium.webp 800w, ${cdnBasePath}-large.webp 1200w, ${cdnBasePath}-xlarge.webp 1600w`;

  const res = await fetch(`${baseUrl}/api/uploads`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Cookie: `${cookieName}=${cookieValue}`,
    },
    body: JSON.stringify({
      basePath: `e2e/test/test-upload`,
      cdnBasePath,
      srcset,
      purpose: "general",
      filename: "[E2E] test-upload.jpg",
    }),
  });

  if (!res.ok) {
    throw new Error(`Seed API returned ${res.status}: ${await res.text()}`);
  }
  console.log("Seeded E2E upload via API");
}

async function globalSetup() {
  const { p1Password } = loadPasswords();
  const baseUrl = process.env.BASE_URL ?? "http://localhost:5175";

  // Pre-clean stale E2E records from any previous failed teardown
  try {
    execSync("npx tsx scripts/pre-cleanup-e2e.ts", {
      stdio: "inherit",
      cwd: REPO_ROOT,
    });
  } catch (err) {
    console.error("Pre-cleanup failed (non-fatal):", err);
  }

  await loginAs(PERSONAS.p1.email, p1Password, baseUrl, STORAGE_STATE_P1);

  // Ensure P1 user record is correct before seeding
  try {
    execSync("npx tsx scripts/pre-setup-p1-e2e.ts", {
      stdio: "inherit",
      cwd: REPO_ROOT,
    });
  } catch (err) {
    console.error("P1 pre-setup failed (non-fatal):", err);
  }

  // Seed E2E test upload via the dev server API.
  // Uses the server's GCP credentials — no local GCP setup needed.
  const storageState = JSON.parse(fs.readFileSync(STORAGE_STATE_P1, "utf-8"));
  const sessionCookie = storageState.cookies?.find((c: { name: string }) =>
    c.name.endsWith("_session"),
  );

  if (sessionCookie) {
    console.log(`Found session cookie: ${sessionCookie.name}`);
    try {
      await seedUploadViaApi(baseUrl, sessionCookie.name, sessionCookie.value);
    } catch (err) {
      console.warn("Seed upload via API failed (non-fatal):", err);
    }
  } else {
    console.warn(
      "Session cookie not found in storage state — seed upload skipped",
    );
    console.warn(
      "Available cookies:",
      storageState.cookies?.map((c: { name: string }) => c.name),
    );
  }

  console.log("Global setup complete.");
}

export default globalSetup;
