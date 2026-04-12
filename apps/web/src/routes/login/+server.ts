import { redirect } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import { getAuthorizationUrl } from "@nv-gcp-template/auth";

export const prerender = false;

export const GET: RequestHandler = async ({ url }) => {
  const returnTo = url.searchParams.get("returnTo") || "/";
  const state = Buffer.from(JSON.stringify({ returnTo })).toString("base64");
  throw redirect(302, getAuthorizationUrl(url.origin, state));
};
