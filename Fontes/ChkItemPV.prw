/*/{Protheus.doc} User Function ChkItemPV
   (long_description)
   @type  Function
   @author use
   @since 04/10/2021
   @version version
   @param 
   @return return_var, return_type, return_description
   @exampl
   (examples)
   @see (links_or_references)
/*/
User Function ChkItemPV(cSerial)
LOCAL xx := 0
LOCAL nItOrig:=0
LOCAL npNumSeri := 0
LOCAL npC6_ITEM:=0
LOCAL npC6_PRODUTO := 0
LOCAL npC6_NUMSERI := 0
LOCAL npC6_QTDVEN := 0
LOCAL npC6_QTDLIB := 0
LOCAL npC6_PRCVEN := 0
LOCAL npC6_VALOR := 0
LOCAL npC6_BLQ := 0
LOCAL nTSeri:=0

FOR xx:= 1 to LEN(aHeader)
   DO CASE
      CASE aHeader[xx,2] == "C6_XSERIAL"
         npNumSeri := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_ITEM"
         npC6_ITEM := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_PRODUTO"
         npC6_PRODUTO := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_NUMSERI"
         npC6_NUMSERI := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_QTDVEN"
         npC6_QTDVEN := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_QTDLIB"
         npC6_QTDLIB := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_NUMSERI"
            npC6_NUMSERI := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_PRCVEN"
            npC6_PRCVEN := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_VALOR"
            npC6_VALOR := xx
      CASE Alltrim(aHeader[xx,2]) == "C6_BLQ"
            npC6_BLQ := xx
   ENDCASE
NEXT

IF Empty(cSerial) .OR. npNumSeri == 0
   RETURN
ENDIF

//POSICIONA NO SERIAL
IF cSerial <> SBF->BF_PRODUTO
   SBF->(DbSetOrder(3))
   IF .NOT. SBF->(DbSeek(xFilial("SBF")+cSerial))
      Alert("Serial informado não existe ou não encontrado nesta filial")
      RETURN
   ENDIF
ENDIF

//PROCURA PELO PRODUTO DO SERIAL NO ACOLS PARA PEGAR OS DADOS
nItOrig := Ascan(aCols,{|zz,li| .NOT. GdDeleted(li) .AND. zz[npC6_PRODUTO] == SBF->BF_PRODUTO })
IF nItOrig <> 0
   FOR xx:=1 to Len(aCols[n])
      IF xx==npNumSeri .OR. xx==npC6_ITEM //.OR. xx==npC6_PRODUTO
         LOOP
      ELSEIF xx == npC6_NUMSERI
         aCols[n,xx]:=cSerial
      ELSEIF xx == npC6_QTDVEN
         aCols[n,xx]:=1
      ELSEIF xx == npC6_QTDLIB
         aCols[n,xx]:=1
      ELSEIF xx == npC6_VALOR
         aCols[n,xx]:=aCols[n,npC6_PRCVEN]
      ELSEIF xx == npC6_BLQ
      ELSE
         aCols[n,xx]:=aCols[nItOrig,xx]
      ENDIF
   NEXT
ENDIF

nTSeri := 0
AEval(aCols,{|zz,li| nTSeri += IIf( !GdDeleted(li) .AND. (zz[npC6_PRODUTO]==aCols[nItOrig,npC6_PRODUTO]) .AND. !Empty(zz[npC6_NUMSERI]) ,1,0)  })

//aCols[nItOrig,npC6_QTDVEN]:= aCols[nItOrig,npC6_QTDVEN] - 1
aCols[nItOrig,npC6_BLQ] := "R"
/*
IF aCols[nItOrig,npC6_QTDVEN] <= 0
   aCols[nItOrig,npC6_QTDVEN] := nTSeri
   aCols[nItOrig,npC6_BLQ] := "R"
ENDIF
*/
RETURN 
