#INCLUDE "PROTHEUS.CH"
#INCLUDE "DIRECTRY.CH"
#INCLUDE "TOPCONN.CH"

USER FUNCTION Txt2Sql(cPath)
LOCAL aDir:={}
LOCAL nn:=0 
LOCAL cPattern:="*.csv"
LOCAL nOp:=0
LOCAL lCont
LOCAL pp:=0

PRIVATE xFilTrb:=""

//DEFAULT cPath:="\FOLHAMATIC - Arquivos Gerados_2015-12-09\"
//DEFAULT cPath:="C:\001\Cartonale\Folha Pagto\Folhamatic\"
DEFAULT cPath:="\TEMP\Importar\"

cPattern:="???"+cEmpAnt+"0*.csv"
      
aDir:=Directory(cPath+cPattern)

FOR nn:=1 TO Len(aDir)
	nOp:=AVISO("PROCESSO","Processar Arquivo: "+CRLF+"Arq: "+aDir[nn,F_NAME]+CRLF+"De: "+DtOC(aDir[nn,F_DATE])+" "+aDir[nn,F_TIME]+CRLF+"Tam: "+ALLTRIM(STR(aDir[nn,F_SIZE])),{"SIM","NAO","SAIR"},2)
	IF nOp = 1 .AND. (AVISO("PROCESSO","Confirma o Processamento do Arquivo: "+CRLF+aDir[nn,F_NAME],{"SIM","NAO"},1)=1)
		
		//pega a filial de trabalho do nome do arquivo. se não vier assume a filial corrente
		pp:= 3 + Len(cEmpAnt) + 2 //3=nome da tabela + tamanho cod empresa + 2="0"+proximo 
		xFilTrb:=Substr(aDir[nn,F_NAME], pp , At(".",aDir[nn,F_NAME])-pp)
		
		Processa({||  lCont:=Txt2Sql_ex( cPath, aDir[nn,F_NAME] ) },"IMPORTA DE TXT PARA SQL - Arquivo: "+aDir[nn,F_NAME] )
		IF !lCont
			EXIT
		ENDIF
	ELSEIF nOp = 3
		EXIT
	ENDIF
NEXT

IF LEN(aDir)=0
	ALERT("NÃO HÁ ARQUIVOS A PROCESSAR PARA ESTA EMPRESA/FILIAL."+CRLF+"O nome padrao do arquivo é: Nome_SQL_da_Tabela+Filial.csv"+CRLF+"Exemplo: SRA01001.csv")
ENDIF

RETURN



STATIC FUNCTION Txt2Sql_ex( cPath, cFile )
LOCAL nLn:=0
LOCAL cLine:=""
LOCAL aCpos:={}
LOCAL nCpo:=0
LOCAL aDbStru:={}
//LOCAL cDbFile:=Left(cFile,At(".",cFile)-1)
LOCAL aDados:={}
LOCAL cTB:=LEFT(cFile,3)
LOCAL xCont:=""
LOCAL lReturn:=.T.
LOCAL aFilial:={}
//LOCAL aRB_Cod:={"",""}
LOCAL aChvUnq:={}
LOCAL cChvUnq:=""
LOCAL nn:=0
LOCAL cQuery:=""
LOCAL aCabec:={}
//LOCAL aCabAlt:={}
LOCAL nAux:=0
//LOCAL aAux:={}
LOCAL cCposChv:=""

PRIVATE lChkUnq:=.T.

// Abre o arquivo
nHandle := FOpen(cPath+cFile)

// Se houver erro de abertura abandona processamento
IF FError() <> 0
	return
Endif

nTLin := FSEEK(nHandle, 0, 2)        //tamanho do arquivo em bytes (FSeek manda o ponteiro pro fim do arq)
FSeek(nHandle, 0)                    //Volta o ponteiro pro topo do arquivo texto

ProcRegua(nTLin)

DbSelectArea("SX3")
DbSetOrder(2)

