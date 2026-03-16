#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} DOCRESERVA
    Funcao para anexar e visualizar documentos de reserva (pedido de venda prefixo R).
    Salva arquivos na pasta \docs_reserva\{pedido}\ no servidor e registra na ZZ1010.
    Pode ser chamada via botao no browse do MATA461 ou diretamente.
    @type  User Function
    @author Antonio
    @since 16/03/2026
    @version 1.0
/*/
User Function DOCRESERVA()
    Local aArea    := GetArea()
    Local cPedido  := SC5->C5_NUM
    Local cFil     := SC5->C5_FILIAL
    Local cPasta   := "\docs_reserv\" + AllTrim(cPedido) + "\"
    Local cVend    := SC5->C5_VEND1
    Local aArquivos := {}
    Local aCols    := {}
    Local aItems   := {}
    Local oDlg, oList, oBtnAdd, oBtnVer, oBtnDel
    Local nSel     := 0
    Local nI       := 0

    // Criar pasta se nao existe
    If !ExistDir("\docs_reserv\")
        MakeDir("\docs_reserv\")
    EndIf
    If !ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf

    // Listar arquivos existentes na pasta
    aArquivos := Directory(cPasta + "*.*")

    // Montar lista
    aItems := {}
    For nI := 1 To Len(aArquivos)
        aAdd(aItems, aArquivos[nI][1] + " (" + AllTrim(Str(Int(aArquivos[nI][2]/1024))) + " KB)")
    Next

    // Dialog
    DEFINE MSDIALOG oDlg TITLE "Documentos da Reserva " + AllTrim(cPedido) FROM 0,0 TO 400,600 PIXEL

    @ 010,010 SAY "Pasta: " + cPasta SIZE 280,010 OF oDlg PIXEL
    @ 025,010 SAY "Arquivos: " + AllTrim(Str(Len(aItems))) SIZE 280,010 OF oDlg PIXEL

    @ 040,010 LISTBOX oList VAR nSel ITEMS aItems SIZE 280,120 OF oDlg PIXEL

    @ 170,010 BUTTON oBtnAdd PROMPT "Anexar Documento..." SIZE 090,016 OF oDlg PIXEL ;
        ACTION (fAnexarDoc(cPasta, cPedido, cFil, cVend, aItems, oList))

    @ 170,105 BUTTON oBtnVer PROMPT "Visualizar" SIZE 080,016 OF oDlg PIXEL ;
        ACTION (fVisualizarDoc(cPasta, aArquivos, nSel))

    @ 170,190 BUTTON oBtnDel PROMPT "Fechar" SIZE 080,016 OF oDlg PIXEL ;
        ACTION (oDlg:End())

    ACTIVATE MSDIALOG oDlg CENTERED

    RestArea(aArea)
Return

//=====================================================================
// fAnexarDoc - Abre dialogo para selecionar arquivo e copia pro servidor
//=====================================================================
Static Function fAnexarDoc(cPasta, cPedido, cFil, cVend, aItems, oList)
    Local cArqLocal := ""
    Local cNomeArq  := ""
    Local cArqDest  := ""
    Local cExt      := ""
    Local cSeq      := ""
    Local cSQL      := ""
    Local nProxSeq  := 0

    // Dialogo para selecionar arquivo
    cArqLocal := cGetFile("Imagens|*.jpg;*.jpeg;*.png;*.bmp;*.pdf|Todos|*.*", "Selecione o documento", , , .F., , .T.)

    If Empty(cArqLocal)
        Return
    EndIf

    // Pegar extensao
    cExt := Lower(SubStr(cArqLocal, RAt(".", cArqLocal)))

    // Proximo sequencial
    nProxSeq := Len(Directory(cPasta + "*.*")) + 1
    cSeq := StrZero(nProxSeq, 3)
    cNomeArq := "DOC_" + cSeq + cExt
    cArqDest := cPasta + cNomeArq

    // Copiar arquivo para o servidor
    If __CopyFile(cArqLocal, cArqDest)
        ConOut("[DOCRESERVA] Arquivo copiado: " + cArqDest)

        // Registrar na ZZ1010
        cSQL := "INSERT INTO ZZ1010 (ZZ1_FILIAL, ZZ1_PEDIDO, ZZ1_SEQ, ZZ1_DESC, ZZ1_DATA, ZZ1_HORA, ZZ1_VEND, ZZ1_IMAGEM) "
        cSQL += "VALUES ('" + cFil + "', '" + cPedido + "', '" + cSeq + "', '" + cNomeArq + "', '" + DtoS(Date()) + "', '" + SubStr(Time(),1,5) + "', '" + cVend + "', '" + cArqDest + "')"
        TCSqlExec(cSQL)

        // Atualizar lista
        aAdd(aItems, cNomeArq + " (novo)")
        oList:Refresh()

        MsgInfo("Documento anexado com sucesso!" + Chr(13) + Chr(10) + cNomeArq, "Sucesso")
    Else
        MsgStop("Erro ao copiar arquivo para o servidor.", "Erro")
    EndIf

Return

//=====================================================================
// fVisualizarDoc - Abre o arquivo selecionado
//=====================================================================
Static Function fVisualizarDoc(cPasta, aArquivos, nSel)
    Local cArqServ := ""
    Local cArqTemp := ""

    If nSel < 1 .Or. nSel > Len(aArquivos)
        MsgAlert("Selecione um arquivo na lista.", "Aviso")
        Return
    EndIf

    cArqServ := cPasta + aArquivos[nSel][1]

    // Copiar do servidor para pasta temporaria local
    cArqTemp := GetTempPath() + aArquivos[nSel][1]

    If __CopyFile(cArqServ, cArqTemp)
        ShellExecute("open", cArqTemp, "", "", 1)
    Else
        MsgStop("Erro ao abrir arquivo.", "Erro")
    EndIf

Return
