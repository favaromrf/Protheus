#INCLUDE "TOTVS.ch"
#INCLUDE "RESTFUL.ch"

WsRestful WsComisZZA Description "API de Comissoes de Vendedores e Produtos"

    WSDATA codigo AS CHARACTER OPTIONAL
    WSDATA codigodestino AS CHARACTER OPTIONAL
    WSDATA produto AS CHARACTER OPTIONAL

    WSMETHOD GET DESCRIPTION "Retorna os itens de um determinado vendedor" WSSYNTAX "/wscomiszza/{codigo}" PATH "/wscomiszza/{codigo}" PRODUCES APPLICATION_JSON

    // POST com ID diferenciado para a criação de registro
    WSMETHOD POST CriaZZA DESCRIPTION "Cria um registro na tabela ZZA" WSSYNTAX "/wscomiszza/{codigo}" PATH "/wscomiszza/{codigo}" PRODUCES APPLICATION_JSON
    
    // POST com ID diferenciado para a cópia de perfil
    WSMETHOD POST CopiaPerfil DESCRIPTION "Copia Perfil do Vendedor" WSSYNTAX "/copia/{codigo}/{codigodestino}" PATH "/copia/{codigo}/{codigodestino}" PRODUCES APPLICATION_JSON    
    
    WSMETHOD PUT DESCRIPTION "Altera um registro especifico de vendedor e produto" WSSYNTAX "/wscomiszza/{codigo}/{produto}" PATH "/wscomiszza/{codigo}/{produto}" PRODUCES APPLICATION_JSON
    WSMETHOD DELETE DESCRIPTION "Exclui um registro especifico de vendedor e produto" WSSYNTAX "/wscomiszza/{codigo}/{produto}" PATH "/wscomiszza/{codigo}/{produto}" PRODUCES APPLICATION_JSON

End WsRestful

//-------------------------------------------------------------------
// MÉTODO GET: Retorna os itens de um vendedor específico
//-------------------------------------------------------------------
WSMETHOD GET WSSERVICE WsComisZZA
    Local cCodVendedor := AllTrim(::codigo)
    Local cAliasZZA    := GetNextAlias()
    Local cQuery       := ""
    Local oJsonRoot    := JsonObject():new()
    Local aItens       := {}
    Local oItem        := NIL
    Local lRet         := .T.

    If Empty(cCodVendedor)
        ::SetStatus(400)
        ::SetResponse('{"error": "O codigo do vendedor e obrigatorio."}')
        Return .F.
    EndIf

    cQuery := "SELECT ZZA_FILIAL, ZZA_CODV, ZZA_DESCV, ZZA_CODP, ZZA_DESCP, ZZA_COMIS "
    cQuery += "FROM " + RetSqlName("ZZA") + " "
    cQuery += "WHERE ZZA_CODV = '" + cCodVendedor + "' AND D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY ZZA_CODP"

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,,cQuery), cAliasZZA, .T., .T.)

    If (cAliasZZA)->(Eof())
        ::SetStatus(404)
        ::SetResponse('{"error": "Vendedor nao encontrado ou sem itens cadastrados."}')
        (cAliasZZA)->(DbCloseArea())
        Return .F.
    EndIf

    oJsonRoot["ZZA_CODV"]  := AllTrim((cAliasZZA)->ZZA_CODV)
    oJsonRoot["ZZA_DESCV"] := AllTrim((cAliasZZA)->ZZA_DESCV)

    While (cAliasZZA)->(!Eof())
        oItem := JsonObject():new()
        oItem["ZZA_CODP"]  := AllTrim((cAliasZZA)->ZZA_CODP)
        oItem["ZZA_DESCP"] := AllTrim((cAliasZZA)->ZZA_DESCP)
        oItem["ZZA_COMIS"] := (cAliasZZA)->ZZA_COMIS
        
        aAdd(aItens, oItem)
        (cAliasZZA)->(DbSkip())
    EndDo

    (cAliasZZA)->(DbCloseArea())
    oJsonRoot["itens"] := aItens

    ::SetContentType("application/json")
    ::SetResponse(oJsonRoot:ToJson())

Return lRet

//-------------------------------------------------------------------
// MÉTODO POST (CriaZZA): Cria um registro na tabela ZZA
// Rota: /wscomiszza/{codigo}
//-------------------------------------------------------------------
WSMETHOD POST CriaZZA WSSERVICE WsComisZZA
    Local cCodVendedor := AllTrim(::codigo)
    Local cBody        := ::GetContent()
    Local oJsonBody    := JsonObject():new()
    Local cErro        := ""
    Local lRet         := .T.

    cErro := oJsonBody:FromJson(cBody)
    If !Empty(cErro)
        ::SetStatus(400)
        ::SetResponse('{"error": "JSON invalido."}')
        Return .F.
    EndIf

    DbSelectArea("ZZA")
    ZZA->(DbSetOrder(1)) // Ordem por Filial + CodVendedor + CodProduto

    RecLock("ZZA", .T.)
        ZZA->ZZA_FILIAL := xFilial("ZZA")
        ZZA->ZZA_CODV   := cCodVendedor
        ZZA->ZZA_DESCV  := oJsonBody["ZZA_DESCV"]
        ZZA->ZZA_CODP   := oJsonBody["ZZA_CODP"]
        ZZA->ZZA_DESCP  := oJsonBody["ZZA_DESCP"]
        ZZA->ZZA_COMIS  := oJsonBody["ZZA_COMIS"]
    ZZA->(MsUnlock())

    ::SetStatus(201)
    ::SetResponse('{"message": "Registro criado com sucesso!"}')

