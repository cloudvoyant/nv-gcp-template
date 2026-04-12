import type { Session } from "@nv-gcp-template/auth";

declare global {
  namespace App {
    interface Locals {
      session: Session | null;
    }
  }
}

export {};
