///////////////////////////
//verificar número do ID
USER function ProxPV(cPref)

	Local cID
	Local cNum := "00000" //GetNewPar("CM_SERINI","00000000000000007000")
	LOCAL cAux:="%"

   cPref:=IIf(Valtype(cPref)<>"C".OR.Empty(cPref),"0",cPref)

	BeginSql Alias "TID"
			SELECT (CAST(MIN(SUBSTRING(T.C5_NUM,2,5)) AS INT) + 1) IDNEXT
			FROM %Table:SC5% T
			WHERE T.C5_NUM LIKE %Exp:cPref+cAux% AND
			SUBSTRING(T.C5_NUM,2,5) >= %Exp:cNum% AND
			ISNUMERIC(SUBSTRING(T.C5_NUM,2,5))=1 AND
			NOT EXISTS (
				SELECT CAST(SUBSTRING(C5_NUM,	2,5) AS INT) C5_NUM
				FROM %Table:SC5% T1
				WHERE CAST(SUBSTRING(T1.C5_NUM,2,5) AS INT) = (CAST(SUBSTRING(T.C5_NUM,2,5) AS INT) + 1) AND
				ISNUMERIC(SUBSTRING(T1.C5_NUM,2,5))=1 AND
				SUBSTRING(T.C5_NUM,2,5) >= %Exp:cNum% AND
				T1.C5_NUM LIKE %Exp:cPref+cAux%
			)
	EndSQL

	DbSelectArea("TID")
	DbGotop()

	if !eof()
		cID := cPref+Alltrim(strzero( TID->IDNEXT, 5 ))
	else
		cID := cPref+cNum
	endif

	DbSelectArea("TID")
	TID->( DbCloseArea() )

return(cID)
