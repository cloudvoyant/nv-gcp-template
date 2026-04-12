<script lang="ts">
  import type { PageData } from "./$types";
  let { data }: { data: PageData } = $props();
  const sizes = [
    { name: "thumbnail", label: "Thumbnail", width: 150 },
    { name: "small", label: "Small", width: 400 },
    { name: "medium", label: "Medium", width: 800 },
    { name: "large", label: "Large", width: 1200 },
    { name: "xlarge", label: "Extra Large", width: 1600 },
  ] as const;
</script>

<div class="mx-auto max-w-5xl p-8">
  <div class="mb-6">
    <a href="/uploads" class="text-sm text-blue-600 underline">← Back</a>
    <h1 class="mt-2 text-2xl font-bold">{data.upload.filename}</h1>
  </div>
  <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
    {#each sizes as size}
      <div class="rounded border p-4">
        <div class="mb-2 flex justify-between">
          <span class="font-medium">{size.label}</span>
          <span class="text-xs text-gray-500">{size.width}px</span>
        </div>
        <img
          src="{data.upload.cdnBasePath}-{size.name}.webp"
          alt="{size.label} variant"
          class="w-full rounded object-contain"
          loading="lazy"
        />
        <a
          href="{data.upload.cdnBasePath}-{size.name}.webp"
          target="_blank"
          class="mt-2 block text-xs text-blue-600 underline">Open ↗</a
        >
      </div>
    {/each}
  </div>
</div>