DbSelectArea(cTb)
DbSetOrder(1)

aDbStru:=DbStruct()
AAdd(aFilial,{ Ascan(aDbStru, {|str| "_FILIAL" $ str[1] }), xFilial(cTB, xFilTrb) } )

nLn:=0
While cLine <> "_FIM"

	FOR nn:=1 to 48
		IncProc("Processando...")
	NEXT

	cLine := NextEol(nHandle, nTLin, 48)	
	IF Empty(cLine) .OR. cLine=="_FIM" .OR. Len(cLine)<10
		LOOP
	ENDIF
	++nLn   

	//MsgAlert( "Linha: " + cLine + " - Recno: " + StrZero(nLn,3) )    
	IF nLn == 1		
		IF Right(Alltrim(cLine),1)=";"
			cLine :=left( cline, len(cline)-1)  //RETIRA O ULTIMO ; POIS VAI DAR DIFERENÇA DE 1 CAMPO A MAIS EM RELACAO AOS DADOS
		ENDIF
		aCpos := StrTokArr2(cLine, ";",.T.)
			
		LOOP	
	ENDIF

	aDados:=StrTokArr2(cLine, ";",.T.)

	IF Len(aCpos) <> Len(aDados)
		ALERT("ESTRUTURAS DIFERENTES ENTRE CABEÇALHO E DADOS DO ARQUIVO TXT")
		lReturn:=.F.
		EXIT        
	ENDIF
   
	IF !Empty(aDados)
		
		//Check chave unica
		SX2->(MsSeek(cTb))
		aChvUnq := StrTokArr2( Alltrim(SX2->X2_UNICO), "+",.F.)
		cChvUnq := "" 
		cCposChv:=""
		cQuery:=""
		aCabec:={}
		//aCabAlt:={}
		
		/*TRATAVA O RB_COD, MAS AGORA PASSA A VIR DO TXT
		IF cTb = "SRB"
			SRB->(DbSetOrder(1))
			SRB->(DbSeek(aFilial[1,2]+aDados[1]))
			
			IF !SRB->(Found())
				aRb_Cod[1]:=aDados[1]
				aRb_Cod[2]:="01"
			ELSE            
				DbEval({|| aRb_Cod[2]:=SRB->RB_COD },,{|| aDados[1] = SRB->RB_MAT }) //PERCORRE SRB PARA O FUNCIONARIO				
				aRb_Cod[2]:=Soma1(aRb_Cod[2])
			ENDIF
			
		ENDIF
	   */

      //CHECK INTEGRIDADE COM INDICE UNICO
		FOR nn:=1 to Len(aChvUnq)

			IF "_FILIAL" $ aChvUnq[nn]
				cChvUnq += aChvUnq[nn]+" = '"+xFilial(cTb,xFilTrb)+"' "
			ELSE
				nCpo:=Ascan(aCpos,{|cc| cc $ Alltrim(aChvUnq[nn]) })
				IF nCpo = 0
				      Alert("O campo "+aChvUnq[nn]+" faz parte do Indice unico e não foi encontrado no arquivo TXT")
				      nCpo:=999999
				      EXIT
				ENDIF
				//cChvUnq += iif(!Empty(cChvUnq),"AND "," ")+aChvUnq[nn]+" = '"+Alltrim(aDados[nCpo])+"' "
				cChvUnq += iif(!Empty(cChvUnq),"AND "," ")+aCpos[nCpo]+" = '"+iif(Valtype(aDados[nCpo])="D",DtoS(aDados[nCpo]),aDados[nCpo])+"' "
				cCposChv += aCpos[nCpo]+iif(nn=len(aChvUnq),"",",") 
			ENDIF
		NEXT
		IF nCpo=999999
			EXIT
		ENDIF	
		
		cQuery:="SELECT "+cCposChv+", R_E_C_N_O_ NROREG FROM "+RETSQLNAME(cTb)+" WHERE D_E_L_E_T_='' AND "+cChvUnq
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),'CHKUNQ',.T.,.T.)
		lChkUnq:=CHKUNQ->(EOF())
		nAux:=CHKUNQ->NROREG
		CHKUNQ->(DbCloseArea())

		DbSelectArea( (cTb) )      
		IF lChkUnq //inclusao
			DbGoBottom()
			DbSkip()
		ELSE
			DbGoTo(nAux)
		ENDIF
     
		IF cTb="SRB"
			nAux  := Ascan(aCpos, "RB_MAT")
			SRA->(DbSetOrder(1))
			SRA->(MSSEEK(xFilial("SRA",xFilTrb) + aDados[nAux]))
		ENDIF

		//TODO O RESTO
		FOR nCpo:=1 TO Len(aCpos)

			IF	SX3->(DbSeek(aCpos[nCpo])) .AND. SX3->X3_CONTEXT == "V"
				cTpCpo = SX3->X3_TIPO
			ELSE
				nPCpo:=(cTb)->(FieldPos(aCpos[nCpo]))
				IF nPCpo = 0 .AND. !Empty(aDados[nCpo]) .AND. !("R_E_C_D_E_L_"$aCpos[nCpo])
					IF AVISO(cFile,"CAMPO INFORMADO NO TXT  NÃO ENCONTRADO NO DICIONARIO: "+aCpos[nCpo]+";"+CRLF+"Conteudo: "+aDados[nCpo],{"SAIR","CONTINUA"},2) =1
						lReturn:=.F.
						EXIT
					ELSE
						LOOP //IGNORA CAMPO NÃO ENCONTRADO
					ENDIF
				ENDIF
	
				cTpCpo:=Type( (cTb+"->"+aCpos[nCpo]) )
			ENDIF
			xCont:=NIL

			IF cTpCpo = "D"
				xCont:=Ctod( aDados[nCpo] )

			ELSEIF cTpCpo = "N"
				xCont:=Val( aDados[nCpo] )

			ELSEIF cTpCpo = "L"
				xCont:="Erro"

			ELSE
				xCont:=FwNoAccent(aDados[nCpo])
		   ENDIF

			IF aCpos[nCpo] $ "RA_BCDEPSA"
				LOOP
		
			ELSEIF aCpos[nCpo] $ ("RA_CIC;RA_CEP;RA_BCDEPSA	")
				xCont:=StrTran( aDados[nCpo],".","")
				xCont:=StrTRan( xCont,"-","") 
		
			ELSEIF aCpos[nCpo] $ ("RA_DEPIR;RA_DEPSF")
				xCont:=PadL( Alltrim(aDados[nCpo]),2,"0")
		
			ELSEIF aCpos[nCpo] = "RA_ADTPOSE"
				xCont:="***N**"
		
			ELSEIF aCpos[nCpo] = "RA_SINDICA"
				xCont:="01"
				
			ELSEIF aCpos[nCpo] $ ("RJ_FUNCAO,RA_CODFUNC")
				xCont:=Right(aDados[nCpo],5)
				
			ELSEIF aCpos[nCpo] = "RA_TIPOPGT"
				xCont:="M"
				
			ELSEIF aCpos[nCpo] = "RA_CATFUNC"
				xCont:="M"
				
			ELSEIF aCpos[nCpo] = "RA_ENDEREC"
				xCont := StrTokArr2(aDados[nCpo], ",",.T.)
				xCont:=Alltrim(xCont[1])				
				
			ELSEIF aCpos[nCpo] = "RA_NUMENDE"
				nAux  := Ascan(aCpos, "RA_ENDEREC")
				xCont := StrTokArr2(aDados[nAux], ",",.T.)
				IF Len(xCont)>=2
					xCont := Alltrim(Str(Val(Alltrim(xCont[2]))))
				ELSE
					xCont:= ""
				ENDIF
			//ELSEIF aCpos[nCpo] = "RA_ANTEAUM"
			//	xCont:=aDAdos[ Ascan(aCpos,"RA_SALARIO")
		
			ELSEIF aCpos[nCpo] = "RA_SITFOLH"
				DO CASE
					CASE Empty(aDados[nCpo]) .or. aDados[nCpo]="I"
						xCont := "A"
					CASE aDados[nCpo] = "A"
						xCont := " "
					OTHERWISE  
						xCont := aDados[nCpo]
				ENDCASE
				//IF !Empty(xCont)
				//	AAdd(aCabAlt,{aCpos[nCpo],xCont,NIL})
				//	xCont:=" "
				//ENDIF
				xCont:=IIF( lChkUnq, " ",xCont) //se for inclusao sempre RA_SITFOLH=" "
		
			ELSEIF aCpos[nCpo] = "RA_DEMISSA"
				//AAdd(aCabAlt,{aCpos[nCpo], xCont,NIL})
				xCont:=IIF( lChkUnq, Ctod("  /  /  "),xCont)
				 
			ELSEIF aCpos[nCpo] = "RA_RESCRAI"
				//xCont:=" "
		
		      //IF !Empty(aDados[nCpo])
				//	AAdd(aCabAlt,{aCpos[nCpo],aDados[nCpo],NIL})
				//ENDIF
				xCont:=IIF( lChkUnq, " ",xCont)
			
			ELSEIF aCpos[nCpo] = "RA_CESTAB"
				xCont:="S"
				                   
			ELSEIF aCpos[nCpo] = "RA_COMPSAB"
				xCont:="2"
				
			ELSEIF aCpos[nCpo] = "RA_VIEMRAI"
				xCont:="10"
				
			ELSEIF aCpos[nCpo] = "RA_TIPOADM"
				xCont:="9A"
		
			ELSEIF aCpos[nCpo] = "RA_TNOTRAB"
				IF Empty(aDados[nCpo])
					xCont:="1"
				ELSE
					xCont:=aDados[nCpo]
				ENDIF	
		
			ELSEIF aCpos[nCpo] = "RA_CARGO"
				xCont:=Right(aDados[nCpo],5)
	
			//ELSEIF aCpos[nCpo] = "RA_DEPTO"
			//	nAux:=Ascan(aCpos,"RA_CC")
			//	xCont:=aDados[nAux]+aDados[nCpo]


			ELSEIF aCpos[nCpo] = "RA_LOGRTP"
				nAux:=Ascan(aCpos,"RA_ENDEREC")
				xCont:=At(" ",aDados[nAux])-1
				//xCont:=Left(aDados[nAux], IIf(xCont>3,3,xCont))
				xCont:=Left(aDados[nAux], xCont)
				nAux:=0
				
				//IF xCont $ "RUA,R."
				//	xCont:="R"
				//ELSE
				//	nAux:=xCont
				//	xCont:=""
					
					RCC->(DbSetOrder(1))
					RCC->(DbSeek(xFilial("RCC",xFilTrb)+"S054"))
					
					//RCC->(DbEval({|| xCont:=Left(RCC->RCC_CONTEUD,3)},,{|aa| RCC->RCC_CODIGO='S054' .AND. !(nAux $ Substr(RCC->RCC_CONTEUD,25,RAT("|",RCC->RCC_CONTEUD))) },,,.F. ))
					
					DO WHILE RCC->RCC_CODIGO='S054'
						//aAux:=StrtokArr(Substr(RCC->RCC_CONTEU,25,RAT("|",RCC->RCC_CONTEU)),"|")
						//aAux:=StrtokArr( RCC->RCC_CONTEU,"|")
						//nAux:=Ascan(aAux, {|zz,xn|   iif(xn=1, xCont $ zz, ZZ $ xCont) })
						//IF nAux <> 0
						//	xCont:=Left(RCC->RCC_CONTEU,3)
						//	EXIT
						//ENDIF
						IF xCont $ ALLTRIM(RCC->RCC_CONTEU)
							xCont:=Left(RCC->RCC_CONTEU,3)
							nAux:=1
							EXIT
						ENDIF
						
						/*IF (nAux $ Substr(RCC->RCC_CONTEUD,25,RAT("|",RCC->RCC_CONTEUD)))
							xCont:=Left(RCC->RCC_CONTEUD,3)
							EXIT
						ENDIF*/
						RCC->(DbSkip())
					ENDDO
					IF nAux == 0
						xCont:=""
					ENDIF
				//ENDIF					
				lDebug:=.T.

			ELSEIF aCpos[nCpo] = "RA_LOGRDSC"
				nAux:=Ascan(aCabec,{|zz| zz[1]="RA_ENDEREC" })
				xCont:=aCabec[nAux,2]
				xCont:=Substr(xCont,At(" ",xCont)+1)
			
			ELSEIF aCpos[nCpo] = "RA_LOGRNUM"
				nAux:=Ascan(aCabec,{|zz| zz[1]="RA_NUMENDE" })
				xCont:=aCabec[nAux,2]
			
			ELSEIF aCpos[nCpo] = "RA_CODMUN"
				nAux:=Ascan(aCpos,"RA_MUNICIP")
				xCont:=Alltrim(aDados[nAux])
				xCont:=Posicione("CC2",2,xFilial("CC2",xFilTrb)+xCont,"CC2_CODMUN")
            CC2->(DbSetOrder(1))
				
			//===================================		
			ELSEIF aCpos[nCpo] $ ("RB_CIC;	")
				xCont:=StrTran( aDados[nCpo],".","")
				xCont:=StrTRan( xCont,"-","") 
				
			ELSEIF aCpos[nCpo] = "RB_DTENTRA"
				nAux  := Ascan(aCpos, "RB_DTNASC")

				IF xCont < SRA->RA_ADMISSA .OR. iif(nAux<>0, (aDados[nAux]>=aDados[nCpo]), .T.)
					xCont:=CTOD("  /  /  ")
				ENDIF

			ELSEIF aCpos[nCpo] =  "RJ_FUNCAO"
				xCont:=Right(aDados[nCpo],5) 
				
			ELSEIF aCpos[nCpo] =  "RJ_SALARIO"
				IF xCont = 0
					nAux:=Ascan(aCpos, "RJ_FUNCAO")
					xCont:=Posicione("SRA",7,xFilial("SRA",xFilTrb)+aDados[nAux], "RA_SALARIO")
				ENDIF

			ELSEIF aCpos[nCpo] = "QB_DESCRIC" .AND. EMPTY(aDados[nCpo])
				nAux:=Ascan(aCpos, "QB_CC")
				IF nAux >0
					xCont:=Posicione("CTT",1,xFilial("CTT",xFilTrb)+aDados[nAux],"CTT_DESC01")
				ELSE
					xCont:=Space(20)
				ENDIF
			
			ELSEIF aCpos[nCpo] = "RD_CC" .AND. EMPTY(aDados[nCpo])
				nAux:=Ascan(aCpos, "RD_MAT")
				IF nAux >0
					xCont:=Posicione("SRA",1,xFilial("SRA",xFilTrb)+aDados[nAux],"RA_CC")
				ELSE
					xCont:=Space(9)
				ENDIF

			ENDIF
		
			AAdd(aCabec, {aCpos[nCpo],xCont,Nil})
				
		NEXT
		
		IF !lReturn
			EXIT
		ENDIF
	

		IF cTb $ "SRA;SRB;SQB;SE1;SE*2;SB*1"   //Se o Alias constar aqui vai usar MSExecAuto
			lReturn:=Envia(cTb, aCabec)

		ELSE                                   //Senão direto na tabela (proc mandatorio)
		   RecLock( cTb, lChkUnq)
		
			//CAMPO FILIAL
			IF lChkUnq
				(cTb)->(FieldPut( aFilial[1,1], aFilial[1,2]))
			ENDIF
         
			//DEMAIS CAMPOS
			Aeval( aCabec, {|fld| IIf( lChkUnq.OR.!(fld[1]$cChvUnq),(cTb)->(FieldPuT( FieldPos(fld[1]), fld[2])), NIL) })

			DbUnLock()
			DBCommit()
			lReturn:=.T.
		ENDIF   

      IF cTb = "SQ3"
       	xCont:=Posicione("SRJ",1,xFilial("SQ3",xFilTrb)+SQ3->Q3_CARGO,"RJ_DESC")
         	
        	IF !Empty(xCont)
        		RecLock("SQ3",.F.)
        		SQ3->Q3_DESCSUM := xCont
        		DbUnlock()
        	ENDIF
		ENDIF
		
		IF !lReturn //FORÇA O FIM DO PROC
			cLine :="_FIM"
		ENDIF

	ENDIF
