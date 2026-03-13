#include "protheus.ch"
#include "topconn.ch"

USER FUNCTION PE01NFESEFAZ()

Local aProd		:= PARAMIXB[1]
Local cMensCli	:= PARAMIXB[2]
Local cMensFis	:= PARAMIXB[3]
Local aDest		:= PARAMIXB[4]
Local aNota   	:= PARAMIXB[5]
Local aInfoItem	:= PARAMIXB[6]
Local aDupl		:= PARAMIXB[7]
Local aTransp	:= PARAMIXB[8]
Local aEntrega	:= PARAMIXB[9]
Local aRetirada	:= PARAMIXB[10]
Local aVeiculo	:= PARAMIXB[11]
Local aReboque	:= PARAMIXB[12]
Local aNfVincRur:= PARAMIXB[13]
Local aEspVol   := PARAMIXB[14]		// Alterado por Wagner - 09/01/18
Local aNfVinc	:= PARAMIXB[15]		// Alterado por Wagner - 09/01/18
Local aDetPag	:= PARAMIXB[16]		// Alterado por Wagner - 30/07/18 - NFE 4
Local aObsCont	:= PARAMIXB[17]		// Alterado por Wagner - 30/07/18 - NFE 4

Local cTipo		:= aNota[4]		// Alterado por Wagner - 08/12/15

Local aArea		:= GetArea()
Local aRetorno	:= {}
//Local cMsg		:= ""
Local cDescProd := ""
Local cSUS		:= ""
//Local cLote		:= ""
//Local dDtValid	:= Ctod("")
Local cSeekSD2	:= ""
Local cSeekSD1	:= ""
Local nx		:= 0
Local cID		:= ""

IF cTipo == '1'
	msgResolu55( aInfoItem[1,1], @cMensCli )
	msgMedPaci( aInfoItem[1,1], @cMensCli )
ENDIF

