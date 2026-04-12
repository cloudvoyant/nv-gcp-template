import { createRemoteJWKSet, jwtVerify } from "jose";
import type { JWTPayload } from "jose";
import type { KindeConfig, User } from "./types";

let config: KindeConfig | null = null;
let jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

export function initKindeConfig(cfg: KindeConfig) {
  config = cfg;
  jwks = createRemoteJWKSet(new URL(`https://${cfg.domain}/.well-known/jwks`));
}

function getConfig(): KindeConfig {
  if (!config)
    throw new Error("Kinde not initialized. Call initKindeConfig first.");
  return config;
}

export async function validateAccessToken(token: string): Promise<JWTPayload> {
  if (!jwks) throw new Error("Kinde JWKS not initialized.");
  const { payload } = await jwtVerify(token, jwks);
  return payload;
}

export function isTokenExpiredError(err: unknown): boolean {
  return (
    typeof err === "object" &&
    err !== null &&
    (err as { code?: string }).code === "ERR_JWT_EXPIRED"
  );
}

export async function refreshAccessToken(refreshToken: string): Promise<{
  accessToken: string;
  refreshToken?: string;
  expiresIn: number;
}> {
  const cfg = getConfig();
  const response = await fetch(`https://${cfg.domain}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      client_id: cfg.clientId,
      client_secret: cfg.clientSecret,
      refresh_token: refreshToken,
    }),
  });
  if (!response.ok)
    throw new Error(`Token refresh failed: ${response.statusText}`);
  const data = await response.json();
  return {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    expiresIn: data.expires_in,
  };
}

export function getAuthorizationUrl(origin: string, state?: string): string {
  const cfg = getConfig();
  const params = new URLSearchParams({
    client_id: cfg.clientId,
    redirect_uri: `${origin}/auth/callback`,
    response_type: "code",
    scope: "openid profile email offline",
  });
  if (state) params.set("state", state);
  return `https://${cfg.domain}/oauth2/auth?${params.toString()}`;
}

export function getLogoutUrl(origin: string): string {
  const cfg = getConfig();
  return `https://${cfg.domain}/logout?redirect=${encodeURIComponent(origin)}`;
}

export async function exchangeCodeForToken(
  code: string,
  redirectUri: string,
): Promise<{
  access_token: string;
  refresh_token?: string;
  expires_in: number;
}> {
  const cfg = getConfig();
  const response = await fetch(`https://${cfg.domain}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: cfg.clientId,
      client_secret: cfg.clientSecret,
      code,
      redirect_uri: redirectUri,
    }),
  });
  if (!response.ok)
    throw new Error(`Token exchange failed: ${response.statusText}`);
  return response.json();
}

export async function getUserInfo(accessToken: string): Promise<User> {
  const cfg = getConfig();
  const response = await fetch(`https://${cfg.domain}/oauth2/v2/user_profile`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok)
    throw new Error(`getUserInfo failed: ${response.statusText}`);
  const data = await response.json();
  return {
    id: data.id,
    email: data.email,
    name:
      [data.given_name, data.family_name].filter(Boolean).join(" ") ||
      undefined,
    givenName: data.given_name,
    familyName: data.family_name,
  };
}
