import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/card_membro_loja_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/dialog_convite_membro_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/dialog_troca_papel_membro.dart';

/// Container de visualização e gerenciamento dos usuários participantes da loja.
class UsuariosParticipantesContainer extends StatelessWidget {
  final AppTheme theme;
  final List<MembroLoja> membros;
  final List<CargoLoja> cargosPersonalizados;
  final String cpfLogado;
  final bool podeGerenciar;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviarConvite;
  final ValueChanged<String> onRemover;
  final void Function(String cpf, PapelMembro papel) onAtualizarPapel;
  final void Function(String cpf, String? cargoId)? onVincularCargoPersonalizado;
  final VoidCallback onSair;
  final bool ehLojaColetivaNous;
  final String? lojaId;
  final String? nomeLoja;

  const UsuariosParticipantesContainer({
    super.key,
    required this.theme,
    required this.membros,
    this.cargosPersonalizados = const [],
    required this.cpfLogado,
    required this.podeGerenciar,
    required this.buscarConta,
    required this.onEnviarConvite,
    required this.onRemover,
    required this.onAtualizarPapel,
    this.onVincularCargoPersonalizado,
    required this.onSair,
    this.ehLojaColetivaNous = false,
    this.lojaId,
    this.nomeLoja,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          mensagem,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _solicitarAcessoAoDado(
    BuildContext context,
    UsuarioNous usuario,
    String rotulo,
    String chave,
  ) async {
    final auth = context.read<AuthProvider>();
    final notificacoes = context.read<NotificacoesProvider>();
    final usuarioLogado = auth.contaAtual;
    if (usuarioLogado == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Solicitar Acesso',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja enviar uma notificação para ${usuario.nomeExibicao} solicitando autorização para visualizar seu "$rotulo"?',
          style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Enviar Solicitação',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final solicitacao = ConviteLoja(
        id: 'solic_${DateTime.now().millisecondsSinceEpoch}_${usuarioLogado.cpf}',
        cpfConvidante: usuarioLogado.cpf,
        nomeConvidante: usuarioLogado.nomeExibicao,
        cpfConvidado: usuario.cpf,
        lojaId: '',
        nomeLoja: 'Conta Pessoal',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoDadoUsuario,
        dadoSolicitado: chave,
      );
      await notificacoes.adicionarNotificacao(solicitacao);
      if (context.mounted) {
        _avisar(context, 'Solicitação enviada!');
      }
    }
  }

  void _confirmarRemocao(BuildContext context, MembroLoja membro) {
    final ehVoce = membro.cpf == cpfLogado;

    final meuMembro = membros.firstWhere(
      (m) => m.cpf == cpfLogado,
      orElse: () => MembroLoja(
        cpf: cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDono = meuMembro.papel == PapelMembro.dono;
    final ehOutroDono = !ehVoce && souDono && membro.papel == PapelMembro.dono;

    if (!ehVoce) {
      final ehUltimoDono = membro.papel == PapelMembro.dono &&
          membros.where((m) => m.papel == PapelMembro.dono).length <= 1;
      if (ehUltimoDono) {
        _avisar(context, 'A loja precisa de pelo menos um dono.');
        return;
      }
    } else {
      final souDonoOriginal = membro.papel == PapelMembro.dono;
      final quantidadeDonos =
          membros.where((m) => m.papel == PapelMembro.dono).length;
      final outros = membros.where((m) => m.cpf != cpfLogado).toList();
      if (souDonoOriginal && quantidadeDonos <= 1 && outros.isNotEmpty) {
        _avisar(
          context,
          'Você é o único dono. A posse passará para outro membro ao sair.',
        );
      } else if (souDonoOriginal && outros.isEmpty) {
        _avisar(
          context,
          'Você é o único dono e não há outros membros. A loja será excluída.',
        );
      }
    }

    final String titulo;
    final String mensagem;
    final String botaoTexto;
    final Color botaoCor;

    if (ehVoce) {
      titulo = 'Sair da loja';
      mensagem = 'Tem certeza que deseja sair da loja?';
      botaoTexto = 'Sair';
      botaoCor = theme.dangerColor;
    } else if (ehOutroDono) {
      titulo = 'Solicitar saída de dono';
      mensagem =
          'Como "${membro.nome}" também é Dono(a), a saída da loja exige o seu consentimento. Deseja enviar uma solicitação para que ele(a) concorde em sair?';
      botaoTexto = 'Enviar solicitação';
      botaoCor = theme.textColor;
    } else {
      titulo = 'Remover membro';
      mensagem =
          'Remover "${membro.nome}" da loja? Ele(a) receberá uma notificação informando sobre a remoção.';
      botaoTexto = 'Remover';
      botaoCor = theme.dangerColor;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            mensagem,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (ehVoce) {
                  onSair();
                } else {
                  onRemover(membro.cpf);
                }
              },
              child: Text(
                botaoTexto,
                style: theme.getTextStyle(color: botaoCor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirConvite(BuildContext context) {
    DialogConviteMembroLoja.mostrar(
      context,
      theme: theme,
      membrosAtuais: membros,
      buscarConta: buscarConta,
      onEnviar: (conta, papel) {
        onEnviarConvite(conta, papel);
        Navigator.of(context).pop();
        _avisar(context, 'Convite enviado para ${conta.nome}.');
      },
    );
  }

  void _abrirTrocaDePapel(BuildContext context, MembroLoja membro) {
    DialogTrocaPapelMembro.mostrar(
      context: context,
      theme: theme,
      membro: membro,
      membros: membros,
      cargosPersonalizados: cargosPersonalizados,
      cpfLogado: cpfLogado,
      onAtualizarPapel: onAtualizarPapel,
      onVincularCargoPersonalizado: onVincularCargoPersonalizado,
      onAviso: (msg) => _avisar(context, msg),
    );
  }

  Future<void> _abrirIdentidadeDoUsuario(BuildContext context, MembroLoja membro) async {
    final conta = await buscarConta(membro.cpf);
    final usuario = conta ??
        UsuarioNous(
          cpf: membro.cpf,
          nome: membro.nome,
          apelido: membro.nome,
          dataNascimento: '',
        );
    if (!context.mounted) return;
    final ehVoce = membro.cpf.replaceAll(RegExp(r'\D'), '') ==
        cpfLogado.replaceAll(RegExp(r'\D'), '');
    FichaUsuarioDialog.mostrar(
      context,
      theme: theme,
      usuario: usuario,
      somenteLeitura: !ehVoce,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Text(
            'Usuários Participantes',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum membro cadastrado ainda.',
            )
          else
            for (final membro in membros)
              CardMembroLojaWidget(
                theme: theme,
                lojaId: lojaId,
                nomeLoja: nomeLoja,
                membro: membro,
                membros: membros,
                cargosPersonalizados: cargosPersonalizados,
                cpfLogado: cpfLogado,
                podeGerenciar: podeGerenciar,
                ehLojaColetivaNous: ehLojaColetivaNous,
                onAbrirIdentidade: () => _abrirIdentidadeDoUsuario(context, membro),
                onAbrirTrocaDePapel: () => _abrirTrocaDePapel(context, membro),
                onConfirmarRemocao: () => _confirmarRemocao(context, membro),
                onSolicitarAcessoAoDado: (rotulo, chave) async {
                  final conta = await buscarConta(membro.cpf);
                  if (conta != null && context.mounted) {
                    await _solicitarAcessoAoDado(context, conta, rotulo, chave);
                  }
                },
              ),
          if (!ehLojaColetivaNous && podeGerenciar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _abrirConvite(context),
                child: Text(
                  'Convidar usuário para loja',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}