Enddo

// Fecha o Arquivo
FClose(nHandle)

RETURN lReturn


//==================================================================
STATIC FUNCTION NextEol(nHandle, nTBytes, nMaxLen)
LOCAL sLin:=""
LOCAL nLen:=0
LOCAL nPos:=0
LOCAL nn:=1
LOCAL kk,cc, aa
LOCAL nFator:=0
LOCAL cEol    := Chr(13)+Chr(10)

nFator:=2 //NoRound(nMaxLen/3,0)
/*
DO WHILE ((nLen:=At( cEol, sLin)) == 0 .AND. !(Chr(0) $ sLin)
	sLin += FReadStr( nHandle, 20)
	IF sLin = ""
		EXIT
	ENDIF
ENDDO
*/
DO WHILE .T.
	sLin += FReadStr( nHandle, nFator)  //Le o arq ate nfator
	IF sLin = ""     //opa! fim do arquivo
		EXIT
	ELSEIF (nLen:=At( cEol, sLin)) <> 0   //check se tem quebra de linha ( CRLF )
		EXIT
	ELSEIF (nLen:=At( Chr(10), sLin)) <> 0  //check se tem apenas linefeed (pode ocorrer de o LF estar sem o CR)
		nn:=0
		EXIT
	ELSEIF (Chr(0) $ sLin) //fim de arquivo
		EXIT
	ENDIF
