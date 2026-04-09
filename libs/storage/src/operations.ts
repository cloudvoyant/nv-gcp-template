import { getBucket, getConfig } from "./client";
import { getPublicUrl } from "./urls";
import type { UploadOptions, UploadResult, BucketType } from "./types";

/**
 * Translates a logical file path to the actual GCS object name.
 *
 * Public bucket objects are stored with an env prefix so all environments
 * share one bucket without collisions:
 *   logical: "alice/avatar-123-medium.webp"
 *   GCS:     "dev/alice/avatar-123-medium.webp"
 *
 * Private bucket paths are unchanged — private buckets remain per-environment.
 */
function toGcsPath(filePath: string, bucketType: BucketType): string {
  if (bucketType === "public") {
    const config = getConfig();
    if (config.environment) {
      return `${config.environment}/${filePath}`;
    }
  }
  return filePath;
}

export async function uploadFile(
  filePath: string,
  buffer: Buffer,
  options: UploadOptions = {},
  bucketType: BucketType = "public",
): Promise<UploadResult> {
  const bucket = await getBucket(bucketType);
  const gcsPath = toGcsPath(filePath, bucketType);
  const file = bucket.file(gcsPath);

  const saveOptions: Record<string, unknown> = {
    contentType: options.contentType,
  };

  if (options.metadata) {
    saveOptions.metadata = {
      metadata: options.metadata,
    };
  }

  await file.save(buffer, saveOptions);

  const url = bucketType === "public" ? getPublicUrl(filePath) : "";

  return {
    url,
    path: filePath, // logical path, without env prefix
    bucket: bucket.name,
  };
}

export async function downloadFile(
  filePath: string,
  bucketType: BucketType = "public",
): Promise<Buffer> {
  const bucket = await getBucket(bucketType);
  const file = bucket.file(toGcsPath(filePath, bucketType));

  const [buffer] = await file.download();
  return buffer;
}

export async function deleteFile(
  filePath: string,
  bucketType: BucketType = "public",
): Promise<void> {
  const bucket = await getBucket(bucketType);
  const file = bucket.file(toGcsPath(filePath, bucketType));

  await file.delete();
}

export async function generateSignedUrl(
  filePath: string,
  expiresIn: number = 3600,
  bucketType: BucketType = "public",
): Promise<string> {
  const bucket = await getBucket(bucketType);
  const file = bucket.file(toGcsPath(filePath, bucketType));

  const [url] = await file.getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + expiresIn * 1000,
  });

  return url;
}

/**
 * Generate a v4 signed URL for direct browser upload (PUT) to GCS.
 *
 * The browser can then do:
 *   fetch(signedUrl, { method: 'PUT', body: blob, headers: { 'Content-Type': contentType } })
 *
 * @param filePath  - Logical GCS object path (without env prefix)
 * @param contentType - MIME type the browser will send (must match what's signed)
 * @param bucketType  - "public" for image variants, "private" for originals
 * @param expiresIn   - seconds until URL expires (default: 15 minutes)
 */
export async function generateSignedUploadUrl(
  filePath: string,
  contentType: string,
  bucketType: BucketType = "public",
  expiresIn: number = 900,
): Promise<string> {
  const bucket = await getBucket(bucketType);
  const file = bucket.file(toGcsPath(filePath, bucketType));

  const [url] = await file.getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + expiresIn * 1000,
    contentType,
  });

  return url;
}

export async function fileExists(
  filePath: string,
  bucketType: BucketType = "public",
): Promise<boolean> {
  const bucket = await getBucket(bucketType);
  const file = bucket.file(toGcsPath(filePath, bucketType));

  const [exists] = await file.exists();
  return exists;
}

export async function listFiles(
  prefix?: string,
  bucketType: BucketType = "public",
): Promise<string[]> {
  const bucket = await getBucket(bucketType);
  const gcsPrefix = prefix ? toGcsPath(prefix, bucketType) : undefined;
  const [files] = await bucket.getFiles({ prefix: gcsPrefix });

  return files.map((file) => file.name);
}
