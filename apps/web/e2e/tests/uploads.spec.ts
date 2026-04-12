import { test, expect } from "@playwright/test";
import * as path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TEST_IMAGE = path.join(__dirname, "../fixtures/test-image.png");
const E2E_UPLOAD_FILENAME = "[E2E] test-upload.jpg";

/** Selector for actual upload grid items (excludes the "New Upload" nav button) */
const UPLOAD_ITEM = "div.grid a[href^='/uploads/']";

test.describe("Upload page", () => {
  test("unauthenticated user is redirected to login", async ({ page }) => {
    // Clear cookies to simulate an unauthenticated user
    await page.context().clearCookies();
    await page.goto("/uploads/new");
    // /uploads/new → /login → Kinde OAuth page
    await expect(page).toHaveURL(/kinde\.com/);
  });

  test("authenticated user can upload an image", async ({ page }) => {
    await page.goto("/uploads/new");
    // Should not redirect — p1 is authenticated via global setup
    await expect(page).not.toHaveURL(/\/login/);
    await expect(page.locator("h1")).toContainText("Upload");

    // Upload the test image
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles(TEST_IMAGE);

    // Wait for the file to be picked up (filename should appear)
    await expect(page.locator("p.text-muted-foreground.truncate")).toBeVisible({
      timeout: 5_000,
    });

    // Click upload and wait for redirect to /uploads list
    await page.locator('button[type="submit"]').click();
    await page.waitForURL((url) => url.pathname === "/uploads", {
      timeout: 45_000,
    });
    await expect(page).toHaveURL(/\/uploads$/);
  });
});

test.describe("Uploads list page", () => {
  test("authenticated user sees uploads grid", async ({ page }) => {
    await page.goto("/uploads");
    await expect(page).not.toHaveURL(/\/login/);
    await expect(page.locator("h1")).toContainText("Uploads");
  });

  test("seeded E2E upload appears in grid", async ({ page }) => {
    await page.goto("/uploads");
    // Wait for at least one actual upload item (not the "New Upload" nav button)
    await expect(page.locator(UPLOAD_ITEM).first()).toBeVisible({
      timeout: 10_000,
    });
  });

  test("clicking an upload navigates to detail page", async ({ page }) => {
    await page.goto("/uploads");
    const firstUpload = page.locator(UPLOAD_ITEM).first();
    await expect(firstUpload).toBeVisible({ timeout: 10_000 });
    await firstUpload.click();
    await expect(page).toHaveURL(/\/uploads\/.+/);
  });
});

test.describe("Upload details page", () => {
  test("detail page shows all 5 image variants", async ({ page }) => {
    // Navigate to uploads list and click the first actual upload item
    await page.goto("/uploads");
    const firstUpload = page.locator(UPLOAD_ITEM).first();
    await expect(firstUpload).toBeVisible({ timeout: 10_000 });
    await firstUpload.click();
    await expect(page).toHaveURL(/\/uploads\/.+/);

    // All 5 variant labels should be visible (exact match to avoid "Large" matching "Extra Large")
    for (const label of [
      "Thumbnail",
      "Small",
      "Medium",
      "Large",
      "Extra Large",
    ]) {
      await expect(page.getByText(label, { exact: true })).toBeVisible();
    }

    // 5 variant images should be present
    const variantImages = page.locator("img");
    await expect(variantImages).toHaveCount(5);
  });

  test("unauthenticated user is redirected to login", async ({ page }) => {
    // Clear cookies to simulate an unauthenticated user
    await page.context().clearCookies();
    await page.goto("/uploads/some-id");
    // /uploads/some-id → /login → Kinde OAuth page
    await expect(page).toHaveURL(/kinde\.com/);
  });
});

// Suppress unused variable warning for E2E_UPLOAD_FILENAME
void E2E_UPLOAD_FILENAME;
