import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/filtro_chat_personalizado.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_atribuir_filtro_chat.dart';
import 'package:nous/src/features/chat/views/widgets/barra_filtros_chat_widget.dart';
import 'package:nous/src/features/chat/views/widgets/barra_stories_mensageria_widget.dart';
import 'package:nous/src/features/chat/views/widgets/item_conversa_tile.dart';

class ListaConversasWidget extends StatefulWidget {
  final MensageriaController controller;
  final AppTheme theme;
  final VoidCallback onAbrirNovaConversa;
  final VoidCallback onAbrirCriarGrupo;
  final void Function(ConversaChat) onSelecionarConversa;
  final void Function(ConversaChat) onAlternarFixar;
  final void Function(ConversaChat) onAlternarArquivar;
  final void Function(ConversaChat) onAlternarSilenciar;
  final void Function(ConversaChat) onRenomearConversa;
  final void Function(ConversaChat)? onExcluirConversa;

  const ListaConversasWidget({
    super.key,
    required this.controller,
    required this.theme,
    required this.onAbrirNovaConversa,
    required this.onAbrirCriarGrupo,
    required this.onSelecionarConversa,
    required this.onAlternarFixar,
    required this.onAlternarArquivar,
    required this.onAlternarSilenciar,
    required this.onRenomearConversa,
    this.onExcluirConversa,
  });

  @override
  State<ListaConversasWidget> createState() => _ListaConversasWidgetState();
}

