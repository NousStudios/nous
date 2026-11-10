import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/resolvedor_foto_chat.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final filtradas = widget.controller.obterConversasFiltradas();

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

        // Lista de chats
        Expanded(
          child: filtradas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.controller.termoBusca.isEmpty
                          ? 'Nenhuma conversa iniciada.'
                          : 'Nenhum resultado encontrado.',
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
                      onRenomear: () => widget.onRenomearConversa(conversa),
                      onTap: () => widget.onSelecionarConversa(conversa),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
