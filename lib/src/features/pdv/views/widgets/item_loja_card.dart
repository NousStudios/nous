import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

// Um "quadrado" de item dentro da aba Loja (um produto/serviço do
// catálogo). Recebe o nome, o preço e o tipo (Produto/Serviço) reais
// do item. Nome e preço agora podem ser editados DIRETO aqui, sem
// precisar abrir o popup "Editar Item" — o popup continua existindo
// para editar os outros campos (descrição, variantes, etc.).
class ItemLojaCard extends StatefulWidget {
  final AppTheme theme;
  final String nome;
  final String preco;
  final TipoItemLoja? tipo;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  // NOVO: chamados a cada mudança no campo de nome/preço editado
  // direto no card. Quem decide o que fazer com o novo valor (achar o
  // item certo pelo id e atualizar a lista) é a tela DadosPerfilView.
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final rotuloTipo = _rotuloDoTipo();

    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 32, color: theme.secondaryTextColor),
          const SizedBox(height: 4),
          // NOVO: rótulo pequeno do tipo (Produto/Serviço), só aparece
          // se o item já tiver um tipo escolhido.
          if (rotuloTipo.isNotEmpty)
            Text(
              rotuloTipo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 9,
                color: theme.secondaryTextColor,
              ),
            ),
          // ALTERADO: era um Text simples; agora é um campo de texto
          // editável, mas com a MESMA aparência de antes (sem borda,
          // sem fundo) — a diferença só aparece quando o usuário toca
          // para editar.
          TextField(
            controller: _nomeController,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: theme.getTextStyle(fontSize: 11),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: widget.onNomeAlterado,
          ),
          // ALTERADO: preço também editável, com o prefixo "R$" fixo
          // (não editável) e só o número dentro do campo.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'R\$ ',
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              ),
              SizedBox(
                width: 46,
                child: TextField(
                  controller: _precoController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: theme.getTextStyle(
                    fontSize: 10,
                    color: theme.secondaryTextColor,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '00,00',
                  ),
                  onChanged: widget.onPrecoAlterado,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 16, color: theme.secondaryTextColor),
            color: theme.cardBackgroundColor,
            onSelected: (valor) {
              if (valor == 'editar') widget.onEditar();
              if (valor == 'excluir') widget.onExcluir();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Text('Editar Item', style: theme.getTextStyle()),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir Item', style: theme.getTextStyle()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}