#!/usr/bin/env tsx
/**
 * Seed E2E test uploads into Firestore. Idempotent — skips if [E2E] upload already exists.
 *
 * Required env vars (from apps/web/.env.e2e.local):
 *   GCP_PROJECT_ID, FIRESTORE_DATABASE_ID, E2E_P1_USER_ID
 *
 * Usage: WORKSPACE=dev npx tsx scripts/seed-uploads.ts
 */
import * as dotenv from "dotenv";
dotenv.config({ path: "apps/web/.env.e2e.local" });
dotenv.config({ path: "apps/web/.env.local" }); // local dev fallback for GCP vars

import { Firestore } from "@google-cloud/firestore";

const E2E_MARKER = "[E2E]";
const E2E_UPLOAD_FILENAME = `${E2E_MARKER} test-upload.jpg`;

async function seedUploads() {
  const projectId = process.env.GCP_PROJECT_ID;
  const databaseId = process.env.FIRESTORE_DATABASE_ID ?? "(default)";
  const userId = process.env.E2E_P1_USER_ID;

  if (!projectId || !userId) {
    console.log(
      "Skipping seed-uploads: GCP_PROJECT_ID or E2E_P1_USER_ID not set",
    );
    return;
  }

  const db = new Firestore({ projectId, databaseId });

  // Check if already seeded (idempotent)
  const existing = await db
    .collection("uploads")
    .where("userId", "==", userId)
    .where("filename", "==", E2E_UPLOAD_FILENAME)
    .limit(1)
    .get();

  if (!existing.empty) {
    console.log("E2E upload already seeded — skipping");
    return;
  }

  // Use placeholder CDN base path (no actual GCS upload needed for list/detail tests)
  const cdnBasePath = `https://storage.googleapis.com/placeholder-bucket/e2e/test-upload`;
  const srcset = `${cdnBasePath}-small.webp 400w, ${cdnBasePath}-medium.webp 800w, ${cdnBasePath}-large.webp 1200w, ${cdnBasePath}-xlarge.webp 1600w`;

  await db.collection("uploads").add({
    userId,
    userEmail: process.env.E2E_P1_EMAIL ?? "adalovelace@cloudvoyant.io",
    basePath: `${userId}/test-upload-e2e`,
    cdnBasePath,
    srcset,
    original: null,
    purpose: "general",
    filename: E2E_UPLOAD_FILENAME,
    uploadedAt: new Date(),
  });

  console.log(`Seeded E2E upload: ${E2E_UPLOAD_FILENAME}`);
}

seedUploads().catch((err) => {
  console.error("seed-uploads failed:", err);
  process.exit(1);
});
