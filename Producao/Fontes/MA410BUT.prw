#Include "Protheus.ch"

/*/{Protheus.doc} MA410BUT
    Ponto de entrada para adicionar botoes customizados na tela do Pedido de Venda (MATA410).
    Adiciona botao "Documentos" para ver/anexar documentos da reserva.
    @type  User Function
    @author Antonio
    @since 16/03/2026
    @version 1.0
/*/
User Function MA410BUT()
    Local aButtons := {}

    aAdd(aButtons, {"Documentos", { || U_DOCRESERVA() }, "Ver/Anexar documentos da reserva"})

Return aButtons
