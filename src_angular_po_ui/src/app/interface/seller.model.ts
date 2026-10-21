export interface Sx3FieldMetadata {
  valor: any;
  descricao: string;
  tipo: string;
  tamanho: number;
}

export interface Seller {
  A3_FILIAL?: Sx3FieldMetadata;
  A3_COD?: Sx3FieldMetadata;
  A3_NOME?: Sx3FieldMetadata;
  A3_NREDUZ?: Sx3FieldMetadata;
  A3_END?: Sx3FieldMetadata;
  A3_BAIRRO?: Sx3FieldMetadata;
  A3_MUN?: Sx3FieldMetadata;
  A3_EST?: Sx3FieldMetadata;
  A3_CEP?: Sx3FieldMetadata;
  A3_DDDTEL?: Sx3FieldMetadata;
  A3_MSBLQL?: Sx3FieldMetadata;
  A3_TEL?: Sx3FieldMetadata;
  A3_FAX?: Sx3FieldMetadata;
  A3_TELEX?: Sx3FieldMetadata;
  A3_TIPO?: Sx3FieldMetadata;
  A3_CGC?: Sx3FieldMetadata;
  A3_INSCR?: Sx3FieldMetadata;
  A3_INSCRM?: Sx3FieldMetadata;
  A3_EMAIL?: Sx3FieldMetadata;
  A3_HPAGE?: Sx3FieldMetadata;
  A3_CODUSR?: Sx3FieldMetadata;
  A3_SUPER?: Sx3FieldMetadata;
  A3_GEREN?: Sx3FieldMetadata;
  A3_FORNECE?: Sx3FieldMetadata;
  A3_LOJA?: Sx3FieldMetadata;
  A3_GERASE2?: Sx3FieldMetadata;
  A3_BCO1?: Sx3FieldMetadata;
  A3_REGIAO?: Sx3FieldMetadata;
  A3_COMIS?: Sx3FieldMetadata;
  A3_ALEMISS?: Sx3FieldMetadata;
  A3_ALBAIXA?: Sx3FieldMetadata;
  A3_ICM?: Sx3FieldMetadata;
  A3_ICMSRET?: Sx3FieldMetadata;
  A3_UNIDAD?: Sx3FieldMetadata;
  A3_ISS?: Sx3FieldMetadata;
  A3_IPI?: Sx3FieldMetadata;
  A3_REGSLA?: Sx3FieldMetadata;
  A3_QTCONTA?: Sx3FieldMetadata;
  A3_GRPREP?: Sx3FieldMetadata;
  A3_FRETE?: Sx3FieldMetadata;
  A3_ACREFIN?: Sx3FieldMetadata;
  A3_DIA?: Sx3FieldMetadata;
  A3_DDD?: Sx3FieldMetadata;
  A3_CARGO?: Sx3FieldMetadata;
  A3_PERDESC?: Sx3FieldMetadata;
  A3_TIPSUP?: Sx3FieldMetadata;
  A3_DIARESE?: Sx3FieldMetadata;
  A3_SENHA?: Sx3FieldMetadata;
  A3_PEDINI?: Sx3FieldMetadata;
  A3_PEDFIM?: Sx3FieldMetadata;
  A3_CLIINI?: Sx3FieldMetadata;
  A3_CLIFIM?: Sx3FieldMetadata;
  A3_PROXPED?: Sx3FieldMetadata;
  A3_PROXCLI?: Sx3FieldMetadata;
  A3_SINCTAF?: Sx3FieldMetadata;
  A3_FAT_RH?: Sx3FieldMetadata;
  A3_SINCAGE?: Sx3FieldMetadata;
  A3_GRUPSAN?: Sx3FieldMetadata;
  A3_SINCCON?: Sx3FieldMetadata;
  A3_DEPEND?: Sx3FieldMetadata;
  A3_PERAGE?: Sx3FieldMetadata;
  A3_PEN_ALI?: Sx3FieldMetadata;
  A3_PERTAF?: Sx3FieldMetadata;
  A3_TIPVEND?: Sx3FieldMetadata;
  A3_TIMEMIN?: Sx3FieldMetadata;
  A3_NUMRA?: Sx3FieldMetadata;
  A3_URLEXG?: Sx3FieldMetadata;
  A3_USUCORP?: Sx3FieldMetadata;
  A3_PAIS?: Sx3FieldMetadata;
  A3_HABSINC?: Sx3FieldMetadata;
  A3_DDI?: Sx3FieldMetadata;
  A3_CEL?: Sx3FieldMetadata;
  A3_ADMISS?: Sx3FieldMetadata;
  A3_NVLSTR?: Sx3FieldMetadata;
  A3_NIVEL?: Sx3FieldMetadata;
  A3_LANEXG?: Sx3FieldMetadata;
  A3_PISCOF?: Sx3FieldMetadata;
  A3_EMACORP?: Sx3FieldMetadata;
  A3_BIAGEND?: Sx3FieldMetadata;
  A3_BITAREF?: Sx3FieldMetadata;
  A3_BICONT?: Sx3FieldMetadata;
  A3_CODISS?: Sx3FieldMetadata;
  A3_MSEXP?: Sx3FieldMetadata;
  A3_HREXPO?: Sx3FieldMetadata;
  A3_BASEIR?: Sx3FieldMetadata;
  A3_HRUMOV?: Sx3FieldMetadata;
  A3_DTUMOV?: Sx3FieldMetadata;
  A3_FILFUN?: Sx3FieldMetadata;
  A3_SNAEXG?: Sx3FieldMetadata;
  A3_MODTRF?: Sx3FieldMetadata;
  A3_COMIS2?: Sx3FieldMetadata;
  A3_COMIS3?: Sx3FieldMetadata;
  
  // Propriedades auxiliares de exibição na tabela
  code?: string;
  name?: string;
  personalIdentification?: string;
  active?: boolean;

  [key: string]: any;
}

export interface SellerResponse {
  vendedores?: Seller[];
  items?: Seller[];
  hasNext?: boolean;
}