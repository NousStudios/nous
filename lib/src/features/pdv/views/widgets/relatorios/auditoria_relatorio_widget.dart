import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';
import 'auditoria/barra_acao_widget.dart';
import 'auditoria/detalhes_acao_dialog.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

class AuditoriaRelatorioWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final List<RegistroAcao> acoesOrigem;
  final List<PedidoLoja> pedidos;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<String>? onExcluirPedido;
  final void Function(String pedidoId, DadosComentario dados)?
      onSalvarComentario;
  final void Function(String clienteId)? aoAbrirClientes;

  const AuditoriaRelatorioWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.acoesOrigem,
    required this.pedidos,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onExcluirPedido,
    this.onSalvarComentario,
    this.aoAbrirClientes,
  });

  @override
  State<AuditoriaRelatorioWidget> createState() =>
      _AuditoriaRelatorioWidgetState();
}

class _AuditoriaRelatorioWidgetState extends State<AuditoriaRelatorioWidget> {
  static const int _passoPaginacao = 50;
  final _buscaAcoesController = TextEditingController();
  final _acoesScrollController = ScrollController();
  int _limiteExibicao = _passoPaginacao;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _acoesScrollController.addListener(_aoRolar);
  }

  void _aoRolar() {
    if (_acoesScrollController.position.pixels >=
        _acoesScrollController.position.maxScrollExtent - 60) {
      if (_limiteExibicao < widget.acoesOrigem.length) {
        setState(() {
          _limiteExibicao += _passoPaginacao;
        });
      }
    }
  }

  @override
  void dispose() {
    _acoesScrollController.removeListener(_aoRolar);
    _buscaAcoesController.dispose();
    _acoesScrollController.dispose();
    super.dispose();
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  List<RegistroAcao> _acoesFiltradas(List<RegistroAcao> origem) {
    final termo = _buscaAcoesController.text.trim();
    final lista = termo.isEmpty
        ? List.of(origem)
        : origem.where((a) {
            if (TextoUtils.contemIgnorandoAcentos(a.descricao, termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(a.nomeAutor, termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(a.emailAutor, termo)) return true;
            if (a.cpfAutor.contains(termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(formatarCpfAuditoria(a.cpfAutor), termo)) {
              return true;
            }
            if (TextoUtils.contemIgnorandoAcentos(_dataHoraCurta(a.dataHora), termo)) {
              return true;
            }
            return false;
          }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  void _abrirDetalhesAcao(RegistroAcao acao) {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final clientes = loja?.clientesLoja ?? const <Cliente>[];

    Cliente? clienteEncontrado;
    final matchAspas = RegExp(r'"([^"]+)"').firstMatch(acao.descricao);
    if (matchAspas != null) {
      final nome = matchAspas.group(1)?.trim().toLowerCase() ?? '';
      clienteEncontrado = clientes
          .where((c) => c.nome.trim().toLowerCase() == nome)
          .firstOrNull;
    }

    PedidoLoja? pedidoEncontrado;
    final matchPedido = RegExp(r'#(\d+)').firstMatch(acao.descricao);
    if (matchPedido != null) {
      final numPed = int.tryParse(matchPedido.group(1)!);
      if (numPed != null) {
        pedidoEncontrado =
            widget.pedidos.where((p) => p.numero == numPed).firstOrNull;
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => DetalhesAcaoDialog(
        theme: theme,
        acao: acao,
        clienteVinculado: clienteEncontrado,
        pedidoVinculado: pedidoEncontrado,
        onAbrirPerfilCliente:
            clienteEncontrado != null && widget.aoAbrirClientes != null
                ? () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    widget.aoAbrirClientes!(clienteEncontrado!.id);
                  }
                : null,
        onAbrirPedido: pedidoEncontrado != null
            ? () {
                Navigator.of(ctx).pop();
                VendaRegistradaDialog.mostrar(
                  context,
                  theme: theme,
                  lojaId: widget.lojaId,
                  pedido: pedidoEncontrado!,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onSalvarComentario: widget.onSalvarComentario != null
                      ? (dados) => widget.onSalvarComentario!(
                            pedidoEncontrado!.id,
                            dados,
                          )
                      : null,
                  onExcluir: widget.onExcluirPedido != null
                      ? () => widget.onExcluirPedido!(pedidoEncontrado!.id)
                      : null,
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todasFiltradas = _acoesFiltradas(widget.acoesOrigem);
    final totalFiltradas = todasFiltradas.length;
    final acoesExibidas = todasFiltradas.take(_limiteExibicao).toList();
    final nadaRegistrado = widget.acoesOrigem.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Ações',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          TextField(
            controller: _buscaAcoesController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Pesquisar ações (texto ou data)'),
            onChanged: (_) => setState(() {
              _limiteExibicao = _passoPaginacao;
            }),
          ),
          const SizedBox(height: 10),
          if (nadaRegistrado)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação registrada ainda.',
            )
          else if (totalFiltradas == 0)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação encontrada.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                controller: _acoesScrollController,
                shrinkWrap: true,
                itemCount: acoesExibidas.length +
                    (_limiteExibicao < totalFiltradas ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == acoesExibidas.length) {
                    return Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _limiteExibicao += _passoPaginacao;
                          });
                        },
                        icon: const Icon(Icons.expand_more, size: 16),
                        label: Text(
                          'Carregar mais ações (${totalFiltradas - acoesExibidas.length} restantes)',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }
                  return BarraAcaoWidget(
                    theme: theme,
                    acao: acoesExibidas[index],
                    onTap: () => _abrirDetalhesAcao(acoesExibidas[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