Return lRet

//-------------------------------------------------------------------
// MÉTODO POST (CopiaPerfil): Copia o perfil de um vendedor para outro
// Rota: /copia/{codigo}/{codigodestino}
//-------------------------------------------------------------------
WSMETHOD POST CopiaPerfil WSSERVICE WsComisZZA
    Local cCodVendedor := AllTrim(::codigo)
    Local cCodDestino  := AllTrim(::codigodestino)
    Local lRet         := .T.
    Local cQuery       := ""
    Local cAliasQry    := GetNextAlias()

    If Empty(cCodVendedor) .Or. Empty(cCodDestino)
        ::SetStatus(400)
        ::SetResponse('{"error": "Informe o codigo do vendedor e o codigo de destino."}')
        Return .F.
    EndIf

    // Seleciona os registros do vendedor de origem
    cQuery := "SELECT * FROM " + RetSqlName("ZZA") + " "
    cQuery += "WHERE ZZA_FILIAL = '" + xFilial("ZZA") + "' "
    cQuery += "  AND ZZA_CODV = '" + cCodVendedor + "' "
    cQuery += "  AND D_E_L_E_T_ = ' ' "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQry, .T., .T.)

    If (cAliasQry)->(Eof())
        ::SetStatus(404)
        ::SetResponse('{"error": "Vendedor de origem nao encontrado ou sem registros."}')
        (cAliasQry)->(DbCloseArea())
        Return .F.
    EndIf

    cQuery := ""
    cQuery := "DELETE " + RetSqlName("ZZA") + " WHERE ZZA_FILIAL = '" + FwxFilial("ZZA") + "'"
    cQuery += "  AND ZZA_CODV = '" + cCodVendedor + "' "
    TCSqlExec(cQuery)

    While (cAliasQry)->(!Eof())
        RecLock("ZZA", .T.)
            ZZA->ZZA_FILIAL := xFilial("ZZA")
            ZZA->ZZA_CODP   := (cAliasQry)->ZZA_CODP
            ZZA->ZZA_DESCP  := (cAliasQry)->ZZA_DESCP
            ZZA->ZZA_COMIS  := (cAliasQry)->ZZA_COMIS
            ZZA->ZZA_CODV   := cCodDestino
            ZZA->ZZA_DESCV  := Posicione("SA3", 1, FwxFilial("SA3") + cCodDestino, "A3_NOME")
            ZZA->(MsUnlock())
        (cAliasQry)->(DbSkip())
    EndDo

    (cAliasQry)->(DbCloseArea())

    ::SetStatus(200)
    ::SetResponse('{"message": "Registros copiados com sucesso!"}')

Return lRet

//-------------------------------------------------------------------
// MÉTODO PUT: Altera um registro específico (Vendedor + Produto)
//-------------------------------------------------------------------
WSMETHOD PUT WSSERVICE WsComisZZA
    Local cCodVendedor := AllTrim(::codigo)
    Local cCodProduto  := AllTrim(::produto)
    Local cBody        := ::GetContent()
    Local oJsonBody    := JsonObject():new()
    Local cErro        := ""
    Local lRet         := .T.

    If Empty(cCodVendedor) .Or. Empty(cCodProduto)
        ::SetStatus(400)
        ::SetResponse('{"error": "O codigo do vendedor e o codigo do produto sao obrigatorios."}')
        Return .F.
    EndIf

    cErro := oJsonBody:FromJson(cBody)
    If !Empty(cErro)
        ::SetStatus(400)
        ::SetResponse('{"error": "JSON invalido."}')
        Return .F.
    EndIf

    DbSelectArea("ZZA")
    ZZA->(DbSetOrder(1))

    If ZZA->(DbSeek(xFilial("ZZA") + cCodVendedor + cCodProduto))
        RecLock("ZZA", .F.)
            ZZA->ZZA_DESCV  := oJsonBody["ZZA_DESCV"]
            ZZA->ZZA_DESCP  := oJsonBody["ZZA_DESCP"]
            ZZA->ZZA_COMIS  := oJsonBody["ZZA_COMIS"]
        ZZA->(MsUnlock())

        ::SetStatus(200)
        ::SetResponse('{"message": "Registro alterado com sucesso!"}')
    Else
        ::SetStatus(404)
        ::SetResponse('{"error": "Registro nao encontrado para alteracao."}')
        lRet := .F.
    EndIf

Return lRet

//-------------------------------------------------------------------
// MÉTODO DELETE: Exclui um registro específico (Vendedor + Produto)
//-------------------------------------------------------------------
WSMETHOD DELETE WSSERVICE WsComisZZA
    Local cCodVendedor := AllTrim(::codigo)
    Local cCodProduto  := AllTrim(::produto)
    Local lRet         := .T.

    If Empty(cCodVendedor) .Or. Empty(cCodProduto)
        ::SetStatus(400)
        ::SetResponse('{"error": "O codigo do vendedor e o codigo do produto sao obrigatorios."}')
        Return .F.
    EndIf

    DbSelectArea("ZZA")
    ZZA->(DbSetOrder(1))

    If ZZA->(DbSeek(xFilial("ZZA") + cCodVendedor + cCodProduto))
        RecLock("ZZA", .F.)
            ZZA->(DbDelete())
        ZZA->(MsUnlock())

        ::SetStatus(200)
        ::SetResponse('{"message": "Registro excluido com sucesso!"}')
    Else
        ::SetStatus(404)
        ::SetResponse('{"error": "Registro nao encontrado para exclusao."}')
        lRet := .F.
    EndIf

Return lRet
