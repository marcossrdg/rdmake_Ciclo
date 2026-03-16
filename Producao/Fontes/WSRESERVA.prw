#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RESTFUL.ch"

/*/{Protheus.doc} WSRESERVA
    REST API para criacao de Pedidos de Reserva (prefixo R) pelo app mobile do vendedor.
    - GET /WSRESERVA?serial=XXXXXX&vendedor=XXXXXX  -> Busca dados do serial em consignacao (SB6/SDB)
    - POST /WSRESERVA (JSON body)                   -> Cria pedido de reserva via MsExecAuto MATA410
    - GET /WSRESERVA?acao=listar&vendedor=XXXXXX     -> Lista itens em consignacao do vendedor
    - GET /WSRESERVA?acao=login&vendedor=XXXXXX&senha=XXXX -> Autentica vendedor
    @type  WSRESTFUL
    @author Antonio
    @since 16/03/2026
    @version 1.0
/*/

WSRESTFUL WSRESERVA DESCRIPTION "API Reserva - App Mobile Vendedor"

    WSDATA serial   AS STRING
    WSDATA vendedor AS STRING
    WSDATA senha    AS STRING
    WSDATA acao     AS STRING
    WSDATA cliente  AS STRING
    WSDATA fil      AS STRING

    WSMETHOD GET  DESCRIPTION "Buscar serial / Login / Listar consignados" WSSYNTAX "/WSRESERVA?serial={serial}&vendedor={vendedor}"
    WSMETHOD POST DESCRIPTION "Criar Pedido de Reserva"                    WSSYNTAX "/WSRESERVA {JSON body}"

END WSRESTFUL

//=====================================================================
// GET - Multiplas acoes:
//   ?acao=login&vendedor=XXX&senha=XXX   -> Autentica
//   ?acao=listar&vendedor=XXX&cliente=XXX&fil=XX -> Lista consignados
//   ?serial=XXX&vendedor=XXX             -> Busca serial especifico
//=====================================================================
WSMETHOD GET WSRECEIVE serial, vendedor, senha, acao, cliente, fil WSSERVICE WSRESERVA

    Local cAcao    := Upper(AllTrim(::acao))
    Local cVend    := AllTrim(::vendedor)
    Local cSenha   := AllTrim(::senha)
    Local cSerial  := AllTrim(::serial)
    Local cCliente := AllTrim(::cliente)
    Local cFil     := AllTrim(::fil)
    Local cJson    := ""

    ::SetContentType("application/json")

    //--- Login do vendedor ---
    If cAcao == "LOGIN"
        cJson := fLoginVendedor(cVend, cSenha)
        ::SetResponse(cJson)
        Return .T.
    EndIf

    //--- Validar vendedor em todas as acoes ---
    If Empty(cVend)
        ::SetResponse('{"ok":false,"msg":"Parametro vendedor obrigatorio"}')
        Return .T.
    EndIf

    //--- Listar itens consignados ---
    If cAcao == "LISTAR"
        cJson := fListarConsignados(cVend, cCliente, cFil)
        ::SetResponse(cJson)
        Return .T.
    EndIf

    //--- Buscar serial especifico ---
    If !Empty(cSerial)
        cJson := fBuscarSerial(cSerial, cVend)
        ::SetResponse(cJson)
        Return .T.
    EndIf

    ::SetResponse('{"ok":false,"msg":"Informe serial ou acao (login/listar)"}')
Return .T.

//=====================================================================
// POST - Criar Pedido de Reserva
// Body JSON:
// {
//   "vendedor": "000109",
//   "senha": "xxx",
//   "cliente": "007712",
//   "loja": "01",
//   "fil": "02",
//   "medico": "M0011.0",
//   "nomeMedico": "ANDRE LUIZ DE REZENDE",
//   "paciente": "GISELA PIERRY",
//   "convenio": "ASSOCIACAO PETROBRAS",
//   "codConvenio": "008405",
//   "dtUso": "16/03/2026",
//   "mennota": "PROCEDIMENTO 16/03",
//   "itens": [
//     {"serial":"211502","produto":"PNML6F088904","lote":"H00008881",
//      "validade":"20280903","preco":4200.00}
//   ]
// }
//=====================================================================
WSMETHOD POST WSRECEIVE WSSERVICE WSRESERVA

    Local cBody   := ::GetContent()
    Local oJson   := JsonObject():New()
    Local cError  := ""
    Local cJson   := ""

    ::SetContentType("application/json")

    cError := oJson:FromJson(cBody)
    If !Empty(cError)
        ::SetResponse('{"ok":false,"msg":"JSON invalido: ' + EncodeUTF8(cError) + '"}')
        FreeObj(oJson)
        Return .T.
    EndIf

    cJson := fCriarReserva(oJson)
    ::SetResponse(cJson)

    FreeObj(oJson)
