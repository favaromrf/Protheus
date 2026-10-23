import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { MunicipiosResponse } from '../interface/municipio.interface'; // Ajuste o caminho se necessário

@Injectable({
  providedIn: 'root'
})
export class MunicipioService { // <-- Note a palavra 'export' aqui
  private apiUrl = 'http://dacolonia196730.protheus.cloudtotvs.com.br:10422/rest/restmunic';
  private getHeaders() {
    return new HttpHeaders({
      'Authorization': 'Basic ' + btoa('totvs.everton:T@tvs2026'), // Substitua por sua credencial ou Token Bearer
      'Content-Type': 'application/json'
    });
  }
  
  constructor(private http: HttpClient) {}

  getMunicipios(estado: string): Observable<MunicipiosResponse> {
    return this.http.get<MunicipiosResponse>(`${this.apiUrl}?estado=${estado}`, { headers: this.getHeaders() });
  }
}