ENDDO

/*
IF nLen > nMaxLen
	nLen:=nMaxLen
	nn:=0
ENDIF
*/

//REPOSICIONA O PONTEIRO DO ARQ PARA QUEBRA de LINHA ENCONTRADA EM SLIN
nPos:=FSeek( nHandle, ((nLen+nn) - Len(sLin)), 1)

IF nPos <= nTBytes //nLen > 1
	sLin:= Left( sLin, nLen-nn )

	kk:=""  //TRATA a string que será retornada limpando os char invalidos e de controle
	FOR nn:=1 to Len(sLin)
		cc:=Substr(sLin,nn,1)
		aa:=Asc(cc)
		kk:= kk + IIf( aa<>127 .AND. aa>=21 .AND. aa<=165 ,cc,"")
		//kk:= kk + IIf( aa<>127 .AND. aa>=21 .AND. aa<=165 ,cc,"")
	NEXT
	sLin:= kk
ELSE
	sLin:="_FIM"
ENDIF

RETURN sLin

//-- Função criada para exemplificar a chamada da execução da rotina de cadastro de funcionários
STATIC Function Envia(cTb, aCabec) //, aCabAlt)
LOCAL lReturn:=.F.
Local nX:=0 
//LOCAL nY:=0
LOCAL cAux:=""
LOCAL aCab2:={}

