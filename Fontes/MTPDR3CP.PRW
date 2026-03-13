/*/{Protheus.doc} User Function MTPDR3CP
   P.E. NA MONTAGEM DA TELA DE DOCUMENTOS DE ORIGEM NA MATA103
   @type  Function
   @author MARCIO AFLITOS
   @since 01/09/2021
   @version 
   @param param_name, param_type, param_descr
   @return aHead, array, return_description
   @example
   (examples)
   @see https://tdn.totvs.com/pages/releaseview.action?pageId=6085824
   /*/
User Function MTPDR3CP()

Local cEs      := PARAMIXB[1] //Entrada ou Saida
Local aHead    := PARAMIXB[2] //Campos que serão incluidos na tela de selecao de docs de origem
Local cCpoSerial:=""

IF cES = "E"
   cCpoSerial:="D2_NUMSERI"
ELSE 
   cCpoSerial:="D1_XSERIAL"
ENDIF

DbSelectArea("SX3")
DbSetOrder(2)

If MsSeek(cCpoSerial)
   aadd(aHead,{ SX3->X3_CAMPO, SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL, ""}) //"'"+ALLTRIM(SX3->X3_PICTURE)+"'"})
EndIf
RETURN aHead
