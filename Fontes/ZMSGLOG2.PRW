#include "PROTHEUS.CH"

////////////////////////////////////////
//Tela de mensagem - com salvamento
User Function zMsgLog2(cMsg, cTitulo, nTipo, lEdit)
	Local lRetMens := .F.
	Local oDlgMens
	Local oBtnOk, cTxtConf := ""
	Local oBtnCnc, cTxtCancel := ""
	Local oBtnSlv
	Local oFntTxt := TFont():New("Lucida Console",,-015,,.F.,,,,,.F.,.F.)
	Local oMsg
	//Local nIni:=1 // Retirado dia 27-12-2020 por Thiago Rocco
	//Local nFim:=50 // Retirado dia 27-12-2020 por Thiago Rocco
	//Default cMsg    := "..."
	Default cTitulo := "zMsgLog"
	Default nTipo   := 1 // 1=Ok; 2= Confirmar e Cancelar
	Default lEdit   := .F.
	//Definindo os textos dos botões
	If(nTipo == 1)
		cTxtConf:='&Ok'
	Else
		cTxtConf:='&Confirmar'
		cTxtCancel:='C&ancelar'
	EndIf
	//Criando a janela centralizada com os botões
	DEFINE MSDIALOG oDlgMens TITLE cTitulo FROM 000, 000  TO 300, 400 COLORS 0, 16777215 PIXEL
	//Get com o Log
	@ 002, 004 GET oMsg VAR cMsg OF oDlgMens MULTILINE SIZE 191, 121 FONT oFntTxt COLORS 0, 16777215 HSCROLL PIXEL
	If !lEdit
		oMsg:lReadOnly := .T.
	EndIf
	//Se for Tipo 1, cria somente o botão OK
	If (nTipo==1)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
		//Senão, cria os botões OK e Cancelar
	ElseIf(nTipo==2)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 009 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
		@ 137, 144 BUTTON oBtnCnc PROMPT cTxtCancel SIZE 051, 009 ACTION (lRetMens:=.F., oDlgMens:End()) OF oDlgMens PIXEL
	EndIf
	//Botão de Salvar em Txt
	@ 127, 004 BUTTON oBtnSlv PROMPT "&Salvar em .txt" SIZE 051, 019 ACTION (fSalvArq(cMsg, cTitulo)) OF oDlgMens PIXEL
	ACTIVATE MSDIALOG oDlgMens CENTERED
Return lRetMens
/*-----------------------------------------------*
| Função: fSalvArq                              |
| Descr.: Função para gerar um arquivo texto    |
*-----------------------------------------------*/
Static Function fSalvArq(cMsg, cTitulo)
	Local cFileNom :='\x_arq_'+dToS(Date())+StrTran(Time(),":")+".txt"
	Local cQuebra  := chr(13)+chr(10) + "+=======================================================================+" + chr(13)+chr(10)
	Local lOk      := .T.
	Local cTexto   := ""
	//Pegando o caminho do arquivo
	cFileNom := cGetFile( "Arquivo TXT *.txt | *.txt", "Arquivo .txt...",,'',.T., GETF_LOCALHARD)
	//Se o nome não estiver em branco    
	If !Empty(cFileNom)
		//Teste de existência do diretório
		If ! ExistDir(SubStr(cFileNom,1,RAt('\',cFileNom)))
			Alert("Diretório não existe:" + chr(13)+chr(10) + SubStr(cFileNom, 1, RAt('\',cFileNom)) + "!")
			Return
		EndIf
		//Montando a mensagem
		cTexto := "Função   - "+ FunName()       + chr(13)+chr(10)
		cTexto += "Usuário  - "+ cUserName       + chr(13)+chr(10)
		cTexto += "Data     - "+ dToC(dDataBase) + chr(13)+chr(10)
		cTexto += "Hora     - "+ Time()          + chr(13)+chr(10)
		cTexto += "Mensagem - "+ cTitulo + cQuebra  + cMsg + cQuebra
		//Testando se o arquivo já existe
		If File(cFileNom)
			lOk := MsgYesNo("Arquivo já existe, deseja substituir?", "Atenção")
		EndIf
		If lOk
			MemoWrite(cFileNom, cTexto)
			MsgInfo("Arquivo Gerado com Sucesso:"+chr(13)+chr(10)+cFileNom,"Atenção")
		EndIf
	EndIf
Return()
