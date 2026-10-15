import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

class _HorarioInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 4 ? digitos.substring(0, 4) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2) buffer.write(':');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    var offset = newValue.selection.end;
    if (offset > texto.length) offset = texto.length;
    if (texto.length > oldValue.text.length && offset == 2) {
      offset++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

double _precoComoNumero(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo) ?? 0.0;
}

String _valorFormatado(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

class ProgramarPedidoDialog extends StatefulWidget {
  final String lojaId;
  final Cliente cliente;

  const ProgramarPedidoDialog({
    super.key,
    required this.lojaId,
    required this.cliente,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required String lojaId,
    required Cliente cliente,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ProgramarPedidoDialog(
        lojaId: lojaId,
        cliente: cliente,
      ),
    );
  }

  @override
  State<ProgramarPedidoDialog> createState() => _ProgramarPedidoDialogState();
}

class _ProgramarPedidoDialogState extends State<ProgramarPedidoDialog> {
  // Modo de Programação: 'dias_semana' (contratos/semanal) ou 'calendario' (datas específicas)
  String _modoProgramacao = 'dias_semana';

  // Dias da Semana (1 = Seg, 2 = Ter, 3 = Qua, 4 = Qui, 5 = Sex, 6 = Sáb, 7 = Dom)
  final Set<int> _diasSemanaSelecionados = {1, 2, 3, 4, 5}; // Padrão Dias Úteis

  // Calendário interativo de datas específicas
  DateTime _mesCalendario = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final Set<DateTime> _datasEspecificasSelecionadas = {
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  };

  // Horário
  TimeOfDay _horarioSelecionado = const TimeOfDay(hour: 12, minute: 0);
  late final TextEditingController _horarioController;
  final FocusNode _horarioFocusNode = FocusNode();
  bool _mouseSobreHorario = false;

  // Lista de Itens do Pedido
  final List<ItemVendido> _itensAdicionados = [];

  // Estado do item atual em seleção
  CategoriaLoja? _categoriaSelecionada;
  bool _modoItemSolto = false;
  ItemLoja? _itemSelecionado;
  VarianteItem? _varianteSelecionada;
  int _quantidadeItem = 1;
  final Map<String, int> _acompanhamentosQuantidades = {};
  final _obsItemController = TextEditingController();

  // Pagamento e Observações do Pedido
  String _formaPagamento = 'Dinheiro';
  final _obsGeralController = TextEditingController();

  static const List<String> _formas = [
    'Dinheiro',
    'Pix',
    'Débito',
    'Crédito',
    'À Prazo',
  ];

  @override
  void initState() {
    super.initState();
    _horarioController = TextEditingController(
      text: _formatarHora(_horarioSelecionado),
    );
    _horarioFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _horarioFocusNode.dispose();
    _horarioController.dispose();
    _obsItemController.dispose();
    _obsGeralController.dispose();
    super.dispose();
  }

  String _formatarHora(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _sincronizarHorarioDoTexto() {
    final partes = _horarioController.text.trim().split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        _horarioSelecionado = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  void _aoDigitarHorario(String valor) {
    final partes = valor.trim().split(':');
    if (partes.length == 2 && partes[0].length == 2 && partes[1].length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        setState(() {
          _horarioSelecionado = TimeOfDay(hour: h, minute: m);
        });
      }
    }
  }

  double get _precoBaseItemAtual {
    if (_itemSelecionado == null) return 0.0;
    var precoItemStr = _itemSelecionado!.preco;
    if (_varianteSelecionada != null && _varianteSelecionada!.preco.isNotEmpty) {
      precoItemStr = _varianteSelecionada!.preco;
    }
    var base = _precoComoNumero(precoItemStr);
    if (!_modoItemSolto && _categoriaSelecionada != null) {
      base += _precoComoNumero(_categoriaSelecionada!.preco);
    }
    return base;
  }

  double get _subtotalItemAtual {
    if (_itemSelecionado == null) return 0.0;
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final itensDisponiveis = loja?.itensLoja ?? [];

    var unitario = _precoBaseItemAtual;
    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem =
            itensDisponiveis.where((i) => i.id == entrada.key).firstOrNull;
        if (acompItem != null) {
          unitario += _precoComoNumero(acompItem.preco) * entrada.value;
        }
      }
    }
    return unitario * _quantidadeItem;
  }

  double get _totalGeralPedido {
    return _itensAdicionados.fold<double>(0.0, (s, i) => s + i.subtotal);
  }

  void _adicionarItemAoPedido() {
    if (_itemSelecionado == null) return;
    final loja = context.read<PdvProvider>().buscarPorId(widget.lojaId);
    final itensDisponiveis = loja?.itensLoja ?? [];

    final item = _itemSelecionado!;
    final fotoPrincipal = item.imagens.isNotEmpty ? item.imagens.first : '';

    final listaAcompanhamentos = <AcompanhamentoEscolhido>[];
    for (final entrada in _acompanhamentosQuantidades.entries) {
      if (entrada.value > 0) {
        final acompItem =
            itensDisponiveis.where((i) => i.id == entrada.key).firstOrNull;
        if (acompItem != null) {
          listaAcompanhamentos.add(
            AcompanhamentoEscolhido(
              itemId: acompItem.id,
              nomeItem: acompItem.nome,
              precoItem: _precoComoNumero(acompItem.preco),
              quantidadePorUnidade: entrada.value,
            ),
          );
        }
      }
    }

    final precoItemNum = _precoComoNumero(
      (_varianteSelecionada != null && _varianteSelecionada!.preco.isNotEmpty)
          ? _varianteSelecionada!.preco
          : item.preco,
    );

    final precoCategoriaNum = (!_modoItemSolto && _categoriaSelecionada != null)
        ? _precoComoNumero(_categoriaSelecionada!.preco)
        : 0.0;

    final novoItemVendido = ItemVendido(
      itemId: item.id,
      nomeItem: item.nome,
      foto: fotoPrincipal,
      categoriaId:
          (!_modoItemSolto && _categoriaSelecionada != null) ? _categoriaSelecionada!.id : null,
      nomeCategoria: (!_modoItemSolto && _categoriaSelecionada != null)
          ? _categoriaSelecionada!.nome
          : null,
      varianteNome: _varianteSelecionada?.nome ?? '',
      precoItem: precoItemNum,
      precoCategoria: precoCategoriaNum,
      quantidade: _quantidadeItem,
      acompanhamentos: listaAcompanhamentos,
      observacao: _obsItemController.text.trim(),
    );

    setState(() {
      _itensAdicionados.add(novoItemVendido);
      _itemSelecionado = null;
      _varianteSelecionada = null;
      _quantidadeItem = 1;
      _acompanhamentosQuantidades.clear();
      _obsItemController.clear();
    });
  }

  void _ajustarMinutos(int deltaMinutos) {
    _sincronizarHorarioDoTexto();
    var novoMinuto = _horarioSelecionado.minute + deltaMinutos;
    var novaHora = _horarioSelecionado.hour;
    if (novoMinuto >= 60) {
      novoMinuto = novoMinuto - 60;
      novaHora = (novaHora + 1) % 24;
    } else if (novoMinuto < 0) {
      novoMinuto = novoMinuto + 60;
      novaHora = (novaHora - 1 + 24) % 24;
    }
    final novo = TimeOfDay(hour: novaHora, minute: novoMinuto);
    setState(() {
      _horarioSelecionado = novo;
      _horarioController.text = _formatarHora(novo);
    });
  }

  Widget _botaoAjusteMinuto(AppTheme theme, int deltaMinutos, String label) {
    return InkWell(
      onTap: () => _ajustarMinutos(deltaMinutos),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: theme.textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSeletorHora(AppTheme theme) async {
    _sincronizarHorarioDoTexto();
    final picked = await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DigitarHorarioDialog(
        horarioInicial: _horarioSelecionado,
        theme: theme,
      ),
    );
    if (picked != null) {
      setState(() {
        _horarioSelecionado = picked;
        _horarioController.text = _formatarHora(picked);
      });
    }
  }

  Future<void> _salvarPedidoProgramado() async {
    _sincronizarHorarioDoTexto();

    if (_itensAdicionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item ao pedido.')),
      );
      return;
    }

    if (_modoProgramacao == 'dias_semana' && _diasSemanaSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um dia da semana para o contrato.')),
      );
      return;
    }

    if (_modoProgramacao == 'calendario' && _datasEspecificasSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma data no calendário.')),
      );
      return;
    }

    final enderecoCompleto = [
      widget.cliente.endereco,
      widget.cliente.numero,
    ].where((e) => e.trim().isNotEmpty).join(', ');

    final diasSemanaList = _diasSemanaSelecionados.toList()..sort();
    final datasList = _datasEspecificasSelecionadas.toList()..sort();

    final pedido = PedidoProgramado.novo(
      lojaId: widget.lojaId,
      clienteId: widget.cliente.id,
      clienteNome: widget.cliente.nome,
      clienteTelefone: widget.cliente.telefone,
      clienteEndereco: enderecoCompleto,
      itens: _itensAdicionados,
      valorTotal: _totalGeralPedido,
      formaPagamento: _formaPagamento,
      horario: _formatarHora(_horarioSelecionado),
      recorrente: _modoProgramacao == 'dias_semana',
      modoProgramacao: _modoProgramacao,
      diasSemana: diasSemanaList,
      datasEspecificas: datasList,
      dataProgramada: datasList.isNotEmpty ? datasList.first : null,
      observacao: _obsGeralController.text.trim(),
    );

    await context.read<PdvProvider>().adicionarPedidoProgramado(widget.lojaId, pedido);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final loja = context.watch<PdvProvider>().buscarPorId(widget.lojaId);
        final categorias = loja?.categoriasLoja ?? <CategoriaLoja>[];
        final todosItens = loja?.itensLoja ?? <ItemLoja>[];
        final grupos = loja?.gruposComponentesLoja ?? <GrupoComponentesLoja>[];

        final bool travarScrollJanela =
            _mouseSobreHorario || _horarioFocusNode.hasFocus;

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_horarioFocusNode.hasFocus) {
                _horarioFocusNode.unfocus();
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: theme.textColor, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Programar Pedido do Cliente',
                                style: theme.getTextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              Text(
                                'Cliente: ${widget.cliente.nome}',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: travarScrollJanela
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ═════════════════════════════════════════════════
                          // BLOCO 1: CALENDÁRIO PROGRAMÁVEL E DIAS DA SEMANA
                          // ═════════════════════════════════════════════════
                          _blocoProgramacaoDatas(theme),
                          const SizedBox(height: 12),

                          // ═════════════════════════════════════════════════
                          // BLOCO 2: SELEÇÃO DE ITEM (CATEGORIA OU SOLTO)
                          // ═════════════════════════════════════════════════
                          _blocoSelecaoItemComanda(
                            theme: theme,
                            categorias: categorias,
                            todosItens: todosItens,
                            grupos: grupos,
                          ),
                          const SizedBox(height: 12),

                          // ═════════════════════════════════════════════════
                          // BLOCO 3: ITENS JÁ ADICIONADOS AO PEDIDO
                          // ═════════════════════════════════════════════════
                          _blocoItensDoPedido(theme),
                          const SizedBox(height: 12),

                          // ═════════════════════════════════════════════════
                          // BLOCO 4: FORMA DE PAGAMENTO E OBSERVAÇÕES
                          // ═════════════════════════════════════════════════
                          _blocoPagamentoEObservacoes(theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Botões inferiores
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textColor,
                            side: BorderSide(color: theme.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.textColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'Salvar Programação (${_valorFormatado(_totalGeralPedido)})',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          onPressed: _salvarPedidoProgramado,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  // ═════════════════════════════════════════════════════════════════
  // WIDGET: PROGRAMAÇÃO VISUAL DE DATAS E HORÁRIO
  // ═════════════════════════════════════════════════════════════════
  Widget _blocoProgramacaoDatas(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Frequência e Horário do Pedido',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Abas de tipo de agendamento: Dias da Semana vs Calendário
          Row(
            children: [
              Expanded(
                child: _abaFrequencia(
                  theme: theme,
                  label: 'Contrato / Dias da Semana',
                  icon: Icons.date_range,
                  selecionado: _modoProgramacao == 'dias_semana',
                  onTap: () => setState(() => _modoProgramacao = 'dias_semana'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _abaFrequencia(
                  theme: theme,
                  label: 'Calendário de Datas',
                  icon: Icons.calendar_month,
                  selecionado: _modoProgramacao == 'calendario',
                  onTap: () => setState(() => _modoProgramacao = 'calendario'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_modoProgramacao == 'dias_semana') ...[
            // Seletor dos 7 dias da semana
            Text(
              'Selecione os dias em que o pedido deve ser produzido:',
              style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chipDiaSemana(theme: theme, numero: 1, label: 'Seg'),
                _chipDiaSemana(theme: theme, numero: 2, label: 'Ter'),
                _chipDiaSemana(theme: theme, numero: 3, label: 'Qua'),
                _chipDiaSemana(theme: theme, numero: 4, label: 'Qui'),
                _chipDiaSemana(theme: theme, numero: 5, label: 'Sex'),
                _chipDiaSemana(theme: theme, numero: 6, label: 'Sáb'),
                _chipDiaSemana(theme: theme, numero: 7, label: 'Dom'),
              ],
            ),
            const SizedBox(height: 8),
            // Atalhos rápidos
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _atalhoDiaSemana(
                  theme: theme,
                  label: 'Dias Úteis (Seg a Sex)',
                  dias: [1, 2, 3, 4, 5],
                ),
                _atalhoDiaSemana(
                  theme: theme,
                  label: 'Fim de Semana',
                  dias: [6, 7],
                ),
                _atalhoDiaSemana(
                  theme: theme,
                  label: 'Todos os Dias',
                  dias: [1, 2, 3, 4, 5, 6, 7],
                ),
              ],
            ),
          ] else ...[
            // Calendário Visual de Datas
            _renderCalendarioMensal(theme),
          ],

          const Divider(height: 18),

          // Seletor de Horário com Digitação Direta
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MouseRegion(
                onEnter: (_) {
                  if (!_mouseSobreHorario) {
                    setState(() => _mouseSobreHorario = true);
                  }
                },
                onExit: (_) {
                  if (_mouseSobreHorario) {
                    setState(() => _mouseSobreHorario = false);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horário (digite ex: 12:07):',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              if (pointerSignal.scrollDelta.dy < 0) {
                                _ajustarMinutos(1);
                              } else if (pointerSignal.scrollDelta.dy > 0) {
                                _ajustarMinutos(-1);
                              }
                            }
                          },
                          child: Tooltip(
                            message: 'Digite ou use a rodinha do mouse para ajustar o horário',
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: theme.backgroundColor.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: _horarioFocusNode.hasFocus
                                      ? theme.textColor
                                      : theme.borderColor,
                                  width: _horarioFocusNode.hasFocus ? 1.6 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: theme.textColor),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 52,
                                    child: TextField(
                                      focusNode: _horarioFocusNode,
                                      controller: _horarioController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      cursorColor: theme.textColor,
                                      inputFormatters: [_HorarioInputFormatter()],
                                      style: theme.getTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: _aoDigitarHorario,
                                      onSubmitted: (_) => _horarioFocusNode.unfocus(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: theme.secondaryTextColor,
                                    tooltip: 'Abrir seletor de horário',
                                    onPressed: () => _abrirSeletorHora(theme),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Botões rápidos de ajuste minuto a minuto (-1m e +1m)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          _botaoAjusteMinuto(theme, -1, '-1m'),
                          const SizedBox(width: 4),
                          _botaoAjusteMinuto(theme, 1, '+1m'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    _chipHorarioRapido(theme, const TimeOfDay(hour: 11, minute: 30)),
                    _chipHorarioRapido(theme, const TimeOfDay(hour: 12, minute: 0)),
                    _chipHorarioRapido(theme, const TimeOfDay(hour: 12, minute: 30)),
                    _chipHorarioRapido(theme, const TimeOfDay(hour: 18, minute: 0)),
                    _chipHorarioRapido(theme, const TimeOfDay(hour: 19, minute: 30)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _abaFrequencia({
    required AppTheme theme,
    required String label,
    required IconData icon,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor,
            width: selecionado ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                  color: theme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipDiaSemana({
    required AppTheme theme,
    required int numero,
    required String label,
  }) {
    final ativo = _diasSemanaSelecionados.contains(numero);
    return InkWell(
      onTap: () {
        setState(() {
          if (ativo) {
            _diasSemanaSelecionados.remove(numero);
          } else {
            _diasSemanaSelecionados.add(numero);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ativo ? theme.textColor : theme.borderColor,
            width: ativo ? 1.6 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.getTextStyle(
              fontSize: 11,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _atalhoDiaSemana({
    required AppTheme theme,
    required String label,
    required List<int> dias,
  }) {
    final bateExatamente = _diasSemanaSelecionados.length == dias.length &&
        dias.every((d) => _diasSemanaSelecionados.contains(d));

    return InkWell(
      onTap: () {
        setState(() {
          _diasSemanaSelecionados
            ..clear()
            ..addAll(dias);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bateExatamente
              ? theme.textColor.withValues(alpha: 0.15)
              : theme.borderColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: bateExatamente ? theme.textColor : theme.borderColor,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: bateExatamente ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _chipHorarioRapido(AppTheme theme, TimeOfDay hora) {
    final selecionado = _horarioSelecionado.hour == hora.hour &&
        _horarioSelecionado.minute == hora.minute;
    return InkWell(
      onTap: () => setState(() {
        _horarioSelecionado = hora;
        _horarioController.text = _formatarHora(hora);
      }),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor,
            width: selecionado ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          _formatarHora(hora),
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // CALENDÁRIO VISUAL PROGRAMÁVEL DENTRO DO CONTAINER
  // ═════════════════════════════════════════════════════════════════
  Widget _renderCalendarioMensal(AppTheme theme) {
    const nomesMeses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    final primeiroDiaMes = DateTime(_mesCalendario.year, _mesCalendario.month, 1);
    final ultimoDiaMes = DateTime(_mesCalendario.year, _mesCalendario.month + 1, 0);

    // weekday: 1 (segunda) ... 7 (domingo). No Brasil normalmente a coluna 0 é Domingo.
    final offsetDomingo = primeiroDiaMes.weekday % 7;
    final totalDias = ultimoDiaMes.day;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Barra de Navegação do Mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.textColor,
                onPressed: () {
                  setState(() {
                    _mesCalendario = DateTime(
                        _mesCalendario.year, _mesCalendario.month - 1, 1);
                  });
                },
              ),
              Text(
                '${nomesMeses[_mesCalendario.month - 1]} ${_mesCalendario.year}',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.textColor,
                onPressed: () {
                  setState(() {
                    _mesCalendario = DateTime(
                        _mesCalendario.year, _mesCalendario.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Cabeçalho dos dias da semana (Dom, Seg, Ter, Qua, Qui, Sex, Sáb)
          Row(
            children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Grade dos Dias
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offsetDomingo + totalDias,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              if (index < offsetDomingo) {
                return const SizedBox.shrink();
              }
              final dia = index - offsetDomingo + 1;
              final dataCorrente =
                  DateTime(_mesCalendario.year, _mesCalendario.month, dia);

              final selecionada = _datasEspecificasSelecionadas.any((d) =>
                  d.year == dataCorrente.year &&
                  d.month == dataCorrente.month &&
                  d.day == dataCorrente.day);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (selecionada) {
                      _datasEspecificasSelecionadas.removeWhere((d) =>
                          d.year == dataCorrente.year &&
                          d.month == dataCorrente.month &&
                          d.day == dataCorrente.day);
                    } else {
                      _datasEspecificasSelecionadas.add(dataCorrente);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: selecionada
                        ? theme.textColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selecionada ? theme.textColor : theme.borderColor.withValues(alpha: 0.3),
                      width: selecionada ? 1.6 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dia',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${_datasEspecificasSelecionadas.length} data(s) marcada(s) no calendário',
            style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // WIDGET: SELEÇÃO DE ITEM (CATEGORIA OU SOLTO + ACOMPANHAMENTOS)
  // ═════════════════════════════════════════════════════════════════
  Widget _blocoSelecaoItemComanda({
    required AppTheme theme,
    required List<CategoriaLoja> categorias,
    required List<ItemLoja> todosItens,
    required List<GrupoComponentesLoja> grupos,
  }) {
    // Itens elegíveis para o dropdown
    final List<ItemLoja> itensElegiveis;
    if (_modoItemSolto || _categoriaSelecionada == null) {
      itensElegiveis = todosItens;
    } else {
      itensElegiveis = _categoriaSelecionada!.itemIds
          .map((id) => todosItens.where((i) => i.id == id).firstOrNull)
          .whereType<ItemLoja>()
          .toList();
    }

    // Grupos de adicionais vinculados à categoria selecionada
    final List<GrupoComponentesLoja> gruposElegiveis;
    if (!_modoItemSolto && _categoriaSelecionada != null) {
      gruposElegiveis = _categoriaSelecionada!.grupoIds
          .map((gId) => grupos.where((g) => g.id == gId).firstOrNull)
          .whereType<GrupoComponentesLoja>()
          .toList();
    } else {
      gruposElegiveis = const [];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, size: 16, color: theme.textColor),
              const SizedBox(width: 6),
              Text(
                'Adicionar Item ao Pedido',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Seletor de Categoria vs Item Solto
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CategoriaLoja?>(
                  initialValue: _modoItemSolto ? null : _categoriaSelecionada,
                  isExpanded: true,
                  dropdownColor: theme.cardBackgroundColor,
                  decoration: InputDecoration(
                    labelText: 'Categoria (opcional)',
                    labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<CategoriaLoja?>(
                      value: null,
                      child: Text(
                        'Item Solto / Avulso (sem categoria)',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    ...categorias.map((cat) {
                      final precoCat = _precoComoNumero(cat.preco) > 0
                          ? ' (+ ${_valorFormatado(_precoComoNumero(cat.preco))})'
                          : '';
                      return DropdownMenuItem<CategoriaLoja?>(
                        value: cat,
                        child: Text(
                          '${cat.nome}$precoCat',
                          style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (cat) {
                    setState(() {
                      if (cat == null) {
                        _modoItemSolto = true;
                        _categoriaSelecionada = null;
                      } else {
                        _modoItemSolto = false;
                        _categoriaSelecionada = cat;
                      }
                      _itemSelecionado = null;
                      _varianteSelecionada = null;
                      _acompanhamentosQuantidades.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Seletor de Item
          DropdownButtonFormField<ItemLoja?>(
            key: ValueKey('${_categoriaSelecionada?.id}_$_modoItemSolto'),
            initialValue: _itemSelecionado,
            isExpanded: true,
            dropdownColor: theme.cardBackgroundColor,
            decoration: InputDecoration(
              labelText: _modoItemSolto
                  ? 'Produto / Item Solto'
                  : (_categoriaSelecionada != null
                      ? 'Item da Categoria ${_categoriaSelecionada!.nome}'
                      : 'Produto / Item'),
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
            items: itensElegiveis.map((item) {
              final precoTotalUnit = _precoComoNumero(item.preco) +
                  (!_modoItemSolto && _categoriaSelecionada != null
                      ? _precoComoNumero(_categoriaSelecionada!.preco)
                      : 0.0);
              return DropdownMenuItem<ItemLoja?>(
                value: item,
                child: Text(
                  '${item.nome} (${_valorFormatado(precoTotalUnit)})',
                  style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (item) {
              setState(() {
                _itemSelecionado = item;
                _varianteSelecionada = null;
                _acompanhamentosQuantidades.clear();
              });
            },
          ),

          // Seletor de Variante (se o item possuir)
          if (_itemSelecionado != null && _itemSelecionado!.variantes.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<VarianteItem?>(
              key: ValueKey('${_itemSelecionado?.id}_variante'),
              initialValue: _varianteSelecionada,
              isExpanded: true,
              dropdownColor: theme.cardBackgroundColor,
              decoration: InputDecoration(
                labelText: 'Opção / Variante (opcional)',
                labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
              ),
              items: [
                DropdownMenuItem<VarianteItem?>(
                  value: null,
                  child: Text(
                    'Desativado',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                ..._itemSelecionado!.variantes.map((v) {
                  final precoVar = v.preco.isNotEmpty
                      ? ' (${_valorFormatado(_precoComoNumero(v.preco))})'
                      : '';
                  return DropdownMenuItem<VarianteItem?>(
                    value: v,
                    child: Text(
                      '${v.nome}$precoVar',
                      style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                    ),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _varianteSelecionada = v),
            ),
          ],

          // Grupos de Acompanhamentos / Adicionais da Categoria
          if (gruposElegiveis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Acompanhamentos e Adicionais:',
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            for (final grupo in gruposElegiveis) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupo.nome,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final itemId in grupo.itemIds)
                      Builder(builder: (ctx) {
                        final acomp =
                            todosItens.where((i) => i.id == itemId).firstOrNull;
                        if (acomp == null) return const SizedBox.shrink();
                        final qtdAtual = _acompanhamentosQuantidades[itemId] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  acomp.nome,
                                  style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
                                ),
                              ),
                              Text(
                                _valorFormatado(_precoComoNumero(acomp.preco)),
                                style: theme.getTextStyle(
                                    fontSize: 10, color: theme.secondaryTextColor),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(2),
                                color: theme.textColor,
                                onPressed: qtdAtual > 0
                                    ? () {
                                        setState(() {
                                          if (qtdAtual <= 1) {
                                            _acompanhamentosQuantidades.remove(itemId);
                                          } else {
                                            _acompanhamentosQuantidades[itemId] = qtdAtual - 1;
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '$qtdAtual',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(2),
                                color: theme.textColor,
                                onPressed: () {
                                  setState(() {
                                    _acompanhamentosQuantidades[itemId] = qtdAtual + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 10),

          // Quantidade e Observação do Item
          Row(
            children: [
              Text(
                'Quantidade:',
                style: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: theme.textColor,
                onPressed: _quantidadeItem > 1
                    ? () => setState(() => _quantidadeItem--)
                    : null,
              ),
              Text(
                '$_quantidadeItem',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: theme.textColor,
                onPressed: () => setState(() => _quantidadeItem++),
              ),
              const Spacer(),
              if (_itemSelecionado != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal Item:',
                      style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
                    ),
                    Text(
                      _valorFormatado(_subtotalItemAtual),
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _obsItemController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 11, color: theme.textColor),
            decoration: InputDecoration(
              labelText: 'Observação do item (ex.: sem cebola, bem passado)',
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.textColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('Adicionar Item ao Pedido'),
              onPressed: _itemSelecionado != null ? _adicionarItemAoPedido : null,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // WIDGET: LISTA DOS ITENS ADICIONADOS AO PEDIDO
  // ═════════════════════════════════════════════════════════════════
  Widget _blocoItensDoPedido(AppTheme theme) {
    if (_itensAdicionados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            'Nenhum item adicionado ao pedido ainda.',
            style: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comanda do Pedido (${_itensAdicionados.length} itens)',
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Text(
                _valorFormatado(_totalGeralPedido),
                style: theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itensAdicionados.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = _itensAdicionados[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantidade}x ${item.nomeExibicao}',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          if (item.acompanhamentos.isNotEmpty)
                            Text(
                              item.acompanhamentos
                                  .map((a) => '+ ${a.quantidadePorUnidade}x ${a.nomeItem}')
                                  .join(', '),
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          if (item.observacao.isNotEmpty)
                            Text(
                              'Obs: ${item.observacao}',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.secondaryTextColor,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          Text(
                            _valorFormatado(item.subtotal),
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _itensAdicionados.removeAt(index));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // WIDGET: FORMA DE PAGAMENTO E OBSERVAÇÕES
  // ═════════════════════════════════════════════════════════════════
  Widget _blocoPagamentoEObservacoes(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forma de Pagamento e Detalhes',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _formaPagamento,
            dropdownColor: theme.cardBackgroundColor,
            decoration: InputDecoration(
              labelText: 'Forma de Pagamento',
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
            items: _formas.map((f) {
              return DropdownMenuItem<String>(
                value: f,
                child: Text(
                  f,
                  style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _formaPagamento = val);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _obsGeralController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            decoration: InputDecoration(
              labelText: 'Observações do Contrato / Pedido Programado (opcional)',
              labelStyle: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// DIÁLOGO: DIGITAR O HORÁRIO COM SUPORTE À BOLINHA DO MOUSE E SALVAR
// ═════════════════════════════════════════════════════════════════
class _DigitarHorarioDialog extends StatefulWidget {
  final TimeOfDay horarioInicial;
  final AppTheme theme;

  const _DigitarHorarioDialog({
    required this.horarioInicial,
    required this.theme,
  });

  @override
  State<_DigitarHorarioDialog> createState() => _DigitarHorarioDialogState();
}

class _DigitarHorarioDialogState extends State<_DigitarHorarioDialog> {
  late TimeOfDay _horario;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _horario = widget.horarioInicial;
    _controller = TextEditingController(text: _formatarHora(_horario));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatarHora(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _sincronizarDoTexto() {
    final partes = _controller.text.trim().split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        _horario = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  void _ajustarMinutos(int delta) {
    _sincronizarDoTexto();
    var novoMinuto = _horario.minute + delta;
    var novaHora = _horario.hour;
    if (novoMinuto >= 60) {
      novoMinuto = novoMinuto - 60;
      novaHora = (novaHora + 1) % 24;
    } else if (novoMinuto < 0) {
      novoMinuto = novoMinuto + 60;
      novaHora = (novaHora - 1 + 24) % 24;
    }
    setState(() {
      _horario = TimeOfDay(hour: novaHora, minute: novoMinuto);
      _controller.text = _formatarHora(_horario);
    });
  }

  void _aoDigitar(String valor) {
    final partes = valor.trim().split(':');
    if (partes.length == 2 && partes[0].length == 2 && partes[1].length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60) {
        setState(() {
          _horario = TimeOfDay(hour: h, minute: m);
        });
      }
    }
  }

  void _salvar() {
    _sincronizarDoTexto();
    Navigator.of(context).pop(_horario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy < 0) {
                // Rolar a bolinha para cima: sobe / aumenta o horário
                _ajustarMinutos(1);
              } else if (pointerSignal.scrollDelta.dy > 0) {
                // Rolar a bolinha para baixo: desce / diminui o horário
                _ajustarMinutos(-1);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho da janela
                Row(
                  children: [
                    Icon(Icons.access_time_filled, color: theme.textColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digite o Horário (HH:MM)',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Digite o horário ou role a rodinha do mouse neste painel para subir ou descer os números.',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Painel de entrada com visor grande
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.7),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 28),
                            color: theme.textColor,
                            tooltip: 'Diminuir 1 minuto',
                            onPressed: () => _ajustarMinutos(-1),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              cursorColor: theme.textColor,
                              inputFormatters: [_HorarioInputFormatter()],
                              style: theme.getTextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                              ),
                              onChanged: _aoDigitar,
                              onSubmitted: (_) => _salvar(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 28),
                            color: theme.textColor,
                            tooltip: 'Aumentar 1 minuto',
                            onPressed: () => _ajustarMinutos(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Botões rápidos de delta (-10m, -5m, +5m, +10m)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chipAjuste(theme, -10, '-10m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, -5, '-5m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, 5, '+5m'),
                          const SizedBox(width: 6),
                          _chipAjuste(theme, 10, '+10m'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sugestões comerciais de horário
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _chipSugerido(theme, const TimeOfDay(hour: 11, minute: 30)),
                    _chipSugerido(theme, const TimeOfDay(hour: 12, minute: 0)),
                    _chipSugerido(theme, const TimeOfDay(hour: 12, minute: 30)),
                    _chipSugerido(theme, const TimeOfDay(hour: 18, minute: 0)),
                    _chipSugerido(theme, const TimeOfDay(hour: 19, minute: 30)),
                  ],
                ),
                const SizedBox(height: 20),

                // Botões de Ação no Rodapé: Cancelar e Salvar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          'Salvar',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        onPressed: _salvar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipAjuste(AppTheme theme, int delta, String label) {
    return InkWell(
      onTap: () => _ajustarMinutos(delta),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.textColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: theme.getTextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }

  Widget _chipSugerido(AppTheme theme, TimeOfDay hora) {
    final selecionado = _horario.hour == hora.hour && _horario.minute == hora.minute;
    return InkWell(
      onTap: () {
        setState(() {
          _horario = hora;
          _controller.text = _formatarHora(hora);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado
              ? theme.textColor.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selecionado ? theme.textColor : theme.borderColor,
            width: selecionado ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          _formatarHora(hora),
          style: theme.getTextStyle(
            fontSize: 11,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
}
