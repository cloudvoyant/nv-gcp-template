import type { Session } from "@mise-app-template/auth";

declare global {
  namespace App {
    interface Locals {
      session: Session | null;
    }
  }
}

export {};
