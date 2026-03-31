#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RESTFUL.ch"

/*/{Protheus.doc} WSLOGISTICA
    REST API para Solicitacoes de Logistica Cirurgica - CicloMed

    Endpoints:
    - GET  /WSLOGISTICA?acao=listar             -> Todas as solicitacoes
    - GET  /WSLOGISTICA?acao=listar&status=P    -> Apenas pendentes (P=Pendente, A=Atendido)
    - GET  /WSLOGISTICA?acao=listar&tipo=E      -> Por tipo (E=Eletivo, R=Reserva, P=Reposicao)
    - POST /WSLOGISTICA {"acao":"incluir",...}  -> Inclui nova solicitacao
    - POST /WSLOGISTICA {"acao":"atualizar",...}-> Atualiza status de uma solicitacao

    Tabela: ZLG010 (ver Scripts_SQL/ZLG_setup.sql para criacao)

    @type  WSRESTFUL
    @author Antonio
    @since 31/03/2026
    @version 1.0
/*/

WSRESTFUL WSLOGISTICA DESCRIPTION "API Logistica CicloMed - Solicitacoes Cirurgicas"

    WSDATA acao   AS STRING
    WSDATA status AS STRING
    WSDATA tipo   AS STRING
    WSDATA q      AS STRING

    WSMETHOD GET  DESCRIPTION "Listar solicitacoes"         WSSYNTAX "/WSLOGISTICA?acao=listar[&status=P|A][&tipo=E|R|P]"
    WSMETHOD POST DESCRIPTION "Incluir ou atualizar"        WSSYNTAX "/WSLOGISTICA"

END WSRESTFUL

//=====================================================================
// GET - Listar solicitacoes
//   ?acao=listar              -> Todas
//   ?acao=listar&status=P     -> Pendentes
//   ?acao=listar&status=A     -> Atendidos
//   ?acao=listar&tipo=E       -> Por tipo
//=====================================================================
WSMETHOD GET WSRECEIVE acao, status, tipo, q WSSERVICE WSLOGISTICA

    Local cAcao   := Upper(AllTrim(::acao))
    Local cStatus := Upper(AllTrim(::status))
    Local cTipo   := Upper(AllTrim(::tipo))

    ::SetContentType("application/json")

    // Headers CORS
    ::SetHeader("Access-Control-Allow-Origin",  "*")
    ::SetHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    ::SetHeader("Access-Control-Allow-Headers", "Authorization, Content-Type")

    If cAcao == "LISTAR" .Or. Empty(cAcao)
        ::SetResponse(fListarLog(cStatus, cTipo))
        Return .T.
    ElseIf cAcao == "PRODUTOS"
        ::SetResponse(fListarProdutos(AllTrim(::q)))
        Return .T.
    ElseIf cAcao == "HOSPITAIS"
        ::SetResponse(fListarHospitais())
        Return .T.
    EndIf

    ::SetResponse('{"ok":false,"msg":"Acao invalida. Use: listar, produtos, hospitais"}')
Return .T.

//=====================================================================
// POST - Incluir ou atualizar solicitacao
//   Body: {"acao":"incluir","prioridade":"URGENTE","tipo":"ELETIVO",
//          "hospital":"...","paciente":"...","dataProc":"2026-03-31",
//          "horaProc":"10:30","convenio":"...","medico":"...",
//          "materiais":"...","observacao":"...","anexo":""}
//
//   Body: {"acao":"atualizar","id":"LOG-0001","status":"A"}
//=====================================================================
WSMETHOD POST WSRECEIVE WSSERVICE WSLOGISTICA

    Local cBody  := ::GetContent()
    Local oJson  := JsonObject():New()
    Local cError := ""
    Local cResp  := ""

    ::SetContentType("application/json")

    // Headers CORS
    ::SetHeader("Access-Control-Allow-Origin",  "*")
    ::SetHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    ::SetHeader("Access-Control-Allow-Headers", "Authorization, Content-Type")

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetResponse('{"ok":false,"msg":"JSON invalido: ' + cError + '"}')
        FreeObj(oJson)
        Return .T.
    EndIf

    Do Case
        Case Upper(AllTrim(jStr(oJson,"acao"))) == "INCLUIR"
            cResp := fIncluirLog(oJson)
        Case Upper(AllTrim(jStr(oJson,"acao"))) == "ATUALIZAR"
            cResp := fAtualizarLog(oJson)
        Otherwise
            cResp := '{"ok":false,"msg":"Acao invalida. Use: incluir ou atualizar"}'
    EndCase

    ::SetResponse(cResp)
    FreeObj(oJson)
