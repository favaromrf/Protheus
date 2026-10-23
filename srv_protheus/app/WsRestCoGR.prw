#Include "totvs.ch"
#Include "restful.ch"

WsRestful WsRestCoGR Description "API REST para consulta de tabelas e comissões Por Grupos do Protheus (SA1, SB1, SBM, ACY, ACN, DES)" 

    WSDATA page     AS INTEGER OPTIONAL
    WSDATA pageSize AS INTEGER OPTIONAL
    WSDATA tabela   AS STRING  OPTIONAL

    WSMETHOD GET  Description "Retorna os dados dos campos de comissão e tabelas solicitadas" WSSYNTAX "/tabela" PATH "/tabela" PRODUCES APPLICATION_JSON
    WSMETHOD POST Description "Inclui um novo registro nas tabelas SBM, ACY ou ACN" WSSYNTAX "/tabela" PATH "/tabela" PRODUCES APPLICATION_JSON
    WSMETHOD PUT  Description "Atualiza exclusivamente os campos de comissão nas tabelas SBM, ACY ou ACN" WSSYNTAX "/tabela" PATH "/tabela" PRODUCES APPLICATION_JSON

End WsRestful

/*-------------------------------------------------------------------
  Método GET
-------------------------------------------------------------------*/
WSMETHOD GET WSSERVICE WsRestCoGR
    Local lRet      := .T.
    Local cTabela   := Upper(AllTrim(::tabela))
    Local nPage     := IIf(::page == NIL, 1, ::page)
    Local nPageSize := IIf(::pageSize == NIL, 50, ::pageSize)
    Local cJson     := ""
    Local oJson     := JsonObject():New()
    Local aDados    := {}
    
    If Empty(cTabela)
        SetRestFault(400, "O parametro 'tabela' e obrigatorio (Valores aceitos: SA1, SB1, SBM, ACY, ACN, DES).")
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
            SetRestFault(400, "Tabela invalida para GET.")
            Return .F.
    EndCase

    oJson['tabela'] := cTabela
    oJson['pagina'] := nPage
    oJson['itens']  := aDados

    cJson := oJson:ToJson()

    ::SetContentType("application/json")
    ::SetResponse(cJson)

Return lRet

/*-------------------------------------------------------------------
  Método POST (Inclusão completa)
-------------------------------------------------------------------*/
WSMETHOD POST WSSERVICE WsRestCoGR
    Local lRet      := .T.
    Local cTabela   := Upper(AllTrim(::tabela))
    Local cBody     := ::GetContent()
    Local oJson     := JsonObject():New()
    Local oRes      := JsonObject():New()
    Local cError    := JsonObject():New()

    If Empty(cTabela)
        SetRestFault(400, "O parametro 'tabela' e obrigatorio.")
        Return .F.
    EndIf

    If !(cTabela $ "SBM/ACY/ACN")
        SetRestFault(400, "A tabela informada nao permite operacao de POST (Apenas SBM, ACY e ACN).")
        Return .F.
    EndIf

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetStatus(400)
        oResponse["error"] := "JSON inválido: " + cError
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    Do Case
        Case cTabela == "SBM"
            lRet := fIncluiSBM(oJson, @oRes)
        Case cTabela == "ACY"
            lRet := fIncluiACY(oJson, @oRes)
        Case cTabela == "ACN"
            lRet := fIncluiACN(oJson, @oRes)
    EndCase

    If lRet
        ::SetContentType("application/json")
        ::SetResponse(oRes:ToJson())
    EndIf

Return lRet

