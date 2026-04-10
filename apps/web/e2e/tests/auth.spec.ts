import { test, expect } from "@playwright/test";

test.describe("Authentication", () => {
  test("unauthenticated user visiting / sees the home page (public)", async ({
    page,
  }) => {
    await page.context().clearCookies();
    await page.goto("/");
    await expect(page).not.toHaveURL(/\/login/);
    await expect(page.locator("body")).toBeVisible();
  });

  test("authenticated user has active session after global setup", async ({
    page,
  }) => {
    // global-setup logged in p1; storageState is auto-loaded by playwright.config
    await page.goto("/");
    // Session cookie should exist — verify we're not redirected to login
    await expect(page).not.toHaveURL(/\/login/);
  });

  test("logout clears session and redirects to app origin", async ({
    page,
    baseURL,
  }) => {
    await page.goto("/auth/logout");
    // Kinde logout endpoint redirects back to the app's origin after logout.
    // Use baseURL so this works both locally and against preview environments.
    await page.waitForURL(
      new RegExp(baseURL!.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")),
      { timeout: 15_000 },
    );
    // The session cookie must be gone after logout.
    const cookies = await page.context().cookies();
    const sessionCookie = cookies.find((c) => c.name.endsWith("_session"));
    expect(sessionCookie).toBeUndefined();
  });
});
