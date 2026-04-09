/** Size variant names used throughout the app */
export type ImageSizeName =
  | "thumbnail"
  | "small"
  | "medium"
  | "large"
  | "xlarge";

/** Max widths (px) for each size. Height is calculated proportionally. */
export const RESIZE_SIZES: Record<ImageSizeName, number> = {
  thumbnail: 150,
  small: 400,
  medium: 800,
  large: 1200,
  xlarge: 1600,
};

/** Map of size name -> resized WebP Blob */
export type ResizeVariants = Record<ImageSizeName, Blob>;

/**
 * Resize a File or Blob to a WebP Blob with the given max width.
 * Height is calculated proportionally. If the source is already smaller
 * than maxWidth, it is returned at its original dimensions.
 *
 * Browser-only: uses HTMLCanvasElement and CanvasRenderingContext2D.
 */
export async function resizeToWebP(
  source: File | Blob,
  maxWidth: number,
  quality = 0.85,
): Promise<Blob> {
  const bitmap = await createImageBitmap(source);
  const { width, height } = bitmap;

  const scale = Math.min(1, maxWidth / width);
  const targetWidth = Math.round(width * scale);
  const targetHeight = Math.round(height * scale);

  const canvas = document.createElement("canvas");
  canvas.width = targetWidth;
  canvas.height = targetHeight;

  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas 2D context unavailable");

  ctx.drawImage(bitmap, 0, 0, targetWidth, targetHeight);
  bitmap.close();

  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (blob) {
          resolve(blob);
        } else {
          reject(new Error("canvas.toBlob returned null"));
        }
      },
      "image/webp",
      quality,
    );
  });
}

/**
 * Resize a user-selected File into all five standard size variants (WebP).
 * All resizes run in parallel.
 *
 * @param file - The original image File from an <input type="file"> or drop event
 * @returns Map of size name -> WebP Blob
 */
export async function resizeImageToVariants(
  file: File,
): Promise<ResizeVariants> {
  const entries = await Promise.all(
    (Object.entries(RESIZE_SIZES) as [ImageSizeName, number][]).map(
      async ([name, maxWidth]) =>
        [name, await resizeToWebP(file, maxWidth)] as const,
    ),
  );

  return Object.fromEntries(entries) as ResizeVariants;
}