/*-------------------------------------------------------------------
  Método PUT (Atualização exclusiva de comissões)
-------------------------------------------------------------------*/
WSMETHOD PUT WSSERVICE WsRestCoGR
    Local lRet      := .T.
    Local cTabela   := Upper(AllTrim(::tabela))
    Local cBody     := ::GetContent()
    Local oJson     := JsonObject():New()
    Local oRes      := JsonObject():New()
    Local cError    := JsonObject():New()
    If Empty(cTabela)
        SetRestFault(400, "O parametro 'tabela' e obrigatorio.")
        Return .F.
    EndIf

    If !(cTabela $ "SBM/ACY/ACN")
        SetRestFault(400, "A tabela informada nao permite operacao de PUT (Apenas SBM, ACY e ACN).")
        Return .F.
    EndIf

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetStatus(400)
        oResponse["error"] := "JSON inválido: " + cError
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    Do Case
        Case cTabela == "SBM"
            lRet := fAlteraSBM(oJson, @oRes)
        Case cTabela == "ACY"
            lRet := fAlteraACY(oJson, @oRes)
        Case cTabela == "ACN"
            lRet := fAlteraACN(oJson, @oRes)
    EndCase

    If lRet
        ::SetContentType("application/json")
        ::SetResponse(oRes:ToJson())
    EndIf

Return lRet


/*-------------------------------------------------------------------
  Funções Auxiliares de Consulta por Tabela (GET)
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
    cQuery += "  AND B1_MSBLQL <> '1' "
    cQuery += "  AND UPPER(RTRIM(B1_TIPO)) IN ('PA', 'ME') "
    
    aRes := ExecQueryToJson(cQuery, nPage, nPageSize)
Return aRes


/*-------------------------------------------------------------------
  Funções de Inclusão (POST) com FwXFilial automática
-------------------------------------------------------------------*/

Static Function fIncluiSBM(oJson, oRes)
    Local lRet := .T.
    Local cFilSBM := FwXFilial("SBM")
    
    If !oJson:HasProperty("BM_GRUPO")
        SetRestFault(400, "O campo 'BM_GRUPO' e obrigatorio.")
        Return .F.
    EndIf

    DbSelectArea("SBM")
    SBM->(DbSetOrder(1)) // BM_FILIAL + BM_GRUPO
    If SBM->(MsSeek(cFilSBM + oJson['BM_GRUPO']))
        SetRestFault(409, "Registro ja cadastrado para o grupo " + oJson['BM_GRUPO'])
        Return .F.
    EndIf

    RecLock("SBM", .T.)
    SBM->BM_FILIAL := cFilSBM
    SBM->BM_GRUPO  := oJson['BM_GRUPO']
    If oJson:HasProperty("BM_DESC");   SBM->BM_DESC   := oJson['BM_DESC'];   EndIf
    If oJson:HasProperty("BM_COMIS1"); SBM->BM_COMIS1 := oJson['BM_COMIS1']; EndIf
    If oJson:HasProperty("BM_COMIS2"); SBM->BM_COMIS2 := oJson['BM_COMIS2']; EndIf
    If oJson:HasProperty("BM_COMIS3"); SBM->BM_COMIS3 := oJson['BM_COMIS3']; EndIf
    If oJson:HasProperty("BM_COMIS4"); SBM->BM_COMIS4 := oJson['BM_COMIS4']; EndIf
    SBM->(MsUnlock())

    oRes['status']   := "Sucesso"
    oRes['mensagem'] := "Registro incluido com sucesso na SBM."
    oRes['BM_GRUPO'] := oJson['BM_GRUPO']
Return lRet

Static Function fIncluiACY(oJson, oRes)
    Local lRet := .T.
    Local cFilACY := FwXFilial("ACY")
    
    If !oJson:HasProperty("ACY_GRPVEN")
        SetRestFault(400, "O campo 'ACY_GRPVEN' e obrigatorio.")
        Return .F.
    EndIf

    DbSelectArea("ACY")
    ACY->(DbSetOrder(1)) // ACY_FILIAL + ACY_GRPVEN
    If ACY->(MsSeek(cFilACY + oJson['ACY_GRPVEN']))
        SetRestFault(409, "Registro ja cadastrado para o grupo de vendas " + oJson['ACY_GRPVEN'])
        Return .F.
    EndIf

    RecLock("ACY", .T.)
    ACY->ACY_FILIAL := cFilACY
    ACY->ACY_GRPVEN := oJson['ACY_GRPVEN']
    
    If oJson:HasProperty("ACY_DESCRI"); ACY->ACY_DESCRI := oJson['ACY_DESCRI']; EndIf
    If oJson:HasProperty("ACY_COMIS1"); ACY->ACY_COMIS1 := oJson['ACY_COMIS1']; EndIf
    If oJson:HasProperty("ACY_COMIS2"); ACY->ACY_COMIS2 := oJson['ACY_COMIS2']; EndIf
    If oJson:HasProperty("ACY_COMIS3"); ACY->ACY_COMIS3 := oJson['ACY_COMIS3']; EndIf
    If oJson:HasProperty("ACY_COMIS4"); ACY->ACY_COMIS4 := oJson['ACY_COMIS4']; EndIf
    
    ACY->(MsUnlock())

    oRes['status']     := "Sucesso"
    oRes['mensagem']   := "Registro incluido com sucesso na ACY."
    oRes['ACY_GRPVEN'] := oJson['ACY_GRPVEN']
