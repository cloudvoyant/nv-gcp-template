export interface KindeConfig {
  domain: string;
  clientId: string;
  clientSecret: string;
}

export interface User {
  id: string;
  email: string;
  name?: string;
  givenName?: string;
  familyName?: string;
}

export interface Session {
  user: User;
  accessToken: string;
  refreshToken?: string;
  expiresAt: number;
}
