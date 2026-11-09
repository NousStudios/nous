import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/data_input_formatter.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';
import 'package:provider/provider.dart';

enum FiltroDataHistorico {
  todas('Todas as datas'),
  hoje('Hoje'),
  ultimos7Dias('Últimos 7 dias'),
  esteMes('Este mês'),
  personalizado('Personalizado');

  final String rotulo;
  const FiltroDataHistorico(this.rotulo);
}

class HistoricoComprasClienteWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final Cliente cliente;
  final List<PedidoLoja> historico;

  const HistoricoComprasClienteWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cliente,
    required this.historico,
  });

  @override
  State<HistoricoComprasClienteWidget> createState() =>
      _HistoricoComprasClienteWidgetState();
}

class _HistoricoComprasClienteWidgetState
    extends State<HistoricoComprasClienteWidget> {
  FiltroDataHistorico _filtroData = FiltroDataHistorico.todas;
  String _filtroForma = 'Todas';
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  static const List<String> _formasDisponiveis = [
    'Todas',
    'Dinheiro',
    'Pix',
    'Débito',
    'Crédito',
    'Voucher',
    'À Prazo',
  ];

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _dataInicioController.dispose();
    _dataFimController.dispose();
    super.dispose();
  }

  static String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static DateTime? _parseData(String texto) {
    final limpo = texto.trim();
    if (limpo.length != 10) return null;
    final partes = limpo.split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;
    if (ano < 1900 || ano > 2100 || mes < 1 || mes > 12 || dia < 1 || dia > 31) {
      return null;
    }
    try {
      final data = DateTime(ano, mes, dia);
      if (data.day != dia || data.month != mes || data.year != ano) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  static String _formatarDataBR(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  bool _pedidoCorrespondeData(PedidoLoja p) {
    final dInicio = _parseData(_dataInicioController.text);
    final dFim = _parseData(_dataFimController.text);

    if (dInicio != null || dFim != null) {
      if (dInicio != null) {
        final inicio = DateTime(dInicio.year, dInicio.month, dInicio.day);
        if (p.dataHora.isBefore(inicio)) return false;
      }
      if (dFim != null) {
        final fim = DateTime(dFim.year, dFim.month, dFim.day, 23, 59, 59);
        if (p.dataHora.isAfter(fim)) return false;
      }
      return true;
    }

    if (_filtroData == FiltroDataHistorico.todas) return true;
    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);

    switch (_filtroData) {
      case FiltroDataHistorico.hoje:
        return p.dataHora.isAfter(inicioHoje) ||
            p.dataHora.isAtSameMomentAs(inicioHoje);
      case FiltroDataHistorico.ultimos7Dias:
        final limite7 = inicioHoje.subtract(const Duration(days: 6));
        return p.dataHora.isAfter(limite7) ||
            p.dataHora.isAtSameMomentAs(limite7);
      case FiltroDataHistorico.esteMes:
        final inicioMes = DateTime(agora.year, agora.month, 1);
        return p.dataHora.isAfter(inicioMes) ||
            p.dataHora.isAtSameMomentAs(inicioMes);
      case FiltroDataHistorico.personalizado:
      case FiltroDataHistorico.todas:
        return true;
    }
  }

  bool _pedidoCorrespondeForma(PedidoLoja p) {
    if (_filtroForma == 'Todas') return true;
    final termoAlvo = _filtroForma.trim().toLowerCase();

    for (final pag in p.todosPagamentos) {
      final f = pag.forma.trim().toLowerCase();
      if (f.contains(termoAlvo) || termoAlvo.contains(f)) {
        return true;
      }
      if (termoAlvo == 'à prazo' &&
          (f.contains('prazo') || f.contains('fiado'))) {
        return true;
      }
      if (termoAlvo == 'crédito' && f.contains('crédito')) {
        return true;
      }
      if (termoAlvo == 'débito' && f.contains('débito')) {
        return true;
      }
    }
    return false;
  }

  List<PedidoLoja> get _pedidosFiltrados {
    return widget.historico.where((p) {
      return _pedidoCorrespondeData(p) && _pedidoCorrespondeForma(p);
    }).toList();
  }

  String _obterDescricaoFiltros() {
    final partes = <String>[];
    final temDatasDigitadas = _dataInicioController.text.isNotEmpty ||
        _dataFimController.text.isNotEmpty;

    if (temDatasDigitadas) {
      final de = _dataInicioController.text.trim();
      final ate = _dataFimController.text.trim();
      if (de.isNotEmpty && ate.isNotEmpty) {
        partes.add('Período: $de até $ate');
      } else if (de.isNotEmpty) {
        partes.add('Período: a partir de $de');
      } else if (ate.isNotEmpty) {
        partes.add('Período: até $ate');
      }
    } else if (_filtroData != FiltroDataHistorico.todas &&
        _filtroData != FiltroDataHistorico.personalizado) {
      partes.add('Período: ${_filtroData.rotulo}');
    }

    if (_filtroForma != 'Todas') {
      partes.add('Forma: $_filtroForma');
    }
    return partes.isEmpty ? 'Completo (sem filtros)' : partes.join(' | ');
  }

  void _ajustarDiaController(TextEditingController controller, int delta) {
    DateTime base;
    final atual = _parseData(controller.text);
    if (atual != null) {
      base = atual.add(Duration(days: delta));
    } else {
      base = DateTime.now();
    }
    setState(() {
      controller.text = _formatarDataBR(base);
      _filtroData = FiltroDataHistorico.personalizado;
    });
  }

  Future<void> _abrirDatePickerController(
      BuildContext context, TextEditingController controller) async {
    final atual = _parseData(controller.text) ?? DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.buttonColor != Colors.transparent
                  ? theme.buttonColor
                  : theme.textColor,
              onPrimary: theme.buttonTextColor,
              surface: theme.cardBackgroundColor,
              onSurface: theme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selecionada != null) {
      setState(() {
        controller.text = _formatarDataBR(selecionada);
        _filtroData = FiltroDataHistorico.personalizado;
      });
    }
  }

  Widget _campoDataComNavegacao({
    required BuildContext context,
    required String rotulo,
    required TextEditingController controller,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _ajustarDiaController(controller, -1),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 14,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(width: 3),
        SizedBox(
          width: 125,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [DataInputFormatterBR()],
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: rotulo,
              hintStyle: theme.getTextStyle(
                fontSize: 10.5,
                color: theme.secondaryTextColor,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              filled: true,
              fillColor: theme.cardBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.textColor,
                  width: 1.2,
                ),
              ),
              suffixIcon: InkWell(
                onTap: () => _abrirDatePickerController(context, controller),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 14,
                  color: theme.textColor,
                ),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _filtroData = FiltroDataHistorico.personalizado;
              });
            },
          ),
        ),
        const SizedBox(width: 3),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _ajustarDiaController(controller, 1),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarExtratoPDF(BuildContext context) async {
    try {
      final pdv = context.read<PdvProvider>();
      final loja = pdv.buscarPorId(widget.lojaId) ??
          (pdv.lojas.isNotEmpty ? pdv.lojas.first : null);

      if (loja == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Loja não encontrada para gerar o extrato.',
                style: theme.getTextStyle(color: theme.dangerColor),
              ),
            ),
          );
        }
        return;
      }

      final filtrados = _pedidosFiltrados;
      if (filtrados.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.cardBackgroundColor,
              content: Text(
                'Nenhuma compra encontrada para os filtros selecionados.',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          );
        }
        return;
      }

      final caminho = await ImpressaoService.exportarExtratoClientePDF(
        loja: loja,
        cliente: widget.cliente,
        pedidos: filtrados,
        filtroDescricao: _obterDescricaoFiltros(),
      );

      if (caminho != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Extrato do cliente exportado com sucesso em $caminho',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Falha ao exportar extrato: $e',
              style: theme.getTextStyle(color: theme.dangerColor),
            ),
          ),
        );
      }
    }
  }

  Widget _seletorFiltro<T>({
    required IconData icone,
    required T valor,
    required List<DropdownMenuItem<T>> itens,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          dropdownColor: theme.cardBackgroundColor,
          icon: Icon(Icons.arrow_drop_down, size: 18, color: theme.textColor),
          style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
          onChanged: onChanged,
          items: itens,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _pedidosFiltrados;
    final totalGastoFiltrado = filtrados
        .where((p) => p.status != StatusPedido.cancelado)
        .fold<double>(0, (s, p) => s + p.valor);

    final temFiltroAtivo = _filtroData != FiltroDataHistorico.todas ||
        _filtroForma != 'Todas' ||
        _dataInicioController.text.isNotEmpty ||
        _dataFimController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Compras',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (widget.historico.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${filtrados.length} de ${widget.historico.length} ${widget.historico.length == 1 ? "compra" : "compras"} • Total: ${_valor(totalGastoFiltrado)}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.historico.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 15,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Exportar Extrato PDF',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  onPressed: () => _exportarExtratoPDF(context),
                ),
            ],
          ),
          if (widget.historico.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Filtro superior: Formas de pagamento e datas selecionadas
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _seletorFiltro<FiltroDataHistorico>(
                  icone: Icons.calendar_today_outlined,
                  valor: _filtroData,
                  itens: FiltroDataHistorico.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.rotulo),
                    );
                  }).toList(),
                  onChanged: (novo) {
                    if (novo != null) {
                      setState(() {
                        _filtroData = novo;
                        if (novo != FiltroDataHistorico.personalizado) {
                          _dataInicioController.clear();
                          _dataFimController.clear();
                        }
                      });
                    }
                  },
                ),
                _seletorFiltro<String>(
                  icone: Icons.payment_outlined,
                  valor: _filtroForma,
                  itens: _formasDisponiveis.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f == 'Todas' ? 'Todas as formas' : f),
                    );
                  }).toList(),
                  onChanged: (novo) {
                    if (novo != null) setState(() => _filtroForma = novo);
                  },
                ),
                if (temFiltroAtivo)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _filtroData = FiltroDataHistorico.todas;
                        _filtroForma = 'Todas';
                        _dataInicioController.clear();
                        _dataFimController.clear();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Text(
                        'Limpar filtros',
                        style: theme
                            .getTextStyle(
                              fontSize: 10,
                              color: theme.dangerColor,
                              fontWeight: FontWeight.w600,
                            )
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Filtro por input posicionado ABAIXO
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _campoDataComNavegacao(
                  context: context,
                  rotulo: 'De: DD/MM/AAAA',
                  controller: _dataInicioController,
                ),
                _campoDataComNavegacao(
                  context: context,
                  rotulo: 'Até: DD/MM/AAAA',
                  controller: _dataFimController,
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (widget.historico.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra registrada para este cliente.',
            )
          else if (filtrados.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma compra para os filtros selecionados.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtrados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BarraVenda(
                    theme: theme,
                    lojaId: widget.lojaId,
                    pedido: filtrados[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
