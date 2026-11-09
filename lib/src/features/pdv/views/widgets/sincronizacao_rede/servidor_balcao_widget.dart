import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class ServidorBalcaoWidget extends StatelessWidget {
  final AppTheme theme;
  final ServidorRedeLocal servidor;
  final Loja? loja;
  final String perfilHostSelecionado;
  final ValueChanged<String> onPerfilHostChanged;
  final ValueChanged<bool> onAlternarServidor;

  const ServidorBalcaoWidget({
    super.key,
    required this.theme,
    required this.servidor,
    required this.loja,
    required this.perfilHostSelecionado,
    required this.onPerfilHostChanged,
    required this.onAlternarServidor,
  });

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final auth = context.watch<AuthProvider>();

    final nomeUsuario = auth.contaAtual?.nomeExibicao.isNotEmpty == true
        ? auth.contaAtual!.nomeExibicao
        : (auth.contaAtual?.nome.isNotEmpty == true
            ? auth.contaAtual!.nome
            : 'Usuário Nous');

    return ValueListenableBuilder<bool>(
      valueListenable: servidor.estaAtivo,
      builder: (context, ativo, _) {
        final lojaAtiva = servidor.lojaAtiva;
        final nomeHostAtivo = (lojaAtiva != null &&
                !LojasService.ehLojaHostFalsa(
                    lojaAtiva.id, lojaAtiva.tags, lojaAtiva.nome))
            ? 'Loja "${lojaAtiva.nome}"'
            : 'Usuário Nous ($nomeUsuario)';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        ativo
                            ? Icons.wifi_tethering_rounded
                            : Icons.wifi_tethering_off_rounded,
                        color: ativo
                            ? Colors.greenAccent
                            : theme.secondaryTextColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ativo ? 'Servidor Ativo' : 'Servidor Desativado',
                              style: theme.getTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ativo
                                  ? 'Transmitindo na rede como "$nomeHostAtivo"'
                                  : 'Ative para permitir conexões de celulares',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: ativo,
                        onChanged: onAlternarServidor,
                        activeThumbColor: theme.textColor,
                        activeTrackColor:
                            theme.borderColor.withValues(alpha: 0.5),
                        inactiveThumbColor: theme.secondaryTextColor,
                        inactiveTrackColor: Colors.transparent,
                        trackOutlineColor:
                            WidgetStateProperty.all(theme.borderColor),
                      ),
                    ],
                  ),
                  if (!ativo && loja == null) ...[
                    const SizedBox(height: 12),
                    Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 16, color: theme.secondaryTextColor),
                        const SizedBox(width: 6),
                        Text(
                          'Transmitir na rede como:',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: perfilHostSelecionado,
                          isExpanded: true,
                          dropdownColor: theme.cardBackgroundColor,
                          style: theme.getTextStyle(
                              fontSize: 13, color: theme.textColor),
                          items: [
                            DropdownMenuItem(
                              value: 'host_usuario',
                              child: Text('👤 Usuário Nous ($nomeUsuario)'),
                            ),
                            ...pdv.lojas
                                .where((l) =>
                                    !LojasService.ehLojaHostFalsa(
                                        l.id, l.tags, l.nome) &&
                                    l.id != PdvProvider.idLojaColetivaNous)
                                .map(
                              (l) => DropdownMenuItem(
                                value: l.id,
                                child: Text('🏬 Loja: ${l.nome}'),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              onPerfilHostChanged(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  if (ativo) ...[
                    const SizedBox(height: 14),
                    Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Endereço de Conexão:',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${servidor.ipServidor}:${servidor.porta}',
                              style: theme.getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${servidor.ipServidor}:${servidor.porta}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Endereço copiado!')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copiar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.borderColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<List<TerminalConectadoInfo>>(
                      valueListenable: servidor.terminaisConectados,
                      builder: (context, terminais, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Terminais Pareados (${terminais.length}):',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (terminais.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Ativo',
                                      style: theme.getTextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (terminais.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.textColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Nenhum celular ou terminal móvel conectado no momento.',
                                    textAlign: TextAlign.center,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: terminais.map((term) {
                                  final hora =
                                      '${term.conectadoEm.hour.toString().padLeft(2, '0')}:${term.conectadoEm.minute.toString().padLeft(2, '0')}';
                                  final ehBalcao =
                                      term.id == 'balcao_servidor_local';
                                  final temUsuario = term.nomeUsuario != null &&
                                      term.nomeUsuario!.trim().isNotEmpty;
                                  final temCpf = term.cpf != null &&
                                      term.cpf!.trim().isNotEmpty;
                                  final temApelido = term.apelido != null &&
                                      term.apelido!.trim().isNotEmpty;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.textColor
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.borderColor
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ehBalcao
                                              ? Icons.desktop_windows_rounded
                                              : Icons.smartphone_rounded,
                                          size: 22,
                                          color: Colors.greenAccent,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      term.nome,
                                                      style: theme.getTextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: theme.textColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '• ${term.ip}',
                                                    style: theme.getTextStyle(
                                                      fontSize: 11,
                                                      color: theme
                                                          .secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (temUsuario || temCpf) ...[
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .person_outline_rounded,
                                                        size: 12,
                                                        color: theme
                                                            .secondaryTextColor),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            if (temUsuario)
                                                              TextSpan(
                                                                text: term
                                                                    .nomeUsuario!,
                                                                style: theme
                                                                    .getTextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: theme
                                                                      .textColor,
                                                                ),
                                                              ),
                                                            if (temApelido)
                                                              TextSpan(
                                                                text:
                                                                    ' (@${term.apelido})',
                                                                style: theme
                                                                    .getTextStyle(
                                                                  fontSize: 11,
                                                                  color: theme
                                                                      .secondaryTextColor,
                                                                ),
                                                              ),
                                                            if (temCpf)
                                                              TextSpan(
                                                                text:
                                                                    ' • CPF: ${CpfValidator.formatProtegido(term.cpf!)}',
                                                                style: theme
                                                                    .getTextStyle(
                                                                  fontSize: 11,
                                                                  color: theme
                                                                      .secondaryTextColor,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 2),
                                              Text(
                                                'Conectado às $hora',
                                                style: theme.getTextStyle(
                                                  fontSize: 10,
                                                  color: theme
                                                      .secondaryTextColor
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (temCpf)
                                          IconButton(
                                            tooltip:
                                                'Ver Identidade do Membro',
                                            icon: Icon(
                                                Icons.info_outline_rounded,
                                                size: 18,
                                                color:
                                                    theme.secondaryTextColor),
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () async {
                                              final auth =
                                                  context.read<AuthProvider>();
                                              final conta =
                                                  await ContasNousService
                                                      .buscarPorCpf(term.cpf!);
                                              if (!context.mounted) return;
                                              final usuarioParaAbrir = conta ??
                                                  UsuarioNous(
                                                    cpf: term.cpf!,
                                                    nome: term.nomeUsuario ??
                                                        term.nome,
                                                    apelido: term.apelido ?? '',
                                                    dataNascimento: '',
                                                  );
                                              FichaUsuarioDialog.mostrar(
                                                context,
                                                usuario: usuarioParaAbrir,
                                                theme: theme,
                                                somenteLeitura:
                                                    term.cpf != auth.cpf,
                                              );
                                            },
                                          ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
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
                            _secaoDispositivosNaoPareados(context, theme, terminais),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dica: Mantenha este computador ligado e conectado ao mesmo roteador Wi-Fi dos celulares para garantir a sincronização instantânea de pedidos e estoque.',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _secaoDispositivosNaoPareados(
    BuildContext context,
    AppTheme theme,
    List<TerminalConectadoInfo> pareados,
  ) {
    return ValueListenableBuilder<List<TerminalConectadoInfo>>(
      valueListenable: servidor.terminaisHistorico,
      builder: (context, historico, _) {
        final ipsPareados = pareados.map((p) => p.ip).toSet();
        final idsPareados = pareados.map((p) => p.id).toSet();

        final todosCandidatos = [
          ...historico,
          ...ClienteRedeLocal().presencasAtivas.value,
        ];

        final naoPareados = <TerminalConectadoInfo>[];
        final ipsVistos = <String>{};

        for (final p in todosCandidatos) {
          if (p.id == 'balcao_servidor_local' || p.id == 'este_dispositivo') {
            continue;
          }
          if (idsPareados.contains(p.id) || ipsPareados.contains(p.ip)) {
            continue;
          }
          if (!ipsVistos.add(p.ip)) {
            continue;
          }
          naoPareados.add(p);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.devices_other_rounded,
                  size: 16,
                  color: theme.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Outros Dispositivos na Rede (Não Pareados):',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${naoPareados.length}',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (naoPareados.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.textColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nenhum outro dispositivo não pareado detectado na rede no momento.',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              )
            else
              Column(
                children: naoPareados.map((term) {
                  final temUsuario = term.nomeUsuario != null && term.nomeUsuario!.trim().isNotEmpty;
                  final nomeDisp = temUsuario ? '${term.nome} (${term.nomeUsuario})' : term.nome;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.textColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.perm_device_information_rounded,
                          size: 20,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextoRolante(
                                texto: nomeDisp,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'IP: ${term.ip} • Desconectado (Nous Fechado ou Fora do Alcance)',
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
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
    );
  }
}
