import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/grupo_componentes_container.dart';

// Uma linha de "Produto" dentro de uma Categoria (ou Grupo de
// Componentes) expandida. Mostra o ItemLoja de verdade (escolhido no
// seletor da categoria/grupo). Nome e preço podem ser editados DIRETO
// aqui, na própria linha, sem precisar abrir nenhum popup — e o menu
// "⋮" também tem a opção "Editar Item", que abre o popup completo (com
// descrição, variantes, etc.), igual já acontece na lista "Itens".
// Continua guardando sua própria lista de Grupos de Componentes,
// criada pela opção "Adicionar Grupo de Componentes" no menu "⋮" —
// essa parte ainda não persiste (fica só na memória da tela), é um
// próximo passo separado.
//
// ALTERADO: antes, o título de cada grupo (ex: "Grupo de componentes
// A") era calculado toda vez, na hora de montar a lista, a partir da
// posição do grupo em _grupoIds (_letraDoGrupo(indice)). Isso
// funcionava bem enquanto o título era só um texto fixo — mas agora
// que o GrupoComponentesContainer deixa o título editável, ele precisa
// de um "dono" que lembre o valor atual de cada grupo, e não
// recalcule a letra e sobrescreva o que o usuário digitou. Por isso
// _gruposTitulos guarda o título atual de cada id de grupo, começando
// com a letra automática no momento da criação e podendo ser
// sobrescrito livremente depois, via onTituloAlterado.
class ProdutoLojaRow extends StatefulWidget {
  final AppTheme theme;
  final ItemLoja item;

  // Chamado quando o usuário escolhe "Excluir Produto" no "⋮". Quem
  // decide tirar este produto da categoria é o container pai (na
  // prática, remove o id deste item da lista itemIds da categoria/
  // grupo).
  final VoidCallback onExcluir;

  // Chamado quando o usuário escolhe "Editar Item" no "⋮". Abre o
  // popup completo de edição do item (a tela DadosPerfilView decide
  // isso, reaproveitando o mesmo popup usado pela lista "Itens").
  final VoidCallback onEditar;

  // Chamados a cada mudança no nome/preço editado direto nesta linha.
  final ValueChanged<String> onNomeAlterado;
  final ValueChanged<String> onPrecoAlterado;

  const ProdutoLojaRow({
    super.key,
    required this.theme,
    required this.item,
    required this.onExcluir,
    required this.onEditar,
    required this.onNomeAlterado,
    required this.onPrecoAlterado,
  });

  @override
  State<ProdutoLojaRow> createState() => _ProdutoLojaRowState();
}

class _ProdutoLojaRowState extends State<ProdutoLojaRow> {
  bool _ativo = true;
  bool _expandido = false;

  final List<int> _grupoIds = [];
  int _proximoIdGrupo = 0;

  // NOVO: título atual de cada grupo, por id. Ver comentário no topo
  // do arquivo.
  final Map<int, String> _gruposTitulos = {};

  late final TextEditingController _nomeController =
      TextEditingController(text: widget.item.nome);
  late final TextEditingController _precoController =
      TextEditingController(text: widget.item.preco);

  String _letraDoGrupo(int indice) => String.fromCharCode(65 + indice);

  void _adicionarGrupo() {
    setState(() {
      final id = _proximoIdGrupo;
      // A letra automática só é usada como valor INICIAL do título,
      // calculada a partir de quantos grupos já existem agora. Depois
      // de criado, o título vive independente em _gruposTitulos e só
      // muda se o usuário editar o campo.
      _gruposTitulos[id] = 'Grupo de componentes ${_letraDoGrupo(_grupoIds.length)}';
      _grupoIds.add(id);
      _proximoIdGrupo++;
    });
  }

  void _removerGrupo(int id) {
    setState(() {
      _grupoIds.remove(id);
      _gruposTitulos.remove(id);
    });
  }

  void _renomearGrupo(int id, String novoTitulo) {
    // Não precisa de setState aqui: o TextField do
    // GrupoComponentesContainer já mostra o texto digitado sozinho
    // (via seu próprio controller). Isso só mantém _gruposTitulos
    // sincronizado, pra caso a lista precise ser reconstruída (ex:
    // outro grupo é excluído) e o título customizado não se perca.
    _gruposTitulos[id] = novoTitulo;
  }

  @override
  void didUpdateWidget(covariant ProdutoLojaRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o nome/preço deste item mudou por FORA desta linha (por
    // exemplo, editado no card da lista "Itens", ou pelo popup
    // "Editar Item"), atualiza o texto mostrado aqui também.
    if (widget.item.nome != oldWidget.item.nome &&
        widget.item.nome != _nomeController.text) {
      _nomeController.text = widget.item.nome;
    }
    if (widget.item.preco != oldWidget.item.preco &&
        widget.item.preco != _precoController.text) {
      _precoController.text = widget.item.preco;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _abrirMenuOpcoes(BuildContext context, Offset posicaoToque) async {
    final theme = widget.theme;

    final selecionado = await showMenu<String>(
      context: context,
      color: theme.cardBackgroundColor,
      position: RelativeRect.fromLTRB(
        posicaoToque.dx,
        posicaoToque.dy,
        posicaoToque.dx,
        posicaoToque.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'editar',
          child: Text('Editar Item', style: theme.getTextStyle()),
        ),
        PopupMenuItem(
          value: 'grupo',
          child: Text('Adicionar Grupo de Componentes',
              style: theme.getTextStyle()),
        ),
        PopupMenuItem(
          value: 'excluir',
          child: Text('Excluir Produto', style: theme.getTextStyle()),
        ),
      ],
    );

    if (selecionado == 'editar') widget.onEditar();
    if (selecionado == 'grupo') _adicionarGrupo();
    if (selecionado == 'excluir') widget.onExcluir();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6)),
                ),
                child: Icon(Icons.image_outlined,
                    size: 18, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nomeController,
                  maxLines: 1,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onNomeAlterado,
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _ativo,
                  activeThumbColor: theme.buttonColor,
                  onChanged: (valor) => setState(() => _ativo = valor),
                ),
              ),
              SizedBox(
                width: 66,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$',
                      style: theme.getTextStyle(fontSize: 11),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _precoController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: theme.getTextStyle(fontSize: 11),
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
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _expandido = !_expandido),
                child: Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTapDown: (details) =>
                    _abrirMenuOpcoes(context, details.globalPosition),
                child: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (_expandido && _grupoIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final id in _grupoIds) ...[
              GrupoComponentesContainer(
                key: ValueKey('grupo_$id'),
                theme: theme,
                // ALTERADO: era "_letraDoGrupo(_grupoIds.indexOf(id))"
                // calculado direto aqui; agora lê o título atual (que
                // pode já ter sido editado pelo usuário) de
                // _gruposTitulos, com a letra automática só como
                // último recurso de segurança.
                titulo: _gruposTitulos[id] ??
                    'Grupo de componentes ${_letraDoGrupo(_grupoIds.indexOf(id))}',
                onTituloAlterado: (novoTitulo) =>
                    _renomearGrupo(id, novoTitulo),
                onExcluir: () => _removerGrupo(id),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}