/*/{Protheus.doc} nomeFunction
   (long_description)
   @type  Function
   @author user
   @since 31/08/2021
   @version version
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see (links_or_references)

   ESTA ROTINA ESTA SENDO 
/*/
//U_TMATA265("01092021 ","001","2136  ","01")

#Include "PROTHEUS.CH"
#include "tbiconn.ch"
#include "topconn.ch"

//   ********* ENDEREÇAR UM ITEM *********
User Function TMATA265( cNF, cSerie, cCliFor, cLoja, cOrigem)

Local lReturn:=.T.
Local aCabSDA     := {}
Local aItSDB      := {}
Local _aItensSDB  := {} 

Local cQry:=""
LOCAL nItem:=1
Local cId:=""
Local cMsg:=""
Local aAReaSD1:=SD1->(GetArea())

Private	lMsErroAuto := .F.

IF FunName()="MATA265"  //EXECUTA SOBRE O REGISTRO QUE ESTIVER POSICIONADO
   cNf      :=SDA->DA_DOC
   cSerie   :=SDA->DA_SERIE
   cCliFor  :=SDA->DA_CLIFOR
   cLoja    :=SDA->DA_LOJA
   cOrigem  :="SD1"
ENDIF

cQry:="SELECT DA_PRODUTO, DA_NUMSEQ, DA_SALDO, DA_DATA  "+CRLF
cQry+="FROM "+RetSqlName("SDA")+" A "+CRLF
//DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA                                                                                       
cQry+="WHERE A.DA_FILIAL='"+xFilial("SDA") +"' AND A.DA_DOC='"+cNF+"' AND A.DA_SERIE='"+cSerie+"' AND A.DA_CLIFOR='"+cCliFor+"' AND A.DA_LOJA='"+cLoja+"' AND "
cQry+=" A.DA_SALDO > 0 AND "
cQry+=" A.D_E_L_E_T_=''"

DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMP",.F.,.T.) 

TcSetField("TMP","DA_SALDO","N",10)
TcSetField("TMP","DA_DATA","D",10)

DbGoTop()
IF TMP->(Eof())
   cMsg:="NADA A PROCESSAR" 
   lReturn:=.F.
ENDIF

DO WHILE .NOT. TMP->(Eof())
   
   //MATRIZ DA EXECAUTO
   _aItensSDB:={}

   //Cabeçalho com a informação do item e NumSeq que sera endereçado.
   aCabSDA := {{"DA_PRODUTO" ,TMP->DA_PRODUTO,Nil},;
               {"DA_NUMSEQ"  ,TMP->DA_NUMSEQ,Nil}}

   //Dados do item que será endereçado
   SD1->(DbSetOrder(4))
   SD1->(DbSeek(xFilial("SD1")+TMP->DA_NUMSEQ))
   IF .NOT. Empty(SD1->D1_XSERIAL) .AND. SD1->D1_QUANT==1
      cId:=SD1->D1_XSERIAL
   ELSE
      cId:=CalId()
   ENDIF
   RestArea(aAReaSD1)

   FOR nItem:=1 TO TMP->DA_SALDO

      aItSDB:={{"DB_ITEM"   ,StrZero(nItem,4),Nil},;
               {"DB_ESTORNO"  ," "        ,Nil},;
               {"DB_LOCALIZ"  ,"GERAL"    ,Nil},;
               {"DB_DATA"     ,dDataBase  ,Nil},;
               {"DB_QUANT"    ,1          ,Nil},;
               {"DB_NUMSERI"  ,cId   ,Nil}} 
            
      aadd(_aItensSDB,aitSDB)

      cId:=Soma1(cId)
   NEXT

   //Executa o endereçamento do item
   MSEXECAUTO({|cab,it| MATA265( cab, it ) }, aCabSDA, _aItensSDB, 3)

   If lMsErroAuto
      MostraErro()
      lReturn:=.F.
      cMsg:='Devido a ocorrencia exibida anteriormente, o processo sera encerrado. Após ANALISAR O ERRO EXECECUTE MANUALMENTE SERIALIZAÇÃO DA NF PELO PRG DE ENDEREÇAMENTO (MATA265)'
      EXIT
   Endif

   TMP->(DbSkip())

ENDDO

TMP->(DbCloseArea())

