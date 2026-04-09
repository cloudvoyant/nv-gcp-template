import { redirect } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import { SESSION_COOKIE_NAME, getLogoutUrl } from "@nv-gcp-template/auth";

export const prerender = false;

export const GET: RequestHandler = async ({ cookies, url }) => {
  cookies.delete(SESSION_COOKIE_NAME, { path: "/" });
  let logoutUrl: string;
  try {
    logoutUrl = getLogoutUrl(url.origin);
  } catch {
    // Kinde not configured (missing env vars) — fall back to home
    throw redirect(302, "/");
  }
  throw redirect(302, logoutUrl);
};
