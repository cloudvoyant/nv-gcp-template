/**
 * E2E test persona definitions. Emails are committed; passwords are fetched
 * from GCP Secret Manager via `mise run fetch-e2e-secrets`.
 *
 * One-time setup:
 *   1. Create both users in Kinde (nonprod app).
 *   2. Run `mise run fetch-e2e-secrets` to pull passwords into .env.e2e.local.
 */
export const PERSONAS = {
  p1: {
    email: "adalovelace@cloudvoyant.io",
    displayName: "Ada Lovelace",
  },
  p2: {
    email: "alanturing@cloudvoyant.io",
    handle: undefined as string | undefined,
  },
} as const;