For nx := 1 to len(aProd)
	
	cDescProd := ""
	If cTipo == "1"


		SB1->(DbSeek( xFilial("SB1")+aProd[nx][2] ))
		aProd[nX,25]+=InfAnvisa()
		
		SD2->(dbSetOrder(3))
		SD2->( MsSeek( cSeekSD2 := xFilial('SD2') + SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA), .F. ) )
		While SD2->(!Eof()) .And. cSeekSD2 == SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA)

			If Empty(cDescProd)
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Atualiza descrição do produto com a informação do SUS. ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				cSUS := SB1->B1_SUS //Posicione("SB1",1,xFilial("SB1")+aProd[nx][2],"B1_SUS")
				SC5->(dbSetOrder(1))
				SC5->(MsSeek(xFilial("SC5")+SD2->D2_PEDIDO))
				If SC5->C5_VD_SUS .And. !Empty( cSUS )// Indica se e venda SUS
					cDescProd := " Cod. SUS: "+cSUS  // COD.SUS
				EndIf
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Atualiza descrição do produto com a informação do Lote ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If aProd[nx][2] = SD2->D2_COD .And. aProd[nx][19] = SD2->D2_LOTECTL
					
					If !Empty(SD2->D2_LOTECTL) .And. !Empty(SD2->D2_DTVALID)
						If !Empty(SD2->D2_NUMLOTE)
							cDescProd += " LOTE: "+AllTrim(StrTran(SD2->(D2_LOTECTL+D2_NUMLOTE),"/",""))+" ("+ Alltrim(StrTran(Dtoc(SD2->D2_DTVALID),"/","-"))+")" // Inf. do Lote
						Else
							cDescProd += " LOTE: "+AllTrim(StrTran(SD2->D2_LOTECTL,"/",""))+" ("+Alltrim(StrTran(Dtoc(SD2->D2_DTVALID),"/","-"))+")" // Inf. do Lote
						EndIf
					EndIf
				EndIf
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza mensagem do cliente / fornecedor              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SF4->(dbSetOrder(1))
			If SF4->(dbSeeK(xFilial("SF4")+SD2->D2_TES))
				
				If !Empty(SF4->F4_FORMULA) .And. !AllTrim(FORMULA(SF4->F4_FORMULA)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_FORMULA))
				EndIf
				
				If !Empty(SF4->F4_MSG01) .And. !AllTrim(FORMULA(SF4->F4_MSG01)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG01))
				EndIf
				
				If !Empty(SF4->F4_MSG02) .And. !AllTrim(FORMULA(SF4->F4_MSG02)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG02))
				EndIf
				
				If !Empty(SF4->F4_MSG03) .And. !AllTrim(FORMULA(SF4->F4_MSG03)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG03))
				EndIf
			EndIf
			
			SD2->(dbSkip())
		EndDo
		
	Else
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza descrição do produto com a informação do Lote ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SD1->(dbSetOrder(1))
		SD1->( MsSeek( cSeekSD1 := xFilial('SD1') + SF1->(F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA), .F. ) )
		While SD1->(!Eof()) .And. cSeekSD1 == SD1->(D1_FILIAL+D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA)
			
			If Empty(cDescProd)
				If aProd[nx][2] = SD1->D1_COD .And. aProd[nx][19] = SD1->D1_LOTECTL
					
					If !Empty(SD1->D1_LOTECTL) .And. !Empty(SD1->D1_DTVALID)
						//If !Empty(SD1->D1_NUMLOTE)
						//	cDescProd := "Lote: "+AllTrim(StrTran(SD1->(D1_LOTECTL + D1_NUMLOTE),"/","")) + " (" + StrTran(Dtoc(StoD(SD1->D1_DTVALID)),"/","-")+ ")" // Inf. do Lote
						//Else
						//	cDescProd := "Lote: "+AllTrim(StrTran(SD1->D1_LOTECTL,"/","")) + " (" + StrTran(Dtoc(StoD(SD1->D1_DTVALID)),"/","-") + ")" // Inf. do Lote
						//EndIf
						
						If !Empty(SD1->D1_NUMLOTE)
							cDescProd += " LOTE: "+AllTrim(StrTran(SD1->(D1_LOTECTL+D1_NUMLOTE),"/",""))+" ("+ Alltrim(StrTran(Dtoc(SD1->D1_DTVALID),"/","-"))+")" // Inf. do Lote
						Else
							cDescProd += " LOTE: "+AllTrim(StrTran(SD1->D1_LOTECTL,"/",""))+" ("+Alltrim(StrTran(Dtoc(SD1->D1_DTVALID),"/","-"))+")" // Inf. do Lote
						EndIf
						
					EndIf
				EndIf
			EndIf
			
			If !Empty(SF1->F1_MSG1) .And. !AllTrim(SF1->F1_MSG1) $ cMensCli
				//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
				//	cMensCli += " () "
				//EndIf
				cMensCli += AllTrim(SF1->F1_MSG1)
			EndIf
			If !Empty(SF1->F1_MSG2) .And. !AllTrim(SF1->F1_MSG2) $ cMensCli
				//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
				//	cMensCli += " () "
				//EndIf
				cMensCli += AllTrim(SF1->F1_MSG2)
			EndIf
			If !Empty(SF1->F1_MSG3) .And. !AllTrim(SF1->F1_MSG3) $ cMensCli
				//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
				//	cMensCli += " () "
				//EndIf
				cMensCli += AllTrim(SF1->F1_MSG3)
			EndIf
			If !Empty(SF1->F1_MSG4) .And. !AllTrim(SF1->F1_MSG4) $ cMensCli
				//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
				//	cMensCli += " () "
				//EndIf
				cMensCli += AllTrim(SF1->F1_MSG4)
			EndIf
			If !Empty(SF1->F1_MSG5) .And. !AllTrim(SF1->F1_MSG5) $ cMensCli
				//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
				//	cMensCli += " () "
				//EndIf
				cMensCli += AllTrim(SF1->F1_MSG5)
			EndIf
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza mensagem do cliente / fornecedor              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SF4->(dbSetOrder(1))
			If SF4->(dbSeeK(xFilial("SF4")+SD1->D1_TES))
				
				If !Empty(SF4->F4_FORMULA) .And. !AllTrim(FORMULA(SF4->F4_FORMULA)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_FORMULA))
				EndIf
				
				If !Empty(SF4->F4_MSG01) .And. !AllTrim(FORMULA(SF4->F4_MSG01)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG01))
				EndIf
				
				If !Empty(SF4->F4_MSG02) .And. !AllTrim(FORMULA(SF4->F4_MSG02)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG02))
				EndIf
				
				If !Empty(SF4->F4_MSG03) .And. !AllTrim(FORMULA(SF4->F4_MSG03)) $ cMensCli
					//If Len(cMensCli) > 0 .And. SubStr(cMensCli, Len(cMensCli), 1) <> "()"
					//	cMensCli += " () "
					//EndIf
					cMensCli += AllTrim(FORMULA(SF4->F4_MSG03))
				EndIf
			EndIf
			
			SD1->(dbSkip())
		EndDo
		
	EndIf
	
	///////////////////////////////////////////////////////////////
	//Alteração referente ao projeto seriais
	//Inclusão dos Seriais na Descrição dos itens
	//Connit - Alexandre Carvalho - 11/02/2018
	cID:= ""
	cIDM := ""
	
	if GETNEWPAR("CM_LSERIAB",.F.) //.and. ( substr(SA1->A1_CGC,1,8) <> substr(SM0->M0_CGC,1,8) )
		
		if cTipo == "1"  //NF Saida
			SD2->(dbSetOrder(3))
			SD2->( MsSeek( cSeekSD2 := xFilial('SD2') + SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA) + aProd[nx][2], .F. ) )
		else	//NF Entrada
			SD1->(dbSetOrder(1))
			SD1->( MsSeek( cSeekSD1 := xFilial('SD1') + SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) + aProd[nx][2], .F. ) )
		endif
		
		//Percorrendo todos os itens
		While IIF(cTipo == "1", ;
			SD2->(!Eof()) .And. cSeekSD2 == SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA + D2_COD),;
			SD1->(!Eof()) .And. cSeekSD1 == SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA + D1_COD))
			
			//Se for o mesmo Lote e item
			if IIF(cTipo == "1", ;
				alltrim(SD2->D2_LOTECTL) == alltrim(aProd[nx][19]) .and. val(SD2->D2_ITEM) == aProd[nx][01], ;
				alltrim(SD1->D1_LOTECTL) == alltrim(aProd[nx][19]) .and. val(SD1->D1_ITEM) == aProd[nx][01] )
				
				//Verificando liberação
				DbSelectArea("Z09")
				DbSetOrder(2) //Pedido + Item
				DbGoTop()
				if cTipo == "1"
					DbSeek(xFilial("Z09") + Alltrim( SD2->(D2_PEDIDO+D2_ITEMPV) ) )
				endif

				//Saida				
				if cTipo == "1" .and. Z09->( found() )
					
					cID := ""
					
					//Percorrendo todos registros de Separação
					While !eof() .and. Z09->Z09_PEDIDO == SD2->D2_PEDIDO .and. Z09->Z09_ITEMPV == SD2->D2_ITEMPV
						
						DbSelectArea("Z07")
						DbSetOrder(1)
						DbGoTop()
						DbSeek( xFilial("Z07") + Z09->Z09_ID )
						
						//Verificando se é a última saída
						if found() .and. alltrim(Z07->Z07_PROD) == alltrim(SD2->D2_COD) .and. ;
							alltrim(Z07->Z07_LOTE) == alltrim(SD2->D2_LOTECTL) .and. ;
							alltrim(Z07->Z07_PROD) == alltrim(aProd[nx][2]) .and. ;
							alltrim(Z07->Z07_LOTE) == alltrim(aProd[nx][19]) .and. ;
							!( "NOID" $ Z09->Z09_ID ) .and. ;
							!(alltrim(str(val( IIF(cEmpAnt=="02",substr(Z09->Z09_ID,2,19),Z09->Z09_ID) ))) $ cIDM)
							
							//Acumulando ID do Item
							cID += alltrim(str(val( IIF(cEmpAnt=="02",substr(Z09->Z09_ID,2,19),Z09->Z09_ID) ))) + " / "
							//Acumulando todos os ID da NF
							cIDM += alltrim(str(val( IIF(cEmpAnt=="02",substr(Z09->Z09_ID,2,19),Z09->Z09_ID) ))) + " / "

							if !(Z07->Z07_STATUS $ "A|O|C|V")
								SF4->( DbSetOrder(1) )
								SF4->( DbSeek( xFilial("SF4") + SD2->D2_TES ) )
								DbSelectArea("Z07")
								RecLock("Z07", .F.)
									if ( substr( SA1->A1_COD ,1,8) == substr(SM0->M0_CGC,1,8) )
										Z07->Z07_STATUS := "O"
									else
										Z07->Z07_STATUS := IIF( SF4->F4_PODER3=="R", "C", "V")
									endif
								Z07->( MsUnLock() )
							endif

						endif
						
						Z09->( DbSkip() )
					end
					
				else
					
					//Localizando o histórico do ID
					DbSelectArea("Z08")
					DbSetOrder(2) //NF + Cliente/Fornecedor
					DbGoTop()
					DbSeek(xFilial("Z08") + IIF(cTipo == "1", ;
					Alltrim( SD2->(D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) ) ,;
					Alltrim( SD1->(D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) ) ) )
					
					if found()
						
						cID := ""
						
						//Percorrendo todo o histórico
						While Z08->( !eof() ) .and. IIF(cTipo == "1", ;
							Z08->Z08_NF == SD2->(D2_DOC+D2_SERIE), ;
							Z08->Z08_NF == SD1->(D1_DOC+D1_SERIE) )
							
							DbSelectArea("Z07")
							DbSetOrder(1)
							DbGoTop()
							DbSeek( xFilial("Z07") + Z08->Z08_ID )
							
							//Verificando se é a última Saída
							if found() .and. alltrim(Z07->Z07_PROD) == alltrim(IIF(cTipo=="1", SD2->D2_COD, SD1->D1_COD)) .and. ;
								alltrim(Z07->Z07_LOTE) == alltrim(IIF(cTipo=="1", SD2->D2_LOTECTL, SD1->D1_LOTECTL)) .and.;
								alltrim(Z07->Z07_PROD) == alltrim(aProd[nx][02]) .and.;
								alltrim(Z07->Z07_LOTE) == alltrim(aProd[nx][19]) .and.;
								IIF(cTipo == "1", Z08->Z08_TIPO == 'S', Z08->Z08_TIPO == 'D') .and. ;
								!(alltrim(str(val( IIF(cEmpAnt=="02",substr(Z08->Z08_ID,2,19),Z08->Z08_ID) ))) $ cIDM)
								
								//Acumulando ID do Item
								cID += alltrim(str(val( IIF(cEmpAnt=="02",substr(Z08->Z08_ID,2,19),Z08->Z08_ID) ))) + " / "
								//Acumulando todos os ID da NF
								cIDM += alltrim(str(val( IIF(cEmpAnt=="02",substr(Z08->Z08_ID,2,19),Z08->Z08_ID) ))) + " / "

								if !(Z07->Z07_STATUS $ IIF(cTipo == "1", "A|O|C|V", "O|A") )
									SF4->( DbSetOrder(1) )
									SF4->( DbSeek( xFilial("SF4") + IIF(cTipo == "1", SD2->D2_TES, SD1->D1_TES) ) )
									DbSelectArea("Z07")
									RecLock("Z07", .F.)
										if ( substr(IIF(cTipo == "1", A1->A1_COD, SA2->A2_CGC),1,8) == substr(SM0->M0_CGC,1,8) )
											Z07->Z07_STATUS := IIF(cTipo == "1", "O", "A")
										else
											Z07->Z07_STATUS := IIF(cTipo == "1", IIF(SF4->F4_PODER3=="R", "C", "V"), "A" )
										endif
									Z07->( MsUnLock() )
								endif

							endif
							
							Z08->( DbSkip() )
							
						end
						
					endif
				endif
			endif
			
			if cTipo == "1" //Venda
				DbSelectArea("SD2")
				SD2->(dbSkip())
			else //Entrada
				DbSelectArea("SD1")
				SD1->(dbSkip())
			endif
			
		EndDo
		
	endif
	
	///////////////////////////////////////////////////////
	//Atualiza descrição na matriz
	aProd[nx][04] += cDescProd
	aProd[nx][25] += IIF(!empty(cID), "Serial(is): " + substr(cID, 1, len(cID)-3), "") // infAdProd - Usado essa tag por causa da limitação da descrição
	cID := ""
	