STATIC aCabIt:={}
STATIC lChkUnqIt
                         
PRIVATE lMsErroAuto := .F.

//-- Faz a chamada da rotina de cadastro de funcionários (opção 3) 
//-- Opcao 3 - Inclusao registro
IF cTb = "SRA"

	M->RA_TIPOALT:=SPACE(3)
	M->RA_DATAALT:=Ctod("  /  /  ")

	MSExecAuto({|x,y,k,w| GPEA010(x,y,k,w)},NIL,NIL,aCabec,IIF(lChkUnq,3,4)) 

	nx:=Ascan(acabec,{|zz| zz[1]="RA_SITFOLH" })
	if .NOT. lChkUnq .AND. aCabec[nx,2]="D"
		lDebug:=.T.
	ENDIF

	If .NOT. lMsErroAuto	
		nx:=Ascan(acabec,{|zz| zz[1]="RA_MAT" })
		If SRA->(EOF()) .OR. SRA->RA_MAT <> aCabec[nx,2]
			SRA->(DbSetOrder(1))
			SRA->(MsSeek(xFilial("SRA",xFilTrb)+aCabec[nx,2]))
		ENDIF

		nx:=Ascan(acabec,{|zz| zz[1]="RA_SALARIO" })
		IF nx <> 0 .AND. aCabec[nx,2] <>0 .AND. SRA->RA_SALARIO <> aCabec[nx,2]
			RECLOCK("SRA",.F.)
			SRA->RA_SALARIO := aCabec[nx,2]
			SRA->(DbUnlock())
		ENDIF
	ENDIF
	
