import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede/identidade_ativa_card_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede/servidor_balcao_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/sincronizacao_rede/cliente_terminal_widget.dart';

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
  State<SincronizacaoRedeDialog> createState() =>
      _SincronizacaoRedeDialogState();
}

class _SincronizacaoRedeDialogState extends State<SincronizacaoRedeDialog> {
  final _servidor = ServidorRedeLocal();
  final _cliente = ClienteRedeLocal();

  late TextEditingController _ipManualController;
  late TextEditingController _portaManualController;
  late TextEditingController _nomeTerminalController;
  late TextEditingController _buscaUsuariosClienteController;

  int _abaSelecionada = 0; // 0: Balcão (Servidor), 1: Celular (Cliente)
  bool _conectando = false;
  String? _mensagemStatus;
  String _perfilHostSelecionado = 'host_usuario';

  @override
  void initState() {
    super.initState();
    _ipManualController = TextEditingController(text: '192.168.0.');
    _portaManualController = TextEditingController(text: '8080');
    _nomeTerminalController =
        TextEditingController(text: _cliente.nomeDispositivo);
    _buscaUsuariosClienteController = TextEditingController();

    if (widget.loja != null) {
      _perfilHostSelecionado = widget.loja!.id;
    } else if (_servidor.ativo && _servidor.lojaAtiva != null) {
      _perfilHostSelecionado = _servidor.lojaAtiva!.id;
    } else {
      _perfilHostSelecionado = 'host_usuario';
    }

    _cliente.obterNomeDispositivo().then((nome) {
      if (mounted && _nomeTerminalController.text != nome) {
        setState(() {
          _nomeTerminalController.text = nome;
        });
      }
    });

    if (_cliente.conectado) {
      _abaSelecionada = 1;
    } else {
      _abaSelecionada = 0;
    }

    _cliente.iniciarDescoberta();
  }

  @override
  void dispose() {
    _ipManualController.dispose();
    _portaManualController.dispose();
    _nomeTerminalController.dispose();
    _buscaUsuariosClienteController.dispose();
    _cliente.pararDescoberta();
    super.dispose();
  }

  Loja? _obterLojaSelecionada(PdvProvider pdv) {
    if (widget.loja != null) {
      return widget.loja;
    }
    if (_perfilHostSelecionado != 'host_usuario') {
      final loja = pdv.buscarPorId(_perfilHostSelecionado);
      if (loja != null &&
          !LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) {
        return loja;
      }
    }
    return null;
  }

  Future<void> _alternarServidor(bool ligar) async {
    setState(() => _mensagemStatus = null);
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();

    final lojaSelecionada = _obterLojaSelecionada(pdv);

    if (ligar) {
      final sucesso = await _servidor.iniciar(
          loja: lojaSelecionada, pdv: pdv, auth: auth);
      if (!mounted) return;
      if (sucesso) {
        final rotuloHost = lojaSelecionada != null
            ? 'como Loja "${lojaSelecionada.nome}"'
            : 'em Modo Usuário Nous';
        setState(() {
          _mensagemStatus = 'Servidor iniciado $rotuloHost com sucesso!';
        });
      } else {
        setState(() {
          _mensagemStatus =
              'Erro ao iniciar servidor na porta ${_servidor.porta}.';
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
    final sucesso =
        await _cliente.conectar(ip: ip, porta: porta, pdv: pdv, auth: auth);

    if (!mounted) return;
    setState(() {
      _conectando = false;
      if (sucesso) {
        _mensagemStatus = 'Conectado com sucesso à loja no balcão!';
      } else {
        _mensagemStatus =
            _cliente.ultimoErro.value ?? 'Não foi possível conectar a $ip:$porta.';
      }
    });
  }

  Future<void> _desconectarCliente() async {
    await _cliente.desconectar(manual: true);
    if (!mounted) return;
    setState(() {
      _mensagemStatus = 'Desconectado da loja no balcão.';
    });
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
            color: selecionado
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.4),
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

              // Identidade Ativa na Rede
              IdentidadeAtivaCardWidget(theme: theme),
              const SizedBox(height: 14),

              // Abas: Balcão (Servidor) vs. Terminal Móvel (Cliente)
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
                  child: _abaSelecionada == 0
                      ? ServidorBalcaoWidget(
                          theme: theme,
                          servidor: _servidor,
                          loja: widget.loja,
                          perfilHostSelecionado: _perfilHostSelecionado,
                          onPerfilHostChanged: (novoPerfil) {
                            setState(() => _perfilHostSelecionado = novoPerfil);
                          },
                          onAlternarServidor: _alternarServidor,
                        )
                      : ClienteTerminalWidget(
                          theme: theme,
                          cliente: _cliente,
                          servidor: _servidor,
                          nomeTerminalController: _nomeTerminalController,
                          ipManualController: _ipManualController,
                          portaManualController: _portaManualController,
                          buscaUsuariosClienteController:
                              _buscaUsuariosClienteController,
                          conectando: _conectando,
                          onDesconectar: _desconectarCliente,
                          onConectar: _conectarAoServidor,
                        ),
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
                    color: _mensagemStatus!.contains('Erro') ||
                            _mensagemStatus!.contains('Não')
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
}
