<script lang="ts">
  import type { PageData } from "./$types";
  import { Button } from "@mise-app-template/ui/components/button";
  let { data }: { data: PageData } = $props();
</script>

<div class="mx-auto max-w-4xl p-8">
  <div class="mb-6 flex items-center justify-between">
    <h1 class="text-2xl font-bold">Uploads</h1>
    <Button href="/uploads/new" size="sm">New Upload</Button>
  </div>
  {#if data.uploads.length === 0}
    <p class="text-muted-foreground">
      No uploads yet. <Button
        variant="link"
        href="/uploads/new"
        class="p-0 h-auto">Upload your first image.</Button
      >
    </p>
  {:else}
    <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
      {#each data.uploads as upload (upload.id)}
        <a
          href="/uploads/{upload.id}"
          class="group block overflow-hidden rounded border hover:shadow-md"
        >
          <img
            src="{upload.cdnBasePath}-small.webp"
            alt={upload.filename}
            class="aspect-square w-full object-cover"
            loading="lazy"
          />
          <div class="truncate p-2 text-xs text-muted-foreground">
            {upload.filename}
          </div>
        </a>
      {/each}
    </div>
  {/if}
</div>
