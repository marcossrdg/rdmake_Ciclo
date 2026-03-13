#INCLUDE "PROTHEUS.CH"
#INCLUDE "Rwmake.CH"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MT103IPC  ºAutor  ³Wagner Cherubelli   º Data ³  23/04/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de Entrada para carregar campos especificos do PC na  º±±
±±º          ³Nota Fiscal de entrada                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Geral                                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
08/09/21 - MARCIO AFLITOS - ROTINA REVISADA APOS AVALIAÇÃO DOS CAMPOS

*/ 

User Function MT103IP2()

Local ExpN1 	:= PARAMIXB[1]

//08/09/21 - Marcio Aflitos
//IF ExistTrigger('D1_COD')  
//	RunTrigger(2,ExpN1,nil,,'D1_COD')
//ENDIF


Local nPosDsIt	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_DESCPRD'})
//Local nPosTpOp	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_CODFOR'})
//Local nPosDsOp	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_LOCAL'})

// 24/09/16 - Wagner
//Local nPosLote	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_LOTECTL'})
//Local nPosDtLt	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_DTVALID'})
//Local nPosAdic	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_ADICAO'})
//Local nPosSqAd	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_SEQADI'})

// 26/12/18 - Wagner
//Local nPosVend	:= aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_XVEND'})
// 26/12/18 - Wagner

// Verifica se o campo foi localizado, para não ocorrer erro de array
If nPosDsIt > 0		
	aCols[ExpN1][nPosDsIt]	:= SC7->C7_DESCRI 		// Descrição do Produto
EndIf
/*
If nPosTpOp > 0
	aCols[ExpN1][nPosTpOp]	:= SC7->C7_CODFOR		// Codigo do Produto no Fornecedor
EndIf

If nPosDsOp > 0
	aCols[ExpN1][nPosDsOp]	:= SC7->C7_LOCAL		// Local - Armazem
EndIf

// 24/09/16 - Wagner
If nPosLote > 0
	aCols[ExpN1][nPosLote]	:= SC7->C7_XLOTECTL		// Lote fornecedor
EndIf

If nPosDtLt > 0
	aCols[ExpN1][nPosDtLt]	:= SC7->C7_XDTLOTE		// Data Validade Lote fornecedor
EndIf

If nPosAdic > 0
	aCols[ExpN1][nPosAdic]	:= SC7->C7_XNUMADIC		// Numero Adicao
EndIf

If nPosSqAd > 0
	aCols[ExpN1][nPosSqAd]	:= SC7->C7_XSEQADIC		// Sequencia Adicao
EndIf

// 26/12/18 - Wagner
If nPosVend > 0
	aCols[ExpN1][nPosVend]	:= SC7->C7_XVEND		// Codigo Vendedor para Despesas
EndIf
// 26/12/18 - Wagner
*/

Return(ExpN1)