Next nx

For nx := 1 to len(aDest)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza codigo do cliente / fornecedor no nome        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nx = 2
		If cTipo == "1"
			If SF2->F2_TIPO $ "DB"
				aDest[nx] := AllTrim(SA2->A2_NOME)+" (Codigo: "+AllTrim(SA2->A2_COD)+")"
			Else
				aDest[nx] := AllTrim(SA1->A1_NOME)+" (Codigo: "+AllTrim(SA1->A1_COD)+")"
			EndIf
		Else
			If SF1->F1_TIPO $ "DB"
				aDest[nx] := AllTrim(SA1->A1_NOME)+" (Codigo: "+AllTrim(SA1->A1_COD)+")"
			Else
				aDest[nx] := AllTrim(SA2->A2_NOME)+" (Codigo: "+AllTrim(SA2->A2_COD)+")"
			EndIf
		Endif
	EndIf
Next nx

//O retorno deve ser exatamente nesta ordem e passando o conteúdo completo dos arrays
//pois no rdmake nfesefaz é atribuido o retorno completo para as respectivas variáveis
//Ordem:
//		aRetorno[1] -> aProd
//		aRetorno[2] -> cMensCli
//		aRetorno[3] -> cMensFis
//		aRetorno[4] -> aDest
//		aRetorno[5] -> aNota
//		aRetorno[6] -> aInfoItem
//		aRetorno[7] -> aDupl
//		aRetorno[8] -> aTransp
//		aRetorno[9] -> aEntrega
//		aRetorno[10] -> aRetirada
//		aRetorno[11] -> aVeiculo
//		aRetorno[12] -> aReboque
//		aRetorno[13] -> aNfVincRur
//		aRetorno[14] -> aEspVol   	// Alterado por Wagner - 09/01/18
//		aRetorno[15] -> aNfVinc		// Alterado por Wagner - 09/01/18

