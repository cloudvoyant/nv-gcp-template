import { execSync } from "child_process";

async function globalTeardown() {
  const workspace = process.env.WORKSPACE ?? "local";
  console.log(`Running E2E teardown for workspace: ${workspace}`);

  try {
    execSync(`WORKSPACE=${workspace} npx tsx scripts/teardown-e2e.ts`, {
      stdio: "inherit",
      cwd: new URL("../../../", import.meta.url).pathname,
    });
    console.log("E2E teardown complete.");
  } catch (err) {
    console.error("Teardown script failed (non-fatal):", err);
    // Don't throw — a teardown failure shouldn't fail the test run
  }
}

export default globalTeardown;
