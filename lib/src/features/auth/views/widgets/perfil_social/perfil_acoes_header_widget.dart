import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/compartilhar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/validacao_identidade_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/timeline/views/central_conta_social_view.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_denuncia_social.dart';
import 'package:provider/provider.dart';

/// Fila horizontal de botões de ação do cabeçalho do perfil social
/// (Conta, Editar Perfil / Seguir, Compartilhar, Mensagens, Silenciar/Bloquear,
/// Denunciar) e botão de validação de identidade quando aplicável.
class PerfilAcoesHeaderWidget extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous conta;
  final UsuarioNous? contaPropria;
  final bool ehProprioUsuario;
  final Color textoSobreFundo;
  final Color textoSecSobreFundo;
  final ValueChanged<UsuarioNous> onContaAtualizada;
  final VoidCallback onPerfilAtualizado;

  const PerfilAcoesHeaderWidget({
    super.key,
    required this.theme,
    required this.conta,
    required this.contaPropria,
    required this.ehProprioUsuario,
    required this.textoSobreFundo,
    required this.textoSecSobreFundo,
    required this.onContaAtualizada,
    required this.onPerfilAtualizado,
  });

  @override
  State<PerfilAcoesHeaderWidget> createState() =>
      _PerfilAcoesHeaderWidgetState();
}

class _PerfilAcoesHeaderWidgetState extends State<PerfilAcoesHeaderWidget> {
  static const double _offsetInicialBotaoConta = 86.0;
  final ScrollController _botoesAcaoScrollCtrl = ScrollController();
  bool _offsetInicialAplicado = false;

