#Include "totvs.ch"
#Include "restful.ch"

WsRestful WsRestCoGR Description "API REST para consulta de tabelas e comissões Por Grupos do Protheus (SA1, SB1, SBM, ACY, ACN, DES)" 

    WSDATA page     AS INTEGER OPTIONAL
    WSDATA pageSize AS INTEGER OPTIONAL
    WSDATA tabela   AS STRING  OPTIONAL

    WSMETHOD GET Description "Retorna os dados dos campos de comissão e tabelas solicitadas" WSSYNTAX "/tabela" PATH "/tabela" PRODUCES APPLICATION_JSON

End WsRestful

WSMETHOD GET WSSERVICE WsRestCoGR
    Local lRet      := .T.
    Local cTabela   := Upper(AllTrim(::tabela))
    Local nPage     := IIf(::page == NIL, 1, ::page)
    Local nPageSize := IIf(::pageSize == NIL, 50, ::pageSize)
    Local cJson     := ""
    Local oJson     := JsonObject():New()
    Local aDados    := {}
    
    // Validação da tabela solicitada
    If Empty(cTabela)
        SetRestFault(400, "O parametro 'tabela' e obrigatorio (Valores aceitos: SA1, SB1, SBM, ACY, ACN).")
        Return .F.
    EndIf

    Do Case
        Case cTabela == "SA1"
            aDados := fBuscaSA1(nPage, nPageSize)
        Case cTabela == "SB1"
            aDados := fBuscaSB1(nPage, nPageSize)
        Case cTabela == "SBM"
            aDados := fBuscaSBM(nPage, nPageSize)
        Case cTabela == "ACY"
            aDados := fBuscaACY(nPage, nPageSize)
        Case cTabela == "ACN"
            aDados := fBuscaACN(nPage, nPageSize)
        Case cTabela == "DES"
            aDados := fBuscaDES(nPage, nPageSize)
        Other
            SetRestFault(400, "Tabela invalida. Informe SA1, SB1, SBM, ACY ou ACN. // DES PARA DESCICAO DE PRODUTO")
            Return .F.
    EndCase

    // Monta o retorno JSON
    oJson['tabela'] := cTabela
    oJson['pagina'] := nPage
    oJson['itens']  := aDados

    cJson := oJson:ToJson()

    ::SetContentType("application/json")
    ::SetResponse(cJson)

Return lRet

/*-------------------------------------------------------------------
  Funções Auxiliares de Consulta por Tabela
-------------------------------------------------------------------*/

Static Function fBuscaSA1(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT A1_GRPVEN, A1_COMIS1, A1_COMIS2, A1_COMIS3, A1_COMIS4 "
    cQuery += "FROM " + RetSqlName("SA1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' '"
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


Static Function fBuscaSB1(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT B1_GRUPO, B1_COMIS1, B1_COMIS2, B1_COMIS3, B1_COMIS4 "
    cQuery += "FROM " + RetSqlName("SB1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' '"
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


Static Function fBuscaSBM(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT BM_GRUPO, BM_DESC, BM_COMIS1, BM_COMIS2, BM_COMIS3, BM_COMIS4 "
    cQuery += "FROM " + RetSqlName("SBM") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' '"
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


Static Function fBuscaACY(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT ACY_GRPVEN, ACY_DESCRI, ACY_GRPSUP, ACY_CHAVE, ACY_HREXPO, ACY_MSEXP, ACY_COMIS1, ACY_COMIS2, ACY_COMIS3, ACY_COMIS4 "
    cQuery += "FROM " + RetSqlName("ACY") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' '"
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


Static Function fBuscaACN(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT ACN_GRPPRO, ACN_CODREG, ACN_ITEM, ACN_CODPRO, ACN_DESCON, ACN_ITEMGR, ACN_COMIS1, ACN_COMIS2, ACN_COMIS3, ACN_COMIS4 "
    cQuery += "FROM " + RetSqlName("ACN") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' '"
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


Static Function fBuscaDES(nPage, nPageSize)
    Local aRes := {}
    Local cQuery := ""
    
    cQuery := "SELECT B1_COD, B1_DESC "
    cQuery += "FROM " + RetSqlName("SB1") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    // Garante que não está bloqueado (B1_MSBLQL diferente de 1 ou igual a 2/vazio)
    cQuery += "  AND B1_MSBLQL <> '1' "
    // Filtra estritamente para que o tipo seja PA ou ME (tratando espaços e maiúsculas)
    cQuery += "  AND UPPER(RTRIM(B1_TIPO)) IN ('PA', 'ME') "
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes

/*-------------------------------------------------------------------
  Função genérica para conversão de SQL para Array de Objetos JSON
-------------------------------------------------------------------*/
Static Function ExecQueryToJson(cQuery, nPage, nPageSize)
    Local aRet      := {}
    Local cAliasQry := GetNextAlias()
    Local nX        := 0
    Local aStruct   := {}
    Local nStart    := ((nPage - 1) * nPageSize) + 1
    Local nCount    := 0
    Local oRow      := NIL
    Local xVal      := ""
    Local cField    := ""

    // Paginação compatível (exemplo simplificado via cursor/recno ou TOP se preferir otimizar por banco)
    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAliasQry, .T., .T.)
    
    aStruct := (cAliasQry)->(DbStruct())

    (cAliasQry)->(DbGoTop())
    While (cAliasQry)->(!Eof())
        nCount++
        If nCount >= nStart .And. Len(aRet) < nPageSize
            oRow := JsonObject():New()
            For nX := 1 To Len(aStruct)
                cField := aStruct[nX][1]
                xVal   := (cAliasQry)->(&(cField))
                
                // Trata tipos para JSON
                If ValType(xVal) == "D"
                    xVal := DToS(xVal)
                ElseIf ValType(xVal) == "C"
                    xVal := AllTrim(xVal)
                EndIf
                
                oRow[cField] := xVal
            Next nX
            AAdd(aRet, oRow)
        EndIf
        
        If Len(aRet) >= nPageSize
            Exit
        EndIf
        
        (cAliasQry)->(DbSkip())
    EndDo

    (cAliasQry)->(DbCloseArea())
Return aRet
