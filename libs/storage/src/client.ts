import { Storage } from "@google-cloud/storage";
import { GoogleAuth, Impersonated } from "google-auth-library";
import type { StorageConfig, BucketType } from "./types";

// Promise-based lazy singleton — allows async initialization (needed for SA impersonation).
let storagePromise: Promise<Storage> | null = null;
let config: StorageConfig | null = null;

export function initStorageConfig(cfg: StorageConfig) {
  config = cfg;
}

export function getConfig(): StorageConfig {
  if (!config) {
    throw new Error("Storage config not initialized");
  }
  return config;
}

async function createStorageClient(): Promise<Storage> {
  if (!config) {
    throw new Error("Storage config not initialized");
  }

  if (config.serviceAccountPath) {
    // Explicit SA key file (e.g. legacy local dev or CI with downloaded key)
    return new Storage({
      projectId: config.projectId,
      keyFilename: config.serviceAccountPath,
    });
  }

  if (config.serviceAccountEmail) {
    // Local dev: impersonate the Cloud Run SA via IAM signBlob API.
    // Uses GoogleAuth.getClient() to get a real AuthClient with a synchronous
    // universeDomain property — required by the Impersonated constructor.
    // ADC user must have roles/iam.serviceAccountTokenCreator on this SA.
    const auth = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });
    const sourceClient = await auth.getClient();
    const impersonated = new Impersonated({
      sourceClient: sourceClient as never,
      targetPrincipal: config.serviceAccountEmail,
      lifetime: 3600,
      delegates: [],
      targetScopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });
    return new Storage({
      projectId: config.projectId,
      authClient: impersonated as never,
    });
  }

  // Production: Cloud Run attached SA via ADC — signing works natively
  return new Storage({ projectId: config.projectId });
}

export async function getStorageClient(): Promise<Storage> {
  if (!storagePromise) {
    storagePromise = createStorageClient();
  }
  return storagePromise;
}

export async function getBucket(bucketType: BucketType = "public") {
  if (!config) {
    throw new Error("Storage config not initialized");
  }

  const client = await getStorageClient();
  const bucketName =
    bucketType === "public"
      ? config.publicBucketName
      : config.privateBucketName;

  return client.bucket(bucketName);
}