ELSEIF cTb="SRB"
   nX:=Len(aCabIt)
   
	IF nX=0 .OR. (aCabIt[nX,1,2] = aCabec[1,2])
		lReturn:=.T.
		lChkUnqIt:=IIf(nX=0,lChkUnq,lChkUnqIt)
	ELSE
		cAux:=aCabIt[1,1,2] //MATRICULA
		
		SRA->(DbSetOrder(1))
		SRA->(MSSEEK(xFilial("SRA",xFilTrb) + cAux))
		IF !SRA->(EOF())
			//	Alert('COD. FUNC. NÃO CADASTRADO '+ cAux)
			//	lReturn:=.F.
			//ELSE
			aCab2 := {}
			aadd(aCab2,{"RA_FILIAL"  ,xFilial("SRB",xFilTrb) ,Nil  })
			aadd(aCab2,{"RA_MAT"   ,cAux ,Nil  })

			MSExecAuto({|x,y,k,w,z| GPEA020(x,y,k,w,z)},NIL,aCab2,aCabIt,IIf(lChkUnqIt,3,4))		
		ENDIF
		aCabIt:={}
		lChkUnqIt:=lChkUnq
		
	ENDIF
	AAdd(aCabIt, aCabec)

ELSEIF cTb = "SQB"
	MSEXECAUTO({|x,y,k,w| CSAA100(x,y,k,w)},NIL,NIL,aCabec,iif(lChkUnq,3,4))

