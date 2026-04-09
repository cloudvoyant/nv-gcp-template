import { json, error } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import {
  generateSignedUploadUrl,
  getPublicUrl,
  getImageSrcset,
} from "@nv-gcp-template/storage";

export const POST: RequestHandler = async ({ request, locals }) => {
  // Auth check
  const session = locals.session;
  if (!session?.user?.id) {
    throw error(401, "Unauthorized");
  }

  const body = await request.json();

  // Validate original filename for extension
  const filename = body.filename as string;
  if (!filename || typeof filename !== "string") {
    throw error(400, "filename is required");
  }
  const ext = filename.split(".").pop()?.toLowerCase() ?? "bin";
  const allowedExts = ["jpg", "jpeg", "png", "gif", "webp", "avif"];
  if (!allowedExts.includes(ext)) {
    throw error(400, `File type .${ext} not allowed`);
  }

  const purpose = (body.purpose as string) ?? "general";
  const userId = session.user.id;
  const timestamp = Date.now();
  // basePath shared across all variants (size suffix and extension appended per variant)
  const basePath = `${userId}/${purpose}-${timestamp}`;

  const SIZES = ["thumbnail", "small", "medium", "large", "xlarge"] as const;
  const EXPIRES = 900; // 15 minutes

  // Generate signed PUT URLs for all public-bucket variants in parallel
  const variantEntries = await Promise.all(
    SIZES.map(async (size) => {
      const path = `${basePath}-${size}.webp`;
      const url = await generateSignedUploadUrl(
        path,
        "image/webp",
        "public",
        EXPIRES,
      );
      return [size, url] as const;
    }),
  );

  // Generate signed PUT URL for original (private bucket, original format)
  const originalPath = `${basePath}-original.${ext}`;
  const originalUrl = await generateSignedUploadUrl(
    originalPath,
    `image/${ext === "jpg" ? "jpeg" : ext}`,
    "private",
    EXPIRES,
  );

  // Compute CDN base path (what the client stores in cdnBasePath).
  const cdnBasePath = getPublicUrl(basePath);

  // Compute srcset from the resolved CDN display URLs (not the signed upload URLs)
  const srcset = getImageSrcset({
    small: `${cdnBasePath}-small.webp`,
    medium: `${cdnBasePath}-medium.webp`,
    large: `${cdnBasePath}-large.webp`,
    xlarge: `${cdnBasePath}-xlarge.webp`,
  });

  return json({
    variants: Object.fromEntries(variantEntries) as Record<string, string>,
    original: originalUrl,
    basePath,
    cdnBasePath,
    srcset,
  });
};
