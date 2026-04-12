import type { Session } from "./types";
import {
  validateAccessToken,
  isTokenExpiredError,
  refreshAccessToken,
  getUserInfo,
} from "./kinde-client";

export const SESSION_COOKIE_NAME = `${process.env.PROJECT ?? "nv-gcp-template"}_session`;

export function createSession(
  user: Session["user"],
  accessToken: string,
  expiresIn: number,
  refreshToken?: string,
): Session {
  return {
    user,
    accessToken,
    refreshToken,
    expiresAt: Date.now() + expiresIn * 1000,
  };
}

export function serializeSession(session: Session): string {
  return Buffer.from(JSON.stringify(session)).toString("base64");
}

export function deserializeSession(encoded: string): Session | null {
  try {
    return JSON.parse(
      Buffer.from(encoded, "base64").toString("utf-8"),
    ) as Session;
  } catch {
    return null;
  }
}

export function getSessionCookieOptions(isHttps: boolean) {
  return {
    path: "/",
    httpOnly: true,
    secure: isHttps,
    sameSite: "lax" as const,
    maxAge: 60 * 60 * 24 * 7, // 7 days
  };
}

async function refreshSession(session: Session): Promise<Session> {
  const { accessToken, refreshToken, expiresIn } = await refreshAccessToken(
    session.refreshToken!,
  );
  const updatedUser = await getUserInfo(accessToken);
  return createSession(updatedUser, accessToken, expiresIn, refreshToken);
}

export async function validateOrRefreshSession(session: Session): Promise<{
  status: "valid" | "refreshed" | "invalid";
  session: Session | null;
}> {
  try {
    await validateAccessToken(session.accessToken);
    return { status: "valid", session };
  } catch (err) {
    if (isTokenExpiredError(err) && session.refreshToken) {
      try {
        const newSession = await refreshSession(session);
        return { status: "refreshed", session: newSession };
      } catch {
        return { status: "invalid", session: null };
      }
    }
    return { status: "invalid", session: null };
  }
}
