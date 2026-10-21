#INCLUDE "totvs.ch"
#INCLUDE "restful.ch"

// Define o serviço REST
WSRESTFUL restmunic DESCRIPTION "API para listagem de municípios do Protheus por Estado"

    // Parâmetro passado via URL: /api/v1/restmunic?estado=SP
    WSDATA estado AS CHARACTER
    
    WSMETHOD GET DESCRIPTION "Retorna os municípios de um determinado estado" WSSYNTAX "/restmunic" PATH "/restmunic" PRODUCES APPLICATION_JSON

END WSRESTFUL

// Implementação do Método GET
WSMETHOD GET WSRECEIVE estado WSSERVICE restmunic
    
    Local cJson      := ""
    Local cEstado    := UPPER(AllTrim(::estado))
    Local oJsonRet   := JsonObject():New()
    Local aMunicipios := {}
    Local oItem      := Nil

    // Valida se o parâmetro foi informado
    If Empty(cEstado)
        ::SetRestFault(400, "O parametro 'estado' e obrigatorio.")
        Return .F.
    EndIf

    // Abre a tabela CC2 (Municípios)
    DbSelectArea("CC2")
    CC2->(DbSetOrder(1)) // Ordem geralmente é CC2_FILIAL + CC2_EST + CC2_CODMUN

    // Posiciona ou busca os registros do Estado informado
    // CC2_EST armazena a sigla do estado (ex: 'SP', 'RJ')
    If CC2->(DbSeek(xFilial("CC2") + cEstado))
        
        While CC2->(!Eof()) .And. CC2->CC2_FILIAL == xFilial("CC2") .And. CC2->CC2_EST == cEstado
            
            oItem := JsonObject():New()
            oItem["municipio"] := AllTrim(CC2->CC2_MUN)
            AAdd(aMunicipios, oItem)
            
            CC2->(DbSkip())
        EndDo
        
    EndIf

    // Monta o objeto de retorno
    If Len(aMunicipios) > 0
        oJsonRet["status"]     := "success"
        oJsonRet["total"]      := Len(aMunicipios)
        oJsonRet["municipios"] := aMunicipios
        
        cJson := oJsonRet:ToJson()
        
        ::SetResponse(cJson)
        ::SetContentType("application/json")
    Else
        ::SetRestFault(404, "Nenhum municipio encontrado para o estado informado.")
        Return .F.
    EndIf

Return .T.
