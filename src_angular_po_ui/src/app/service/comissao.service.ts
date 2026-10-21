import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../models/comissao.model';

@Injectable({
  providedIn: 'root'
})
export class ComissaoService {

  private apiUrl = 'http://localhost:9595/rest/wsrestcogr/tabela';

  private getHeaders(): HttpHeaders {
    const credentials = btoa('admin:xadrez392@D');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + credentials
    });
  }

  constructor(private http: HttpClient) {}

  /**
   * Busca os dados de qualquer tabela suportada pela API (SA1, SB1, SBM, ACY, ACN, DES)
   * mantendo paginação e o retorno exato dos itens.
   */
  getDadosTabela(tabela: string, page: number = 1, pageSize: number = 50): Observable<ApiResponse> {
    const params = new HttpParams()
      .set('tabela', tabela)
      .set('page', page.toString())
      .set('pageSize', pageSize.toString());

    return this.http.get<ApiResponse>(this.apiUrl, {
      headers: this.getHeaders(),
      params: params
    });
  }
}