import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { map, Observable } from 'rxjs';
import { Seller, SellerResponse } from '../interface/seller.model';

@Injectable({
  providedIn: 'root'
})
export class SellerService {
  private http = inject(HttpClient);
  private apiUrl = 'http://dacolonia196730.protheus.cloudtotvs.com.br:10422/rest/wsrestsa3/vendedores'; 

  private getHeaders() {
    return new HttpHeaders({
      'Authorization': 'Basic ' + btoa('totvs.everton:T@tvs2026'),
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