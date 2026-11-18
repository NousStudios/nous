import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

class DialogSalvarPublicacao extends StatefulWidget {
  final AppTheme theme;
  final String usuarioCpf;
  final String publicacaoId;

  const DialogSalvarPublicacao({
    super.key,
    required this.theme,
    required this.usuarioCpf,
    required this.publicacaoId,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String usuarioCpf,
    required String publicacaoId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DialogSalvarPublicacao(
        theme: theme,
        usuarioCpf: usuarioCpf,
        publicacaoId: publicacaoId,
      ),
    );
  }

  @override
  State<DialogSalvarPublicacao> createState() => _DialogSalvarPublicacaoState();
}

class _DialogSalvarPublicacaoState extends State<DialogSalvarPublicacao> {
  final TextEditingController _novaListaCtrl = TextEditingController();
  final TextEditingController _buscaColabCtrl = TextEditingController();

  List<ListaSalvosSocial> _listas = [];
  List<UsuarioNous> _todosUsuarios = [];
  final List<UsuarioNous> _colabsSelecionados = [];
  VisibilidadeListaSalvos _visibilidade = VisibilidadeListaSalvos.privada;
  bool _criandoNova = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _novaListaCtrl.dispose();
    _buscaColabCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    await TimelineService.obterOuCriarListaPadraoSalvos(widget.usuarioCpf);
    final listas = await TimelineService.listarListasSalvos(widget.usuarioCpf);
    final users = await ContasNousService.carregarTodas();
    final meuNorm = widget.usuarioCpf.replaceAll(RegExp(r'\D'), '');
    if (!mounted) return;
    setState(() {
      _listas = listas;
      _todosUsuarios = users
          .where((u) => u.cpf.replaceAll(RegExp(r'\D'), '') != meuNorm)
          .toList();
    });
  }

  Future<void> _salvarNaLista(ListaSalvosSocial lista) async {
    await TimelineService.salvarPublicacaoEmLista(
      listaId: lista.id,
      usuarioCpf: widget.usuarioCpf,
      publicacaoId: widget.publicacaoId,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _criarESalvar() async {
    final nome = _novaListaCtrl.text.trim();
    if (nome.isEmpty) return;
    final nova = await TimelineService.criarListaSalvos(
      donoCpf: widget.usuarioCpf,
      nome: nome,
      visibilidade: _visibilidade,
      colaboradoresCpfs: _colabsSelecionados.map((u) => u.cpf).toList(),
    );
    await _salvarNaLista(nova);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final filtro = _buscaColabCtrl.text.trim().toLowerCase();
    final sugestoes = filtro.isEmpty
        ? const <UsuarioNous>[]
        : _todosUsuarios
            .where((u) =>
                u.nomeExibicao.toLowerCase().contains(filtro) ||
                u.usernameExibicao.toLowerCase().contains(filtro))
            .take(5)
            .toList();

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Salvar Publicação',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              for (final lista in _listas)
                ListTile(
                  leading: Icon(
                    lista.visibilidade == VisibilidadeListaSalvos.publicaFeed
                        ? Icons.public_rounded
                        : lista.visibilidade ==
                                VisibilidadeListaSalvos.colaboradores
                            ? Icons.group_outlined
                            : Icons.lock_outline_rounded,
                    color: theme.buttonColor,
                  ),
                  title: Text(
                    lista.nome,
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    lista.visibilidade == VisibilidadeListaSalvos.publicaFeed
                        ? 'Aparece na timeline Conteúdos Salvos'
                        : lista.visibilidade ==
                                VisibilidadeListaSalvos.colaboradores
                            ? 'Compartilhada com colaboradores'
                            : 'Lista privada',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () => _salvarNaLista(lista),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _criandoNova = !_criandoNova),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Criar nova lista'),
              ),
              if (_criandoNova) ...[
                const SizedBox(height: 12),
                ThemedTextField(
                  theme: theme,
                  controller: _novaListaCtrl,
                  label: 'Nome da nova lista',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Privada'),
                      selected:
                          _visibilidade == VisibilidadeListaSalvos.privada,
                      onSelected: (_) => setState(
                        () => _visibilidade = VisibilidadeListaSalvos.privada,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Colaboradores'),
                      selected: _visibilidade ==
                          VisibilidadeListaSalvos.colaboradores,
                      onSelected: (_) => setState(
                        () => _visibilidade =
                            VisibilidadeListaSalvos.colaboradores,
                      ),
                    ),
                  ],
                ),
                if (_visibilidade == VisibilidadeListaSalvos.colaboradores) ...[
                  const SizedBox(height: 8),
                  ThemedTextField(
                    theme: theme,
                    controller: _buscaColabCtrl,
                    label: 'Adicionar colaborador (@ ou nome)',
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_colabsSelecionados.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: _colabsSelecionados
                          .map(
                            (u) => Chip(
                              label: Text(u.nomeExibicao),
                              onDeleted: () => setState(
                                () => _colabsSelecionados.remove(u),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  if (sugestoes.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: sugestoes
                          .map(
                            (u) => ActionChip(
                              label: Text('+ ${u.nomeExibicao}'),
                              onPressed: () => setState(() {
                                if (!_colabsSelecionados.any(
                                  (c) => c.cpf == u.cpf,
                                )) {
                                  _colabsSelecionados.add(u);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                  ),
                  onPressed: _criarESalvar,
                  child: const Text('Criar e Salvar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
