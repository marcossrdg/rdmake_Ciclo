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
    ConOut("[WSRESERVA] fBuscarSerial INICIO - Serial: " + cSerial + " Vend: " + cVend)
    Local cAlias  := GetNextAlias()
    Local aArea   := GetArea()
    Local cProduto  := ""
    Local cLote     := ""
    Local cSerFull  := ""
    Local cCliFor   := ""
    Local cLoja     := ""
    Local cArmaz    := ""
    Local cOrigem   := ""
    Local cDocDB    := ""
    Local cSerieDB  := ""
    Local cDescProd := ""
    Local nPrcVen   := 0
    Local cPedOrig  := ""
    Local cIdentB6  := ""
    Local cPedido   := ""
    Local cAliasB6  := ""
    Local cQryB6    := ""
    Local cNfRem    := ""
    Local cSerNF    := ""
    Local cDtRem    := ""
    Local nPreco    := 0
    Local cArmB6    := ""
    Local cIdentB   := ""
    Local cFilB6    := ""
    Local cNomeCli  := ""
    Local cValidade := ""
    Local cVendPed  := ""
    Local cCondPag  := ""
    Local cFilSerial := ""

    ConOut("[WSRESERVA] fBuscarSerial INICIO - Serial:[" + cSerial + "] Vend:[" + cVend + "] cFilAnt=[" + cFilAnt + "] cEmpAnt=[" + cEmpAnt + "]")

    // Busca serial na SDB (mesmo criterio do CHKITEMPV) - busca simples primeiro
    cQry := " SELECT TOP 1 "
    cQry += "   RTRIM(DB.DB_PRODUTO) AS PRODUTO, "
    cQry += "   RTRIM(DB.DB_LOTECTL) AS LOTE, "
    cQry += "   RTRIM(DB.DB_NUMSERI) AS SERIAL_FULL, "
    cQry += "   RTRIM(DB.DB_CLIFOR)  AS CLIFOR, "
    cQry += "   RTRIM(DB.DB_LOJA)    AS LOJA, "
    cQry += "   RTRIM(DB.DB_LOCAL)   AS ARMAZ, "
    cQry += "   RTRIM(DB.DB_LOCALIZ) AS LOCALIZ, "
    cQry += "   DB.DB_ORIGEM         AS DB_ORIGEM, "
    cQry += "   RTRIM(DB.DB_DOC)     AS DB_DOC, "
    cQry += "   RTRIM(DB.DB_SERIE)   AS DB_SERIE, "
    cQry += "   RTRIM(DB.DB_TM)      AS TES, "
    cQry += "   RTRIM(DB.DB_NUMSEQ)  AS DOCNUMSEQ, "
    cQry += "   DB.DB_DATA           AS NFEMISSAO, "
    cQry += "   RTRIM(DB.DB_FILIAL)  AS DB_FILIAL, "
    cQry += "   COALESCE(D2.D2_PRCVEN,0) AS D2_PRCVEN, "
    cQry += "   COALESCE(RTRIM(D2.D2_VEND1),'') AS VEND1, "
    cQry += "   COALESCE(RTRIM(D2.D2_PEDIDO),'') AS PEDIDO_ORIG, "
    cQry += "   COALESCE(RTRIM(D2.D2_IDENTB6),'') AS D2_IDENTB6, "
    cQry += "   RTRIM(B1.B1_DESC)    AS DESC_PROD, "
    cQry += "   COALESCE((SELECT TOP 1 C6_NUM FROM " + RetSqlName("SC6") + " SC6 "
    cQry += "     WHERE SC6.D_E_L_E_T_='' AND SC6.C6_FILIAL=DB.DB_FILIAL "
    cQry += "     AND SC6.C6_NUMSERI=DB.DB_NUMSERI AND SC6.C6_QTDENT=0),'      ') AS PEDIDO "
    // Tabela principal: SDB (mesmo criterio CHKITEMPV)
    cQry += " FROM " + RetSqlName("SDB") + " DB WITH (NOLOCK) "
    // LEFT JOIN SD2 pelo NUMSEQ (mesmo criterio CHKITEMPV)
    cQry += " LEFT JOIN " + RetSqlName("SD2") + " D2 WITH (NOLOCK) "
    cQry += "   ON D2.D_E_L_E_T_ = '' AND D2.D2_FILIAL = DB.DB_FILIAL "
    cQry += "   AND D2.D2_NUMSEQ = DB.DB_NUMSEQ "
    // JOIN SB1 para descricao do produto
    cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 WITH (NOLOCK) "
    cQry += "   ON B1.D_E_L_E_T_ = '' AND B1.B1_COD = DB.DB_PRODUTO "
    // Filtros: sem filtro de filial para garantir encontrar o serial
    cQry += " WHERE DB.D_E_L_E_T_ = '' "
    cQry += "   AND DB.DB_NUMSERI = '" + cSerial + "' "
    cQry += "   AND DB.DB_ESTORNO <> 'S' "
    cQry += " ORDER BY DB.DB_DATA DESC, DB.DB_IDOPERA DESC "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQry), cAlias, .F., .T.)

    // Trava 1: Serial nao existe
    If (cAlias)->(Eof())
        ConOut("[WSRESERVA] TRAVA 1 - Serial NAO encontrado na SDB")
        (cAlias)->(dbCloseArea())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Serial nao encontrado em nenhuma filial"}'
    Else
        ConOut("[WSRESERVA] SDB encontrou - Produto: " + AllTrim((cAlias)->PRODUTO) + " Cliente: " + AllTrim((cAlias)->CLIFOR) + " Filial: " + AllTrim((cAlias)->DB_FILIAL))
    EndIf

    // Guarda dados do registro encontrado
    cFilSerial := AllTrim((cAlias)->DB_FILIAL)
    cProduto  := AllTrim((cAlias)->PRODUTO)
    cLote     := AllTrim((cAlias)->LOTE)
    cSerFull  := AllTrim((cAlias)->SERIAL_FULL)
    cCliFor   := AllTrim((cAlias)->CLIFOR)
    cLoja     := AllTrim((cAlias)->LOJA)
    cArmaz    := AllTrim((cAlias)->ARMAZ)
    cOrigem   := AllTrim((cAlias)->DB_ORIGEM)
    cDocDB    := AllTrim((cAlias)->DB_DOC)
    cSerieDB  := AllTrim((cAlias)->DB_SERIE)
    cDescProd := AllTrim((cAlias)->DESC_PROD)
    nPrcVen   := (cAlias)->D2_PRCVEN
    cPedOrig  := AllTrim((cAlias)->PEDIDO_ORIG)
    cIdentB6  := AllTrim((cAlias)->D2_IDENTB6)
    cPedido   := AllTrim((cAlias)->PEDIDO)
    (cAlias)->(dbCloseArea())

    // Trava 2: Serial ja baixado/consignado para outro cliente (mesmo criterio CHKITEMPV)
    // Se origem SC6 e tem DOC preenchido, significa que ja foi faturado/consignado
    // Nesse caso precisamos checar na SB6 se tem consignacao ativa
    // Se nao tem, o serial ja foi vendido/devolvido
    cAliasB6 := GetNextAlias()
    cQryB6   := ""
    cQryB6 := " SELECT TOP 1 "
    cQryB6 += "   RTRIM(B6.B6_CLIFOR)  AS CLIENTE, "
    cQryB6 += "   RTRIM(B6.B6_LOJA)    AS LOJA, "
    cQryB6 += "   RTRIM(B6.B6_DOC)     AS NF_REMESSA, "
    cQryB6 += "   RTRIM(B6.B6_SERIE)   AS SERIE_NF, "
    cQryB6 += "   B6.B6_EMISSAO        AS DT_REMESSA, "
    cQryB6 += "   B6.B6_PRUNIT         AS PRECO, "
    cQryB6 += "   RTRIM(B6.B6_LOCAL)   AS ARMAZEM, "
    cQryB6 += "   RTRIM(B6.B6_IDENT)   AS IDENT_B6, "
    cQryB6 += "   B6.B6_SALDO          AS SALDO, "
    cQryB6 += "   RTRIM(B6.B6_FILIAL)  AS FILIAL, "
    cQryB6 += "   B6.B6_PODER3         AS PODER3, "
    cQryB6 += "   RTRIM(A1.A1_NOME)    AS NOME_CLI, "
    cQryB6 += "   RTRIM(A1.A1_NREDUZ)  AS NREDUZ_CLI, "
    cQryB6 += "   RTRIM(B8.B8_DTVALID) AS VALIDADE, "
    cQryB6 += "   COALESCE(RTRIM(SC5.C5_VEND1),'') AS VENDEDOR_PED, "
    cQryB6 += "   COALESCE(RTRIM(SC5.C5_CONDPAG),'') AS CONDPAG "
    cQryB6 += " FROM " + RetSqlName("SB6") + " B6 WITH (NOLOCK) "
    cQryB6 += " LEFT JOIN " + RetSqlName("SA1") + " A1 WITH (NOLOCK) "
    cQryB6 += "   ON A1.D_E_L_E_T_ = '' AND A1.A1_COD = B6.B6_CLIFOR AND A1.A1_LOJA = B6.B6_LOJA "
    cQryB6 += " LEFT JOIN " + RetSqlName("SB8") + " B8 WITH (NOLOCK) "
    cQryB6 += "   ON B8.D_E_L_E_T_ = '' AND B8.B8_PRODUTO = B6.B6_PRODUTO "
    cQryB6 += "   AND B8.B8_LOTECTL = B6.B6_LOTECTL AND B8.B8_LOCAL = B6.B6_LOCAL "
    cQryB6 += "   AND B8.B8_FILIAL = B6.B6_FILIAL "
    cQryB6 += " LEFT JOIN " + RetSqlName("SD2") + " D2B WITH (NOLOCK) "
    cQryB6 += "   ON D2B.D_E_L_E_T_ = '' AND D2B.D2_FILIAL = B6.B6_FILIAL "
    cQryB6 += "   AND D2B.D2_COD = B6.B6_PRODUTO AND D2B.D2_IDENTB6 = B6.B6_IDENT "
    cQryB6 += "   AND D2B.D2_NUMSERI = '" + cSerial + "' "
    cQryB6 += " LEFT JOIN " + RetSqlName("SC5") + " SC5 WITH (NOLOCK) "
    cQryB6 += "   ON SC5.D_E_L_E_T_ = '' AND SC5.C5_FILIAL = D2B.D2_FILIAL "
    cQryB6 += "   AND SC5.C5_NUM = D2B.D2_PEDIDO "
    cQryB6 += " WHERE B6.D_E_L_E_T_ = '' "
    cQryB6 += "   AND B6.B6_FILIAL = '" + cFilSerial + "' "
    cQryB6 += "   AND B6.B6_PRODUTO = '" + cProduto + "' "
    cQryB6 += "   AND B6.B6_CLIFOR = '" + cCliFor + "' "
    cQryB6 += "   AND B6.B6_LOJA = '" + cLoja + "' "
    cQryB6 += "   AND B6.B6_SALDO > 0 AND B6.B6_PODER3 = 'R' "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQryB6), cAliasB6, .F., .T.)

    // Trava 3: Nao tem consignacao ativa na SB6
    If (cAliasB6)->(Eof())
        ConOut("[WSRESERVA] TRAVA 3 - SB6 vazio. Produto: " + cProduto + " CliFor: " + cCliFor + " Loja: " + cLoja + " FilSerial=[" + cFilSerial + "]")
        (cAliasB6)->(dbCloseArea())
        RestArea(aArea)
        // Se tem DOC na SDB, o serial ja foi baixado
        If !Empty(cDocDB)
            Return '{"ok":false,"msg":"Serial ja foi baixado pelo Doc ' + cDocDB + '/' + cSerieDB + ' - nao esta mais em consignacao"}'
        EndIf
        Return '{"ok":false,"msg":"Serial nao encontrado em consignacao ativa"}'
    EndIf

    // Trava 4: Serial ja incluido em outro pedido de reserva
    If !Empty(cPedido) .And. AllTrim(cPedido) <> ""
        (cAliasB6)->(dbCloseArea())
        RestArea(aArea)
        Return '{"ok":false,"msg":"Serial ja incluido no Pedido ' + AllTrim(cPedido) + '. Exclua daquele pedido primeiro."}'
    EndIf

    // Tudo OK - monta JSON com dados da SB6
    cNfRem    := AllTrim((cAliasB6)->NF_REMESSA)
    cSerNF    := AllTrim((cAliasB6)->SERIE_NF)
    cDtRem    := AllTrim((cAliasB6)->DT_REMESSA)
    nPreco    := iif(nPrcVen > 0, nPrcVen, (cAliasB6)->PRECO)
    cArmB6    := AllTrim((cAliasB6)->ARMAZEM)
    cIdentB   := AllTrim((cAliasB6)->IDENT_B6)
    cFilB6    := AllTrim((cAliasB6)->FILIAL)
    cNomeCli  := AllTrim((cAliasB6)->NREDUZ_CLI)
    cValidade := AllTrim((cAliasB6)->VALIDADE)
    cVendPed  := AllTrim((cAliasB6)->VENDEDOR_PED)
    cCondPag  := AllTrim((cAliasB6)->CONDPAG)
    (cAliasB6)->(dbCloseArea())

    cJson := '{"ok":true,'
    cJson += '"serial":"'      + cSerFull + '",'
    cJson += '"produto":"'     + cProduto + '",'
    cJson += '"descProduto":"' + EncodeUTF8(cDescProd) + '",'
    cJson += '"lote":"'        + cLote + '",'
    cJson += '"validade":"'    + cValidade + '",'
    cJson += '"cliente":"'     + cCliFor + '",'
    cJson += '"loja":"'        + cLoja + '",'
    cJson += '"nomeCli":"'     + EncodeUTF8(cNomeCli) + '",'
    cJson += '"nfRemessa":"'   + cNfRem + '",'
    cJson += '"serieNF":"'     + cSerNF + '",'
    cJson += '"dtRemessa":"'   + cDtRem + '",'
    cJson += '"preco":'        + AllTrim(Str(nPreco)) + ','
    cJson += '"armazem":"'     + cArmB6 + '",'
    cJson += '"filial":"'      + cFilB6 + '",'
    cJson += '"identB6":"'     + cIdentB  + '",'
    cJson += '"pedidoOrig":"'  + cPedOrig + '",'
    cJson += '"condPag":"'     + cCondPag + '",'
    cJson += '"vendedorPed":"' + cVendPed + '"}'
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

        //--- Salvar fotos no Banco de Conhecimento ---
        fSalvarFotos(oJson, cNumPed, cVend, cFil)

        ConOut("[WSRESERVA] Reserva " + cNumPed + " gerada com sucesso!")
        cJson := '{"ok":true,"pedido":"' + cNumPed + '","msg":"Reserva gerada com sucesso"}'
    EndIf

    RestArea(aArea)
