import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede/usuarios_conectados_rede_widget.dart';

class ClienteTerminalWidget extends StatelessWidget {
  final AppTheme theme;
  final ClienteRedeLocal cliente;
  final ServidorRedeLocal servidor;
  final TextEditingController nomeTerminalController;
  final TextEditingController ipManualController;
  final TextEditingController portaManualController;
  final TextEditingController buscaUsuariosClienteController;
  final bool conectando;
  final VoidCallback onDesconectar;
  final void Function(String ip, int porta) onConectar;

  const ClienteTerminalWidget({
    super.key,
    required this.theme,
    required this.cliente,
    required this.servidor,
    required this.nomeTerminalController,
    required this.ipManualController,
    required this.portaManualController,
    required this.buscaUsuariosClienteController,
    required this.conectando,
    required this.onDesconectar,
    required this.onConectar,
  });

  Widget _buildCardNomeDispositivo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nome deste Aparelho no Balcão:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: nomeTerminalController,
                  label: 'Identificação do Celular',
                  onChanged: (val) {
                    cliente.salvarNomeDispositivo(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  cliente.salvarNomeDispositivo(nomeTerminalController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome do aparelho salvo!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (servidor.ativo) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Icon(Icons.desktop_windows_rounded,
                size: 40, color: theme.textColor),
            const SizedBox(height: 12),
            Text(
              'Este Computador é o Servidor Balcão',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O servidor central da loja já está ativo e operando nesta máquina. Não é necessário conectar este computador como terminal móvel.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCardNomeDispositivo(context),
        ValueListenableBuilder<bool>(
          valueListenable: cliente.estaConectado,
          builder: (context, conectado, _) {
            if (conectado) {
              final lojaSinc = cliente.lojaSincronizada;
              final temLoja = lojaSinc != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          temLoja
                              ? Icons.storefront_rounded
                              : Icons.person_rounded,
                          size: 34,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          temLoja
                              ? 'Conectado à Loja "${lojaSinc.nome}"'
                              : 'Conectado em Modo Usuário Nous',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Endereço do Servidor: ${cliente.enderecoServidor ?? "Rede Local"}',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final auth = context.watch<AuthProvider>();
                            final conta = auth.contaAtual;
                            final nome = conta?.nome ?? 'Usuário Nous';
                            final apelido = conta?.apelido;
                            final temApelido =
                                apelido != null && apelido.trim().isNotEmpty;
                            final cpf = CpfValidator.format(auth.cpf);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.textColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 16,
                                      color: theme.secondaryTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Operador deste aparelho: ',
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: nome,
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          if (temApelido)
                                            TextSpan(
                                              text: ' (@$apelido)',
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                color: theme.secondaryTextColor,
                                              ),
                                            ),
                                          TextSpan(
                                            text: ' • $cpf',
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: onDesconectar,
                          icon: Icon(Icons.link_off_rounded,
                              size: 16, color: theme.dangerColor),
                          label: Text(
                            'Desconectar do Balcão',
                            style: TextStyle(color: theme.dangerColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dangerColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  UsuariosConectadosRedeWidget(
                    theme: theme,
                    cliente: cliente,
                    buscaController: buscaUsuariosClienteController,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hosts e Lojas encontrados no Wi-Fi:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<DispositivoLojaInfo>>(
                  valueListenable: cliente.lojasEncontradas,
                  builder: (context, lojas, _) {
                    if (lojas.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Procurando balcões no Wi-Fi...',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: lojas.map((info) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    theme.borderColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                info.ehUsuario
                                    ? Icons.person_rounded
                                    : Icons.storefront_rounded,
                                color: info.ehUsuario
                                    ? Colors.blueAccent
                                    : Colors.greenAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info.lojaNome,
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    Text(
                                      info.ehUsuario
                                          ? 'Host Pessoal (Usuário Nous) • ${info.enderecoCompleto}'
                                          : 'Balcão Loja • ${info.enderecoCompleto}',
                                      style: theme.getTextStyle(
                                        fontSize: 11,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: conectando
                                    ? null
                                    : () => onConectar(info.ip, info.porta),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.buttonColor,
                                  foregroundColor: theme.buttonTextColor,
                                ),
                                child: conectando
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Conectar'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  'Conectar Manualmente por IP:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ThemedTextField(
                        theme: theme,
                        controller: ipManualController,
                        label: 'Endereço IP (ex: 192.168.0.100)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ThemedTextField(
                        theme: theme,
                        controller: portaManualController,
                        label: 'Porta',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: conectando
                      ? null
                      : () {
                          final ip = ipManualController.text.trim();
                          final porta =
                              int.tryParse(portaManualController.text.trim()) ??
                                  8080;
                          if (ip.isNotEmpty) {
                            onConectar(ip, porta);
                          }
                        },
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: conectando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Conectar ao Endereço'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