Return .T.


//=====================================================================
// fListarLog - Retorna JSON com lista de solicitacoes de ZLG010
//=====================================================================
Static Function fListarLog(cStatus, cTipo)

    Local cJson  := ""
    Local cQry   := ""
    Local cAlias := GetNextAlias()
    Local aArea  := GetArea()
    Local aItens := {}
    Local cItem  := ""

    cQry  := " SELECT "
    cQry  += "   RTRIM(ZLG_ID)     AS ID, "
    cQry  += "   ZLG_PRIOR         AS PRIOR, "
    cQry  += "   ZLG_TIPO          AS TIPO, "
    cQry  += "   ZLG_STATUS        AS STATUS, "
    cQry  += "   RTRIM(ZLG_HOSP)   AS HOSP, "
    cQry  += "   RTRIM(ZLG_PAC)    AS PAC, "
    cQry  += "   RTRIM(ZLG_DTPROC) AS DTPROC, "
    cQry  += "   RTRIM(ZLG_HRPROC) AS HRPROC, "
    cQry  += "   RTRIM(ZLG_CONV)   AS CONV, "
    cQry  += "   RTRIM(ZLG_MED)    AS MED, "
    cQry  += "   RTRIM(ZLG_MAT)    AS MAT, "
    cQry  += "   RTRIM(ZLG_OBS)    AS OBS, "
    cQry  += "   RTRIM(ZLG_ANEXO)  AS ANEXO, "
    cQry  += "   RTRIM(ZLG_DTENVI) AS DTENVI, "
    cQry  += "   RTRIM(ZLG_HRENVI) AS HRENVI "
    cQry  += " FROM ZLG010 WITH (NOLOCK) "
    cQry  += " WHERE D_E_L_E_T_ = ' ' "

    If !Empty(cStatus)
        cQry += "   AND ZLG_STATUS = '" + cStatus + "' "
    EndIf
    If !Empty(cTipo)
        cQry += "   AND ZLG_TIPO = '" + cTipo + "' "
    EndIf

    cQry  += " ORDER BY "
    cQry  += "   CASE ZLG_STATUS WHEN 'P' THEN 0 ELSE 1 END, "
    cQry  += "   ZLG_DTENVI DESC, ZLG_HRENVI DESC "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cItem  := "{"
        cItem  += '"id":"'         + fJStr(AllTrim((cAlias)->ID))     + '",'
        cItem  += '"protocol":"'   + fJStr(AllTrim((cAlias)->ID))     + '",'
        cItem  += '"prioridade":"' + fJStr(fDecPrior(AllTrim((cAlias)->PRIOR))) + '",'
        cItem  += '"tipo":"'       + fJStr(fDecTipo(AllTrim((cAlias)->TIPO)))   + '",'
        cItem  += '"status":"'     + AllTrim((cAlias)->STATUS)                  + '",'
        cItem  += '"hospital":"'   + fJStr(AllTrim((cAlias)->HOSP))  + '",'
        cItem  += '"paciente":"'   + fJStr(AllTrim((cAlias)->PAC))   + '",'
        cItem  += '"dataProc":"'   + fDtBR(AllTrim((cAlias)->DTPROC)) + '",'
        cItem  += '"horaProc":"'   + fJStr(AllTrim((cAlias)->HRPROC)) + '",'
        cItem  += '"convenio":"'   + fJStr(AllTrim((cAlias)->CONV))   + '",'
        cItem  += '"medico":"'     + fJStr(AllTrim((cAlias)->MED))    + '",'
        cItem  += '"materiais":"'  + fJStr(AllTrim((cAlias)->MAT))    + '",'
        cItem  += '"observacao":"' + fJStr(AllTrim((cAlias)->OBS))    + '",'
        cItem  += '"anexo":"'      + fJStr(AllTrim((cAlias)->ANEXO))  + '",'
        cItem  += '"dataEnvio":"'  + fDtBR(AllTrim((cAlias)->DTENVI)) + " " + AllTrim((cAlias)->HRENVI) + '"'
        cItem  += "}"
        aAdd(aItens, cItem)
        (cAlias)->(dbSkip())
    EndDo

    (cAlias)->(dbCloseArea())
    RestArea(aArea)

    cJson  := '{"ok":true,"total":' + cValToChar(Len(aItens)) + ',"lista":['
    cJson  += aStrJoin(aItens, ",")
    cJson  += ']}'

