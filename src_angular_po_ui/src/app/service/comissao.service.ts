import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../models/comissao.model';

@Injectable({
  providedIn: 'root'
})
export class ComissaoService {

  private apiUrl = 'http://dacolonia196730.protheus.cloudtotvs.com.br:10422/rest/wsrestcogr';

  private getHeaders(): HttpHeaders {
    const credentials = btoa('totvs.everton:T@tvs2026');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + credentials
    });
  }

  constructor(private http: HttpClient) {}

  getDadosTabela(tabela: string, page: number = 1, pageSize: number = 50): Observable<ApiResponse> {
    // Montando a URL idêntica ao Postman
    const url = `${this.apiUrl}/tabela?tabela=${tabela}&page=${page}&pageSize=${pageSize}`;
    return this.http.get<ApiResponse>(url, { headers: this.getHeaders() });
  }

  postDadosTabela(tabela: string, dados: any): Observable<any> {
    const url = `${this.apiUrl}/tabela?tabela=${tabela}`;
    return this.http.post<any>(url, dados, { headers: this.getHeaders() });
  }

  putComissaoTabela(tabela: string, dados: any): Observable<any> {
    const url = `${this.apiUrl}/tabela?tabela=${tabela}`;
    return this.http.put<any>(url, dados, { headers: this.getHeaders() });
  }
}