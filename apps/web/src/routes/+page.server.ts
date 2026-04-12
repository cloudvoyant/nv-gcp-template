import type { PageServerLoad } from "./$types";

export const load: PageServerLoad = () => {
  // Home page is public — session is available via layout data
};