Return cJson


//=====================================================================
// fListarProdutos - Retorna JSON com todos os produtos do SB1
//=====================================================================
Static Function fListarProdutos(cQ)

    Local cJson  := ""
    Local cQry   := ""
    Local cAlias := GetNextAlias()
    Local aArea  := GetArea()
    Local aItens := {}
    Local cItem  := ""
    Local cFil   := xFilial("SB1")
    Local nTop   := iif(Empty(cQ), 500, 50)

    cQry  := " SELECT TOP " + cValToChar(nTop) + " RTRIM(B1_COD) AS COD, RTRIM(B1_DESC) AS DSCRI "
    cQry  += " FROM SB1010 WITH (NOLOCK) "
    cQry  += " WHERE D_E_L_E_T_ = ' ' "
    cQry  += " AND B1_FILIAL = '" + cFil + "' "
    If !Empty(cQ)
        cQry += " AND (UPPER(B1_DESC) LIKE '%" + Upper(fSqlStr(cQ)) + "%' "
        cQry += "      OR UPPER(B1_COD)  LIKE '%" + Upper(fSqlStr(cQ)) + "%') "
    EndIf
    cQry  += " ORDER BY B1_DESC "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cItem  := '{"cod":"'  + fJStr(AllTrim((cAlias)->COD))   + '",'
        cItem  += '"desc":"'  + fJStr(AllTrim((cAlias)->DSCRI)) + '"}'
        aAdd(aItens, cItem)
        (cAlias)->(dbSkip())
    EndDo

    (cAlias)->(dbCloseArea())
    RestArea(aArea)

    cJson  := '{"ok":true,"total":' + cValToChar(Len(aItens)) + ',"produtos":['
    cJson  += aStrJoin(aItens, ",")
    cJson  += ']}'

Return cJson


//=====================================================================
// fListarHospitais - Retorna JSON com clientes do SA1
//=====================================================================
Static Function fListarHospitais()

    Local cJson  := ""
    Local cQry   := ""
    Local cAlias := GetNextAlias()
    Local aArea  := GetArea()
    Local aItens := {}
    Local cItem  := ""
    Local cFil   := xFilial("SA1")

    cQry  := " SELECT TOP 1000 RTRIM(A1_COD) AS COD, RTRIM(A1_NOME) AS NOME "
    cQry  += " FROM SA1010 WITH (NOLOCK) "
    cQry  += " WHERE D_E_L_E_T_ = ' ' "
    cQry  += " AND A1_FILIAL = '" + cFil + "' "
    cQry  += " ORDER BY A1_NOME "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cItem  := '{"cod":"'  + fJStr(AllTrim((cAlias)->COD))  + '",'
        cItem  += '"nome":"'  + fJStr(AllTrim((cAlias)->NOME)) + '"}'
        aAdd(aItens, cItem)
        (cAlias)->(dbSkip())
    EndDo

    (cAlias)->(dbCloseArea())
    RestArea(aArea)

    cJson  := '{"ok":true,"total":' + cValToChar(Len(aItens)) + ',"hospitais":['
    cJson  += aStrJoin(aItens, ",")
    cJson  += ']}'

Return cJson