Return .T.


//=====================================================================
// fLoginVendedor - Autentica vendedor por codigo + senha
//=====================================================================
Static Function fLoginVendedor(cVend, cSenha)
    Local cJson  := ""
    Local cQry   := ""
    Local cAlias := GetNextAlias()
    Local aArea  := GetArea()

    If Empty(cVend) .Or. Empty(cSenha)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Vendedor e senha obrigatorios"}'
    EndIf

    cQry := " SELECT RTRIM(A3_COD) AS A3_COD, RTRIM(A3_NOME) AS A3_NOME, "
    cQry += "        RTRIM(A3_NREDUZ) AS A3_NREDUZ, RTRIM(A3_EMAIL) AS A3_EMAIL "
    cQry += " FROM " + RetSqlName("SA3") + " WITH (NOLOCK) "
    cQry += " WHERE D_E_L_E_T_ = '' "
    cQry += "   AND A3_COD = '" + PadR(cVend, TamSX3("A3_COD")[1]) + "' "
    cQry += "   AND A3_SENHA = '" + PadR(cSenha, TamSX3("A3_SENHA")[1]) + "' "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        (cAlias)->(dbCloseArea())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Vendedor ou senha invalidos"}'
    EndIf

    cJson := '{"ok":true,'
    cJson += '"vendedor":"' + AllTrim((cAlias)->A3_COD) + '",'
    cJson += '"nome":"'     + EncodeUTF8(AllTrim((cAlias)->A3_NOME)) + '",'
    cJson += '"nreduz":"'   + EncodeUTF8(AllTrim((cAlias)->A3_NREDUZ)) + '",'
    cJson += '"email":"'    + AllTrim((cAlias)->A3_EMAIL) + '"}'

    (cAlias)->(dbCloseArea())
    RestArea(aArea)
Return cJson


