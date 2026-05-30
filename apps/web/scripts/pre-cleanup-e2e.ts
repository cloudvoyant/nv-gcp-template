#!/usr/bin/env tsx
/**
 * Pre-test cleanup.
 *
 * Stub — add cleanup logic here when needed (e.g., clean up stale E2E records
 * that a previous teardown failed to remove before the test run starts).
 *
 * Called by global-setup before logging in, so it runs even if the previous
 * run's teardown was skipped.
 *
 * Usage: WORKSPACE=dev npx tsx scripts/pre-cleanup-e2e.ts
 */
import * as dotenv from "dotenv";
dotenv.config({ path: "apps/web/.env.e2e.local" });
dotenv.config({ path: "apps/web/.env.local" }); // local dev fallback for GCP vars

async function preCleanup() {
  const projectId = process.env.GCP_PROJECT_ID;
  const databaseId = process.env.FIRESTORE_DATABASE_ID;

  if (!projectId || !databaseId) {
    console.log("Missing GCP env vars — skipping pre-cleanup.");
    return;
  }

  // TODO: Add pre-cleanup logic here
  console.log("Pre-cleanup complete (nothing to do).");
}

preCleanup().catch((err) => {
  console.error("Pre-cleanup failed:", err);
  process.exit(1);
});
