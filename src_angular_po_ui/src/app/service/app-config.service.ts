import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { AppConfig } from '../models/app-config.model'; // Ajuste o caminho do model se necessário

@Injectable({
  providedIn: 'root'
})
export class AppConfigService {
  private config!: AppConfig;

  constructor(private http: HttpClient) {}

  loadConfig(): Promise<void> {
    return firstValueFrom(
      this.http.get<AppConfig>('./assets/data/appConfig.json')
    ).then(data => {
      this.config = data;
    }).catch(error => {
      console.error('Erro ao carregar o arquivo de configuração:', error);
    });
  }

  get apiUrl(): string {
    return this.config?.apiUrl;
  }

  get auth() {
    return this.config?.auth;
  }
}