//=====================================================================
// fBuscarSerial - A partir do serial, busca dados na SDB/SB6
// Retorna: produto, lote, validade, cliente, preco, NF remessa
//=====================================================================
Static Function fBuscarSerial(cSerial, cVend)
    Local cJson   := ""
    Local cQry    := ""
    Local cAlias  := GetNextAlias()
    Local aArea   := GetArea()

    // Busca serial na SDB (entrada original) para pegar produto e lote
    // Depois cruza com SB6 para confirmar que está em consignação
    cQry := " SELECT TOP 1 "
    cQry += "   RTRIM(DB.DB_PRODUTO) AS PRODUTO, "
    cQry += "   RTRIM(DB.DB_LOTECTL) AS LOTE, "
    cQry += "   RTRIM(DB.DB_NUMSERI) AS SERIAL_FULL, "
    cQry += "   RTRIM(B6.B6_CLIFOR)  AS CLIENTE, "
    cQry += "   RTRIM(B6.B6_LOJA)    AS LOJA, "
    cQry += "   RTRIM(B6.B6_DOC)     AS NF_REMESSA, "
    cQry += "   RTRIM(B6.B6_SERIE)   AS SERIE_NF, "
    cQry += "   B6.B6_EMISSAO        AS DT_REMESSA, "
    cQry += "   B6.B6_PRUNIT         AS PRECO, "
    cQry += "   RTRIM(B6.B6_LOCAL)   AS ARMAZEM, "
    cQry += "   RTRIM(B6.B6_IDENT)   AS IDENT_B6, "
    cQry += "   B6.B6_SALDO          AS SALDO, "
    cQry += "   RTRIM(B6.B6_FILIAL)  AS FILIAL, "
    cQry += "   RTRIM(B1.B1_DESC)    AS DESC_PROD, "
    cQry += "   RTRIM(A1.A1_NOME)    AS NOME_CLI, "
    cQry += "   RTRIM(A1.A1_NREDUZ)  AS NREDUZ_CLI, "
    cQry += "   RTRIM(B8.B8_DTVALID) AS VALIDADE, "
    cQry += "   RTRIM(D2.D2_PEDIDO)  AS PEDIDO_ORIG, "
    cQry += "   RTRIM(D2.D2_IDENTB6) AS D2_IDENTB6, "
    cQry += "   RTRIM(SC5.C5_VEND1)  AS VENDEDOR_PED, "
    cQry += "   RTRIM(SC5.C5_CONDPAG) AS CONDPAG "
    cQry += " FROM " + RetSqlName("SDB") + " DB WITH (NOLOCK) "
    // JOIN SB6 pelo produto+cliente+lote+NF para confirmar consignação
    cQry += " INNER JOIN " + RetSqlName("SD2") + " D2 WITH (NOLOCK) "
    cQry += "   ON D2.D_E_L_E_T_ = '' AND D2.D2_FILIAL = DB.DB_FILIAL "
    cQry += "   AND D2.D2_COD = DB.DB_PRODUTO AND D2.D2_NUMSERI = DB.DB_NUMSERI "
    cQry += "   AND D2.D2_DOC = DB.DB_DOC AND D2.D2_SERIE = DB.DB_SERIE "
    cQry += " INNER JOIN " + RetSqlName("SB6") + " B6 WITH (NOLOCK) "
    cQry += "   ON B6.D_E_L_E_T_ = '' AND B6.B6_FILIAL = D2.D2_FILIAL "
    cQry += "   AND B6.B6_PRODUTO = D2.D2_COD AND B6.B6_CLIFOR = D2.D2_CLIENTE "
    cQry += "   AND B6.B6_LOJA = D2.D2_LOJA AND B6.B6_IDENT = D2.D2_IDENTB6 "
    cQry += "   AND B6.B6_SALDO > 0 AND B6.B6_PODER3 = 'R' "
    // JOIN SB1 para descrição do produto
    cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQry += "   ON B1.D_E_L_E_T_ = '' AND B1.B1_COD = DB.DB_PRODUTO "
    // JOIN SA1 para nome do cliente
    cQry += " LEFT JOIN " + RetSqlName("SA1") + " A1 WITH (NOLOCK) "
    cQry += "   ON A1.D_E_L_E_T_ = '' AND A1.A1_COD = B6.B6_CLIFOR AND A1.A1_LOJA = B6.B6_LOJA "
    // JOIN SB8 para validade do lote
    cQry += " LEFT JOIN " + RetSqlName("SB8") + " B8 WITH (NOLOCK) "
    cQry += "   ON B8.D_E_L_E_T_ = '' AND B8.B8_PRODUTO = DB.DB_PRODUTO "
    cQry += "   AND B8.B8_LOTECTL = DB.DB_LOTECTL AND B8.B8_LOCAL = B6.B6_LOCAL "
    cQry += "   AND B8.B8_FILIAL = B6.B6_FILIAL "
    // JOIN SC5 para pegar vendedor e cond.pgto do pedido original
    cQry += " LEFT JOIN " + RetSqlName("SC5") + " SC5 WITH (NOLOCK) "
    cQry += "   ON SC5.D_E_L_E_T_ = '' AND SC5.C5_FILIAL = D2.D2_FILIAL "
    cQry += "   AND SC5.C5_NUM = D2.D2_PEDIDO "
    // Filtros
    cQry += " WHERE DB.D_E_L_E_T_ = '' "
    cQry += "   AND RTRIM(DB.DB_NUMSERI) = '" + cSerial + "' "
    cQry += "   AND DB.DB_ORIGEM = 'SD2' "
    // Só consignação ativa (sem devolução)
    cQry += "   AND NOT EXISTS ( "
    cQry += "     SELECT 1 FROM " + RetSqlName("SD1") + " DEV WITH (NOLOCK) "
    cQry += "     INNER JOIN " + RetSqlName("SF4") + " TES WITH (NOLOCK) "
    cQry += "       ON TES.D_E_L_E_T_ = '' AND TES.F4_CODIGO = DEV.D1_TES AND TES.F4_TEXTO LIKE '%DEV%' "
    cQry += "     WHERE DEV.D_E_L_E_T_ = '' AND DEV.D1_IDENTB6 = B6.B6_IDENT "
    cQry += "   ) "
    // Sem reserva ativa existente
    cQry += "   AND NOT EXISTS ( "
    cQry += "     SELECT 1 FROM " + RetSqlName("SC6") + " RES WITH (NOLOCK) "
    cQry += "     INNER JOIN " + RetSqlName("SC5") + " R5 WITH (NOLOCK) "
    cQry += "       ON R5.D_E_L_E_T_ = '' AND R5.C5_FILIAL = RES.C6_FILIAL AND R5.C5_NUM = RES.C6_NUM "
    cQry += "     WHERE RES.D_E_L_E_T_ = '' AND LEFT(RES.C6_NUM, 1) = 'R' "
    cQry += "     AND RES.C6_NUMSERI = DB.DB_NUMSERI AND RES.C6_PRODUTO = DB.DB_PRODUTO "
    cQry += "     AND RES.C6_BLQ <> 'R' AND RES.C6_QTDENT = 0 "
    cQry += "   ) "
    cQry += " ORDER BY DB.DB_DATA DESC "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    If (cAlias)->(Eof())
        (cAlias)->(dbCloseArea())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Serial nao encontrado em consignacao ou ja reservado"}'
    EndIf

    cJson := '{"ok":true,'
    cJson += '"serial":"'      + AllTrim((cAlias)->SERIAL_FULL) + '",'
    cJson += '"produto":"'     + AllTrim((cAlias)->PRODUTO) + '",'
    cJson += '"descProduto":"' + EncodeUTF8(AllTrim((cAlias)->DESC_PROD)) + '",'
    cJson += '"lote":"'        + AllTrim((cAlias)->LOTE) + '",'
    cJson += '"validade":"'    + AllTrim((cAlias)->VALIDADE) + '",'
    cJson += '"cliente":"'     + AllTrim((cAlias)->CLIENTE) + '",'
    cJson += '"loja":"'        + AllTrim((cAlias)->LOJA) + '",'
    cJson += '"nomeCli":"'     + EncodeUTF8(AllTrim((cAlias)->NREDUZ_CLI)) + '",'
    cJson += '"nfRemessa":"'   + AllTrim((cAlias)->NF_REMESSA) + '",'
    cJson += '"serieNF":"'     + AllTrim((cAlias)->SERIE_NF) + '",'
    cJson += '"dtRemessa":"'   + AllTrim((cAlias)->DT_REMESSA) + '",'
    cJson += '"preco":'        + AllTrim(Str((cAlias)->PRECO)) + ','
    cJson += '"armazem":"'     + AllTrim((cAlias)->ARMAZEM) + '",'
    cJson += '"filial":"'      + AllTrim((cAlias)->FILIAL) + '",'
    cJson += '"identB6":"'     + AllTrim((cAlias)->IDENT_B6) + '",'
    cJson += '"pedidoOrig":"'  + AllTrim((cAlias)->PEDIDO_ORIG) + '",'
    cJson += '"condPag":"'     + AllTrim((cAlias)->CONDPAG) + '",'
    cJson += '"vendedorPed":"' + AllTrim((cAlias)->VENDEDOR_PED) + '"}'

    (cAlias)->(dbCloseArea())
    RestArea(aArea)
