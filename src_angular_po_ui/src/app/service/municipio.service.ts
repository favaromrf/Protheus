import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { MunicipiosResponse } from '../interface/municipio.interface'; // Ajuste o caminho se necessário
import { AppConfigService } from './app-config.service';

@Injectable({
  providedIn: 'root'
})
export class MunicipioService {

  private getHeaders(): HttpHeaders {
    // Pega as credenciais direto do AppConfigService
    const auth = this.appConfigService.auth;
    const credentials = btoa(`${auth?.usuario}:${auth?.senha}`);

    return new HttpHeaders({
      'Authorization': 'Basic ' + credentials,
      'Content-Type': 'application/json'
    });
  }
  
  constructor(
    private http: HttpClient,
    private appConfigService: AppConfigService // Injetando o service de configuração
  ) {}

  private get apiUrl(): string {
    // Pega a URL base do JSON e adiciona o endpoint específico do serviço (/restmunic)
    return `${this.appConfigService.apiUrl}/restmunic`;
  }

  getMunicipios(estado: string): Observable<MunicipiosResponse> {
    return this.http.get<MunicipiosResponse>(`${this.apiUrl}?estado=${estado}`, { headers: this.getHeaders() });
  }
}