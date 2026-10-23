import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../models/comissao.model';
import { AppConfigService } from './app-config.service';

@Injectable({
  providedIn: 'root'
})
export class ComissaoService {

  private getHeaders(): HttpHeaders {
    // Pega as credenciais direto do getter 'auth' do AppConfigService
    const auth = this.appConfigService.auth;
    const credentials = btoa(`${auth?.usuario}:${auth?.senha}`);

    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + credentials
    });
  }

  constructor(
    private http: HttpClient,
    private appConfigService: AppConfigService
  ) {}

  private get apiUrl(): string {
    // Pega a URL base diretamente do getter 'apiUrl' do AppConfigService
    return this.appConfigService.apiUrl;
  }

  getDadosTabela(tabela: string, page: number = 1, pageSize: number = 50): Observable<ApiResponse> {
    const url = `${this.apiUrl}/wsrestcogr/tabela?tabela=${tabela}&page=${page}&pageSize=${pageSize}`;
    return this.http.get<ApiResponse>(url, { headers: this.getHeaders() });
  }

  postDadosTabela(tabela: string, dados: any): Observable<any> {
    const url = `${this.apiUrl}/wsrestcogr/tabela?tabela=${tabela}`;
    return this.http.post<any>(url, dados, { headers: this.getHeaders() });
  }

  putComissaoTabela(tabela: string, dados: any): Observable<any> {
    const url = `${this.apiUrl}/wsrestcogr/tabela?tabela=${tabela}`;
    return this.http.put<any>(url, dados, { headers: this.getHeaders() });
  }
}