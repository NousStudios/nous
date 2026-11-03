import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido/bloco_frequencia_horario_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido/bloco_selecao_item_programado_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/programar_pedido/bloco_comanda_programada_widget.dart';

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
                        const SizedBox(width: 28),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month, color: theme.textColor, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Programar Pedido do Cliente',
                                      textAlign: TextAlign.center,
                                      style: theme.getTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cliente: ${widget.cliente.nome}',
                                textAlign: TextAlign.center,
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
                          BlocoFrequenciaHorarioWidget(
                            theme: theme,
                            modoProgramacao: _modoProgramacao,
                            onModoProgramacaoChanged: (modo) =>
                                setState(() => _modoProgramacao = modo),
                            diasSemanaSelecionados: _diasSemanaSelecionados,
                            onAlternarDiaSemana: (dia) {
                              setState(() {
                                if (_diasSemanaSelecionados.contains(dia)) {
                                  _diasSemanaSelecionados.remove(dia);
                                } else {
                                  _diasSemanaSelecionados.add(dia);
                                }
                              });
                            },
                            onDefinirDiasSemana: (dias) {
                              setState(() {
                                _diasSemanaSelecionados
                                  ..clear()
                                  ..addAll(dias);
                              });
                            },
                            mesCalendario: _mesCalendario,
                            onMesCalendarioChanged: (mes) =>
                                setState(() => _mesCalendario = mes),
                            datasEspecificasSelecionadas:
                                _datasEspecificasSelecionadas,
                            onAlternarDataEspecifica: (dataCorrente) {
                              setState(() {
                                final selecionada =
                                    _datasEspecificasSelecionadas.any((d) =>
                                        d.year == dataCorrente.year &&
                                        d.month == dataCorrente.month &&
                                        d.day == dataCorrente.day);
                                if (selecionada) {
                                  _datasEspecificasSelecionadas.removeWhere(
                                      (d) =>
                                          d.year == dataCorrente.year &&
                                          d.month == dataCorrente.month &&
                                          d.day == dataCorrente.day);
                                } else {
                                  _datasEspecificasSelecionadas
                                      .add(dataCorrente);
                                }
                              });
                            },
                            horarioSelecionado: _horarioSelecionado,
                            horarioController: _horarioController,
                            horarioFocusNode: _horarioFocusNode,
                            onMouseSobreHorarioChanged: (mouse) =>
                                setState(() => _mouseSobreHorario = mouse),
                            onDigitarHorario: _aoDigitarHorario,
                            onAjustarMinutos: _ajustarMinutos,
                            onHorarioSelecionado: (h) {
                              setState(() {
                                _horarioSelecionado = h;
                                _horarioController.text = _formatarHora(h);
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          BlocoSelecaoItemProgramadoWidget(
                            theme: theme,
                            categorias: categorias,
                            todosItens: todosItens,
                            grupos: grupos,
                            categoriaSelecionada: _categoriaSelecionada,
                            modoItemSolto: _modoItemSolto,
                            onCategoriaChanged: (cat) {
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
                            itemSelecionado: _itemSelecionado,
                            onItemChanged: (item) {
                              setState(() {
                                _itemSelecionado = item;
                                _varianteSelecionada = null;
                                _acompanhamentosQuantidades.clear();
                              });
                            },
                            varianteSelecionada: _varianteSelecionada,
                            onVarianteChanged: (v) =>
                                setState(() => _varianteSelecionada = v),
                            acompanhamentosQuantidades:
                                _acompanhamentosQuantidades,
                            onAlterarQuantidadeAcompanhamento: (itemId, delta) {
                              setState(() {
                                final qtd =
                                    _acompanhamentosQuantidades[itemId] ?? 0;
                                final nova = qtd + delta;
                                if (nova <= 0) {
                                  _acompanhamentosQuantidades.remove(itemId);
                                } else {
                                  _acompanhamentosQuantidades[itemId] = nova;
                                }
                              });
                            },
                            quantidadeItem: _quantidadeItem,
                            onAlterarQuantidadeItem: (delta) {
                              setState(() {
                                final nova = _quantidadeItem + delta;
                                if (nova >= 1) _quantidadeItem = nova;
                              });
                            },
                            obsItemController: _obsItemController,
                            subtotalItemAtual: _subtotalItemAtual,
                            onAdicionarItem: _itemSelecionado != null
                                ? _adicionarItemAoPedido
                                : null,
                            valorFormatado: _valorFormatado,
                            precoComoNumero: _precoComoNumero,
                          ),
                          const SizedBox(height: 12),
                          BlocoComandaProgramadaWidget(
                            theme: theme,
                            itensAdicionados: _itensAdicionados,
                            totalGeralPedido: _totalGeralPedido,
                            onRemoverItem: (idx) => setState(
                                () => _itensAdicionados.removeAt(idx)),
                            formaPagamento: _formaPagamento,
                            formasDisponiveis: _formas,
                            onFormaPagamentoChanged: (val) {
                              if (val != null) {
                                setState(() => _formaPagamento = val);
                              }
                            },
                            obsGeralController: _obsGeralController,
                            valorFormatado: _valorFormatado,
                          ),
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
}
