import { exchangeCodeForToken, getUserInfo } from "./kinde-client";
import { createSession } from "./session";
import type { Session } from "./types";

export async function createSessionFromCode(
  code: string,
  origin: string,
): Promise<Session> {
  const redirectUri = `${origin}/auth/callback`;
  const tokens = await exchangeCodeForToken(code, redirectUri);
  const user = await getUserInfo(tokens.access_token);
  return createSession(
    user,
    tokens.access_token,
    tokens.expires_in,
    tokens.refresh_token,
  );
}
