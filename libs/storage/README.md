# @nv-gcp-template/storage

GCS storage client for the nv-gcp-template monorepo.

## Features

- Multi-auth: service account key file, IAM impersonation (local dev), or Cloud Run ADC (prod)
- Public/private bucket separation with environment-prefixed paths
- Direct browser upload via v4 signed PUT URLs (no server proxy)
- Browser-side image resizing to 5 WebP variants (Canvas API)
- CDN URL generation with GCS fallback
- Responsive `<Image>` Svelte component

## Usage

### Server initialization (hooks.server.ts)

```typescript
import { initStorageConfig } from "@nv-gcp-template/storage";

initStorageConfig({
  projectId: env.GCP_PROJECT_ID,
  publicBucketName: env.GCS_PUBLIC_BUCKET_NAME,
  privateBucketName: env.GCS_PRIVATE_BUCKET_NAME,
  // Local dev: impersonate Cloud Run SA (requires roles/iam.serviceAccountTokenCreator)
  serviceAccountEmail: env.GCS_SERVICE_ACCOUNT_EMAIL,
  // CDN (optional — falls back to direct GCS URLs)
  cdnBaseUrl: env.CDN_BASE_URL,
  environment: env.ENVIRONMENT,
});
```

### Generate signed upload URLs (server-side API route)

```typescript
import {
  generateSignedUploadUrl,
  getPublicUrl,
  getImageSrcset,
} from "@nv-gcp-template/storage";

const signedUrl = await generateSignedUploadUrl(
  "alice/avatar-123-medium.webp",
  "image/webp",
  "public",
  900,
);
const cdnUrl = getPublicUrl("alice/avatar-123"); // → https://cdn.example.com/dev/alice/avatar-123
```

### Resize image in the browser

```typescript
import { resizeImageToVariants } from "@nv-gcp-template/storage/resize";

const variants = await resizeImageToVariants(file);
// variants.thumbnail, .small, .medium, .large, .xlarge → WebP Blobs
```

### Display with the Image component

```svelte
<script>
  import { Image } from "@nv-gcp-template/storage";
</script>

<Image image={upload} alt="Profile photo" />
```

## Authentication Strategies

| Strategy          | When                            | How                                                                         |
| ----------------- | ------------------------------- | --------------------------------------------------------------------------- |
| SA key file       | Legacy / CI with downloaded key | `serviceAccountPath` in config                                              |
| IAM impersonation | Local dev without key           | `serviceAccountEmail` + ADC user has `roles/iam.serviceAccountTokenCreator` |
| Cloud Run ADC     | Production                      | No extra config needed — Cloud Run SA is the ADC principal                  |

## Environment Variables

| Variable                    | Description                                             |
| --------------------------- | ------------------------------------------------------- |
| `GCS_PUBLIC_BUCKET_NAME`    | Shared CDN public bucket                                |
| `GCS_PRIVATE_BUCKET_NAME`   | Per-workspace private bucket                            |
| `GCS_SERVICE_ACCOUNT_EMAIL` | Cloud Run SA email (for IAM impersonation in local dev) |
| `CDN_BASE_URL`              | CDN base URL (optional — falls back to direct GCS)      |
| `ENVIRONMENT`               | Path prefix in public bucket (`dev`, `prod`, etc.)      |
