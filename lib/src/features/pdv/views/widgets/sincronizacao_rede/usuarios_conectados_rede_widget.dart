import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class UsuariosConectadosRedeWidget extends StatefulWidget {
  final AppTheme theme;
  final ClienteRedeLocal cliente;
  final TextEditingController buscaController;

  const UsuariosConectadosRedeWidget({
    super.key,
    required this.theme,
    required this.cliente,
    required this.buscaController,
  });

  @override
  State<UsuariosConectadosRedeWidget> createState() =>
      _UsuariosConectadosRedeWidgetState();
}

class _UsuariosConectadosRedeWidgetState
    extends State<UsuariosConectadosRedeWidget> {
  AppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: ValueListenableBuilder<List<TerminalConectadoInfo>>(
        valueListenable: widget.cliente.presencasAtivas,
        builder: (context, presencas, _) {
          final termo =
              widget.buscaController.text.trim().toLowerCase();
          final termoSemArroba =
              termo.startsWith('@') ? termo.substring(1) : termo;
          final termoDigitos = termo.replaceAll(RegExp(r'\D'), '');

          final listaFiltrada = presencas.where((p) {
            if (termo.isEmpty) return true;
            final nome = p.nomeUsuario ?? p.nome;
            final apelido = p.apelido ?? '';
            final cpf = p.cpf ?? '';

            if (nome.toLowerCase().contains(termo)) return true;
            if (apelido.toLowerCase().contains(termoSemArroba)) return true;
            if (termoDigitos.isNotEmpty &&
                cpf.replaceAll(RegExp(r'\D'), '').contains(termoDigitos)) {
              return true;
            }
            return false;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.hub_rounded, size: 18, color: theme.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'UsuÃ¡rios Conectados na Rede:',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.buscaController,
                onChanged: (_) => setState(() {}),
                style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Pesquisar por nome, @username ou CPF...',
                  hintStyle: theme.getTextStyle(
                      fontSize: 11, color: theme.secondaryTextColor),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 16, color: theme.secondaryTextColor),
                  suffixIcon: widget.buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 14, color: theme.secondaryTextColor),
                          onPressed: () {
                            widget.buscaController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.cardBackgroundColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.buttonColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${presencas.length} online na rede',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (listaFiltrada.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    presencas.isEmpty
                        ? 'Nenhum outro usuÃ¡rio detectado na rede atÃ© o momento.'
                        : 'Nenhum usuÃ¡rio encontrado para a busca "$termo".',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              else
                Column(
                  children: listaFiltrada.map((term) {
                    final nomeExibicao = term.nomeUsuario ?? term.nome;
                    final temApelido =
                        term.apelido != null && term.apelido!.trim().isNotEmpty;
                    final temCpf =
                        term.cpf != null && term.cpf!.trim().isNotEmpty;
                    final hora =
                        '${term.conectadoEm.hour.toString().padLeft(2, '0')}:${term.conectadoEm.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                theme.buttonColor.withValues(alpha: 0.15),
                            child: Icon(
                              term.ehHost
                                  ? Icons.desktop_windows_rounded
                                  : Icons.person_rounded,
                              size: 15,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextoRolante(
                                        texto: nomeExibicao,
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                    if (term.ehHost)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        margin:
                                            const EdgeInsets.only(left: 6),
                                        decoration: BoxDecoration(
                                          color: theme.buttonColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Host',
                                          style: theme.getTextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: theme.buttonColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextoRolante(
                                        texto: [
                                          if (temApelido) '@${term.apelido}',
                                          if (temCpf) CpfValidator.formatProtegido(term.cpf!),
                                        ].join(' • '),
                                        style: theme.getTextStyle(
                                          fontSize: 10,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      hora,
                                      style: theme.getTextStyle(
                                        fontSize: 9,
                                        color: theme.secondaryTextColor
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (temCpf)
                            IconButton(
                              tooltip: 'Ver Ficha do UsuÃ¡rio',
                              icon: Icon(Icons.info_outline_rounded,
                                  size: 16, color: theme.secondaryTextColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final auth = context.read<AuthProvider>();
                                final conta = await ContasNousService
                                    .buscarPorCpf(term.cpf!);
                                if (!context.mounted) return;
                                final usuarioParaAbrir = conta ??
                                    UsuarioNous(
                                      cpf: term.cpf!,
                                      nome: term.nomeUsuario ?? term.nome,
                                      apelido: term.apelido ?? '',
                                      dataNascimento: '',
                                    );
                                FichaUsuarioDialog.mostrar(
                                  context,
                                  usuario: usuarioParaAbrir,
                                  theme: theme,
                                  somenteLeitura: term.cpf != auth.cpf,
                                );
                              },
                            ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
