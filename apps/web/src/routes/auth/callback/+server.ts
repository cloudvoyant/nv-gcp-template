import { redirect, error } from "@sveltejs/kit";
import type { RequestHandler } from "./$types";
import {
  SESSION_COOKIE_NAME,
  serializeSession,
  getSessionCookieOptions,
} from "@nv-gcp-template/auth";
import { createSessionFromCode } from "@nv-gcp-template/auth/server";

export const prerender = false;

export const GET: RequestHandler = async ({ url, cookies }) => {
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const oauthError = url.searchParams.get("error");

  if (oauthError) {
    throw error(
      400,
      `OAuth error: ${oauthError} - ${url.searchParams.get("error_description")}`,
    );
  }
  if (!code) throw error(400, "Missing authorization code");

  try {
    const session = await createSessionFromCode(code, url.origin);
    const isHttps = url.protocol === "https:";
    cookies.set(
      SESSION_COOKIE_NAME,
      serializeSession(session),
      getSessionCookieOptions(isHttps),
    );

    let returnTo = "/";
    if (state) {
      try {
        const decoded = JSON.parse(Buffer.from(state, "base64").toString());
        returnTo = decoded.returnTo || "/";
      } catch {
        /* invalid state, use default */
      }
    }

    throw redirect(302, returnTo);
  } catch (err: unknown) {
    if (typeof err === "object" && err !== null && "status" in err) {
      const e = err as { status: number };
      if (e.status >= 300 && e.status < 400) throw err;
    }
    console.error("Failed to create session:", err);
    throw error(500, "Authentication failed");
  }
};
