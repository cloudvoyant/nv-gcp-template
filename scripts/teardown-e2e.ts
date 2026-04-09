#!/usr/bin/env tsx
/**
 * E2E teardown — deletes all [E2E]-tagged uploads from Firestore.
 *
 * Required env vars (from apps/web/.env.e2e.local):
 *   GCP_PROJECT_ID, FIRESTORE_DATABASE_ID, E2E_P1_USER_ID
 *
 * Usage: WORKSPACE=dev npx tsx scripts/teardown-e2e.ts
 */
import * as dotenv from "dotenv";
dotenv.config({ path: "apps/web/.env.e2e.local" });
dotenv.config({ path: "apps/web/.env.local" }); // local dev fallback for GCP vars

import { Firestore } from "@google-cloud/firestore";

async function teardownE2e() {
  const projectId = process.env.GCP_PROJECT_ID;
  const databaseId = process.env.FIRESTORE_DATABASE_ID ?? "(default)";
  const userId = process.env.E2E_P1_USER_ID;

  if (!projectId || !userId) {
    console.log(
      "Skipping teardown: GCP_PROJECT_ID or E2E_P1_USER_ID not set",
    );
    return;
  }

  const db = new Firestore({ projectId, databaseId });

  // Delete only E2E-tagged uploads
  const snapshot = await db
    .collection("uploads")
    .where("userId", "==", userId)
    .where("filename", ">=", "[E2E]")
    .where("filename", "<", "[E2F]")
    .get();

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  console.log(`Cleaned up ${snapshot.size} E2E uploads`);
}

teardownE2e().catch((err) => {
  console.error("teardown-e2e failed:", err);
  process.exit(1);
});
