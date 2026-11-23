import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';

class DialogCriarGrupo {
  static void mostrar(
    BuildContext context, {
    required AppTheme theme,
    required Map<String, String> participantesDisponiveis,
    required String? lojaId,
    required String? criadorCpf,
    required String? criadorNome,
    required void Function(ConversaChat grupoCriado) onCriado,
  }) {
    final TextEditingController nomeGrupoController = TextEditingController();
    final Set<String> selecionados = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group_add_outlined,
                            color: theme.textColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Novo Grupo',
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: theme.secondaryTextColor,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    TextField(
                      controller: nomeGrupoController,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome do Grupo',
                        labelStyle: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        hintText: 'Ex: Equipe de Atendimento, Financeiro...',
                        hintStyle: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Selecione os Participantes (${selecionados.length} selecionados):',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: participantesDisponiveis.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Nenhum membro ou contato disponível.',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: participantesDisponiveis.length,
                              itemBuilder: (context, index) {
                                final cpf = participantesDisponiveis.keys
                                    .elementAt(index);
                                final nome = participantesDisponiveis.values
                                    .elementAt(index);
                                final selecionado = selecionados.contains(cpf);

                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    nome,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: selecionado
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    cpf,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                  value: selecionado,
                                  activeColor: theme.buttonColor,
                                  checkColor: theme.buttonTextColor,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selecionados.add(cpf);
                                      } else {
                                        selecionados.remove(cpf);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancelar',
                            style: theme.getTextStyle(
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final nomeGrupo = nomeGrupoController.text.trim();
                            if (nomeGrupo.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Informe o nome do grupo.'),
                                ),
                              );
                              return;
                            }
                            if (selecionados.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Selecione pelo menos 1 participante.'),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(ctx);
                            final todosParticipantes = {...selecionados};
                            if (criadorCpf != null && criadorCpf.isNotEmpty) {
                              todosParticipantes.add(criadorCpf);
                            }

                            final grupoCriado = await ChatService.criarGrupo(
                              nome: nomeGrupo,
                              membrosCpfs: todosParticipantes.toList(),
                              autorCpf: criadorCpf ?? '',
                              autorNome: criadorNome ?? 'Usuário',
                              lojaOrigemId: lojaId,
                            );

                            onCriado(grupoCriado);
                          },
                          child: const Text('Criar Grupo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }
}