//=====================================================================
// fIncluirLog - INSERT em ZLG010
//=====================================================================
Static Function fIncluirLog(oJson)

    Local aArea   := GetArea()
    Local cId     := ""
    Local cPrior  := ""
    Local cTipo   := ""
    Local cHosp   := ""
    Local cPac    := ""
    Local cDtProc := ""
    Local cHrProc := ""
    Local cConv   := ""
    Local cMed    := ""
    Local cMat    := ""
    Local cObs    := ""
    Local cAnexo  := ""
    Local nRet    := 0
    Local cSql    := ""

    // Leitura dos campos com protecao contra NIL
    cPrior  := fEncPrior(Upper(AllTrim(jStr(oJson,"prioridade"))))
    cTipo   := fEncTipo(Upper(AllTrim(jStr(oJson,"tipo"))))
    cHosp   := Left(jStr(oJson,"hospital"),  80)
    cPac    := Left(jStr(oJson,"paciente"),   80)
    cDtProc := fDtIso(jStr(oJson,"dataProc"))
    cHrProc := Left(jStr(oJson,"horaProc"),   5)
    cConv   := Left(jStr(oJson,"convenio"),  80)
    cMed    := Left(jStr(oJson,"medico"),    80)
    cMat    := Left(jStr(oJson,"materiais"), 250)
    cObs    := Left(jStr(oJson,"observacao"),250)
    cAnexo  := Left(jStr(oJson,"anexo"),    200)

    // Validacoes
    If Empty(cHosp)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Campo hospital obrigatorio"}'
    EndIf
    If Empty(cMat)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Campo materiais obrigatorio"}'
    EndIf
    If Empty(cPrior)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Prioridade invalida. Use: URGENTE/MEDIA/BAIXA"}'
    EndIf
    If Empty(cTipo)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Tipo invalido. Use: ELETIVO/RESERVA/REPOSICAO"}'
    EndIf

    // Gera proximo protocolo
    cId := fProxIdLog()

    // INSERT
    cSql  := "INSERT INTO ZLG010 ("
    cSql  += "  D_E_L_E_T_,ZLG_ID,ZLG_PRIOR,ZLG_TIPO,ZLG_STATUS,"
    cSql  += "  ZLG_HOSP,ZLG_PAC,ZLG_DTPROC,ZLG_HRPROC,"
    cSql  += "  ZLG_CONV,ZLG_MED,ZLG_MAT,ZLG_OBS,ZLG_ANEXO,"
    cSql  += "  ZLG_DTENVI,ZLG_HRENVI"
    cSql  += ") VALUES ("
    cSql  += "  ' ',"
    cSql  += "  '" + fSqlStr(cId)    + "',"
    cSql  += "  '" + cPrior          + "',"
    cSql  += "  '" + cTipo           + "',"
    cSql  += "  'P',"
    cSql  += "  '" + fSqlStr(cHosp)  + "',"
    cSql  += "  '" + fSqlStr(cPac)   + "',"
    cSql  += "  '" + cDtProc         + "',"
    cSql  += "  '" + cHrProc         + "',"
    cSql  += "  '" + fSqlStr(cConv)  + "',"
    cSql  += "  '" + fSqlStr(cMed)   + "',"
    cSql  += "  '" + fSqlStr(cMat)   + "',"
    cSql  += "  '" + fSqlStr(cObs)   + "',"
    cSql  += "  '" + fSqlStr(cAnexo) + "',"
    cSql  += "  '" + DToS(Date())    + "',"
    cSql  += "  '" + Left(Time(),5)  + "'"
    cSql  += ")"

    nRet := TcSqlExec(cSql)

    If nRet < 0
        ConOut("[WSLOGISTICA] Erro INSERT: " + TcSqlError())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Erro ao gravar no banco de dados"}'
    EndIf

    ConOut("[WSLOGISTICA] Incluido: " + cId + " | " + cHosp + " | " + fDecPrior(cPrior))
    RestArea(aArea)

Return '{"ok":true,"protocol":"' + cId + '"}'


//=====================================================================
// fAtualizarLog - UPDATE status em ZLG010
//=====================================================================
Static Function fAtualizarLog(oJson)

    Local aArea   := GetArea()
    Local cId     := AllTrim(jStr(oJson,"id"))
    Local cStatus := Upper(AllTrim(jStr(oJson,"status")))
    Local nRet    := 0

    If Empty(cId)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Campo id obrigatorio"}'
    EndIf
    If cStatus <> "P" .And. cStatus <> "A"
        RestArea(aArea)
        Return '{"ok":false,"msg":"Status invalido. Use: P=Pendente ou A=Atendido"}'
    EndIf

    nRet := TcSqlExec( ;
        "UPDATE ZLG010 SET ZLG_STATUS = '" + cStatus + "' " + ;
        "WHERE D_E_L_E_T_ = ' ' AND ZLG_ID = '" + fSqlStr(cId) + "'" )

    If nRet < 0
        ConOut("[WSLOGISTICA] Erro UPDATE: " + TcSqlError())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Erro ao atualizar registro"}'
    EndIf

    ConOut("[WSLOGISTICA] Atualizado: " + cId + " -> Status: " + cStatus)
    RestArea(aArea)

Return '{"ok":true,"protocol":"' + cId + '","status":"' + cStatus + '"}'


