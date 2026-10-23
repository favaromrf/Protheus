export interface AuthConfig {
  usuario: string;
  senha: string;
}

export interface AppConfig {
  apiUrl: string;
  auth: AuthConfig;
}