Return cJson

//=====================================================================
// fSalvarFotos - Salva fotos no Banco de Conhecimento (ACB) e vincula ao PV (AC9)
//=====================================================================
Static Function fSalvarFotos(oJson, cPedido, cVend, cFil)
    Local aFotos    := oJson:GetJsonObject("fotos")
    Local oFoto     := Nil
    Local cBase64   := ""
    Local cDesc     := ""
    Local cBinario  := ""
    Local cArquivo  := ""
    Local cNomeArq  := ""
    Local cCodObj   := ""
    Local cPasta    := ""
    Local cEntidade := "SC5"
    Local cCodEnt   := ""
    Local nHandle   := 0
    Local nI        := 0
    Local nProxCod  := 0
    Local cAliasAux := ""
    Local cQryAux   := ""

    If aFotos == Nil .Or. Len(aFotos) == 0
        Return
    EndIf

    // Montar o CODENT no formato que o Protheus espera para SC5
    // Baseado nos existentes: filial + dados identificadores
    cCodEnt := PadR(AllTrim(cPedido), 70)

    // Buscar proximo codigo de objeto no ACB
    cAliasAux := GetNextAlias()
    cQryAux := "SELECT ISNULL(MAX(CAST(ACB_CODOBJ AS INT)),0) AS MAXCOD FROM " + RetSqlName("ACB") + " WHERE D_E_L_E_T_=' '"
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQryAux), cAliasAux, .F., .T.)
    nProxCod := (cAliasAux)->MAXCOD
    (cAliasAux)->(dbCloseArea())

    // Pasta do Banco de Conhecimento no rootpath do Protheus
    cPasta := "\knowledge\"
    If !ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf

    For nI := 1 To Len(aFotos)
        oFoto   := aFotos[nI]
        cBase64 := AllTrim(oFoto:GetJsonObject("base64"))
        cDesc   := AllTrim(oFoto:GetJsonObject("desc"))

        // Remover prefixo data:image/jpeg;base64, se existir
        If "base64," $ cBase64
            cBase64 := SubStr(cBase64, At("base64,", cBase64) + 7)
        EndIf

        // Decodificar base64 e gravar arquivo JPG
        cBinario := Decode64(cBase64)
        cNomeArq := "RES_" + AllTrim(cPedido) + "_" + StrZero(nI, 2) + ".jpg"
        cArquivo := cPasta + cNomeArq

        nHandle := FCreate(cArquivo)
        If nHandle >= 0
            FWrite(nHandle, cBinario)
            FClose(nHandle)
            ConOut("[WSRESERVA] Foto salva no KB: " + cArquivo)
        Else
            ConOut("[WSRESERVA] Erro ao criar arquivo: " + cArquivo + " - Erro: " + Str(FError()))
            Loop
        EndIf

        // Gerar proximo codigo de objeto
        nProxCod++
        cCodObj := StrZero(nProxCod, 10)

        // Inserir registro no ACB (Banco de Conhecimento)
        ACB->(dbSetOrder(1))
        If RecLock("ACB", .T.)
            ACB->ACB_FILIAL := cFil
            ACB->ACB_CODOBJ := cCodObj
            ACB->ACB_OBJETO := cNomeArq
            ACB->ACB_DESCRI := "Reserva " + AllTrim(cPedido) + " - " + cDesc
            MsUnlock()
            ConOut("[WSRESERVA] ACB criado: " + cCodObj + " - " + cNomeArq)
        EndIf

        // Inserir vinculo no AC9 (Vinculo Banco de Conhecimento -> Pedido de Venda)
        AC9->(dbSetOrder(1))
        If RecLock("AC9", .T.)
            AC9->AC9_FILIAL := cFil
            AC9->AC9_FILENT := cFil
            AC9->AC9_ENTIDA := cEntidade
            AC9->AC9_CODENT := cCodEnt
            AC9->AC9_CODOBJ := cCodObj
            MsUnlock()
            ConOut("[WSRESERVA] AC9 vinculo criado: " + cCodObj + " -> SC5/" + AllTrim(cPedido))
        EndIf
    Next

    ConOut("[WSRESERVA] " + Str(Len(aFotos)) + " foto(s) salvas no Banco de Conhecimento para pedido " + AllTrim(cPedido))
Return
