import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

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

/// Card que exibe a lista de trabalhadores e status dos seus dispositivos na rede local.
class BlocoTrabalhadoresStatusWidget extends StatelessWidget {
  final String lojaId;
  final List<MembroLoja> membrosFallback;
  final String cpfLogado;
  final AppTheme theme;

  const BlocoTrabalhadoresStatusWidget({
    super.key,
    required this.lojaId,
    required this.membrosFallback,
    required this.cpfLogado,
    required this.theme,
  });

  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.cardBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.borderColor),
    );
  }

  Widget _tituloDoBloco(AppTheme theme, String titulo) {
    return Text(
      titulo,
      style: theme.getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loja = context.watch<PdvProvider>().buscarPorId(lojaId);
    final membros = loja?.membros ?? membrosFallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Lista de Trabalhadores'),
          const SizedBox(height: 12),
          if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum trabalhador cadastrado ainda.',
            )
          else
            for (final membro in membros)
              _LinhaTrabalhadorStatusWidget(
                lojaId: lojaId,
                membro: membro,
                cpfLogado: cpfLogado,
                theme: theme,
              ),
        ],
      ),
    );
  }
}

class _LinhaTrabalhadorStatusWidget extends StatefulWidget {
  final String lojaId;
  final MembroLoja membro;
  final String cpfLogado;
  final AppTheme theme;

  const _LinhaTrabalhadorStatusWidget({
    required this.lojaId,
    required this.membro,
    required this.cpfLogado,
    required this.theme,
  });

  @override
  State<_LinhaTrabalhadorStatusWidget> createState() =>
      _LinhaTrabalhadorStatusWidgetState();
}

