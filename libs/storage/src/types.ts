export interface UploadOptions {
  contentType?: string;
  public?: boolean;
  metadata?: Record<string, string>;
}

export interface UploadResult {
  url: string;
  path: string;
  bucket: string;
}

export interface StorageConfig {
  publicBucketName: string;
  privateBucketName: string;
  projectId?: string;
  serviceAccountPath?: string;
  /**
   * Service account email for IAM-based URL signing in local dev.
   * When set (without a key file), the GCS client calls the IAM signBlob API,
   * impersonating this SA using Application Default Credentials.
   * The ADC principal must have roles/iam.serviceAccountTokenCreator on this SA.
   */
  serviceAccountEmail?: string;
  /** Base URL of the CDN, e.g. "https://cdn.readership.io". Omit to fall back to direct GCS URLs. */
  cdnBaseUrl?: string;
  /** Environment name used in CDN path prefix, e.g. "dev" | "stage" | "prod". Required when cdnBaseUrl is set. */
  environment?: string;
}

export type BucketType = "public" | "private";