ELSEIF cTb = "SB1"
	MSExecAuto({|x,y| Mata010(x,y)},aCabec,iif(lChkUnq,3,4))

ELSEIF cTb = "SE1"
	/* 
	EXCLUSAO DE REGISTROS
	SE1->(DBSETORDER(2)) //FILIAL + CLIENTE + LOJA    + PREFIXO + NUM     + PARCELA +TIPO
	IF (SE1->(DBSEEK( XFILIAL("SE1")+ACABEC[5,2]+ACABEC[6,2]+ACABEC[2,2]+ACABEC[3,2]+ACABEC[4,2]+ACABEC[7,2])))
		MsExecAuto( { |x,y| FINA040(x,y)} , aCabec, 5)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	ENDIF
	*/
	MsExecAuto( { |x,y| FINA040(x,y)} , aCabec, IIf(lChkUnqIt,3,4))  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
ELSEIF cTb = "SE2"

   MsExecAuto( { |x,y,z| FINA050(x,y,z)},aCabec,,4) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

ENDIF
	
If lMsErroAuto	
	MostraErro()
	lReturn:=.F.
ELSE
	lReturn:=.T.
ENDIF

IF !lReturn
	lReturn:=MsgYesNo("Continua importação ?")
ENDIF

Return(lReturn)