//=====================================================================
// fProxIdLog - Gera proximo protocolo: LOG-0001, LOG-0002 ...
// Usa MAX(ZLG_ID) para garantir unicidade mesmo com concorrencia baixa
//=====================================================================
Static Function fProxIdLog()

    Local cAlias := GetNextAlias()
    Local nProx  := 1

    dbUseArea(.T., "TOPCONN", TCGenQry(,, ;
        "SELECT ISNULL(MAX(CAST(SUBSTRING(ZLG_ID,5,4) AS INT)),0)+1 AS PROXIMO " + ;
        "FROM ZLG010 WITH (NOLOCK) WHERE D_E_L_E_T_=' ' AND ZLG_ID LIKE 'LOG-%'" ), ;
        cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nProx := (cAlias)->PROXIMO
    EndIf
    (cAlias)->(dbCloseArea())

Return "LOG-" + Right("0000" + cValToChar(nProx), 4)


//=====================================================================
// Codificacao/Decodificacao de Prioridade e Tipo
//   Banco:  U/M/B    HTML: URGENTE/MEDIA/BAIXA
//   Banco:  E/R/P    HTML: ELETIVO/RESERVA/REPOSICAO
//=====================================================================
Static Function fEncPrior(c)
    Do Case
        Case Left(c,1) == "U" ; Return "U"   // URGENTE
        Case Left(c,1) == "M" ; Return "M"   // MEDIA / M..DIA
        Case Left(c,1) == "B" ; Return "B"   // BAIXA
    EndCase
Return ""

Static Function fDecPrior(c)
    // Retorna em ISO-8859/CP1252 — EncodeUTF8 feito em fJStr
    Do Case
        Case c == "U" ; Return "URGENTE"
        Case c == "M" ; Return "M" + Chr(201) + "DIA"   // MÉDIA
        Case c == "B" ; Return "BAIXA"
    EndCase
Return c

Static Function fEncTipo(c)
    Do Case
        Case Left(c,1) == "E"   ; Return "E"   // ELETIVO
        Case Left(c,4) == "RESE"; Return "R"   // RESERVA
        Case Left(c,3) == "REP" ; Return "P"   // REPOSICAO/REPOSIÇÃO
    EndCase
Return ""

Static Function fDecTipo(c)
    // Retorna em ISO-8859/CP1252 — EncodeUTF8 feito em fJStr
    Do Case
        Case c == "E" ; Return "ELETIVO"
        Case c == "R" ; Return "RESERVA"
        Case c == "P" ; Return "REPOSI" + Chr(199) + Chr(195) + "O"  // REPOSIÇÃO
    EndCase
Return c


//=====================================================================
// Auxiliares de data
//=====================================================================
Static Function fDtBR(cDt)
    // YYYYMMDD -> DD/MM/YYYY   (campo vazio -> "-")
    If Empty(AllTrim(cDt)) .Or. Len(AllTrim(cDt)) < 8
        Return "-"
    EndIf
Return SubStr(cDt,7,2) + "/" + SubStr(cDt,5,2) + "/" + SubStr(cDt,1,4)

Static Function fDtIso(cDt)
    // Aceita DD/MM/YYYY ou YYYY-MM-DD  ->  YYYYMMDD (para gravar no banco)
    cDt := AllTrim(cDt)
    If Empty(cDt) .Or. cDt == "-"
        Return "        "
    EndIf
    If "/" $ cDt
        Return SubStr(cDt,7,4) + SubStr(cDt,4,2) + SubStr(cDt,1,2)
    EndIf
    If "-" $ cDt
        Return StrTran(cDt,"-","")
    EndIf
Return PadR(cDt, 8)


//=====================================================================
// Auxiliares de string
//=====================================================================

// jStr: acesso seguro a campo string no JsonObject (evita erro se campo eh NIL)
Static Function jStr(oJson, cKey)
    Local v := oJson[cKey]
Return iif(ValType(v) == "C", v, iif(ValType(v) == "N", cValToChar(v), ""))

// fSqlStr: escapa aspas simples para INSERT/UPDATE SQL
Static Function fSqlStr(c)
Return StrTran(c, "'", "''")

// fJStr: prepara string para incluir em JSON (escapa aspas, converte para UTF-8)
Static Function fJStr(c)
    Local s := StrTran(c, "\", "\\")
    s := StrTran(s, '"', '\"')
    s := StrTran(s, Chr(13), "")
    s := StrTran(s, Chr(10), "\n")
Return EncodeUTF8(s)

// aStrJoin: une array de strings com separador
Static Function aStrJoin(aArr, cSep)
    Local cRet := ""
    Local i    := 0
    For i := 1 To Len(aArr)
        cRet += aArr[i]
        If i < Len(aArr) ; cRet += cSep ; EndIf
    Next i
Return cRet
