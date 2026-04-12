<script lang="ts">
  import { DEFAULT_IMAGE_SIZES } from "./urls";

  interface ImageVariants {
    srcset?: string;
    sizes: {
      medium: string;
      [key: string]: string;
    };
  }

  let {
    image,
    alt,
    sizes = DEFAULT_IMAGE_SIZES,
    class: className = "",
  }: {
    image: ImageVariants;
    alt: string;
    /** HTML sizes attribute — override for non-standard layout widths */
    sizes?: string;
    class?: string;
  } = $props();

  // Prefer srcset stored on the variant; fall back to medium for browsers
  // that don't support srcset (none in practice, but defensive)
  const src = $derived(image.sizes.medium);
  const srcset = $derived(image.srcset ?? undefined);
</script>

<img
  {src}
  {srcset}
  {sizes}
  {alt}
  class={className}
  loading="lazy"
  decoding="async"
/>
