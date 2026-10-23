import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:provider/provider.dart';

class SincronizacaoRedeDialog extends StatefulWidget {
  final Loja? loja;
  final AppTheme theme;
  final bool modoLogin;

  const SincronizacaoRedeDialog({
    super.key,
    this.loja,
    required this.theme,
    this.modoLogin = false,
  });

  static Future<void> mostrar(
    BuildContext context, {
    Loja? loja,
    AppTheme? theme,
    bool modoLogin = false,
  }) {
    final t = theme ?? ThemeController.currentTheme.value;
    return showDialog<void>(
      context: context,
      builder: (ctx) => SincronizacaoRedeDialog(
        loja: loja,
        theme: t,
        modoLogin: modoLogin,
      ),
    );
  }

  @override
  State<SincronizacaoRedeDialog> createState() => _SincronizacaoRedeDialogState();
}

class _SincronizacaoRedeDialogState extends State<SincronizacaoRedeDialog> {
  final _servidor = ServidorRedeLocal();
  final _cliente = ClienteRedeLocal();

  late TextEditingController _ipManualController;
  late TextEditingController _portaManualController;
  late TextEditingController _nomeTerminalController;

  int _abaSelecionada = 0; // 0: Balcão (Servidor), 1: Celular (Cliente)
  bool _conectando = false;
  String? _mensagemStatus;

  @override
  void initState() {
    super.initState();
    _ipManualController = TextEditingController(text: '192.168.0.');
    _portaManualController = TextEditingController(text: '8080');
    _nomeTerminalController = TextEditingController(text: _cliente.nomeDispositivo);

    _cliente.obterNomeDispositivo().then((nome) {
      if (mounted && _nomeTerminalController.text != nome) {
        setState(() {
          _nomeTerminalController.text = nome;
        });
      }
    });

    // Se já estiver conectado como cliente ou se não tiver loja, abre na aba de cliente
    if (widget.loja == null || _cliente.conectado) {
      _abaSelecionada = 1;
    } else if (_servidor.ativo) {
      _abaSelecionada = 0;
    }

    _cliente.iniciarDescoberta();
  }

  @override
  void dispose() {
    _ipManualController.dispose();
    _portaManualController.dispose();
    _nomeTerminalController.dispose();
    _cliente.pararDescoberta();
    super.dispose();
  }

  Future<void> _alternarServidor(bool ligar) async {
    setState(() => _mensagemStatus = null);
    final pdv = context.read<PdvProvider>();

    if (ligar) {
      if (widget.loja == null) {
        setState(() {
          _mensagemStatus = 'Abra uma loja cadastrada para iniciar o servidor balcão.';
        });
        return;
      }
      final auth = context.read<AuthProvider>();
      final sucesso = await _servidor.iniciar(loja: widget.loja!, pdv: pdv, auth: auth);
      if (!mounted) return;
      if (sucesso) {
        setState(() {
          _mensagemStatus = 'Servidor iniciado com sucesso!';
        });
      } else {
        setState(() {
          _mensagemStatus = 'Erro ao iniciar servidor na porta ${_servidor.porta}.';
        });
      }
    } else {
      await _servidor.parar();
      if (!mounted) return;
      setState(() {
        _mensagemStatus = 'Servidor encerrado.';
      });
    }
  }

  Future<void> _conectarAoServidor(String ip, int porta) async {
    if (_servidor.ativo) {
      setState(() {
        _mensagemStatus = 'Este computador já é o Servidor Balcão ativo.';
      });
      return;
    }

    setState(() {
      _conectando = true;
      _mensagemStatus = null;
    });

    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final sucesso = await _cliente.conectar(ip: ip, porta: porta, pdv: pdv, auth: auth);

    if (!mounted) return;
    setState(() {
      _conectando = false;
      if (sucesso) {
        _mensagemStatus = 'Conectado com sucesso à loja no balcão!';
      } else {
        _mensagemStatus = _cliente.ultimoErro.value ?? 'Não foi possível conectar a $ip:$porta.';
      }
    });
  }