Return lRet

Static Function fIncluiACN(oJson, oRes)
    Local lRet := .T.
    Local cFilACN := FwXFilial("ACN")
    
    If !oJson:HasProperty("ACN_GRPPRO") .Or. !oJson:HasProperty("ACN_CODREG") .Or. !oJson:HasProperty("ACN_ITEM")
        SetRestFault(400, "Os campos 'ACN_GRPPRO', 'ACN_CODREG' e 'ACN_ITEM' sao obrigatorios.")
        Return .F.
    EndIf

    DbSelectArea("ACN")
    ACN->(DbSetOrder(1)) // ACN_FILIAL + ACN_GRPPRO + ACN_CODREG + ACN_ITEM
    If ACN->(MsSeek(cFilACN + oJson['ACN_GRPPRO'] + oJson['ACN_CODREG'] + oJson['ACN_ITEM']))
        SetRestFault(409, "Registro ja cadastrado na ACN para a chave informada.")
        Return .F.
    EndIf

    RecLock("ACN", .T.)
    ACN->ACN_FILIAL := cFilACN
    ACN->ACN_GRPPRO := oJson['ACN_GRPPRO']
    ACN->ACN_CODREG := oJson['ACN_CODREG']
    ACN->ACN_ITEM   := oJson['ACN_ITEM']
    If oJson:HasProperty("ACN_CODPRO"); ACN->ACN_CODPRO := oJson['ACN_CODPRO']; EndIf
    If oJson:HasProperty("ACN_DESCON"); ACN->ACN_DESCON := oJson['ACN_DESCON']; EndIf
    If oJson:HasProperty("ACN_ITEMGR"); ACN->ACN_ITEMGR := oJson['ACN_ITEMGR']; EndIf
    If oJson:HasProperty("ACN_COMIS1"); ACN->ACN_COMIS1 := oJson['ACN_COMIS1']; EndIf
    If oJson:HasProperty("ACN_COMIS2"); ACN->ACN_COMIS2 := oJson['ACN_COMIS2']; EndIf
    If oJson:HasProperty("ACN_COMIS3"); ACN->ACN_COMIS3 := oJson['ACN_COMIS3']; EndIf
    If oJson:HasProperty("ACN_COMIS4"); ACN->ACN_COMIS4 := oJson['ACN_COMIS4']; EndIf
    ACN->(MsUnlock())

    oRes['status']   := "Sucesso"
    oRes['mensagem'] := "Registro incluido com sucesso na ACN."
Return lRet


/*-------------------------------------------------------------------
  Funções de Atualização Exclusiva de Comissão (PUT) com FwXFilial
-------------------------------------------------------------------*/