aadd(aRetorno,aProd)
aadd(aRetorno,cMensCli)
aadd(aRetorno,cMensFis)
aadd(aRetorno,aDest)
aadd(aRetorno,aNota)
aadd(aRetorno,aInfoItem)
aadd(aRetorno,aDupl)
aadd(aRetorno,aTransp)
aadd(aRetorno,aEntrega)
aadd(aRetorno,aRetirada)
aadd(aRetorno,aVeiculo)
aadd(aRetorno,aReboque)
aadd(aRetorno,aNfVincRur)
aadd(aRetorno,aEspVol)		// Alterado por Wagner - 09/01/18
aadd(aRetorno,aNfVinc)		// Alterado por Wagner - 09/01/18

If ValType(aDetPag) <> "U"	// Alterado por Wagner - 30/07/18 - NFE 4
	aadd(aRetorno,aDetPag)
EndIf

If ValType(aObsCont) <> "U"	// Alterado por Wagner - 30/07/18 - NFE 4
	aadd(aRetorno,aObsCont)
EndIf

RestArea(aArea)

Return(aRetorno)


STATIC FUNCTION msgResolu55(cNPedVen, cMensCli)
LOCAL cMsgCli:=""
LOCAL cMensag:=""
LOCAL cQuery :=""
LOCAL a:=0
LOCAL b:=0
LOCAL z:=0