  @override
  void dispose() {
    _botoesAcaoScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirEdicaoPerfil(BuildContext context) async {
    final atualizou = await showDialog<bool>(
      context: context,
      builder: (_) => EditarPerfilDialog(usuario: widget.conta),
    );
    if (atualizou == true && mounted) {
      widget.onPerfilAtualizado();
    }
  }

  void _compartilharPerfil(BuildContext context) {
    CompartilharPerfilDialog.mostrar(
      context: context,
      theme: widget.theme,
      conta: widget.conta,
    );
  }

  void _abrirMensagensUsuario(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final meuCpf = auth.contaAtual?.cpf ?? auth.cpf;
    final ehMeuProprioPerfil =
        ChatService.normalizarCpf(meuCpf) ==
        ChatService.normalizarCpf(widget.conta.cpf);

    if (ehMeuProprioPerfil) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MensageriaView(modoLoja: false),
        ),
      );
      return;
    }

    final meuCpfNorm = ChatService.normalizarCpf(meuCpf);
    if (widget.conta.quemPodeEnviarMensagens == 'apenas_seguidos' &&
        !widget.conta.estaSeguindo(meuCpfNorm)) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: widget.theme.cardBackgroundColor,
          title: Text(
            'Mensagens Restritas',
            style: widget.theme.getTextStyle(
              color: widget.theme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${widget.conta.nomeExibicao} configurou o perfil para receber mensagens diretas apenas de pessoas que ele segue.',
            style: widget.theme.getTextStyle(
              color: widget.theme.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Entendido',
                style: widget.theme.getTextStyle(color: widget.theme.textColor),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final idConversaDireta = ChatService.conversaIdEntreUsuarios(
      meuCpf,
      widget.conta.cpf,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: false,
          conversaInicialId: idConversaDireta,
        ),
      ),
    );
  }

  Future<void> _abrirMenuSilenciarOuBloquear(BuildContext context) async {
    final contaPropria = widget.contaPropria;
    if (contaPropria == null) return;
    final theme = widget.theme;
    final bloqueado = contaPropria.estaBloqueado(widget.conta.cpf);
    final silenciado = contaPropria.estaSilenciado(widget.conta.cpf);

    final acao = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    silenciado
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                    color: theme.textColor,
                  ),
                  title: Text(
                    silenciado ? 'Dessilenciar usuário' : 'Silenciar usuário',
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      color: theme.textColor,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'silenciar'),
                ),
                ListTile(
                  leading: Icon(
                    bloqueado ? Icons.lock_open_outlined : Icons.block_rounded,
                    color: theme.dangerColor,
                  ),
                  title: Text(
                    bloqueado ? 'Desbloquear usuário' : 'Bloquear usuário',
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.dangerColor,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'bloquear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || acao == null) return;
    if (acao == 'silenciar') {
      await context.read<AuthProvider>().alternarSilenciarUsuario(
        widget.conta.cpf,
      );
    } else if (acao == 'bloquear') {
      await context.read<AuthProvider>().alternarBloquearUsuario(
        widget.conta.cpf,
      );
    }
  }

  Widget _buildBotaoPerfil({
    required String rotulo,
    required VoidCallback onTap,
    double? largura,
  }) {
    final theme = widget.theme;
    final conteudo = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.borderColor.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: TextoRolante(
          texto: rotulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
      ),
    );
    if (largura != null) {
      return SizedBox(width: largura, child: conteudo);
    }
    return Expanded(child: conteudo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final conta = widget.conta;
    final contaPropria = widget.contaPropria;
    final ehProprioUsuario = widget.ehProprioUsuario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final qtdPrincipais = (ehProprioUsuario || contaPropria != null)
                ? 3
                : 2;
            final larguraBotao =
                (constraints.maxWidth - ((qtdPrincipais - 1) * 8)) /
                qtdPrincipais;

            if (ehProprioUsuario && !_offsetInicialAplicado) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_botoesAcaoScrollCtrl.hasClients) {
                  _offsetInicialAplicado = true;
                  _botoesAcaoScrollCtrl.jumpTo(_offsetInicialBotaoConta);
                }
              });
            }

            return SingleChildScrollView(
              controller: _botoesAcaoScrollCtrl,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (ehProprioUsuario) ...[
                    _buildBotaoPerfil(
                      rotulo: 'Conta',
                      largura: 76,
                      onTap: () => CentralContaSocialView.abrir(
                        context,
                        theme: theme,
                        usuario: conta,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildBotaoPerfil(
                      rotulo: 'Editar Perfil',
                      largura: larguraBotao,
                      onTap: () => _abrirEdicaoPerfil(context),
                    ),
                    const SizedBox(width: 8),
                  ] else if (contaPropria != null) ...[
                    _buildBotaoPerfil(
                      rotulo: contaPropria.estaSeguindo(conta.cpf)
                          ? 'Seguindo'
                          : 'Seguir',
                      largura: larguraBotao,
                      onTap: () async {
                        await context.read<AuthProvider>().alternarSeguir(
                          conta.cpf,
                        );
                        if (mounted) widget.onPerfilAtualizado();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildBotaoPerfil(
                    rotulo: 'Compartilhar',
                    largura: larguraBotao,
                    onTap: () => _compartilharPerfil(context),
                  ),
                  const SizedBox(width: 8),
                  _buildBotaoPerfil(
                    rotulo: 'Mensagens',
                    largura: larguraBotao,
                    onTap: () => _abrirMensagensUsuario(context),
                  ),
                  const SizedBox(width: 8),
                  if (contaPropria != null && !ehProprioUsuario)
                    Tooltip(
                      message: 'Silenciar ou Bloquear',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _abrirMenuSilenciarOuBloquear(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            contaPropria.estaBloqueado(conta.cpf)
                                ? Icons.block_rounded
                                : Icons.more_horiz_rounded,
                            size: 17,
                            color: contaPropria.estaBloqueado(conta.cpf)
                                ? theme.dangerColor
                                : widget.textoSobreFundo,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (contaPropria != null && !ehProprioUsuario)
                    Tooltip(
                      message: 'Denunciar',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final ok = await DialogDenunciaSocial.mostrar(
                            context,
                            theme: theme,
                            denunciante: contaPropria,
                            alvoCpf: conta.cpf,
                            alvoNome: conta.nomeExibicao,
                          );
                          if (ok == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                content: Text(
                                  'Denúncia registrada.',
                                  style: theme.getTextStyle(
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (!ehProprioUsuario &&
            contaPropria != null &&
            !conta.jaValidadoPor(contaPropria.cpf)) ...[
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final atualizado = await ValidacaoIdentidadeDialog.mostrar(
                  context: context,
                  alvo: conta,
                  theme: theme,
                );
                if (atualizado != null && mounted) {
                  widget.onContaAtualizada(atualizado);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: widget.textoSecSobreFundo,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Validar identidade',
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        color: widget.textoSecSobreFundo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
