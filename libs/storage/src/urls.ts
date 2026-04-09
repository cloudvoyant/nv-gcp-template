import { getConfig } from "./client";

/**
 * Returns the public URL for a file in the public bucket.
 *
 * - When CDN is configured: https://{cdnBaseUrl}/{env}/{path}
 *   e.g. https://cdn.example.com/prod/alice/avatar-123-medium.webp
 *
 * - When CDN is not configured (dev without CDN, preview envs):
 *   https://storage.googleapis.com/{publicBucketName}/{path}
 */
export function getPublicUrl(path: string): string {
  const config = getConfig();

  if (config.cdnBaseUrl && config.environment) {
    const base = config.cdnBaseUrl.replace(/\/$/, "");
    const env = config.environment;
    return `${base}/${env}/${path}`;
  }

  const envPrefix = config.environment ? `${config.environment}/` : "";
  return `https://storage.googleapis.com/${config.publicBucketName}/${envPrefix}${path}`;
}

/**
 * Default HTML `sizes` attribute for responsive images.
 * Mobile: full viewport width (browser picks small/medium based on DPR).
 * Tablet: 800px column. Desktop: 1200px column.
 */
export const DEFAULT_IMAGE_SIZES =
  "(max-width: 640px) 100vw, (max-width: 1024px) 800px, 1200px";

/**
 * Build an HTML `srcset` attribute string from image variant URLs.
 * Thumbnail (150px) is excluded from srcset because:
 *   - The pre-computed srcset is designed for content images (covers, heroes, editor images)
 *     where the display slot is always ≥ 400px, so 150w would never be selected.
 *   - For avatar use cases where 150px is the right size, the UI references
 *     `sizes.thumbnail` directly rather than relying on srcset selection.
 *
 * @param sizes - Object with full URLs for small (400w), medium (800w), large (1200w),
 *   and xlarge (1600w) variants. These are already-resolved CDN or GCS URLs (not GCS paths).
 *
 * @example
 *   getImageSrcset({ small: "https://cdn.../img-small.webp", ... })
 *   // -> "https://cdn.../img-small.webp 400w, ..., https://cdn.../img-xlarge.webp 1600w"
 */
export function getImageSrcset(sizes: {
  small: string;
  medium: string;
  large: string;
  xlarge: string;
}): string {
  return [
    `${sizes.small} 400w`,
    `${sizes.medium} 800w`,
    `${sizes.large} 1200w`,
    `${sizes.xlarge} 1600w`,
  ].join(", ");
}
