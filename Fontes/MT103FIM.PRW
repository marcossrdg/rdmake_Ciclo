#INCLUDE "PROTHEUS.CH"

User Function MT103FIM()

Local cAlias:="SF1"  //PARAMIXB[1]
Local nOpcao := PARAMIXB[1] 
Local nConfirma := PARAMIXB[2]
Local cAllId:=""
/*
Local nExec:=1

//MsgGet2( "Indique o numero correto para a tabela:" + calias, "Campo: "+cCposx8, @cNum, , , )
nEXec:=Aviso("Executando: "+FUNNAME()+"- MT103FIM",;
"Origem :"+Funname() + " - "+ProcName(1)+" / "+ProcName(2)+CRLF+CRLF+;
"Parametros recebidos: "+CRLF+;
"nOpcao    : "+trim(str(nOpcao))+CRLF+;
"nConfirma : "+trim(str(nConfirma))+CRLF+CRLF+;
"Executar? ",;
{"SIM","NAO"},;
3;
)
*/
//Preencher campos de observação para nota de entrada
u_MsgNFEntr()

// fazer o tratamento aqui para a numeracao	
IF (nConfirma==1 .AND. (nOpcao==3 .OR. nOpcao==4)) //.OR. nExec==1
   cAllId:=u_TMATA265( (cAlias)->F1_DOC, (cAlias)->F1_SERIE, (cAlias)->F1_FORNECE, (cAlias)->F1_LOJA, "SD1" )
   
   u_zMsgLog2(cAllID, "Serial(is) Inseridos",1,.F.) // + IIF(cModo == "D", "Excluido(s)", "Inserido(s)"), 1, .F.)
ENDIF

Return 


