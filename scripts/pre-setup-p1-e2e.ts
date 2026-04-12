#!/usr/bin/env tsx
/**
 * Pre-test setup for Persona 1.
 *
 * Stub — add setup logic here when needed (e.g., ensure P1 has the correct
 * Firestore user record before seeding on a fresh environment).
 *
 * Must run AFTER global-setup saves P1's session state to
 * e2e/.auth/storageState.json so the Kinde user ID can be read from it.
 *
 * Usage: WORKSPACE=dev npx tsx scripts/pre-setup-p1-e2e.ts
 */
import * as dotenv from "dotenv";
dotenv.config({ path: "apps/web/.env.e2e.local" });
dotenv.config({ path: "apps/web/.env.local" }); // local dev fallback for GCP vars

async function preSetupP1() {
  const projectId = process.env.GCP_PROJECT_ID;
  const databaseId = process.env.FIRESTORE_DATABASE_ID;

  if (!projectId || !databaseId) {
    console.log("Missing GCP env vars — skipping P1 pre-setup.");
    return;
  }

  // TODO: Add P1 pre-setup logic here
  console.log("P1 pre-setup complete (nothing to do).");
}

preSetupP1().catch((err) => {
  console.error("P1 pre-setup failed:", err);
  process.exit(1);
});
