/*/{Protheus.doc} User Function MTPODER3
   LOCALIZAÇÃO : Function F4Poder3 - Função responsável pela consulta as documentos de poder de/em terceiros.
   EM QUE PONTO : O ponto se encontra após a criação do aHeader e do arquivo temporário. É utilizado para alterar a ordem dos campos na consulta.
   @type  Function
   @author MARCIO AFLITOS
   @since 02/09/2021
   @version version
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see https://tdn.totvs.com/display/public/PROT/MTPODER3
   /*/
User Function MTPODER3()
   Local cTipo:= PARAMIXB[1] //Tipo de Operação - 'E' => Entrada ou 'S' => Saída
   Local _aHeader := PARAMIXB[2] //Aheader dos campos a serem mostrador na tela de consulta
   LOCAL npSerial:=0
   Local cCpo:=""
   
   If cTipo == 'E'
      cCpo:="D2_NUMSERI"
   ELSE
      cCpo:="D1_XSERIAL"
   ENDIF

   IF (npSerial:=aScan(aHeader,{|x| AllTrim(x[2])==cCpo})) == 0
         DbSelectArea("SX3")
         DbSetOrder(2)

         If MsSeek(cCpo)
            Aadd(_aHeader,{ TRIM(SX3->(X3Titulo())),;
							SX3->X3_CAMPO,;
							SX3->X3_PICTURE,;
							SX3->X3_TAMANHO,;
							SX3->X3_DECIMAL,;
							SX3->X3_VALID,;
							SX3->X3_USADO,;
							SX3->X3_TIPO,;
							SX3->X3_ARQUIVO,;
							SX3->X3_CONTEXT,;
							"" })
         ENDIF
   ENDIF

Return(_aHeader)
