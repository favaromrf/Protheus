import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { Seller, SellerResponse } from '../interface/seller.model';
import { AppConfigService } from './app-config.service';

@Injectable({
  providedIn: 'root'
})
export class SellerService {
  private http = inject(HttpClient);
  private appConfigService = inject(AppConfigService); // Injetando o service de configuração

  private get apiUrl(): string {
    // Pega a URL base do JSON e adiciona o endpoint específico do serviço (/wsrestsa3/vendedores)
    return `${this.appConfigService.apiUrl}/wsrestsa3/vendedores`;
  }

  private getHeaders(): HttpHeaders {
    // Pega as credenciais direto do AppConfigService
    const auth = this.appConfigService.auth;
    const credentials = btoa(`${auth?.usuario}:${auth?.senha}`);

    return new HttpHeaders({
      'Authorization': 'Basic ' + credentials,
      'Content-Type': 'application/json'
    });
  }

  getSellers(): Observable<SellerResponse> {
    return this.http.get<SellerResponse>(this.apiUrl, { headers: this.getHeaders() }).pipe(
      map((response: any) => {
        const listaVendedores = response.vendedores || response.items || [];
        
        const normalizedItems = listaVendedores.map((item: any) => {
          const getVal = (field: any) => (field && typeof field === 'object' && 'valor' in field) ? field.valor : field;

          return {
            ...item,
            code: getVal(item.A3_COD),
            name: getVal(item.A3_NOME),
            personalIdentification: getVal(item.A3_CGC),
            active: getVal(item.A3_MSBLQL) !== '1'
          };
        });

        return {
          hasNext: response.hasNext || false,
          items: normalizedItems,
          vendedores: normalizedItems
        };
      })
    );
  }

  createSeller(seller: any): Observable<any> {
    return this.http.post<any>(this.apiUrl, seller, { headers: this.getHeaders() });
  }

  updateSeller(code: string, seller: any): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/${code}`, seller, { headers: this.getHeaders() });
  }
}