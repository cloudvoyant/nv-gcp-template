import * as path from "path";
import * as dotenv from "dotenv";
import { PERSONAS } from "../personas";

// Load passwords from .env.e2e.local (written by fetch-e2e-secrets.sh)
dotenv.config({ path: path.resolve(process.cwd(), ".env.e2e.local") });

export function loadPasswords(): {
  p1Password: string;
  p2Password: string | undefined;
} {
  const p1Password = process.env.E2E_P1_PASSWORD;
  const p2Password = process.env.E2E_P2_PASSWORD;

  if (!p1Password) {
    throw new Error(
      "Missing E2E_P1_PASSWORD.\nRun: mise run fetch-e2e-secrets",
    );
  }

  return { p1Password, p2Password };
}

export { PERSONAS };