Return cJson


//=====================================================================
// fListarConsignados - Lista itens em consignacao dos clientes do vendedor
//=====================================================================
Static Function fListarConsignados(cVend, cCliente, cFil)
    Local cJson   := ""
    Local cQry    := ""
    Local cAlias  := GetNextAlias()
    Local aArea   := GetArea()
    Local lFirst  := .T.

    cQry := " SELECT "
    cQry += "   RTRIM(B6.B6_FILIAL)  AS FILIAL, "
    cQry += "   RTRIM(B6.B6_CLIFOR)  AS CLIENTE, "
    cQry += "   RTRIM(B6.B6_LOJA)    AS LOJA, "
    cQry += "   RTRIM(A1.A1_NREDUZ)  AS NOME_CLI, "
    cQry += "   RTRIM(B6.B6_PRODUTO) AS PRODUTO, "
    cQry += "   RTRIM(B1.B1_DESC)    AS DESC_PROD, "
    cQry += "   RTRIM(D2.D2_NUMSERI) AS SERIAL, "
    cQry += "   RTRIM(D2.D2_LOTECTL) AS LOTE, "
    cQry += "   RTRIM(B8.B8_DTVALID) AS VALIDADE, "
    cQry += "   B6.B6_PRUNIT         AS PRECO, "
    cQry += "   RTRIM(B6.B6_DOC)     AS NF_REMESSA, "
    cQry += "   B6.B6_EMISSAO        AS DT_REMESSA, "
    cQry += "   RTRIM(B6.B6_IDENT)   AS IDENT_B6 "
    cQry += " FROM " + RetSqlName("SB6") + " B6 WITH (NOLOCK) "
    // JOIN SD2 para pegar serial e lote
    cQry += " INNER JOIN " + RetSqlName("SD2") + " D2 WITH (NOLOCK) "
    cQry += "   ON D2.D_E_L_E_T_ = '' AND D2.D2_FILIAL = B6.B6_FILIAL "
    cQry += "   AND D2.D2_COD = B6.B6_PRODUTO AND D2.D2_CLIENTE = B6.B6_CLIFOR "
    cQry += "   AND D2.D2_LOJA = B6.B6_LOJA AND D2.D2_IDENTB6 = B6.B6_IDENT "
    // JOIN SC6/SC5 para filtrar por vendedor
    cQry += " INNER JOIN " + RetSqlName("SC6") + " C6 WITH (NOLOCK) "
    cQry += "   ON C6.D_E_L_E_T_ = '' AND C6.C6_FILIAL = D2.D2_FILIAL "
    cQry += "   AND C6.C6_NUM = D2.D2_PEDIDO AND C6.C6_ITEM = D2.D2_ITEMPV "
    cQry += " INNER JOIN " + RetSqlName("SC5") + " C5 WITH (NOLOCK) "
    cQry += "   ON C5.D_E_L_E_T_ = '' AND C5.C5_FILIAL = C6.C6_FILIAL "
    cQry += "   AND C5.C5_NUM = C6.C6_NUM "
    cQry += "   AND C5.C5_VEND1 = '" + PadR(cVend, TamSX3("A3_COD")[1]) + "' "
    // JOINs auxiliares
    cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQry += "   ON B1.D_E_L_E_T_ = '' AND B1.B1_COD = B6.B6_PRODUTO "
    cQry += " LEFT JOIN " + RetSqlName("SA1") + " A1 WITH (NOLOCK) "
    cQry += "   ON A1.D_E_L_E_T_ = '' AND A1.A1_COD = B6.B6_CLIFOR AND A1.A1_LOJA = B6.B6_LOJA "
    cQry += " LEFT JOIN " + RetSqlName("SB8") + " B8 WITH (NOLOCK) "
    cQry += "   ON B8.D_E_L_E_T_ = '' AND B8.B8_PRODUTO = B6.B6_PRODUTO "
    cQry += "   AND B8.B8_LOTECTL = D2.D2_LOTECTL AND B8.B8_LOCAL = B6.B6_LOCAL "
    cQry += "   AND B8.B8_FILIAL = B6.B6_FILIAL "
    // Filtros: em consignação, com saldo, sem devolução
    cQry += " WHERE B6.D_E_L_E_T_ = '' "
    cQry += "   AND B6.B6_SALDO > 0 AND B6.B6_PODER3 = 'R' "
    cQry += "   AND B6.B6_TPCF = 'C' AND B6.B6_TIPO = 'E' "
    cQry += "   AND RTRIM(ISNULL(D2.D2_NUMSERI,'')) <> '' "
    If !Empty(cCliente)
        cQry += "   AND B6.B6_CLIFOR = '" + PadR(cCliente, TamSX3("A1_COD")[1]) + "' "
    EndIf
    If !Empty(cFil)
        cQry += "   AND B6.B6_FILIAL = '" + PadR(cFil, TamSX3("C5_FILIAL")[1]) + "' "
    EndIf
    // Sem devolução
    cQry += "   AND NOT EXISTS ( "
    cQry += "     SELECT 1 FROM " + RetSqlName("SD1") + " DEV WITH (NOLOCK) "
    cQry += "     INNER JOIN " + RetSqlName("SF4") + " TES WITH (NOLOCK) "
    cQry += "       ON TES.D_E_L_E_T_ = '' AND TES.F4_CODIGO = DEV.D1_TES AND TES.F4_TEXTO LIKE '%DEV%' "
    cQry += "     INNER JOIN " + RetSqlName("SDB") + " SDB WITH (NOLOCK) "
    cQry += "       ON SDB.D_E_L_E_T_ = '' AND SDB.DB_DOC = DEV.D1_DOC AND SDB.DB_SERIE = DEV.D1_SERIE AND SDB.DB_PRODUTO = DEV.D1_COD "
    cQry += "     WHERE DEV.D_E_L_E_T_ = '' AND DEV.D1_IDENTB6 = B6.B6_IDENT "
    cQry += "     AND RTRIM(ISNULL(SDB.DB_NUMSERI,'')) = RTRIM(ISNULL(D2.D2_NUMSERI,'')) "
    cQry += "   ) "
    // Sem reserva ativa
    cQry += "   AND NOT EXISTS ( "
    cQry += "     SELECT 1 FROM " + RetSqlName("SC6") + " RES WITH (NOLOCK) "
    cQry += "     WHERE RES.D_E_L_E_T_ = '' AND LEFT(RES.C6_NUM, 1) = 'R' "
    cQry += "     AND RES.C6_NUMSERI = D2.D2_NUMSERI AND RES.C6_PRODUTO = D2.D2_COD "
    cQry += "     AND RES.C6_BLQ <> 'R' AND RES.C6_QTDENT = 0 "
    cQry += "   ) "
    cQry += " ORDER BY B6.B6_CLIFOR, B6.B6_PRODUTO "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    cJson := '{"ok":true,"itens":['

    While !(cAlias)->(Eof())
        If !lFirst
            cJson += ','
        EndIf
        lFirst := .F.

        cJson += '{'
        cJson += '"filial":"'      + AllTrim((cAlias)->FILIAL) + '",'
        cJson += '"cliente":"'     + AllTrim((cAlias)->CLIENTE) + '",'
        cJson += '"loja":"'        + AllTrim((cAlias)->LOJA) + '",'
        cJson += '"nomeCli":"'     + EncodeUTF8(AllTrim((cAlias)->NOME_CLI)) + '",'
        cJson += '"produto":"'     + AllTrim((cAlias)->PRODUTO) + '",'
        cJson += '"descProduto":"' + EncodeUTF8(AllTrim((cAlias)->DESC_PROD)) + '",'
        cJson += '"serial":"'      + AllTrim((cAlias)->SERIAL) + '",'
        cJson += '"lote":"'        + AllTrim((cAlias)->LOTE) + '",'
        cJson += '"validade":"'    + AllTrim((cAlias)->VALIDADE) + '",'
        cJson += '"preco":'        + AllTrim(Str((cAlias)->PRECO)) + ','
        cJson += '"nfRemessa":"'   + AllTrim((cAlias)->NF_REMESSA) + '",'
        cJson += '"dtRemessa":"'   + AllTrim((cAlias)->DT_REMESSA) + '",'
        cJson += '"identB6":"'     + AllTrim((cAlias)->IDENT_B6) + '"'
        cJson += '}'

        (cAlias)->(dbSkip())
    EndDo

    cJson += ']}'

    (cAlias)->(dbCloseArea())
    RestArea(aArea)
