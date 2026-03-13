#include "protheus.ch"
#include "rwmake.ch"

User Function MsgNFEntr()

	//Local aArea 	:= GetArea()
	//Local lRet		:= .T.
	//Local cFilPesq 	:= SF1->F1_FILIAL
	//Local cNota		:= SF1->F1_DOC
	//Local cSerie	:= SF1->F1_SERIE
	//Local cCliente	:= SF1->F1_FORNECE
	//Local cLojaCli	:= SF1->F1_LOJA
	//Local cNomeCli	:= Posicione("SA1",1,xFilial("SA1")+SF1->F1_FORNECE+SF1->F1_LOJA,"A1_NREDUZ")	//Space(TamSX3("A1_NOME")[1])
	//Local aCabec 	:= {}
	//Local aItens 	:= {}
	//Local nItem 	:= 0

	//Local cTesPed 	:= SuperGetMV("MV_TESPED", ,"") //501
//Local cTesUDev 	:= SuperGetMV("MV_TESUDEV", ,"")//011
//Local cTesConv	:= SuperGetMV("MV_TESCONV", ,"")//011
//Local cTesDvCn	:= SuperGetMV("MV_TESDVCN", ,"")//502

	Local lExclui 	:= (!INCLUI .and. !ALTERA)
	//Local cPedido   := "" //GetSxeNum("SC5","C5_NUM")
	Local cDados1   := Space(080)
	Local cDados2   := Space(080)
	Local cDados3   := Space(080)
	Local cDados4	:= Space(080)
	Local cDados5	:= Space(080)

	//Local oDlg2
	//Local lFatRes	:= .F.
	Local nPosNFORI	:= aScan( aHeader, {|x| Alltrim(x[2]) == "D1_NFORI"		} )
	//Local nPosSEORI	:= aScan( aHeader, {|x| Alltrim(x[2]) == "D1_SERIORI"	} )

	//Local cVendX1 	:= "000001"
	//Local cVendX2 	:= "" // Retirado dia 28-12-2020
	//Local nX
	//Local CR		:= chr(13) + chr(10)
	//Local aVetor1   := {}
	//Local aVetor2   := {}
	//Local cQuery	:= ""
	//Local lEst		:= .F.
	//local lFin		:= .F.

	Private cCodeConv	:= Space( TamSX3("F1_FORNECE")	[1] )
	Private cLojaConv 	:= Space( TamSX3("F1_LOJA")		[1] )
	Private cNomeConv	:= Space( TamSX3("A1_NOME")		[1] )

	Private lMsErroAuto := .F.
	Private lMsHelpAuto	:= .T.

// Alterado por Fabio Jadao Caires
// 14/05/2013
// Tratamento para faturamento de consignado em hospitais da reserva de poder de terceiros

// Alterado por: Antonio Carlos

   If !IsBlind() .or. ("CM02RET" $ upper(procname(14)) .or. "MONTANF" $ upper(procname(7)) ) //verificando se a execução é originada do Controle de IDs
      If .not. lExclui
         cDados1 += "NF orig.: "+Alltrim(aCols[1][nPosNFORI]) //+"/"+Alltrim(aCols[1][nPosSEORI]) // Sai a Serie a pedido de Erivan
         cDados1 := UPPER(Alltrim(cDados1))+Space(80-Len(Alltrim(cDados1)))
         @ 001,001 To 190,500 Dialog oDlg Title "Mensagem para Nota Fiscal: "+Alltrim(SF1->F1_DOC)+"/"+Alltrim(SF1->F1_SERIE)
         //@ 0.4,0.6 To 5.6,24.5
         @ 1.3,1.5 Say "Mensagem1: " SIZE 040,013
         @ 1.1,35  Get cDados1 PICTURE "@!" SIZE 200,013

         @ 16.5,1.5 Say "Mensagem2: " SIZE 040,013
         @ 16.3,35  Get cDados2 PICTURE "@!" SIZE 200,013

         @ 31.7,1.5 Say "Mensagem3: " SIZE 040,013
         @ 31.5,35  Get cDados3 PICTURE "@!" SIZE 200,013

         @ 46.9,1.5 Say "Mensagem4: " SIZE 040,013
         @ 46.7,35  Get cDados4 PICTURE "@!" SIZE 200,013

         @ 61.1,1.5 Say "Mensagem5: " SIZE 040,013
         @ 61.9,35  Get cDados5 PICTURE "@!" SIZE 200,013

         @ 079,088 BMPBUTTON TYPE 01 ACTION Close(oDlg)

         Activate Dialog oDlg Centered

         If !Empty(cDados1) .or. !Empty(cDados2) .or. !Empty(cDados3) .or. !Empty(cDados4) .or. !Empty(cDados5)
            dbSelectArea("SF1")
            RecLock("SF1",.F.)
            SF1->F1_MSG1 	:= Alltrim(cDados1)
            SF1->F1_MSG2 	:= Alltrim(cDados2)
            SF1->F1_MSG3 	:= Alltrim(cDados3)
            SF1->F1_MSG4 	:= Alltrim(cDados4)
            SF1->F1_MSG5 	:= Alltrim(cDados5)
            MsUnlock()
         Endif
      ENDIF
   EndIf

RETURN
