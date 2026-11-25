import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/status_loja/badges_dispositivos_membro_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/status_loja/widgets/secao_ponto_escala_membro_widget.dart';

String _rotuloPapel(PapelMembro papel) {
  switch (papel) {
    case PapelMembro.dono:
      return 'Dono';
    case PapelMembro.socio:
      return 'Sócio';
    case PapelMembro.admin:
      return 'Admin';
    case PapelMembro.funcionario:
      return 'Funcionário';
  }
}

/// Linha individual de um trabalhador ou cidadão no card de status da loja.
class LinhaTrabalhadorStatusWidget extends StatefulWidget {
  final String lojaId;
  final MembroLoja membro;
  final String cpfLogado;
  final AppTheme theme;

  const LinhaTrabalhadorStatusWidget({
    super.key,
    required this.lojaId,
    required this.membro,
    required this.cpfLogado,
    required this.theme,
  });

  @override
  State<LinhaTrabalhadorStatusWidget> createState() =>
      _LinhaTrabalhadorStatusWidgetState();
}

class _LinhaTrabalhadorStatusWidgetState
    extends State<LinhaTrabalhadorStatusWidget> {
  bool _hover = false;
  bool _mostrarPontoEEscala = false;

  AppTheme get theme => widget.theme;

  List<TerminalConectadoInfo> _obterDispositivosDoMembro(String cpfMembro) {
    final digitosMembro = cpfMembro.replaceAll(RegExp(r'\D'), '');
    if (digitosMembro.isEmpty) return [];

    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();

    List<TerminalConectadoInfo> todas;
    if (servidor.ativo) {
      todas = servidor.obterTodasPresencas();
    } else if (cliente.conectado) {
      todas = cliente.presencasAtivas.value;
      final meuCpf = widget.cpfLogado.replaceAll(RegExp(r'\D'), '');
      final jaTemEu = todas.any(
        (t) => (t.cpf ?? '').replaceAll(RegExp(r'\D'), '') == meuCpf,
      );
      if (!jaTemEu && meuCpf == digitosMembro) {
        todas = [
          ...todas,
          TerminalConectadoInfo(
            id: 'este_dispositivo',
            nome: cliente.nomeDispositivo,
            ip: 'Local',
            cpf: meuCpf,
            conectadoEm: DateTime.now(),
          ),
        ];
      }
    } else {
      todas = [];
    }

    return todas.where((t) {
      final cpfTerm = (t.cpf ?? '').replaceAll(RegExp(r'\D'), '');
      return cpfTerm.isNotEmpty && cpfTerm == digitosMembro;
    }).toList();
  }

  void _abrirMensagens(BuildContext context) {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final ehPessoal = widget.lojaId == PdvProvider.idLojaColetivaNous ||
        widget.lojaId == ChatService.idLojaColetivaNous;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: !ehPessoal,
          lojaId: ehPessoal ? null : widget.lojaId,
          nomeLoja: ehPessoal ? null : loja?.nome,
          logoLoja: ehPessoal ? null : loja?.logo,
          operadorCpf: widget.cpfLogado,
          usuarioCpf: widget.cpfLogado,
          conversaInicialId: ehPessoal
              ? ChatService.conversaIdEntreUsuarios(
                  widget.cpfLogado,
                  widget.membro.cpf,
                )
              : ChatService.conversaIdLojaUsuario(
                  widget.lojaId,
                  widget.membro.cpf,
                ),
        ),
      ),
    );
  }

  Widget _construirBotoesAcao({
    required BuildContext context,
    required bool ehEuMesmo,
    required bool ehLojaColetivaNous,
    required UsuarioNous? contaMembro,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!ehEuMesmo)
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: theme.textColor,
            ),
            tooltip: 'Enviar mensagem direta',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _abrirMensagens(context),
          ),
        const SizedBox(width: 2),
        IconButton(
          icon: Icon(
            Icons.badge_outlined,
            size: 16,
            color: theme.textColor,
          ),
          tooltip: 'Identidade do Usuário',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () {
            if (contaMembro != null) {
              FichaUsuarioDialog.mostrar(
                context,
                theme: theme,
                usuario: contaMembro,
              );
            }
          },
        ),
        if (!ehLojaColetivaNous) ...[
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(
              _mostrarPontoEEscala
                  ? Icons.expand_less_rounded
                  : Icons.schedule_rounded,
              size: 16,
              color: _mostrarPontoEEscala
                  ? theme.textColor
                  : theme.secondaryTextColor,
            ),
            tooltip: 'Horários e Escala de Trabalho',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              setState(() => _mostrarPontoEEscala = !_mostrarPontoEEscala);
            },
          ),
        ],
      ],
    );
  }

  Widget _construirBadgeStatus({
    required bool estaOnline,
    required int totalDispositivos,
  }) {
    final corAtiva = theme.textColor;
    final corInativa = theme.secondaryTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: estaOnline
            ? corAtiva.withValues(alpha: 0.12)
            : corInativa.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estaOnline
              ? corAtiva.withValues(alpha: 0.55)
              : theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: estaOnline ? corAtiva : corInativa,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            estaOnline
                ? (totalDispositivos > 1
                    ? 'Online ($totalDispositivos)'
                    : 'Online')
                : 'Offline',
            style: theme.getTextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: estaOnline ? corAtiva : corInativa,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAvatar({
    required String foto,
    required bool temFoto,
    required bool estaOnline,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: estaOnline
              ? theme.textColor
              : theme.borderColor.withValues(alpha: 0.6),
          width: estaOnline ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: temFoto
            ? ImagemService.construirImagem(
                foto,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                fallback: Icon(
                  Icons.person,
                  size: 20,
                  color: theme.textColor,
                ),
              )
            : Icon(
                Icons.person,
                size: 20,
                color: theme.textColor,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();
    final membro = widget.membro;

    String foto = auth.buscarFotoPorCpf(membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
    }

    final temFoto = ImagemService.existe(foto);
    final dispositivos = _obterDispositivosDoMembro(membro.cpf);
    final estaOnline = dispositivos.isNotEmpty;

    final contaMembro = auth.buscarContaPorCpf(membro.cpf);
    final ehEuMesmo = ChatService.normalizarCpf(widget.cpfLogado) ==
        ChatService.normalizarCpf(membro.cpf);
    final ehLojaColetivaNous =
        widget.lojaId == PdvProvider.idLojaColetivaNous ||
            widget.lojaId == ChatService.idLojaColetivaNous;

    // Hierarquia Soberana de Identidade
    final nomeExibido = contaMembro?.nomeExibicaoPara(
          cpfVisualizador: widget.cpfLogado,
          reveladoParaDono: ehEuMesmo,
        ) ??
        (membro.nome.isNotEmpty ? membro.nome : 'Sem nome');

    final cargoPers = membro.cargoPersonalizadoId != null
        ? pdv
            .buscarPorId(widget.lojaId)
            ?.cargosPersonalizados
            .where((c) => c.id == membro.cargoPersonalizadoId)
            .firstOrNull
        : null;
    final rotuloCargo = ehLojaColetivaNous
        ? (membro.cargoPersonalizadoId == 'desenvolvedor'
            ? 'Cidadão Nous • Desenvolvedor'
            : 'Cidadão Nous')
        : (cargoPers != null
            ? '${_rotuloPapel(membro.papel)} (${cargoPers.nome})'
            : _rotuloPapel(membro.papel));

    final meuCpf = ChatService.normalizarCpf(widget.cpfLogado);
    String cpfTexto;
    bool revelado = false;
    if (ehEuMesmo) {
      revelado = auth.dadoEstaReveladoParaDono('cpf');
      cpfTexto = CpfValidator.formatProtegido(membro.cpf, revelado: revelado);
    } else {
      final privado = contaMembro?.dadoEstaPrivado('cpf') ?? true;
      final autorizado =
          contaMembro?.dadoAutorizadoPara('cpf', meuCpf) ?? false;
      cpfTexto = CpfValidator.formatProtegido(
        membro.cpf,
        revelado: !privado || autorizado,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ehModoCelular = constraints.maxWidth < 560;
        final podeVisitarPerfil = ehLojaColetivaNous && contaMembro != null;
        final botoesAcao = _construirBotoesAcao(
          context: context,
          ehEuMesmo: ehEuMesmo,
          ehLojaColetivaNous: ehLojaColetivaNous,
          contaMembro: contaMembro,
        );
        final badgeStatus = _construirBadgeStatus(
          estaOnline: estaOnline,
          totalDispositivos: dispositivos.length,
        );

        return MouseRegion(
          cursor: podeVisitarPerfil
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: podeVisitarPerfil
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PerfilSocialView(
                          usuarioAlvo: contaMembro,
                          mostrarBotaoVoltar: true,
                        ),
                      ),
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _hover
                    ? theme.borderColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hover ? theme.textColor : theme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _construirAvatar(
                        foto: foto,
                        temFoto: temFoto,
                        estaOnline: estaOnline,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextoRolante(
                              texto: nomeExibido,
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$rotuloCargo • $cpfTexto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      fontSize: 10,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                                if (ehEuMesmo) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () =>
                                        auth.alternarRevelacaoParaDono('cpf'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Icon(
                                        revelado
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 13,
                                        color: theme.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!ehModoCelular) ...[
                        const SizedBox(width: 4),
                        botoesAcao,
                        const SizedBox(width: 6),
                        badgeStatus,
                      ] else ...[
                        const SizedBox(width: 6),
                        badgeStatus,
                      ],
                    ],
                  ),
                  if (ehModoCelular) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [botoesAcao],
                    ),
                  ],
                  const SizedBox(height: 8),
                  BadgesDispositivosMembroWidget(
                    estaOnline: estaOnline,
                    dispositivos: dispositivos,
                    theme: theme,
                  ),
                  if (!ehLojaColetivaNous && _mostrarPontoEEscala)
                    SecaoPontoEscalaMembroWidget(
                      lojaId: widget.lojaId,
                      membro: membro,
                      cpfLogado: widget.cpfLogado,
                      theme: theme,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
