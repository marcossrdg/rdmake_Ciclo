/*/{Protheus.doc} User Function MT103LDV
   P.E. PARA TRATAR O RETORNO DA ROTINA RETORNAR DA MATA103 (DOC.ENTRADA)
   @type  Function
   @author MARCIO AFLITOS
   @since 01/09/2021
   @version 1A
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see https://tdn.totvs.com/pages/releaseview.action?spaceKey=PROT&title=MT103LDV
   /*/
User Function MT103LDV()
   
LOCAL _aCpos:=PARAMIXB[1]
LOCAL _cD2Alias:=PARAMIXB[2]
LOCAL nD1_xSerial:=0

nD1_xSerial:=AScan(_aCpos,{|cc| cc[1]=="D1_XSERIAL" })

IF nD1_xSerial == 0
   AAdd(_aCpos, {"D1_XSERIAL","",NIL})
   nD1_xSerial := Len(_aCpos)
ENDIF

_aCpos[nD1_xSerial,2]:=(_cD2Alias)->D2_NUMSERI

RETURN (_aCpos)
