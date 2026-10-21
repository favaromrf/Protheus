export interface ApiResponse<T = any> {
  tabela: string;
  pagina: number;
  itens: T[];
}

export interface Sa1Item {
  A1_GRPVEN: string;
  A1_COMIS1: number;
  A1_COMIS2: number;
  A1_COMIS3: number;
  A1_COMIS4: number;
}

export interface Sb1Item {
  B1_GRUPO: string;
  B1_COMIS1: number;
  B1_COMIS2: number;
  B1_COMIS3: number;
  B1_COMIS4: number;
}

export interface SbmItem {
  BM_GRUPO: string;
  BM_DESC: string;
  BM_COMIS1: number;
  BM_COMIS2: number;
  BM_COMIS3: number;
  BM_COMIS4: number;
}

export interface AcyItem {
  ACY_GRPVEN: string;
  ACY_DESCRI: string;
  ACY_GRPSUP: string;
  ACY_CHAVE: string;
  ACY_HREXPO: string;
  ACY_MSEXP: string;
  ACY_COMIS1: number;
  ACY_COMIS2: number;
  ACY_COMIS3: number;
  ACY_COMIS4: number;
}

export interface AcnItem {
  ACN_GRPPRO: string;
  ACN_CODREG: string;
  ACN_ITEM: string;
  ACN_CODPRO: string;
  ACN_DESCON: string;
  ACN_ITEMGR: string;
  ACN_COMIS1: number;
  ACN_COMIS2: number;
  ACN_COMIS3: number;
  ACN_COMIS4: number;
}

export interface DesItem {
  B1_COD: string;
  B1_DESC: string;
}