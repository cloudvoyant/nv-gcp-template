<script lang="ts">
  import "../app.css";
  import type { LayoutData } from "./$types";
  import { Button } from "@mise-app-template/ui/components/button";

  let {
    children,
    data,
  }: { children: import("svelte").Snippet; data: LayoutData } = $props();
  const session = $derived(data.session);
</script>

<div class="flex flex-col h-screen">
  <nav class="border-b bg-background px-6 py-3 sticky top-0 z-10">
    <div class="mx-auto flex max-w-4xl items-center gap-6">
      <a href="/" class="font-semibold text-sm">mise-app-template</a>
      {#if session}
        <Button variant="ghost" size="sm" href="/uploads/new">Upload</Button>
        <Button variant="ghost" size="sm" href="/uploads">My Uploads</Button>
      {/if}
      <div class="ml-auto">
        {#if session}
          <Button variant="ghost" size="sm" href="/auth/logout">Logout</Button>
        {:else}
          <Button variant="ghost" size="sm" href="/login">Login</Button>
        {/if}
      </div>
    </div>
  </nav>
  <main class="flex-1 overflow-y-auto">
    {@render children()}
  </main>
</div>
