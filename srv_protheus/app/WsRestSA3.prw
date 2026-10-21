#INCLUDE "totvs.ch"
#INCLUDE 'restful.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} WSA3
API REST completa para gerenciamento de Vendedores (Tabela SA3 com metadados do SX3)
@author Marcos Favaro
@since 12/10/2026
/*/
//-------------------------------------------------------------------
WSRESTFUL WSRESTSA3 DESCRIPTION "API Completa de Vendedores - Tabela SA3" FORMAT "application/json"

    WSDATA codigo AS CHARACTER OPTIONAL

    WSMETHOD GET DESCRIPTION "Retorna todos os vendedores ou um específico com nome, descrição e tamanho dos campos" PATH "/vendedores"
    WSMETHOD POST DESCRIPTION "Inclui um novo vendedor" PATH "/vendedores"
    WSMETHOD PUT DESCRIPTION "Altera um vendedor existente por código" PATH "/vendedores/{codigo}"

END WSRESTFUL

//-------------------------------------------------------------------
// Método GET: Consulta de Vendedores
//-------------------------------------------------------------------
WSMETHOD GET WSSERVICE WSRESTSA3
    Local oResponse   := JsonObject():New()
    Local aVendedores := {}
    Local cQuery      := ""
    Local cAliasSA3   := GetNextAlias()
    Local lRet        := .T.

    // Se o parâmetro 'codigo' foi passado na URL
    If !Empty(::codigo)
        cQuery := "SELECT * FROM " + RetSqlName("SA3") + " "
        cQuery += "WHERE A3_FILIAL = '" + xFilial("SA3") + "' "
        cQuery += "  AND A3_COD = '" + ::codigo + "' "
        cQuery += "  AND D_E_L_E_T_ = ' '"
        
        DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasSA3, .F., .T.)
        
        If (cAliasSA3)->(EOF())
            ::SetStatus(404)
            oResponse["error"] := "Vendedor não encontrado."
            ::SetResponse(oResponse:ToJson())
            (cAliasSA3)->(DbCloseArea())
            Return .F.
        EndIf

        oResponse := fMontaJsonSA3(cAliasSA3)
        
        (cAliasSA3)->(DbCloseArea())
        
        ::SetStatus(200)
        ::SetResponse(oResponse:ToJson())
        Return .T.
    EndIf

    // Caso contrário, retorna TODOS os registros
    cQuery := "SELECT * FROM " + RetSqlName("SA3") + " "
    cQuery += "WHERE A3_FILIAL = '" + xFilial("SA3") + "' "
    cQuery += "  AND D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY A3_COD"

    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasSA3, .F., .T.)

    While (cAliasSA3)->(!EOF())
        AAdd(aVendedores, fMontaJsonSA3(cAliasSA3))
        (cAliasSA3)->(DbSkip())
    EndDo

    (cAliasSA3)->(DbCloseArea())

    oResponse["vendedores"] := aVendedores
    ::SetStatus(200)
    ::SetResponse(oResponse:ToJson())

Return lRet

//-------------------------------------------------------------------
// Método POST: Inclusão de Novo Vendedor
//-------------------------------------------------------------------
WSMETHOD POST WSSERVICE WSRESTSA3
    Local cBody     := ::GetContent()
    Local oJson     := JsonObject():New()
    Local oResponse := JsonObject():New()
    Local cError    := ""
    Local cCod      := ""

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetStatus(400)
        oResponse["error"] := "JSON inválido: " + cError
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    cCod := oJson:GetJsonObject("A3_COD")

    If Empty(cCod)
        ::SetStatus(400)
        oResponse["error"] := "O campo obrigatório A3_COD não foi informado."
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    DbSelectArea("SA3")
    SA3->(DbSetOrder(1))

    If SA3->(DbSeek(xFilial("SA3") + cCod))
        ::SetStatus(400)
        oResponse["error"] := "Vendedor já cadastrado. Utilize o método PUT para alterar."
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    Begin Transaction
        RecLock("SA3", .T.)
        SA3->A3_FILIAL := xFilial("SA3")
        SA3->A3_COD    := cCod
        
        fGravaCamposSA3(oJson)
        
        SA3->(MsUnlock())
    End Transaction

    ::SetStatus(201)
    oResponse["status"]  := "success"
    oResponse["message"] := "Vendedor incluído com sucesso."
    oResponse["A3_COD"]  := cCod
    ::SetResponse(oResponse:ToJson())

Return .T.

//-------------------------------------------------------------------
// Método PUT: Alteração de Vendedor Existente por Código
//-------------------------------------------------------------------
WSMETHOD PUT WSSERVICE WSRESTSA3
    Local cBody     := ::GetContent()
    Local oJson     := JsonObject():New()
    Local oResponse := JsonObject():New()
    Local cError    := ""
    Local cCod      := ::codigo // Captura o parâmetro {codigo} da URL

    If Empty(cCod)
        ::SetStatus(400)
        oResponse["error"] := "O código do vendedor deve ser informado na URL."
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetStatus(400)
        oResponse["error"] := "JSON inválido: " + cError
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    DbSelectArea("SA3")
    SA3->(DbSetOrder(1))

    If !SA3->(DbSeek(xFilial("SA3") + cCod))
        ::SetStatus(404)
        oResponse["error"] := "Vendedor não encontrado para alteração."
        ::SetResponse(oResponse:ToJson())
        Return .F.
    EndIf

    Begin Transaction
        RecLock("SA3", .F.)
        
        fGravaCamposSA3(oJson)
        
        SA3->(MsUnlock())
    End Transaction

    ::SetStatus(200)
    oResponse["status"]  := "success"
    oResponse["message"] := "Vendedor alterado com sucesso."
    oResponse["A3_COD"]  := cCod
    ::SetResponse(oResponse:ToJson())

Return .T.

//-------------------------------------------------------------------
// Função Auxiliar: Grava/Atualiza os campos da SA3 dinamicamente
//-------------------------------------------------------------------
Static Function fGravaCamposSA3(oJson)
    If oJson:HasProperty("A3_NOME")    ; SA3->A3_NOME    := oJson:GetJsonObject("A3_NOME")    ; EndIf
    If oJson:HasProperty("A3_NREDUZ")  ; SA3->A3_NREDUZ  := oJson:GetJsonObject("A3_NREDUZ")  ; EndIf
    If oJson:HasProperty("A3_END")     ; SA3->A3_END     := oJson:GetJsonObject("A3_END")     ; EndIf
    If oJson:HasProperty("A3_BAIRRO")  ; SA3->A3_BAIRRO  := oJson:GetJsonObject("A3_BAIRRO")  ; EndIf
    If oJson:HasProperty("A3_MUN")     ; SA3->A3_MUN     := oJson:GetJsonObject("A3_MUN")     ; EndIf
    If oJson:HasProperty("A3_EST")     ; SA3->A3_EST     := oJson:GetJsonObject("A3_EST")     ; EndIf
    If oJson:HasProperty("A3_CEP")     ; SA3->A3_CEP     := oJson:GetJsonObject("A3_CEP")     ; EndIf
    If oJson:HasProperty("A3_DDDTEL")  ; SA3->A3_DDDTEL  := oJson:GetJsonObject("A3_DDDTEL")  ; EndIf
    If oJson:HasProperty("A3_MSBLQL")  ; SA3->A3_MSBLQL  := oJson:GetJsonObject("A3_MSBLQL")  ; EndIf
    If oJson:HasProperty("A3_TEL")     ; SA3->A3_TEL     := oJson:GetJsonObject("A3_TEL")     ; EndIf
    If oJson:HasProperty("A3_FAX")     ; SA3->A3_FAX     := oJson:GetJsonObject("A3_FAX")     ; EndIf
    If oJson:HasProperty("A3_TELEX")   ; SA3->A3_TELEX   := oJson:GetJsonObject("A3_TELEX")   ; EndIf
    If oJson:HasProperty("A3_TIPO")    ; SA3->A3_TIPO    := oJson:GetJsonObject("A3_TIPO")    ; EndIf
    If oJson:HasProperty("A3_CGC")     ; SA3->A3_CGC     := oJson:GetJsonObject("A3_CGC")     ; EndIf
    If oJson:HasProperty("A3_INSCR")   ; SA3->A3_INSCR   := oJson:GetJsonObject("A3_INSCR")   ; EndIf
    If oJson:HasProperty("A3_INSCRM")  ; SA3->A3_INSCRM  := oJson:GetJsonObject("A3_INSCRM")  ; EndIf
    If oJson:HasProperty("A3_EMAIL")   ; SA3->A3_EMAIL   := oJson:GetJsonObject("A3_EMAIL")   ; EndIf
    If oJson:HasProperty("A3_HPAGE")   ; SA3->A3_HPAGE   := oJson:GetJsonObject("A3_HPAGE")   ; EndIf
    If oJson:HasProperty("A3_CODUSR")  ; SA3->A3_CODUSR  := oJson:GetJsonObject("A3_CODUSR")  ; EndIf
    If oJson:HasProperty("A3_SUPER")   ; SA3->A3_SUPER   := oJson:GetJsonObject("A3_SUPER")   ; EndIf
    If oJson:HasProperty("A3_GEREN")   ; SA3->A3_GEREN   := oJson:GetJsonObject("A3_GEREN")   ; EndIf
    If oJson:HasProperty("A3_FORNECE") ; SA3->A3_FORNECE := oJson:GetJsonObject("A3_FORNECE") ; EndIf
    If oJson:HasProperty("A3_LOJA")    ; SA3->A3_LOJA    := oJson:GetJsonObject("A3_LOJA")    ; EndIf
    If oJson:HasProperty("A3_GERASE2") ; SA3->A3_GERASE2 := oJson:GetJsonObject("A3_GERASE2") ; EndIf
    If oJson:HasProperty("A3_BCO1")    ; SA3->A3_BCO1    := oJson:GetJsonObject("A3_BCO1")    ; EndIf
    If oJson:HasProperty("A3_REGIAO")  ; SA3->A3_REGIAO  := oJson:GetJsonObject("A3_REGIAO")  ; EndIf
    If oJson:HasProperty("A3_COMIS")   ; SA3->A3_COMIS   := oJson:GetJsonObject("A3_COMIS")   ; EndIf
    If oJson:HasProperty("A3_ALEMISS") ; SA3->A3_ALEMISS := oJson:GetJsonObject("A3_ALEMISS") ; EndIf
    If oJson:HasProperty("A3_ALBAIXA") ; SA3->A3_ALBAIXA := oJson:GetJsonObject("A3_ALBAIXA") ; EndIf
    If oJson:HasProperty("A3_ICM")     ; SA3->A3_ICM     := oJson:GetJsonObject("A3_ICM")     ; EndIf
    If oJson:HasProperty("A3_ICMSRET") ; SA3->A3_ICMSRET := oJson:GetJsonObject("A3_ICMSRET") ; EndIf
    If oJson:HasProperty("A3_UNIDAD")  ; SA3->A3_UNIDAD  := oJson:GetJsonObject("A3_UNIDAD")  ; EndIf
    If oJson:HasProperty("A3_ISS")     ; SA3->A3_ISS     := oJson:GetJsonObject("A3_ISS")     ; EndIf
    If oJson:HasProperty("A3_IPI")     ; SA3->A3_IPI     := oJson:GetJsonObject("A3_IPI")     ; EndIf
    If oJson:HasProperty("A3_REGSLA")  ; SA3->A3_REGSLA  := oJson:GetJsonObject("A3_REGSLA")  ; EndIf
    If oJson:HasProperty("A3_QTCONTA") ; SA3->A3_QTCONTA := oJson:GetJsonObject("A3_QTCONTA") ; EndIf
    If oJson:HasProperty("A3_GRPREP")  ; SA3->A3_GRPREP  := oJson:GetJsonObject("A3_GRPREP")  ; EndIf
    If oJson:HasProperty("A3_FRETE")   ; SA3->A3_FRETE   := oJson:GetJsonObject("A3_FRETE")   ; EndIf
    If oJson:HasProperty("A3_ACREFIN") ; SA3->A3_ACREFIN := oJson:GetJsonObject("A3_ACREFIN") ; EndIf
    If oJson:HasProperty("A3_DIA")     ; SA3->A3_DIA     := oJson:GetJsonObject("A3_DIA")     ; EndIf
    If oJson:HasProperty("A3_DDD")     ; SA3->A3_DDD     := oJson:GetJsonObject("A3_DDD")     ; EndIf
    If oJson:HasProperty("A3_CARGO")   ; SA3->A3_CARGO   := oJson:GetJsonObject("A3_CARGO")   ; EndIf
    If oJson:HasProperty("A3_PERDESC") ; SA3->A3_PERDESC := oJson:GetJsonObject("A3_PERDESC") ; EndIf
    If oJson:HasProperty("A3_TIPSUP")  ; SA3->A3_TIPSUP  := oJson:GetJsonObject("A3_TIPSUP")  ; EndIf
    If oJson:HasProperty("A3_DIARESE") ; SA3->A3_DIARESE := oJson:GetJsonObject("A3_DIARESE") ; EndIf
    If oJson:HasProperty("A3_SENHA")   ; SA3->A3_SENHA   := oJson:GetJsonObject("A3_SENHA")   ; EndIf
    If oJson:HasProperty("A3_CLIINI")  ; SA3->A3_CLIINI  := oJson:GetJsonObject("A3_CLIINI")  ; EndIf
    If oJson:HasProperty("A3_CLIFIM")  ; SA3->A3_CLIFIM  := oJson:GetJsonObject("A3_CLIFIM")  ; EndIf
    If oJson:HasProperty("A3_PROXPED") ; SA3->A3_PROXPED := oJson:GetJsonObject("A3_PROXPED") ; EndIf
    If oJson:HasProperty("A3_PROXCLI") ; SA3->A3_PROXCLI := oJson:GetJsonObject("A3_PROXCLI") ; EndIf
    If oJson:HasProperty("A3_SINCTAF") ; SA3->A3_SINCTAF := oJson:GetJsonObject("A3_SINCTAF") ; EndIf
    If oJson:HasProperty("A3_FAT_RH")  ; SA3->A3_FAT_RH  := oJson:GetJsonObject("A3_FAT_RH")  ; EndIf
    If oJson:HasProperty("A3_SINCAGE") ; SA3->A3_SINCAGE := oJson:GetJsonObject("A3_SINCAGE") ; EndIf
    If oJson:HasProperty("A3_GRUPSAN") ; SA3->A3_GRUPSAN := oJson:GetJsonObject("A3_GRUPSAN") ; EndIf
    If oJson:HasProperty("A3_SINCCON") ; SA3->A3_SINCCON := oJson:GetJsonObject("A3_SINCCON") ; EndIf
    If oJson:HasProperty("A3_DEPEND")  ; SA3->A3_DEPEND  := oJson:GetJsonObject("A3_DEPEND")  ; EndIf
    If oJson:HasProperty("A3_PERAGE")  ; SA3->A3_PERAGE  := oJson:GetJsonObject("A3_PERAGE")  ; EndIf
    If oJson:HasProperty("A3_PEN_ALI") ; SA3->A3_PEN_ALI := oJson:GetJsonObject("A3_PEN_ALI") ; EndIf
    If oJson:HasProperty("A3_PERTAF")  ; SA3->A3_PERTAF  := oJson:GetJsonObject("A3_PERTAF")  ; EndIf
    If oJson:HasProperty("A3_TIPVEND") ; SA3->A3_TIPVEND := oJson:GetJsonObject("A3_TIPVEND") ; EndIf
    If oJson:HasProperty("A3_TIMEMIN") ; SA3->A3_TIMEMIN := oJson:GetJsonObject("A3_TIMEMIN") ; EndIf
    If oJson:HasProperty("A3_NUMRA")   ; SA3->A3_NUMRA   := oJson:GetJsonObject("A3_NUMRA")   ; EndIf
    If oJson:HasProperty("A3_URLEXG")  ; SA3->A3_URLEXG  := oJson:GetJsonObject("A3_URLEXG")  ; EndIf
    If oJson:HasProperty("A3_USUCORP") ; SA3->A3_USUCORP := oJson:GetJsonObject("A3_USUCORP") ; EndIf
    If oJson:HasProperty("A3_PAIS")    ; SA3->A3_PAIS    := oJson:GetJsonObject("A3_PAIS")    ; EndIf
    If oJson:HasProperty("A3_HABSINC") ; SA3->A3_HABSINC := oJson:GetJsonObject("A3_HABSINC") ; EndIf
    If oJson:HasProperty("A3_DDI")     ; SA3->A3_DDI     := oJson:GetJsonObject("A3_DDI")     ; EndIf
    If oJson:HasProperty("A3_CEL")     ; SA3->A3_CEL     := oJson:GetJsonObject("A3_CEL")     ; EndIf
    If oJson:HasProperty("A3_NVLSTR")  ; SA3->A3_NVLSTR  := oJson:GetJsonObject("A3_NVLSTR")  ; EndIf
    If oJson:HasProperty("A3_NIVEL")   ; SA3->A3_NIVEL   := oJson:GetJsonObject("A3_NIVEL")   ; EndIf
    If oJson:HasProperty("A3_LANEXG")  ; SA3->A3_LANEXG  := oJson:GetJsonObject("A3_LANEXG")  ; EndIf
    If oJson:HasProperty("A3_PISCOF")  ; SA3->A3_PISCOF  := oJson:GetJsonObject("A3_PISCOF")  ; EndIf
    If oJson:HasProperty("A3_EMACORP") ; SA3->A3_EMACORP := oJson:GetJsonObject("A3_EMACORP") ; EndIf
    If oJson:HasProperty("A3_BIAGEND") ; SA3->A3_BIAGEND := oJson:GetJsonObject("A3_BIAGEND") ; EndIf
    If oJson:HasProperty("A3_BITAREF") ; SA3->A3_BITAREF := oJson:GetJsonObject("A3_BITAREF") ; EndIf
    If oJson:HasProperty("A3_BICONT")  ; SA3->A3_BICONT  := oJson:GetJsonObject("A3_BICONT")  ; EndIf
    If oJson:HasProperty("A3_CODISS")  ; SA3->A3_CODISS  := oJson:GetJsonObject("A3_CODISS")  ; EndIf
    If oJson:HasProperty("A3_MSEXP")   ; SA3->A3_MSEXP   := oJson:GetJsonObject("A3_MSEXP")   ; EndIf
    If oJson:HasProperty("A3_HREXPO")  ; SA3->A3_HREXPO  := oJson:GetJsonObject("A3_HREXPO")  ; EndIf
    If oJson:HasProperty("A3_BASEIR")  ; SA3->A3_BASEIR  := oJson:GetJsonObject("A3_BASEIR")  ; EndIf
    If oJson:HasProperty("A3_HRUMOV")  ; SA3->A3_HRUMOV  := oJson:GetJsonObject("A3_HRUMOV")  ; EndIf
    If oJson:HasProperty("A3_FILFUN")  ; SA3->A3_FILFUN  := oJson:GetJsonObject("A3_FILFUN")  ; EndIf
    If oJson:HasProperty("A3_HAND")    ; SA3->A3_HAND    := oJson:GetJsonObject("A3_HAND")    ; EndIf
    If oJson:HasProperty("A3_SNAEXG")  ; SA3->A3_SNAEXG  := oJson:GetJsonObject("A3_SNAEXG")  ; EndIf
    If oJson:HasProperty("A3_MODTRF")  ; SA3->A3_MODTRF  := oJson:GetJsonObject("A3_MODTRF")  ; EndIf
    If oJson:HasProperty("A3_COMIS2")  ; SA3->A3_COMIS2  := oJson:GetJsonObject("A3_COMIS2")  ; EndIf
    If oJson:HasProperty("A3_COMIS3")  ; SA3->A3_COMIS3  := oJson:GetJsonObject("A3_COMIS3")  ; EndIf
Return

//-------------------------------------------------------------------
// Função Auxiliar: Mapeia os campos buscando Descrição e Tamanho do SX3
//-------------------------------------------------------------------
Static Function fMontaJsonSA3(cAlias)
    Local oJsonVnd := JsonObject():New()
    Local aCampos  := {}
    Local nX       := 0
    Local cCampo   := ""
    Local oCampoDet:= NIL
    Local xValor   := NIL

    aAdd(aCampos, "A3_FILIAL")
    aAdd(aCampos, "A3_COD")
    aAdd(aCampos, "A3_NOME")
    aAdd(aCampos, "A3_NREDUZ")
    aAdd(aCampos, "A3_END")
    aAdd(aCampos, "A3_BAIRRO")
    aAdd(aCampos, "A3_MUN")
    aAdd(aCampos, "A3_EST")
    aAdd(aCampos, "A3_CEP")
    aAdd(aCampos, "A3_DDDTEL")
    aAdd(aCampos, "A3_MSBLQL")
    aAdd(aCampos, "A3_TEL")
    aAdd(aCampos, "A3_FAX")
    aAdd(aCampos, "A3_TELEX")
    aAdd(aCampos, "A3_TIPO")
    aAdd(aCampos, "A3_CGC")
    aAdd(aCampos, "A3_INSCR")
    aAdd(aCampos, "A3_INSCRM")
    aAdd(aCampos, "A3_EMAIL")
    aAdd(aCampos, "A3_HPAGE")
    aAdd(aCampos, "A3_CODUSR")
    aAdd(aCampos, "A3_SUPER")
    aAdd(aCampos, "A3_GEREN")
    aAdd(aCampos, "A3_FORNECE")
    aAdd(aCampos, "A3_LOJA")
    aAdd(aCampos, "A3_GERASE2")
    aAdd(aCampos, "A3_BCO1")
    aAdd(aCampos, "A3_REGIAO")
    aAdd(aCampos, "A3_COMIS")
    aAdd(aCampos, "A3_ALEMISS")
    aAdd(aCampos, "A3_ALBAIXA")
    aAdd(aCampos, "A3_ICM")
    aAdd(aCampos, "A3_ICMSRET")
    aAdd(aCampos, "A3_UNIDAD")
    aAdd(aCampos, "A3_ISS")
    aAdd(aCampos, "A3_IPI")
    aAdd(aCampos, "A3_REGSLA")
    aAdd(aCampos, "A3_QTCONTA")
    aAdd(aCampos, "A3_GRPREP")
    aAdd(aCampos, "A3_FRETE")
    aAdd(aCampos, "A3_ACREFIN")
    aAdd(aCampos, "A3_DIA")
    aAdd(aCampos, "A3_DDD")
    aAdd(aCampos, "A3_CARGO")
    aAdd(aCampos, "A3_PERDESC")
    aAdd(aCampos, "A3_TIPSUP")
    aAdd(aCampos, "A3_DIARESE")
    aAdd(aCampos, "A3_SENHA")
    aAdd(aCampos, "A3_PEDINI")
    aAdd(aCampos, "A3_PEDFIM")
    aAdd(aCampos, "A3_CLIINI")
    aAdd(aCampos, "A3_CLIFIM")
    aAdd(aCampos, "A3_PROXPED")
    aAdd(aCampos, "A3_PROXCLI")
    aAdd(aCampos, "A3_SINCTAF")
    aAdd(aCampos, "A3_FAT_RH")
    aAdd(aCampos, "A3_SINCAGE")
    aAdd(aCampos, "A3_GRUPSAN")
    aAdd(aCampos, "A3_SINCCON")
    aAdd(aCampos, "A3_DEPEND")
    aAdd(aCampos, "A3_PERAGE")
    aAdd(aCampos, "A3_PEN_ALI")
    aAdd(aCampos, "A3_PERTAF")
    aAdd(aCampos, "A3_TIPVEND")
    aAdd(aCampos, "A3_TIMEMIN")
    aAdd(aCampos, "A3_NUMRA")
    aAdd(aCampos, "A3_URLEXG")
    aAdd(aCampos, "A3_USUCORP")
    aAdd(aCampos, "A3_PAIS")
    aAdd(aCampos, "A3_HABSINC")
    aAdd(aCampos, "A3_DDI")
    aAdd(aCampos, "A3_CEL")
    aAdd(aCampos, "A3_ADMISS")
    aAdd(aCampos, "A3_NVLSTR")
    aAdd(aCampos, "A3_NIVEL")
    aAdd(aCampos, "A3_LANEXG")
    aAdd(aCampos, "A3_PISCOF")
    aAdd(aCampos, "A3_EMACORP")
    aAdd(aCampos, "A3_BIAGEND")
    aAdd(aCampos, "A3_BITAREF")
    aAdd(aCampos, "A3_BICONT")
    aAdd(aCampos, "A3_CODISS")
    aAdd(aCampos, "A3_MSEXP")
    aAdd(aCampos, "A3_HREXPO")
    aAdd(aCampos, "A3_BASEIR")
    aAdd(aCampos, "A3_HRUMOV")
    aAdd(aCampos, "A3_DTUMOV")
    aAdd(aCampos, "A3_FILFUN")
    aAdd(aCampos, "A3_HAND")
    aAdd(aCampos, "A3_SNAEXG")
    aAdd(aCampos, "A3_MODTRF")
    aAdd(aCampos, "A3_COMIS2")
    aAdd(aCampos, "A3_COMIS3")

    For nX := 1 To Len(aCampos)
        cCampo := aCampos[nX]
        xValor := (cAlias)->(&(cCampo))
        
        If ValType(xValor) == "C"
            xValor := AllTrim(xValor)
        EndIf

        oCampoDet := JsonObject():New()
        oCampoDet["valor"]       := xValor
        oCampoDet["descricao"]   := EncodeUTF8(FWSX3Util():GetDescription( cCampo ))
        oCampoDet["tipo"]        := FWSX3Util():GetFieldStruct( cCampo )[2]
        oCampoDet["tamanho"]     := FWSX3Util():GetFieldStruct( cCampo )[3]
        
        oJsonVnd[cCampo] := oCampoDet
    Next nX

Return oJsonVnd