//Thiago Rocco - 01-07-2020
//Inclusão da MSG da NF para Resolução 55 de 17 de Junho
cQuery := " SELECT B1_POSIPI FROM SB1010 B1 "
cQuery += " INNER JOIN SC6010 C6 ON B1.B1_COD = C6.C6_PRODUTO AND C6.D_E_L_E_T_<>'*' "
cQuery += " WHERE B1.D_E_L_E_T_<>'*' "
//cQuery += " AND B1_MSBLQL<>'1' AND C6_NUM='"+SC5->C5_NUM+"' GROUP BY B1_POSIPI"
cQuery += " AND B1_MSBLQL<>'1' AND C6_NUM='"+cNPedVen+"' GROUP BY B1_POSIPI"

If Select("QRYAUX") <> 0
	dbSelectArea("QRYAUX")
	dbCloseArea()
EndIf

TCQuery cQuery New Alias "QRYAUX"

If Alltrim(QRYAUX->B1_POSIPI) == '90219012' .OR. Alltrim(QRYAUX->B1_POSIPI) == '90219019'
	If Empty(Alltrim(cMensag))
		cMsgCli += "Alteração de NCM"
		cMensag := "Alteração de NCM"
	EndIf
	If Alltrim(QRYAUX->B1_POSIPI) == '90219012' .AND. a < 1
		cMsgCli += "NCM de 90219081 para 90219012 - Conforme Resolução 51 de 17 de Junho de 2020. "
		a := 1
	EndIf

	If Alltrim(QRYAUX->B1_POSIPI) == '90219019' .AND. b < 1
		cMsgCli += "NCM de 90219089 para 90219019 - Conforme Resolução 51 de 17 de Junho de 2020. "
		b := 1
	EndIf
