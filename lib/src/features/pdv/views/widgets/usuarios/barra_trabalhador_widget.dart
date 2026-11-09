import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/dialog_central_contrato_trabalhador.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';

enum ContextoBarraTrabalhador { statusLoja, financeiro, perfil }

class BarraTrabalhadorWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final MembroLoja membro;
  final String cpfLogado;
  final ContextoBarraTrabalhador contexto;
  final List<CargoLoja> cargosPersonalizados;
  final bool podeGerenciar;
  final PagamentoFuncionario? pagamento;
  final VoidCallback? onAbrirMensagem;
  final VoidCallback? onAbrirTrocaDePapel;
  final VoidCallback? onRemoverMembro;
  final VoidCallback? onAbrirHistoricoPagamentos;

  const BarraTrabalhadorWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.membro,
    required this.cpfLogado,
    required this.contexto,
    this.cargosPersonalizados = const [],
    this.podeGerenciar = false,
    this.pagamento,
    this.onAbrirMensagem,
    this.onAbrirTrocaDePapel,
    this.onRemoverMembro,
    this.onAbrirHistoricoPagamentos,
  });

  @override
  State<BarraTrabalhadorWidget> createState() => _BarraTrabalhadorWidgetState();
}

class _BarraTrabalhadorWidgetState extends State<BarraTrabalhadorWidget> {
  bool _hover = false;
  bool _mostrarPontoEEscala = false;

  AppTheme get theme => widget.theme;

  String _formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

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

  void _abrirChatDireto(BuildContext context) {
    if (widget.onAbrirMensagem != null) {
      widget.onAbrirMensagem!();
      return;
    }
    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();
    final conta = auth.buscarContaPorCpf(widget.membro.cpf);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: widget.lojaId.isNotEmpty,
          lojaId: widget.lojaId.isNotEmpty ? widget.lojaId : null,
          nomeLoja: pdv.buscarPorId(widget.lojaId)?.nome,
          operadorCpf: widget.cpfLogado,
          usuarioCpf: widget.membro.cpf,
          usuarioNome: widget.membro.nome,
          usuarioFoto: conta?.foto ?? '',
          usuarioApelido: conta?.apelido ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);

    final ehVoce = widget.membro.cpf == widget.cpfLogado;
    final contaMembro = auth.buscarContaPorCpf(widget.membro.cpf);

    // Hierarquia de nome soberano: Nome Completo (se permitido) -> Apelido -> @Usuário Nous
    final nomeSoberano = contaMembro?.nomeExibicaoPara(
          cpfVisualizador: widget.cpfLogado,
          reveladoParaDono: ehVoce,
        ) ??
        (widget.membro.nome.isNotEmpty ? widget.membro.nome : 'Sem nome');

    String foto = auth.buscarFotoPorCpf(widget.membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(widget.membro.cpf) ?? '';
    }
    final temFoto = ImagemService.existe(foto);

    // CPF mascarado / protegido
    final reveladoCpf = ehVoce
        ? auth.dadoEstaReveladoParaDono('cpf')
        : ((!(contaMembro?.dadoEstaPrivado('cpf') ?? true)) ||
            (contaMembro?.dadoAutorizadoPara('cpf', widget.cpfLogado) ?? false));
    final cpfExibido = CpfValidator.formatProtegido(widget.membro.cpf, revelado: reveladoCpf);

    // Cargo
    final cargoNome = widget.cargosPersonalizados
        .where((c) => c.id == widget.membro.cargoPersonalizadoId)
        .firstOrNull
        ?.nome;
    final rotuloCargo = cargoNome != null && cargoNome.isNotEmpty
        ? '${widget.membro.papel.name} ($cargoNome)'
        : widget.membro.papel.name;

    // Status online/offline para contexto statusLoja
    final dispositivos = widget.contexto == ContextoBarraTrabalhador.statusLoja
        ? _obterDispositivosDoMembro(widget.membro.cpf)
        : const <TerminalConectadoInfo>[];
    final estaOnline = dispositivos.isNotEmpty;

    // Escala e ponto
    final escala = loja?.escalasTrabalho
        .where((e) => e.cpf == widget.membro.cpf)
        .firstOrNull;
    final pontos = loja?.registrosPonto
        .where((p) => p.cpf == widget.membro.cpf)
        .toList() ??
        const [];
    final temPontoAberto = pontos.any((p) => p.estaEmAberto);

