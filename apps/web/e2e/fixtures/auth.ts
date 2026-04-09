import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

export const PERSONAS = {
  p1: {
    email: "adalovelace@cloudvoyant.io",
    displayName: "Ada Lovelace",
  },
} as const;

export type PersonaKey = keyof typeof PERSONAS;

export interface Passwords {
  p1Password: string;
}

/**
 * Load E2E passwords from .env.e2e.local (never committed).
 * Falls back to environment variables (useful in CI after fetch-e2e-secrets).
 */
export function loadPasswords(): Passwords {
  const envPath = path.resolve(process.cwd(), ".env.e2e.local");
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
  }

  const p1Password = process.env.E2E_P1_PASSWORD;
  if (!p1Password) {
    throw new Error("E2E_P1_PASSWORD not set. Run: just fetch-e2e-secrets");
  }
  return { p1Password };
}