Static Function fAlteraSBM(oJson, oRes)
    Local lRet := .T.
    Local cFilSBM := FwXFilial("SBM")
    
    If !oJson:HasProperty("BM_GRUPO")
        SetRestFault(400, "O campo 'BM_GRUPO' e obrigatorio para localizar o registro.")
        Return .F.
    EndIf

    DbSelectArea("SBM")
    SBM->(DbSetOrder(1))
    If !SBM->(MsSeek(cFilSBM + oJson['BM_GRUPO']))
        SetRestFault(404, "Registro nao encontrado na SBM para o grupo " + oJson['BM_GRUPO'])
        Return .F.
    EndIf

    RecLock("SBM", .F.)
    If oJson:HasProperty("BM_COMIS1"); SBM->BM_COMIS1 := oJson['BM_COMIS1']; EndIf
    If oJson:HasProperty("BM_COMIS2"); SBM->BM_COMIS2 := oJson['BM_COMIS2']; EndIf
    If oJson:HasProperty("BM_COMIS3"); SBM->BM_COMIS3 := oJson['BM_COMIS3']; EndIf
    If oJson:HasProperty("BM_COMIS4"); SBM->BM_COMIS4 := oJson['BM_COMIS4']; EndIf
    SBM->(MsUnlock())

    oRes['status']   := "Sucesso"
    oRes['mensagem'] := "Comissoes atualizadas com sucesso na SBM."
    oRes['BM_GRUPO'] := oJson['BM_GRUPO']
Return lRet

Static Function fAlteraACY(oJson, oRes)
    Local lRet := .T.
    Local cFilACY := FwXFilial("ACY")
    
    If !oJson:HasProperty("ACY_GRPVEN")
        SetRestFault(400, "O campo 'ACY_GRPVEN' e obrigatorio para localizar o registro.")
        Return .F.
    EndIf

    DbSelectArea("ACY")
    ACY->(DbSetOrder(1))
    If !ACY->(MsSeek(cFilACY + oJson['ACY_GRPVEN']))
        SetRestFault(404, "Registro nao encontrado na ACY para o grupo de vendas " + oJson['ACY_GRPVEN'])
        Return .F.
    EndIf

    RecLock("ACY", .F.)
    If oJson:HasProperty("ACY_COMIS1"); ACY->ACY_COMIS1 := oJson['ACY_COMIS1']; EndIf
    If oJson:HasProperty("ACY_COMIS2"); ACY->ACY_COMIS2 := oJson['ACY_COMIS2']; EndIf
    If oJson:HasProperty("ACY_COMIS3"); ACY->ACY_COMIS3 := oJson['ACY_COMIS3']; EndIf
    If oJson:HasProperty("ACY_COMIS4"); ACY->ACY_COMIS4 := oJson['ACY_COMIS4']; EndIf
    ACY->(MsUnlock())

    oRes['status']     := "Sucesso"
    oRes['mensagem']   := "Comissoes atualizadas com sucesso na ACY."
    oRes['ACY_GRPVEN'] := oJson['ACY_GRPVEN']
Return lRet

Static Function fAlteraACN(oJson, oRes)
    Local lRet := .T.
    Local cFilACN := FwXFilial("ACN")
    
    If !oJson:HasProperty("ACN_GRPPRO") .Or. !oJson:HasProperty("ACN_CODREG") .Or. !oJson:HasProperty("ACN_ITEM")
        SetRestFault(400, "Os campos 'ACN_GRPPRO', 'ACN_CODREG' e 'ACN_ITEM' sao obrigatorios para localizar o registro.")
        Return .F.
    EndIf

    DbSelectArea("ACN")
    ACN->(DbSetOrder(1))
    If !ACN->(MsSeek(cFilACN + oJson['ACN_GRPPRO'] + oJson['ACN_CODREG'] + oJson['ACN_ITEM']))
        SetRestFault(404, "Registro nao encontrado na ACN para a chave informada.")
        Return .F.
    EndIf

    RecLock("ACN", .F.)
    If oJson:HasProperty("ACN_COMIS1"); ACN->ACN_COMIS1 := oJson['ACN_COMIS1']; EndIf
    If oJson:HasProperty("ACN_COMIS2"); ACN->ACN_COMIS2 := oJson['ACN_COMIS2']; EndIf
    If oJson:HasProperty("ACN_COMIS3"); ACN->ACN_COMIS3 := oJson['ACN_COMIS3']; EndIf
    If oJson:HasProperty("ACN_COMIS4"); ACN->ACN_COMIS4 := oJson['ACN_COMIS4']; EndIf
    ACN->(MsUnlock())

    oRes['status']   := "Sucesso"
    oRes['mensagem'] := "Comissoes atualizadas com sucesso na ACN."
Return lRet


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
