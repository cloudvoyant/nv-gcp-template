<script lang="ts">
  import type { PageData } from "./$types";
  import { resizeImageToVariants } from "@nv-gcp-template/storage/resize";
  import { Button } from "@nv-gcp-template/ui/components/button";
  import { Root as FileDropZone, Trigger as FileDropZoneTrigger } from "@nv-gcp-template/ui/components/file-drop-zone";

  let { data }: { data: PageData } = $props();
  let files = $state<File[]>([]);
  let uploading = $state(false);
  let progress = $state("");
  let uploadError = $state("");

  let previewUrl = $derived(files[0] ? URL.createObjectURL(files[0]) : null);

  async function handleUpload(e: Event) {
    e.preventDefault();
    const selectedFile = files?.[0];
    if (!selectedFile) return;
    uploading = true;
    uploadError = "";
    try {
      progress = "Resizing to 5 WebP variants...";
      const variants = await resizeImageToVariants(selectedFile);

      progress = "Requesting upload URLs...";
      const urlsRes = await fetch("/api/images/upload-urls", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          purpose: "general",
          filename: selectedFile.name,
        }),
      });
      if (!urlsRes.ok) throw new Error(await urlsRes.text());
      const {
        variants: signedUrls,
        original: originalUrl,
        basePath,
        cdnBasePath,
        srcset,
      } = await urlsRes.json();

      progress = "Uploading...";
      await Promise.all(
        Object.entries(signedUrls).map(([size, url]) =>
          fetch(url as string, {
            method: "PUT",
            headers: { "Content-Type": "image/webp" },
            body: variants[size as keyof typeof variants],
          }),
        ),
      );
      await fetch(originalUrl, {
        method: "PUT",
        headers: { "Content-Type": selectedFile.type },
        body: selectedFile,
      });

      progress = "Saving...";
      const saveRes = await fetch("/api/uploads", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          basePath,
          cdnBasePath,
          srcset,
          purpose: "general",
          filename: selectedFile.name,
        }),
      });
      if (!saveRes.ok) throw new Error(await saveRes.text());

      window.location.href = "/uploads";
    } catch (err) {
      uploadError = err instanceof Error ? err.message : "Upload failed";
    } finally {
      uploading = false;
    }
  }
</script>

<div class="mx-auto max-w-lg p-8">
  <h1 class="mb-6 text-2xl font-bold">Upload Image</h1>
  <form onsubmit={handleUpload} class="space-y-4">
    <FileDropZone
      accept=".jpg,.jpeg,.png,.gif,.webp,.avif"
      disabled={uploading}
      onUpload={async (uploaded) => { files = uploaded; }}
    >
      <FileDropZoneTrigger />
    </FileDropZone>
    {#if files.length > 0}
      <div class="flex items-center gap-2">
        {#if previewUrl}
          <img src={previewUrl} alt="Preview" class="h-10 w-10 shrink-0 rounded object-cover border" />
        {/if}
        <p class="text-muted-foreground truncate text-sm">{files[0].name}</p>
      </div>
    {/if}
    <Button type="submit" disabled={uploading} class="w-full">{uploading ? progress : "Upload"}</Button>
{#if uploadError}<p class="text-red-600">{uploadError}</p>{/if}
  </form>
</div>