class _LinhaTrabalhadorStatusWidgetState
    extends State<_LinhaTrabalhadorStatusWidget> {
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
      final jaTemEu = todas.any((t) => (t.cpf ?? '').replaceAll(RegExp(r'\D'), '') == meuCpf);
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

  void _abrirMensagens(BuildContext context, String foto, String? apelido) {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: true,
          lojaId: widget.lojaId,
          nomeLoja: loja?.nome,
          logoLoja: loja?.logo,
          operadorCpf: widget.cpfLogado,
          usuarioCpf: widget.membro.cpf,
          usuarioNome: widget.membro.nome,
          usuarioFoto: foto,
          usuarioApelido: apelido ?? '',
          conversaInicialId: ChatService.conversaIdLojaUsuario(
            widget.lojaId,
            widget.membro.cpf,
          ),
        ),
      ),
    );
  }

  Widget _secaoPontoEEscala(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final auth = context.watch<AuthProvider>();
    final contaMembro = auth.buscarContaPorCpf(widget.membro.cpf);
    final ehEuMesmo = widget.cpfLogado.replaceAll(RegExp(r'\D'), '') ==
        widget.membro.cpf.replaceAll(RegExp(r'\D'), '');

    // Permissões da Conta Nous
    final pontoPrivado = !ehEuMesmo &&
        (contaMembro?.dadoEstaPrivado('registroPonto') ?? false) &&
        !(contaMembro?.dadoAutorizadoPara('registroPonto', widget.cpfLogado) ?? false);
    final escalaPrivada = !ehEuMesmo &&
        (contaMembro?.dadoEstaPrivado('escalaTrabalho') ?? false) &&
        !(contaMembro?.dadoAutorizadoPara('escalaTrabalho', widget.cpfLogado) ?? false);

    final pontos = (loja?.registrosPonto ?? const <RegistroPontoMembro>[])
        .where((p) => p.cpf == widget.membro.cpf)
        .toList()
      ..sort((a, b) => b.dataHoraEntrada.compareTo(a.dataHoraEntrada));
    final ultimoPonto = pontos.firstOrNull;

    final escala = (loja?.escalasTrabalho ?? const <EscalaTrabalhoMembro>[])
        .where((e) => e.cpf == widget.membro.cpf)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horários de Entrada/Saída (Ponto)
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: theme.secondaryTextColor),
              const SizedBox(width: 5),
              Text(
                'Registro de Ponto:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pontoPrivado
                      ? 'Informação privada pelo colaborador'
                      : (ultimoPonto != null
                          ? '${ultimoPonto.estaEmAberto ? "Em jornada desde" : "Última saída em"} ${_formatarHora(ultimoPonto.estaEmAberto ? ultimoPonto.dataHoraEntrada : (ultimoPonto.dataHoraSaida ?? ultimoPonto.dataHoraEntrada))}'
                          : 'Nenhum ponto registrado hoje'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: pontoPrivado ? theme.secondaryTextColor : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Escala de Trabalho
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 13, color: theme.secondaryTextColor),
              const SizedBox(width: 5),
              Text(
                'Escala de Trabalho:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  escalaPrivada
                      ? 'Informação privada pelo colaborador'
                      : (escala != null && escala.horarioEntrada.isNotEmpty
                          ? '${escala.resumoDias()}: ${escala.horarioEntrada} às ${escala.horarioSaida}'
                          : 'Escala flexível / Não definida'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: escalaPrivada ? theme.secondaryTextColor : theme.textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)} às ${dois(d.hour)}:${dois(d.minute)}';
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
    final rotuloCargo = cargoPers != null
        ? '${_rotuloPapel(membro.papel)} (${cargoPers.nome})'
        : _rotuloPapel(membro.papel);

    Widget construirBotoesAcao() {
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
              onPressed: () => _abrirMensagens(context, foto, contaMembro?.apelido),
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
                FichaUsuarioDialog.mostrar(context, theme: theme, usuario: contaMembro);
              }
            },
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(
              _mostrarPontoEEscala
                  ? Icons.expand_less_rounded
                  : Icons.schedule_rounded,
              size: 16,
              color: _mostrarPontoEEscala ? theme.textColor : theme.secondaryTextColor,
            ),
            tooltip: 'Horários e Escala de Trabalho',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              setState(() => _mostrarPontoEEscala = !_mostrarPontoEEscala);
            },
          ),
        ],
      );
    }

    Widget construirBadgeStatus() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: estaOnline
              ? Colors.green.withValues(alpha: 0.15)
              : theme.secondaryTextColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estaOnline
                ? Colors.greenAccent.withValues(alpha: 0.6)
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
                color: estaOnline
                    ? Colors.greenAccent
                    : theme.secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              estaOnline
                  ? (dispositivos.length > 1
                      ? 'Online (${dispositivos.length})'
                      : 'Online')
                  : 'Offline',
              style: theme.getTextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: estaOnline
                    ? Colors.greenAccent
                    : theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ehModoCelular = constraints.maxWidth < 560;

        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
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
                    // Foto do Trabalhador
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: estaOnline
                              ? Colors.greenAccent
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
                    ),
                    const SizedBox(width: 10),
                    // Nome + Cargo + CPF Protegido com Olho
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
                          Builder(
                            builder: (context) {
                              final meuCpf = ChatService.normalizarCpf(widget.cpfLogado);

                              String cpfTexto;
                              bool revelado = false;
                              if (ehEuMesmo) {
                                revelado = auth.dadoEstaReveladoParaDono('cpf');
                                cpfTexto = CpfValidator.formatProtegido(membro.cpf, revelado: revelado);
                              } else {
                                final privado = contaMembro?.dadoEstaPrivado('cpf') ?? true;
                                final autorizado = contaMembro?.dadoAutorizadoPara('cpf', meuCpf) ?? false;
                                cpfTexto = CpfValidator.formatProtegido(membro.cpf, revelado: !privado || autorizado);
                              }

                              return Row(
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
                                      onTap: () => auth.alternarRevelacaoParaDono('cpf'),
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!ehModoCelular) ...[
                      const SizedBox(width: 4),
                      construirBotoesAcao(),
                      const SizedBox(width: 6),
                      construirBadgeStatus(),
                    ] else ...[
                      const SizedBox(width: 6),
                      construirBadgeStatus(),
                    ],
                  ],
                ),
                if (ehModoCelular) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      construirBotoesAcao(),
                    ],
                  ),
                ],
            const SizedBox(height: 8),
            // Dispositivos conectados na rede local (exibição original com IP e tipo)
            if (estaOnline) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dispositivos.map((disp) {
                  final ehBalcao = disp.nome.toLowerCase().contains('balcão') ||
                      disp.id.contains('balcao');
                  final icone = ehBalcao
                      ? Icons.computer_rounded
                      : Icons.smartphone_rounded;

                  return Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icone,
                          size: 12,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: TextoRolante(
                            texto: '${disp.nome}${disp.ip.isNotEmpty && disp.ip != "Local" ? " (${disp.ip})" : ""}',
                            textAlign: TextAlign.start,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 11,
                    color: theme.secondaryTextColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nenhum dispositivo conectado na rede local',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
            // Gaveta de Horários e Escala de Trabalho
            if (_mostrarPontoEEscala) _secaoPontoEEscala(context),
          ],
        ),
      ),
    );
  },
);
  }
}
