/*/{Protheus.doc} User Function A440VCOL
   Ponto de Entrada que customiza os itens do Pedido de Vendas após a confirmação da consulta do Documento de Origem.
   Está localizado na função F4Poder3(), responsável por consultar os Documentos de Origem em Poder de Terceiros.
   @type  Function
   @author MARCIO AFLITOS
   @since 01/09/2021
   @version version
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see https://tdn.totvs.com/display/public/PROT/A440VCOL+-+Customiza+itens+do+Pedido+de+Vendas
   /*/
User Function A440VCOL()

   Local _aHeader := PARAMIXB[1]
   Local _aCols   := PARAMIXB[2]
   Local npSerial := 0
   Local cCpo     := ""

   //IF aScan(_aHeader,{|x| UPPER(Left(x[2],3))=="C6_"}) <> 0
   //   cCpo:="C6_NUMSERI"
   //ELSE
      cCpo:="D1_XSERIAL"
   //ENDIF

   IF (npSerial:=aScan(_aHeader,{|x| AllTrim(x[2])==cCpo})) <> 0
      _aCols[n, npSerial] := ALLTRIM(SD2->D2_NUMSERI)
   ENDIF
   
Return _aCols
