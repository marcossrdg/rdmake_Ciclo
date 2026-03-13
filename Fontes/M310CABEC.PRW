User Function M310CABEC()

Local cProg := PARAMIXB[1]
Local aCabec := PARAMIXB[2]
//Local aPar := PARAMIXB[3]
Local nC5_NUM :=0

If cProg == 'MATA410'
   IF (nC5_NUM:=AScan(aCabec,{|zz| Upper(Alltrim(zz[1])) = "C5_NUM"})) >0
      aCabec[nC5_NUM,2]:=u_ProxPv("T")
   ENDIF

   aadd(aCabec,{'C5_TPSAIDA','T',Nil})
   //aadd(aCabec,{'C5_CONDPAG','00',Nil})
   aadd(aCabec,{'C5_VEND1','000001',Nil})
   aadd(aCabec,{'C5_TPSAIDA','T',Nil})

Endif

Return(aCabec)
