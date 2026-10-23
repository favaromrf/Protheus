import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AppConfigService } from './app-config.service';

export interface ItemComissao {
  ZZA_CODP: string;
  ZZA_DESCP: string;
  ZZA_COMIS: number;
}

export interface VendedorComissao {
  ZZA_CODV: string;
  ZZA_DESCV: string;
  itens: ItemComissao[];
}

@Injectable({
  providedIn: 'root'
})
export class ComissoesService {

  private get apiUrl(): string {
    return `${this.appConfigService.apiUrl}/wscomiszza`;
  }

  private get apiUrl2(): string {
    return `${this.appConfigService.apiUrl}/wscomiszza/copia`;
  }

  private getHeaders(): HttpHeaders {
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

  getVendedor(codigo: string): Observable<VendedorComissao> {
    return this.http.get<VendedorComissao>(`${this.apiUrl}/${codigo}`, { headers: this.getHeaders() });
  }

  criarRegistro(codigo: string, dados: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/${codigo}`, dados, { headers: this.getHeaders() });
  }

  copiarPerfil(codigoOrigem: string, codigoDestino: string): Observable<any> {
    return this.http.post(`${this.apiUrl2}/${codigoOrigem}/${codigoDestino}`, {}, { headers: this.getHeaders() });
  }

  atualizarRegistro(codigo: string, produto: string, dados: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/${codigo}/${produto}`, dados, { headers: this.getHeaders() });
  }

  deletarRegistro(codigo: string, produto: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${codigo}/${produto}`, { headers: this.getHeaders() });
  }
}