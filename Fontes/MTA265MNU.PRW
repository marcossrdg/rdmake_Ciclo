/*/{Protheus.doc} User Function MTA265MNU
   ACRESCENTAR OPCOES AO MENU MATA265 ENDEREÇAMENTO
   @type  Function
   @author MARCIO AFLITOS
   @since 01/09/2021
   @version version
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see (links_or_references)
   /*/
User Function MTA265MNU()

//Local aButUsr   := {}
//Local nOpc       := ParamIxb[1]   // 2=Visualizar   3=Endereçar   4=Estornar

//aAdd(aButUsr,{'SERIALIZAR',{||U_TMata265(SDA->DA_DOC, SDA->DA_SERIE, SDA->DA_CLIFOR, SDA->DA_LOJA )},'Botao 01','Botao 01' } )

AAdd( aRotina, {"SERIALIZAR","U_TMATA265", 0 , 4,0,nil}) 	//"Serializar"

Return NIL
