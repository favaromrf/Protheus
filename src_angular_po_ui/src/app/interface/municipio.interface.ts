export interface MunicipioItem {
  municipio: string;
}

export interface MunicipiosResponse {
  status: string;
  total: number;
  municipios: MunicipioItem[];
}