EndIf

//Alterado dia 06/08/2020

If Alltrim(QRYAUX->B1_POSIPI) == '90219012' .OR. Alltrim(QRYAUX->B1_POSIPI) == '90219080' .OR. Alltrim(QRYAUX->B1_POSIPI) == '90219013'
	If z < 2
		cMsgCli += " Decisão de liminar concedida no Mandado de Segurança n. 1032097-76.2020.8.26.0053"
		z := 2
	EndIf
EndIf

QRYAUX->(DbCloseArea())

IF !Empty(cMsgCli)
	cMensCli := cMensCli + cMsgCli + "/ "
ENDIF

//Fim
RETURN (cMsgCli)


STATIC FUNCTION msgMedPaci(cNPedVen, cMensCli)
LOCAL cMsgCli:=""
LOCAL cTxt:=""

IF cNPedVen == SC5->C5_NUM .OR. SC5->(DbSeek(xFilial("SC5")+cNPedVen))
	
	cTxt:=AllTrim(SC5->C5_MENNOTA) 
	IF .NOT. Empty(cTxt) //.AND. .NOT. cTxt $ cMensCli
		cMsgCli += cTxt +" /"
	ENDIF

	cTxt:=AllTrim(SC5->C5_MENNFSE) 
	IF .NOT. Empty(cTxt) //.AND. .NOT. cTxt $ cMensCli .AND. .NOT. Alltrim(cMenscli) $ cTxt
		cMsgCli+= cTxt +" /"
	ENDIF

	If !Empty(SC5->C5_PACIENT)
		cMsgCli += " PAC.: " + AllTrim(SC5->C5_PACIENT)		// Wagner - Connit - 12/08/16 (Solicitação Erivan/Marcelo)
	ENDIF
	If !Empty(SC5->C5_DTUSO)
		cMsgCli +=  " -DT.USO: " + Alltrim(DTOC(SC5->C5_DTUSO))	// Eduardo Felipe - Connit - 22/09/17 (Solicitação Erivan/Marcelo)
	EndIf
	If !Empty(SC5->C5_MEDICO)
		cMsgCli +=  " -MEDICO: " + Alltrim(Posicione("Z06",1,xFilial("Z06")+SC5->C5_MEDICO,"Z06_NOME"))+" "	// Eduardo Felipe - Connit - 21/09/17 (Solicitação Erivan/Marcelo)
	ENDIF
	If !Empty(SC5->C5_XCONVEN)
		cMsgCli += " -CONVENIO.: " + AllTrim(SC5->C5_XCONVEN)		// Thiago Rocco - 31/08
	ENDIF

ENDIF

IF !Empty(cMsgCli)
	//cMensCli:= cMensCli + cMsgCli+" /"
	cMensCli:= cMsgCli+" /"
ENDIF

RETURN (cMsgCli)

//========
STATIC FUNCTION InfAnvisa()
LOCAL cInfAdic:=""
LOCAL cCmAnvisa:=""
//ESPECIFICO CICLOMED   		
cCmAnvisa   := SB1->B1_XCDANVI	//André Connit - 16/10/2017			                

If !Empty(cCmAnvisa)
	cInfAdic := cInfAdic+" "+"ANVISA: "+cCmAnvisa //André Connit - 16/10/2017
endif  
//ESPECIFICO CICLOMED   		
RETURN cInfAdic