  Future<void> _desconectarCliente() async {
    await _cliente.desconectar();
    if (!mounted) return;
    setState(() {
      _mensagemStatus = 'Desconectado da loja no balcão.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho Centralizado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_rounded, size: 22, color: theme.textColor),
                  const SizedBox(width: 8),
                  Text(
                    'Sincronização em Rede Wi-Fi',
                    style: theme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.modoLogin
                    ? 'Conecte-se ao balcão no Wi-Fi para sincronizar sua conta, ou continue para operar offline.'
                    : 'Opere a mesma loja simultaneamente no computador e no celular.',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 14),

              // Identidade Ativa na Rede (Transparência Radical)
              _buildCardIdentidadeAtiva(context, theme),
              const SizedBox(height: 14),

              // Abas: Balcão (Servidor) vs. Celular/Terminal (Cliente)
              Row(
                children: [
                  Expanded(
                    child: _botaoAba(
                      titulo: 'Balcão (Servidor)',
                      icone: Icons.point_of_sale_rounded,
                      selecionado: _abaSelecionada == 0,
                      onTap: () => setState(() => _abaSelecionada = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _botaoAba(
                      titulo: 'Terminal Móvel',
                      icone: Icons.smartphone_rounded,
                      selecionado: _abaSelecionada == 1,
                      onTap: () => setState(() => _abaSelecionada = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conteúdo com rolagem
              Flexible(
                child: SingleChildScrollView(
                  child: _abaSelecionada == 0 ? _conteudoServidor() : _conteudoCliente(),
                ),
              ),

              if (_mensagemStatus != null) ...[
                const SizedBox(height: 12),
                Text(
                  _mensagemStatus!,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _mensagemStatus!.contains('Erro') || _mensagemStatus!.contains('Não')
                        ? theme.dangerColor
                        : theme.textColor,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.modoLogin) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.secondaryTextColor,
                      ),
                      child: const Text('Pular'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Continuar'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.secondaryTextColor,
                      ),
                      child: const Text('Fechar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardIdentidadeAtiva(BuildContext context, AppTheme theme) {
    final auth = context.watch<AuthProvider>();
    final conta = auth.contaAtual;
    final cpf = auth.cpf;
    final cpfFormatado = CpfValidator.format(cpf);
    final nome = conta?.nome ?? 'Usuário Nous';
    final apelido = conta?.apelido;
    final temApelido = apelido != null && apelido.trim().isNotEmpty;
    final temFoto = ImagemService.existe(conta?.foto);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: temFoto
                ? ImagemService.construirImagem(
                    conta?.foto,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    fallback: Container(
                      width: 42,
                      height: 42,
                      color: theme.textColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded, size: 24, color: theme.secondaryTextColor),
                    ),
                  )
                : Container(
                    width: 42,
                    height: 42,
                    color: theme.textColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person_rounded, size: 24, color: theme.secondaryTextColor),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nome,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (temApelido) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(@$apelido)',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'CPF: $cpfFormatado',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Minha Identidade',
            icon: Icon(Icons.badge_outlined, size: 20, color: theme.textColor),
            onPressed: () {
              final usuario = conta ??
                  UsuarioNous(
                    cpf: cpf,
                    nome: nome,
                    apelido: apelido ?? '',
                    dataNascimento: '',
                  );
              FichaUsuarioDialog.mostrar(
                context,
                theme: theme,
                usuario: usuario,
                somenteLeitura: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _botaoAba({
    required String titulo,
    required IconData icone,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    final theme = widget.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor.withValues(alpha: 0.4),
            width: selecionado ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 16,
              color: selecionado ? theme.textColor : theme.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                color: selecionado ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoServidor() {
    final theme = widget.theme;

    if (widget.loja == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_rounded, size: 36, color: theme.secondaryTextColor),
            const SizedBox(height: 12),
            Text(
              'Nenhuma loja aberta',
              style: theme.getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Para iniciar o Servidor Balcão nesta máquina, acesse uma loja cadastrada e ative o Wi-Fi.',
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

    return ValueListenableBuilder<bool>(
      valueListenable: _servidor.estaAtivo,
      builder: (context, ativo, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de Status do Servidor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        ativo ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                        color: ativo ? Colors.greenAccent : theme.secondaryTextColor,
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
                                  ? 'Transmitindo na rede Wi-Fi local'
                                  : 'Ative para permitir conexões de celulares',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: ativo,
                        onChanged: _alternarServidor,
                        activeThumbColor: theme.textColor,
                        activeTrackColor: theme.borderColor.withValues(alpha: 0.5),
                        inactiveThumbColor: theme.secondaryTextColor,
                        inactiveTrackColor: Colors.transparent,
                        trackOutlineColor: WidgetStateProperty.all(theme.borderColor),
                      ),
                    ],
                  ),
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
                              '${_servidor.ipServidor}:${_servidor.porta}',
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
                                text: '${_servidor.ipServidor}:${_servidor.porta}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Endereço copiado!')),
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
                      valueListenable: _servidor.terminaisConectados,
                      builder: (context, terminais, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(alpha: 0.2),
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
                                  final ehBalcao = term.id == 'balcao_servidor_local';
                                  final temUsuario = term.nomeUsuario != null && term.nomeUsuario!.trim().isNotEmpty;
                                  final temCpf = term.cpf != null && term.cpf!.trim().isNotEmpty;
                                  final temApelido = term.apelido != null && term.apelido!.trim().isNotEmpty;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.textColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.borderColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ehBalcao ? Icons.desktop_windows_rounded : Icons.smartphone_rounded,
                                          size: 22,
                                          color: Colors.greenAccent,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      term.nome,
                                                      style: theme.getTextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.textColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '• ${term.ip}',
                                                    style: theme.getTextStyle(
                                                      fontSize: 11,
                                                      color: theme.secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (temUsuario || temCpf) ...[
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(Icons.person_outline_rounded, size: 12, color: theme.secondaryTextColor),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            if (temUsuario)
                                                              TextSpan(
                                                                text: term.nomeUsuario!,
                                                                style: theme.getTextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: theme.textColor,
                                                                ),
                                                              ),
                                                            if (temApelido)
                                                              TextSpan(
                                                                text: ' (@${term.apelido})',
                                                                style: theme.getTextStyle(
                                                                  fontSize: 11,
                                                                  color: theme.secondaryTextColor,
                                                                ),
                                                              ),
                                                            if (temCpf)
                                                              TextSpan(
                                                                text: ' • CPF: ${CpfValidator.format(term.cpf!)}',
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
                                              ],
                                              const SizedBox(height: 2),
                                              Text(
                                                'Conectado às $hora',
                                                style: theme.getTextStyle(
                                                  fontSize: 10,
                                                  color: theme.secondaryTextColor.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (temCpf)
                                          IconButton(
                                            tooltip: 'Ver Identidade do Membro',
                                            icon: Icon(Icons.info_outline_rounded, size: 18, color: theme.secondaryTextColor),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              final auth = context.read<AuthProvider>();
                                              final conta = await ContasNousService.buscarPorCpf(term.cpf!);
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

  Widget _buildCardNomeDispositivo(AppTheme theme) {
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
                  controller: _nomeTerminalController,
                  label: 'Identificação do Celular',
                  onChanged: (val) {
                    _cliente.salvarNomeDispositivo(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  _cliente.salvarNomeDispositivo(_nomeTerminalController.text);
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conteudoCliente() {
    final theme = widget.theme;

    if (_servidor.ativo) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Icon(Icons.desktop_windows_rounded, size: 40, color: theme.textColor),
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
        _buildCardNomeDispositivo(theme),
        ValueListenableBuilder<bool>(
          valueListenable: _cliente.estaConectado,
          builder: (context, conectado, _) {
            if (conectado) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 36, color: Colors.greenAccent),
                    const SizedBox(height: 8),
                    Text(
                      'Conectado ao Balcão!',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Endereço: ${_cliente.enderecoServidor}',
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
                        final temApelido = apelido != null && apelido.trim().isNotEmpty;
                        final cpf = CpfValidator.format(auth.cpf);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.textColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.badge_outlined, size: 16, color: theme.secondaryTextColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Operador ativo: ',
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _desconectarCliente,
                      icon: Icon(Icons.link_off_rounded, size: 16, color: theme.dangerColor),
                      label: Text(
                        'Desconectar',
                        style: TextStyle(color: theme.dangerColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dangerColor),
                      ),
                    ),
                  ],
                ),
              );
            }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lojas encontradas automaticamente no Wi-Fi
            Text(
              'Lojas Encontradas no Wi-Fi:',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<List<DispositivoLojaInfo>>(
              valueListenable: _cliente.lojasEncontradas,
              builder: (context, lojas, _) {
                if (lojas.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
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
                        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: Colors.greenAccent, size: 20),
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
                                  info.enderecoCompleto,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _conectando
                                ? null
                                : () => _conectarAoServidor(info.ip, info.porta),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.buttonColor,
                              foregroundColor: theme.buttonTextColor,
                            ),
                            child: _conectando
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
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

            // Conexão Manual por IP
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
                    controller: _ipManualController,
                    label: 'Endereço IP (ex: 192.168.0.100)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ThemedTextField(
                    theme: theme,
                    controller: _portaManualController,
                    label: 'Porta',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _conectando
                  ? null
                  : () {
                      final ip = _ipManualController.text.trim();
                      final porta = int.tryParse(_portaManualController.text.trim()) ?? 8080;
                      if (ip.isNotEmpty) {
                        _conectarAoServidor(ip, porta);
                      }
                    },
              icon: const Icon(Icons.link_rounded, size: 16),
              label: _conectando
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