Return cJson


//=====================================================================
// fCriarReserva - Cria pedido de reserva via MsExecAuto MATA410
//=====================================================================
Static Function fCriarReserva(oJson)
    Local aArea    := GetArea()
    Local aCabec   := {}
    Local aItens   := {}
    Local aLinha   := {}
    Local oItems   := Nil
    Local cVend    := AllTrim(oJson:GetJsonObject("vendedor"))
    Local cSenha   := AllTrim(oJson:GetJsonObject("senha"))
    Local cCliente := AllTrim(oJson:GetJsonObject("cliente"))
    Local cLoja    := AllTrim(oJson:GetJsonObject("loja"))
    Local cFil     := AllTrim(oJson:GetJsonObject("fil"))
    Local cMedico  := AllTrim(oJson:GetJsonObject("medico"))
    Local cNomeMed := AllTrim(oJson:GetJsonObject("nomeMedico"))
    Local cPacient := AllTrim(oJson:GetJsonObject("paciente"))
    Local cConven  := AllTrim(oJson:GetJsonObject("convenio"))
    Local cCodConv := AllTrim(oJson:GetJsonObject("codConvenio"))
    Local cDtUso   := AllTrim(oJson:GetJsonObject("dtUso"))
    Local cMenNota := AllTrim(oJson:GetJsonObject("mennota"))
    Local cNumPed  := ""
    Local cJson    := ""
    Local cErro    := ""
    Local cArqLog  := ""
    Local aLogAuto := {}
    Local nX       := 0
    Local nY       := 0

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    //--- Validar vendedor ---
    If Empty(cVend) .Or. Empty(cSenha)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Vendedor e senha obrigatorios"}'
    EndIf

    // Autentica
    DbSelectArea("SA3")
    SA3->(DbSetOrder(1))
    If !SA3->(DbSeek(xFilial("SA3") + PadR(cVend, TamSX3("A3_COD")[1])))
        RestArea(aArea)
        Return '{"ok":false,"msg":"Vendedor nao encontrado"}'
    EndIf
    If AllTrim(SA3->A3_SENHA) <> cSenha
        RestArea(aArea)
        Return '{"ok":false,"msg":"Senha do vendedor invalida"}'
    EndIf

    //--- Validar cliente ---
    If Empty(cCliente) .Or. Empty(cLoja)
        RestArea(aArea)
        Return '{"ok":false,"msg":"Cliente e loja obrigatorios"}'
    EndIf

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))
    If !SA1->(DbSeek(xFilial("SA1") + PadR(cCliente, TamSX3("A1_COD")[1]) + PadR(cLoja, TamSX3("A1_LOJA")[1])))
        RestArea(aArea)
        Return '{"ok":false,"msg":"Cliente nao encontrado"}'
    EndIf

    //--- Itens ---
    oItems := oJson:GetJsonObject("itens")
    If oItems == Nil .Or. Len(oItems) == 0
        RestArea(aArea)
        Return '{"ok":false,"msg":"Nenhum item informado"}'
    EndIf

    //--- Gerar numero do pedido ---
    cNumPed := U_ProxPV("R")
    ConOut("[WSRESERVA] Gerando reserva " + cNumPed + " - Vend: " + cVend + " - Cli: " + cCliente)

    //--- Montar cabecalho ---
    aAdd(aCabec, {"C5_NUM",     cNumPed,  Nil})
    aAdd(aCabec, {"C5_TPSAIDA", "R",      Nil})
    aAdd(aCabec, {"C5_TIPO",    "N",      Nil})
    aAdd(aCabec, {"C5_CLIENTE", cCliente, Nil})
    aAdd(aCabec, {"C5_LOJACLI", cLoja,    Nil})
    aAdd(aCabec, {"C5_LOJAENT", cLoja,    Nil})
    aAdd(aCabec, {"C5_CONDPAG", "002",    Nil})
    aAdd(aCabec, {"C5_VEND1",   cVend,    Nil})

    If !Empty(cMedico)
        aAdd(aCabec, {"C5_MEDICO",  cMedico,  Nil})
    EndIf
    If !Empty(cNomeMed)
        aAdd(aCabec, {"C5_XNOMEDI", cNomeMed, Nil})
    EndIf
    If !Empty(cPacient)
        aAdd(aCabec, {"C5_PACIENT", cPacient, Nil})
    EndIf
    If !Empty(cConven)
        aAdd(aCabec, {"C5_XCONVEN", cConven,  Nil})
    EndIf
    If !Empty(cCodConv)
        aAdd(aCabec, {"C5_XCODCON", cCodConv, Nil})
    EndIf
    If !Empty(cDtUso)
        aAdd(aCabec, {"C5_DTUSO",   CtoD(cDtUso), Nil})
    EndIf
    If !Empty(cMenNota)
        aAdd(aCabec, {"C5_MENNOTA", cMenNota, Nil})
    EndIf

    //--- Montar itens ---
    For nX := 1 To Len(oItems)
        aLinha := {}
        aAdd(aLinha, {"C6_ITEM",    StrZero(nX, 2),                                              Nil})
        aAdd(aLinha, {"C6_PRODUTO", AllTrim(oItems[nX]:GetJsonObject("produto")),                 Nil})
        aAdd(aLinha, {"C6_QTDVEN",  1,                                                           Nil})
        aAdd(aLinha, {"C6_PRCVEN",  oItems[nX]:GetJsonObject("preco"),                            Nil})
        aAdd(aLinha, {"C6_VALOR",   oItems[nX]:GetJsonObject("preco"),                            Nil})
        aAdd(aLinha, {"C6_LOTECTL", AllTrim(oItems[nX]:GetJsonObject("lote")),                    Nil})
        aAdd(aLinha, {"C6_NUMSERI", AllTrim(oItems[nX]:GetJsonObject("serial")),                  Nil})
        aAdd(aLinha, {"C6_TES",     "615",                                                       Nil})
        aAdd(aLinha, {"C6_LOCAL",   "57",                                                        Nil})
        aAdd(aLinha, {"C6_DTVALID", StoD(AllTrim(oItems[nX]:GetJsonObject("validade"))),          Nil})
        aAdd(aItens, aLinha)
    Next

    //--- Executar MATA410 ---
    ConOut("[WSRESERVA] ExecAuto MATA410 - " + cNumPed + " - " + Str(Len(aItens)) + " itens")

    BeginTran()
    MsExecAuto({|x,y,z| MATA410(x,y,z)}, aCabec, aItens, 3, .F.)

    If lMsErroAuto
        RollBackSX8()
        DisarmTransaction()

        // Capturar erro
        aLogAuto := GetAutoGRLog()
        For nY := 1 To Len(aLogAuto)
            cErro += aLogAuto[nY] + Chr(13) + Chr(10)
        Next

        // Gravar log
        If !ExistDir("\log_reserva\")
            MakeDir("\log_reserva\")
        EndIf
        cArqLog := cNumPed + "-" + StrTran(Time(), ":", "-") + ".log"
        MemoWrite("\log_reserva\" + cArqLog, cErro)

        ConOut("[WSRESERVA] ERRO ExecAuto: " + cErro)
        cJson := '{"ok":false,"msg":"Erro ao gerar reserva: ' + EncodeUTF8(AllTrim(cErro)) + '"}'
    Else
        ConfirmSX8()
        EndTran()

        //--- Salvar fotos na ZZ1010 ---
        fSalvarFotos(oJson, cNumPed, cVend, cFil)

        ConOut("[WSRESERVA] Reserva " + cNumPed + " gerada com sucesso!")
        cJson := '{"ok":true,"pedido":"' + cNumPed + '","msg":"Reserva gerada com sucesso"}'
    EndIf

    RestArea(aArea)
Return cJson

//=====================================================================
// fSalvarFotos - Salva fotos como JPG na pasta do servidor e registra caminho na ZZ1010
//=====================================================================
Static Function fSalvarFotos(oJson, cPedido, cVend, cFil)
    Local aFotos   := oJson:GetJsonObject("fotos")
    Local oFoto    := Nil
    Local cBase64  := ""
    Local cDesc    := ""
    Local cSeq     := ""
    Local cData    := DtoS(Date())
    Local cHora    := SubStr(Time(), 1, 5)
    Local cSQL     := ""
    Local cPasta   := "\docs_reserv\" + AllTrim(cPedido) + "\"
    Local cArquivo := ""
    Local cBinario := ""
    Local nHandle  := 0
    Local nI       := 0

    If aFotos == Nil .Or. Len(aFotos) == 0
        Return
    EndIf

    // Criar pasta se nao existe
    If !ExistDir("\docs_reserv\")
        MakeDir("\docs_reserv\")
    EndIf
    If !ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf

    For nI := 1 To Len(aFotos)
        oFoto   := aFotos[nI]
        cBase64 := AllTrim(oFoto:GetJsonObject("base64"))
        cDesc   := AllTrim(oFoto:GetJsonObject("desc"))
        cSeq    := StrZero(nI, 3)

        // Remover prefixo data:image/jpeg;base64, se existir
        If "base64," $ cBase64
            cBase64 := SubStr(cBase64, At("base64,", cBase64) + 7)
        EndIf

        // Decodificar base64 e gravar arquivo JPG
        cBinario := Decode64(cBase64)
        cArquivo := cPasta + cDesc + ".jpg"

        nHandle := FCreate(cArquivo)
        If nHandle >= 0
            FWrite(nHandle, cBinario)
            FClose(nHandle)
            ConOut("[WSRESERVA] Foto salva: " + cArquivo)
        Else
            ConOut("[WSRESERVA] Erro ao criar arquivo: " + cArquivo)
        EndIf

        // Registrar caminho na ZZ1010
        cSQL := "INSERT INTO ZZ1010 (ZZ1_FILIAL, ZZ1_PEDIDO, ZZ1_SEQ, ZZ1_DESC, ZZ1_DATA, ZZ1_HORA, ZZ1_VEND, ZZ1_IMAGEM) "
        cSQL += "VALUES ('" + cFil + "', '" + cPedido + "', '" + cSeq + "', '" + cDesc + "', '" + cData + "', '" + cHora + "', '" + cVend + "', '" + cArquivo + "')"

        If TCSqlExec(cSQL) < 0
            ConOut("[WSRESERVA] Erro ao registrar foto " + cSeq + " no banco")
        EndIf
    Next

Return
