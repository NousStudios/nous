import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

// Um "quadrado" de item dentro da aba Loja (um produto/serviço do
// catálogo). Recebe o nome, o preço e o tipo (Produto/Serviço) reais
// do item. Nome e preço podem ser editados DIRETO aqui, sem precisar
// abrir o popup "Editar Item" — o popup continua existindo para editar
// os outros campos (descrição, variantes, etc.).
//
// ALTERADO (visual): o card agora é dividido em duas partes:
//   1) uma área de imagem no topo (hoje com ícone de placeholder, que
//      muda conforme o tipo), com o rótulo Produto/Serviço como uma
//      "etiqueta" no canto e o menu "⋮" no outro canto;
//   2) o nome em destaque e o preço dentro de uma "pílula" com borda.
// A área de imagem ocupa TODO o espaço vertical que sobrar, então o
// card não fica mais com um vazio embaixo quando a lista dá a ele uma
// altura maior do que o conteúdo precisa.
//
// A assinatura pública (parâmetros do construtor) é a MESMA de antes,
// então nada que usa este card precisa mudar.
class ItemLojaCard extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final TipoItemLoja? tipo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  // Chamados a cada mudança no campo de nome/preço editado direto no
  // card. Quem decide o que fazer com o novo valor (achar o item certo
  // pelo id e atualizar a lista) é a tela DadosPerfilView.
  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;

  const ItemLojaCard({
    super.key,
    required this.theme,
    required this.nome,
    required this.preco,
    this.tipo,
    required this.onEditar,
    required this.onExcluir,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
  });

  @override
  State<ItemLojaCard> createState() => _ItemLojaCardState();
}

class _ItemLojaCardState extends State<ItemLojaCard> {
  late final TextEditingController _nomeController =
      TextEditingController(text: widget.nome);
  late final TextEditingController _precoController =
      TextEditingController(text: widget.preco);

  @override
  void didUpdateWidget(covariant ItemLojaCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o nome/preço mudou por FORA deste card (por exemplo, editado
    // pelo popup "Editar Item", ou pela mesma linha do produto dentro
    // de uma categoria), atualiza o texto mostrado aqui também. Sem
    // isso, os dois lugares que editam o mesmo item poderiam mostrar
    // valores diferentes na tela.
    if (widget.nome != oldWidget.nome && widget.nome != _nomeController.text) {
      _nomeController.text = widget.nome;
    }
    if (widget.preco != oldWidget.preco &&
        widget.preco != _precoController.text) {
      _precoController.text = widget.preco;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  String _rotuloDoTipo() {
    switch (widget.tipo) {
      case TipoItemLoja.produto:
        return 'Produto';
      case TipoItemLoja.servico:
        return 'Serviço';
      case null:
        return '';
    }
  }

  // NOVO: o ícone de placeholder agora acompanha o tipo do item.
  // Serviço ganha um ícone de ferramentas; Produto (e item sem tipo
  // escolhido ainda) continua com a caixinha de antes.
  IconData _iconeDoTipo() {
    return widget.tipo == TipoItemLoja.servico
        ? Icons.handyman_outlined
        : Icons.inventory_2_outlined;
  }

  // Área de imagem do topo. Fica dentro de um Expanded (no build), ou
  // seja, cresce/encolhe conforme a altura que o card recebe.
  Widget _buildAreaImagem(AppTheme theme, String rotuloTipo) {
    return Container(
      decoration: BoxDecoration(
        // Preenchimento bem sutil, calculado a partir da borderColor:
        // funciona nos temas Claro e Escuro (e no botão "vazado") sem
        // precisar de uma cor nova no AppTheme.
        color: theme.borderColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(_iconeDoTipo(),
                size: 30, color: theme.secondaryTextColor),
          ),
          // Etiqueta do tipo. O "right: 28" reserva o espaço do menu
          // "⋮", e o FittedBox garante que o texto nunca quebre linha
          // nem estoure: se faltar espaço, ele só encolhe.
          if (rotuloTipo.isNotEmpty)
            Positioned(
              left: 4,
              top: 6,
              right: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    rotuloTipo,
                    maxLines: 1,
                    style: theme.getTextStyle(
                      fontSize: 9,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 28,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.more_vert, color: theme.secondaryTextColor),
                color: theme.cardBackgroundColor,
                onSelected: (valor) {
                  if (valor == 'editar') widget.onEditar();
                  if (valor == 'excluir') widget.onExcluir();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Editar Item', style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 8),
                        Text('Excluir Item', style: theme.getTextStyle()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Preço dentro de uma "pílula" com borda. O "R$" é fixo (não
  // editável) e só o número fica dentro do campo.
  Widget _buildPreco(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Text(
            'R\$',
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _precoController,
              maxLines: 1,
              // Teclado numérico COM separador decimal, para dar para
              // digitar preços como "12,50".
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: '00,00',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor.withValues(alpha: 0.5),
                ),
              ),
              onChanged: widget.onPrecoAlterado,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final rotuloTipo = _rotuloDoTipo();

    return Container(
      width: 112,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildAreaImagem(theme, rotuloTipo)),
          const SizedBox(height: 6),
          // Nome com a cor de "título de verdade" (textColor), como
          // manda a regra do tema. Continua editável e sem borda; o
          // hint só aparece se o nome estiver vazio.
          TextField(
            controller: _nomeController,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: 'Sem nome',
              hintStyle: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor.withValues(alpha: 0.5),
              ),
            ),
            onChanged: widget.onNomeAlterado,
          ),
          const SizedBox(height: 6),
          _buildPreco(theme),
        ],
      ),
    );
  }
}