IF lReturn
   cMsg:="Seriais foram gerados para NF "+cNf+CRLF
   cQry:="SELECT DB_NUMSERI "
   cQry+="FROM "+RETSQLNAME("SDB")+" A " 
   cQry+="WHERE DB_FILIAL='"+xFilial("SDB")+"' AND "
   cQry+="DB_DOC='"+cNf+"' AND DB_SERIE='"+cSerie+"' AND DB_CLIFOR='"+cCliFor+"' AND DB_LOJA='"+cLoja+"' AND "
   cQry+="DB_ORIGEM='"+cOrigem+"' AND "
   cQry+="A.DB_ESTORNO<>'S' AND "
   cQry+="A.D_E_L_E_T_=''"

   DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TMP",.F.,.T.) 
   DO WHILE .NOT. TMP->(Eof())
      cMsg += TMP->DB_NUMSERI + CRLF
      TMP->(DbSkip())
   ENDDO
   TMP->(DbCloseArea())
ENDIF

//MsgAlert(cMsg)

Return cMsg


///////////////////////////
//verificar número do ID
/*
Static Function calID()

	Local cID
	Local cNum := "000000" //GetNewPar("CM_SERINI","00000000000000007000")

	//Adequação para a Max
	if cEmpAnt == "02"
		cNum := "000000" //GetNewPar("CM_SERINIM","M0000000000000000001")
	endif

	Beginsql Alias "TID"
      SELECT (cast( MIN(substring(DB_NUMSERI,2,5)) as int) + 1) IDNEXT
      FROM %Table:SDB% T
      WHERE T.%NotDel% and 
            substring(T.DB_NUMSERI,2,5) >= %Exp:substr(cNum,2,5)% and
            NOT EXISTS (
                  SELECT cast(substring(DB_NUMSERI,2,5) as int) DB_NUMSERI
                  FROM %Table:SDB% T1
                  WHERE T1.%NotDel% and
                     cast(substring(T1.DB_NUMSERI,2,5) as int) = (cast(substring(T.DB_NUMSERI,2,5) as int) + 1) and
                     substring(T1.DB_NUMSERI,2,5) >= %Exp:substr(cNum,2,5)%
            )
   EndSQL

	DbSelectArea("TID")
	DbGotop()

	if !eof()
		cID := IIF(cEmpAnt=='02','M','0') + alltrim(strzero( TID->IDNEXT, 5 ))
	else
		cID := IIF(cEmpAnt=='02','M','0') + alltrim(strzero( 1, 5 ))
	endif

	if val(substr(cID,2,6)) == 0
		cID := cNum
	endif

	if cEmpAnt == "02" //Tratamento para seriais da MAX
		if substr(cID,1,1) <> "M"
			cID := "M" + substr(cID,2,5)
		endif
	endif

	DbSelectArea("TID")
	TID->( DbCloseArea() )

return(cID)
*/
///////////////////////////
//verificar número do ID
Static Function calID()

	Local cID  := "000001"
	Local cNum := "000000" //GetNewPar("CM_SERINI","00000000000000007000")
   
   //NAO ESTA CONSIDERANDO/TESTANDO OS ESTORNADOS.
	Beginsql Alias "TID"
      SELECT (cast( MIN(substring(DB_NUMSERI,1,6)) as int) + 1) IDNEXT
      FROM %Table:SDB% T
      WHERE T.%NotDel% and 
            substring(T.DB_NUMSERI,1,6) >= %Exp:substr(cNum,1,6)% and
            NOT EXISTS (
                  SELECT cast(substring(DB_NUMSERI,1,6) as int) DB_NUMSERI
                  FROM %Table:SDB% T1
                  WHERE T1.%NotDel% and
                     cast(substring(T1.DB_NUMSERI,1,6) as int) = (cast(substring(T.DB_NUMSERI,1,6) as int) + 1) and
                     substring(T1.DB_NUMSERI,1,6) >= %Exp:substr(cNum,1,6)%
            )
   EndSQL

	DbSelectArea("TID")
	DbGotop()

	if !eof()
		cID := alltrim(strzero( TID->IDNEXT, 6 ))
	endif

	if val(substr(cID,2,6)) == 0
		cID := cNum
	endif

	DbSelectArea("TID")
	TID->( DbCloseArea() )

return(cID)