    Widget construirBotoesAcao() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Mensagem (Chat direto)
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, size: 16, color: theme.textColor),
            tooltip: 'Enviar mensagem direta',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _abrirChatDireto(context),
          ),
          if (widget.contexto == ContextoBarraTrabalhador.statusLoja) ...[
            const SizedBox(width: 2),
            // Botão Identidade do Usuário
            IconButton(
              icon: Icon(Icons.badge_outlined, size: 16, color: theme.textColor),
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
            // Toggle de Ponto & Escala
            IconButton(
              icon: Icon(_mostrarPontoEEscala ? Icons.expand_less : Icons.schedule, size: 16, color: theme.textColor),
              tooltip: 'Horários e Escala de Trabalho',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => setState(() => _mostrarPontoEEscala = !_mostrarPontoEEscala),
            ),
          ],
          if (widget.contexto == ContextoBarraTrabalhador.financeiro) ...[
            const SizedBox(width: 2),
            // Botão Histórico de Pagamentos
            IconButton(
              icon: Icon(Icons.receipt_long_outlined, size: 16, color: theme.textColor),
              tooltip: 'Histórico de Pagamentos',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                CentralContratoTrabalhadorDialog.mostrar(
                  context: context,
                  theme: theme,
                  lojaId: widget.lojaId,
                  membro: widget.membro,
                  cpfLogado: widget.cpfLogado,
                  podeGerenciar: widget.podeGerenciar,
                );
              },
            ),
          ],
          if (widget.contexto == ContextoBarraTrabalhador.perfil) ...[
            const SizedBox(width: 2),
            // Botão Contrato
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                side: BorderSide(color: theme.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: Icon(Icons.description_outlined, size: 12, color: theme.textColor),
              label: Text('Contrato', style: theme.getTextStyle(fontSize: 10.5)),
              onPressed: () {
                CentralContratoTrabalhadorDialog.mostrar(
                  context: context,
                  theme: theme,
                  lojaId: widget.lojaId,
                  membro: widget.membro,
                  cpfLogado: widget.cpfLogado,
                  podeGerenciar: widget.podeGerenciar,
                );
              },
            ),
            if (widget.podeGerenciar && !ehVoce && widget.onAbrirTrocaDePapel != null) ...[
              const SizedBox(width: 2),
              IconButton(
                tooltip: 'Trocar papel',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(Icons.edit, size: 15, color: theme.textColor),
                onPressed: widget.onAbrirTrocaDePapel,
              ),
            ],
            if (widget.onRemoverMembro != null) ...[
              const SizedBox(width: 2),
              IconButton(
                tooltip: ehVoce ? 'Sair da loja' : 'Remover',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                onPressed: widget.onRemoverMembro,
              ),
            ],
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ehModoCelular = constraints.maxWidth < 560;

        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Avatar redondo
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: temFoto
                            ? ImagemService.construirImagem(
                                foto,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                fallback: Icon(Icons.person, size: 20, color: theme.textColor),
                              )
                            : Icon(Icons.person, size: 20, color: theme.textColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Dados centrais
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nomeSoberano,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              if (widget.contexto == ContextoBarraTrabalhador.statusLoja) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: estaOnline ? Colors.greenAccent : theme.secondaryTextColor.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  estaOnline ? 'Online' : 'Offline',
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: estaOnline ? Colors.greenAccent : theme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$rotuloCargo • $cpfExibido'
                            '${widget.pagamento != null ? " • Diária: ${_formatarMoeda(widget.pagamento!.valor)} (${widget.pagamento!.formaPagamento})" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!ehModoCelular) ...[
                      const SizedBox(width: 4),
                      construirBotoesAcao(),
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
                // Seção de dispositivos conectados (se estiver no Status da Loja)
                if (widget.contexto == ContextoBarraTrabalhador.statusLoja && estaOnline) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: dispositivos.map((disp) {
                      final ehBalcao = disp.nome.toLowerCase().contains('balcão') || disp.id.contains('balcao');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.borderColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(ehBalcao ? Icons.computer_rounded : Icons.smartphone_rounded, size: 11, color: theme.textColor),
                            const SizedBox(width: 4),
                            Text(
                              '${disp.nome}${disp.ip.isNotEmpty && disp.ip != "Local" ? " (${disp.ip})" : ""}',
                              style: theme.getTextStyle(fontSize: 9.5, color: theme.textColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                // Seção expansível de Horários de Entrada/Saída e Escala (Status da Loja)
                if (_mostrarPontoEEscala && widget.contexto == ContextoBarraTrabalhador.statusLoja) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ponto: ${temPontoAberto ? "Em jornada ativa" : "Fora do turno"}',
                              style: theme.getTextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: temPontoAberto ? Colors.greenAccent : theme.secondaryTextColor),
                            ),
                            if (escala != null)
                              Text(
                                'Escala: ${escala.resumoDias()} (${escala.horarioEntrada} às ${escala.horarioSaida})',
                                style: theme.getTextStyle(fontSize: 10, color: theme.textColor),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