class _ListaConversasWidgetState extends State<ListaConversasWidget> {
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buscaController.text = widget.controller.termoBusca;
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _formatarHora(DateTime dataHora) {
    final local = dataHora.toLocal();
    final hora = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  Future<void> _abrirCriarFiltro(AppTheme theme) async {
    final nome = await DialogAtribuirFiltroChat.mostrarCriarOuRenomear(
      context,
      theme: theme,
    );
    if (nome != null && nome.isNotEmpty) {
      await widget.controller.criarFiltroPersonalizado(nome);
    }
  }

  Future<void> _abrirGerenciarFiltro(
    AppTheme theme,
    FiltroChatPersonalizado filtro,
  ) async {
    final acao = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: Text(
          'Filtro "${filtro.nome}"',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja renomear ou excluir este filtro personalizado?',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'excluir'),
            child: Text(
              'Excluir',
              style: theme.getTextStyle(
                color: theme.dangerColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'renomear'),
            child: Text(
              'Renomear',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (acao == 'excluir') {
      await widget.controller.excluirFiltroPersonalizado(filtro.id);
    } else if (acao == 'renomear') {
      final novoNome = await DialogAtribuirFiltroChat.mostrarCriarOuRenomear(
        context,
        theme: theme,
        nomeInicial: filtro.nome,
      );
      if (novoNome != null && novoNome.isNotEmpty) {
        await widget.controller.renomearFiltroPersonalizado(filtro, novoNome);
      }
    }
  }

  Future<void> _abrirAtribuirFiltro(
    AppTheme theme,
    ConversaChat conversa,
  ) async {
    await DialogAtribuirFiltroChat.mostrarAtribuirConversa(
      context,
      theme: theme,
      conversa: conversa,
      filtros: widget.controller.filtrosPersonalizados,
      onAlternarFiltro: (filtroId) => widget.controller.alternarConversaNoFiltro(
        filtroId: filtroId,
        conversaId: conversa.id,
      ),
      onCriarEAtribuir: (nome) async {
        final novo = await widget.controller.criarFiltroPersonalizado(nome);
        await widget.controller.alternarConversaNoFiltro(
          filtroId: novo.id,
          conversaId: conversa.id,
        );
        return novo;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final auth = context.watch<AuthProvider>();
    final contaLogada = auth.contaAtual;
    final filtradas =
        widget.controller.obterConversasFiltradas(contaLogada: contaLogada);
    final totalSolicitacoes =
        widget.controller.totalSolicitacoes(contaLogada: contaLogada);
    final emSolicitacoes = widget.controller.exibindoSolicitacoes;

    return Column(
      children: [
        // Topo com Barra de Busca e Botões
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _buscaController,
                    onChanged: (val) {
                      widget.controller.atualizarTermoBusca(val);
                      setState(() {});
                    },
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar contatos ou lojas...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: theme.secondaryTextColor,
                      ),
                      suffixIcon: _buscaController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: theme.secondaryTextColor,
                              ),
                              onPressed: () {
                                _buscaController.clear();
                                widget.controller.atualizarTermoBusca('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Nova Conversa',
                child: InkWell(
                  onTap: widget.onAbrirNovaConversa,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(Icons.add, size: 22, color: theme.textColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Criar Novo Grupo',
                child: InkWell(
                  onTap: widget.onAbrirCriarGrupo,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.group_add_outlined,
                      size: 20,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filtros rápidos e personalizados acima da lista de conversas
        if (!emSolicitacoes) ...[
          BarraFiltrosChatWidget(
            theme: theme,
            filtroAtivo: widget.controller.filtroAtivo,
            filtroPersonalizadoId: widget.controller.filtroPersonalizadoId,
            filtrosPersonalizados: widget.controller.filtrosPersonalizados,
            totalNaoLidas: widget.controller.totalConversasNaoLidas,
            onSelecionarFiltro: (tipo, {personalizadoId}) =>
                widget.controller.selecionarFiltro(
                  tipo,
                  personalizadoId: personalizadoId,
                ),
            onCriarFiltro: () => _abrirCriarFiltro(theme),
            onGerenciarFiltro: (f) => _abrirGerenciarFiltro(theme, f),
          ),
          const SizedBox(height: 6),
        ],

        // Cabeçalho de Navegação de Solicitações (quando dentro da aba)
        if (emSolicitacoes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 20, color: theme.textColor),
                  onPressed: () =>
                      widget.controller.alternarExibindoSolicitacoes(false),
                  tooltip: 'Voltar para todas as conversas',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextoRolante(
                        texto: 'Solicitações de Mensagens',
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      TextoRolante(
                        texto: 'Pessoas que você não segue',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Barra horizontal de stories não vistos acima de Solicitações de Mensagens
        if (!widget.controller.modoLoja && !emSolicitacoes)
          BarraStoriesMensageriaWidget(theme: theme),

        // Banner estilo Instagram para Acessar Solicitações (oculto quando vazio)
        if (!widget.controller.modoLoja &&
            !emSolicitacoes &&
            totalSolicitacoes > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: () => widget.controller.alternarExibindoSolicitacoes(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.textColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 16,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextoRolante(
                            texto: 'Solicitações de Mensagens',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          TextoRolante(
                            texto: totalSolicitacoes == 0
                                ? 'Nenhuma solicitação pendente'
                                : totalSolicitacoes == 1
                                    ? '1 pessoa quer te enviar mensagem'
                                    : '$totalSolicitacoes pessoas querem te enviar mensagens',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalSolicitacoes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.textColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalSolicitacoes',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.backgroundColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Lista de chats
        Expanded(
          child: (widget.controller.carregando && filtradas.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Carregando conversas...',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : filtradas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      emSolicitacoes
                          ? 'Nenhuma solicitação de mensagem pendente.'
                          : (widget.controller.termoBusca.isEmpty
                              ? 'Nenhuma conversa iniciada.'
                              : 'Nenhum resultado encontrado.'),
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filtradas.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final conversa = filtradas[index];
                    final selecionada =
                        widget.controller.conversaSelecionada?.id ==
                        conversa.id;

                    return ItemConversaTile(
                      conversa: conversa,
                      selecionada: selecionada,
                      theme: theme,
                      avatar: ResolvedorFotoChat.instancia.buildAvatar(
                        context,
                        theme: theme,
                        conversa: conversa,
                      ),
                      horaFormatada: _formatarHora(
                        conversa.dataHoraUltimaMensagem,
                      ),
                      onAlternarFixar: () => widget.onAlternarFixar(conversa),
                      onAlternarArquivar: () =>
                          widget.onAlternarArquivar(conversa),
                      onAlternarSilenciar: () =>
                          widget.onAlternarSilenciar(conversa),
                      onAlternarFavorita: () =>
                          widget.controller.alternarFavoritaConversa(conversa),
                      onAtribuirFiltro: () =>
                          _abrirAtribuirFiltro(theme, conversa),
                      onRenomear: () => widget.onRenomearConversa(conversa),
                      onExcluir: widget.onExcluirConversa != null
                          ? () => widget.onExcluirConversa!(conversa)
                          : null,
                      onTap: () => widget.onSelecionarConversa(conversa),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
