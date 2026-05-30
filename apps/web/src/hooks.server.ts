import type { Handle } from "@sveltejs/kit";
import { env } from "$env/dynamic/private";
import { existsSync } from "fs";
import {
  initKindeConfig,
  SESSION_COOKIE_NAME,
  deserializeSession,
  serializeSession,
  getSessionCookieOptions,
  validateOrRefreshSession,
} from "@mise-app-template/auth";
import { initStorageConfig } from "@mise-app-template/storage";

const KINDE_DOMAIN = env.VITE_KINDE_DOMAIN;
const KINDE_CLIENT_ID = env.VITE_KINDE_CLIENT_ID;
const KINDE_CLIENT_SECRET = env.KINDE_CLIENT_SECRET;

const GCP_PROJECT_ID = env.GCP_PROJECT_ID;
const GCS_PUBLIC_BUCKET_NAME = env.GCS_PUBLIC_BUCKET_NAME;
const GCS_PRIVATE_BUCKET_NAME = env.GCS_PRIVATE_BUCKET_NAME;
const GCS_SERVICE_ACCOUNT_EMAIL = env.GCS_SERVICE_ACCOUNT_EMAIL ?? "";
const CDN_BASE_URL = env.CDN_BASE_URL ?? "";
const CDN_ENV_SUFFIX = env.CDN_ENV_SUFFIX ?? env.ENVIRONMENT ?? "local";
const GOOGLE_APPLICATION_CREDENTIALS = env.GOOGLE_APPLICATION_CREDENTIALS;

// Only use service account key if the file actually exists on disk
const serviceAccountPath =
  GOOGLE_APPLICATION_CREDENTIALS && existsSync(GOOGLE_APPLICATION_CREDENTIALS)
    ? GOOGLE_APPLICATION_CREDENTIALS
    : undefined;

if (KINDE_DOMAIN && KINDE_CLIENT_ID && KINDE_CLIENT_SECRET) {
  initKindeConfig({
    domain: KINDE_DOMAIN,
    clientId: KINDE_CLIENT_ID,
    clientSecret: KINDE_CLIENT_SECRET,
  });
} else {
  console.warn("Kinde credentials not set — auth will not work");
}

if (GCP_PROJECT_ID && GCS_PUBLIC_BUCKET_NAME && GCS_PRIVATE_BUCKET_NAME) {
  initStorageConfig({
    projectId: GCP_PROJECT_ID,
    publicBucketName: GCS_PUBLIC_BUCKET_NAME,
    privateBucketName: GCS_PRIVATE_BUCKET_NAME,
    serviceAccountPath,
    ...(GCS_SERVICE_ACCOUNT_EMAIL
      ? { serviceAccountEmail: GCS_SERVICE_ACCOUNT_EMAIL }
      : {}),
    ...(CDN_BASE_URL ? { cdnBaseUrl: CDN_BASE_URL } : {}),
    environment: CDN_ENV_SUFFIX,
  });
} else {
  console.warn(
    "GCS bucket names not set — storage features will be unavailable",
  );
}

export const handle: Handle = async ({ event, resolve }) => {
  const cookieValue = event.cookies.get(SESSION_COOKIE_NAME) ?? null;
  const rawSession = cookieValue ? deserializeSession(cookieValue) : null;

  if (!rawSession) {
    event.locals.session = null;
  } else {
    const isHttps = new URL(event.request.url).protocol === "https:";
    const { status, session } = await validateOrRefreshSession(rawSession);
    event.locals.session = session;

    if (status === "refreshed" && session) {
      event.cookies.set(
        SESSION_COOKIE_NAME,
        serializeSession(session),
        getSessionCookieOptions(isHttps),
      );
    } else if (status === "invalid") {
      event.cookies.delete(SESSION_COOKIE_NAME, { path: "/" });
    }
  }

  return resolve(event);
};

export const handleError = ({ error, event }) => {
  const errorId = crypto.randomUUID();

  console.error("Unhandled error", {
    errorId,
    error,
    pathname: event.url.pathname,
  });

  return {
    message: error instanceof Error ? error.message : "Internal server error",
  };
};
