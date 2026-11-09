import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

class DialogNovoGastoFixo extends StatefulWidget {
  final AppTheme theme;
  final List<MembroLoja> membros;
  final ValueChanged<GastoFixo> onSalvar;

  const DialogNovoGastoFixo({
    super.key,
    required this.theme,
    this.membros = const [],
    required this.onSalvar,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    List<MembroLoja> membros = const [],
    required ValueChanged<GastoFixo> onSalvar,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DialogNovoGastoFixo(
        theme: theme,
        membros: membros,
        onSalvar: onSalvar,
      ),
    );
  }

  @override
  State<DialogNovoGastoFixo> createState() => _DialogNovoGastoFixoState();
}

class _DialogNovoGastoFixoState extends State<DialogNovoGastoFixo> {
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _diaMesController = TextEditingController(text: '1');
  TipoRecorrenciaGasto _recorrencia = TipoRecorrenciaGasto.diario;
  final List<int> _diasDaSemana = [1, 2, 3, 4, 5]; // Seg-Sex por padrão
  String _formaPagamento = 'Dinheiro';
  String? _cpfFuncionarioSelecionado;

  static const List<String> _formas = [
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
    _descricaoController.dispose();
    _valorController.dispose();
    _diaMesController.dispose();
    super.dispose();
  }

  void _salvar() {
    final desc = _descricaoController.text.trim();
    final textoValor = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(textoValor) ?? 0.0;

    if (desc.isEmpty || valor <= 0) return;

    int? diaMes;
    if (_recorrencia == TipoRecorrenciaGasto.mensal) {
      diaMes = int.tryParse(_diaMesController.text.trim()) ?? 1;
    }

    String nomeFuncionario = '';
    if (_cpfFuncionarioSelecionado != null && _cpfFuncionarioSelecionado!.isNotEmpty) {
      final m = widget.membros.where((mem) => mem.cpf == _cpfFuncionarioSelecionado).firstOrNull;
      nomeFuncionario = m?.nome ?? '';
    }

    final novo = GastoFixo.novo(
      descricao: desc,
      valor: valor,
      recorrencia: _recorrencia,
      diasDaSemana: _recorrencia == TipoRecorrenciaGasto.diasDaSemana || _recorrencia == TipoRecorrenciaGasto.semanal
          ? _diasDaSemana
          : const [],
      diaDoMes: diaMes,
      formaPagamentoPadrao: _formaPagamento,
      cpfFuncionario: _cpfFuncionarioSelecionado ?? '',
      nomeFuncionario: nomeFuncionario,
      ativo: true,
    );

    widget.onSalvar(novo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );

    const nomesDias = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Row(
        children: [
          Icon(Icons.repeat_rounded, size: 20, color: theme.textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Configurar Gasto Fixo Recorrente',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Descrição do Gasto',
                style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _descricaoController,
                cursorColor: theme.textColor,
                style: theme.getTextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: Aluguel, Diária Faxina, Carne da semana',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: borda(theme.borderColor.withValues(alpha: 0.6)),
                  focusedBorder: borda(theme.textColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Recorrente',
                          style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _valorController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                          ],
                          cursorColor: theme.textColor,
                          style: theme.getTextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            prefixText: 'R\$ ',
                            prefixStyle: theme.getTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
                            hintText: '0,00',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: borda(theme.borderColor.withValues(alpha: 0.6)),
                            focusedBorder: borda(theme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forma Pagamento',
                          style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _formaPagamento,
                              dropdownColor: theme.cardBackgroundColor,
                              isExpanded: true,
                              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                              items: _formas.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _formaPagamento = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Recorrência',
                style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
              ),
              const SizedBox(height: 4),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoRecorrenciaGasto>(
                    value: _recorrencia,
                    dropdownColor: theme.cardBackgroundColor,
                    isExpanded: true,
                    style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                    items: TipoRecorrenciaGasto.values.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r.rotulo));
                    }).toList(),
                    onChanged: (novo) {
                      if (novo != null) setState(() => _recorrencia = novo);
                    },
                  ),
                ),
              ),
              if (_recorrencia == TipoRecorrenciaGasto.diasDaSemana || _recorrencia == TipoRecorrenciaGasto.semanal) ...[
                const SizedBox(height: 10),
                Text(
                  _recorrencia == TipoRecorrenciaGasto.semanal ? 'Dia da semana (ex: toda quinta-feira):' : 'Dias específicos:',
                  style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (idx) {
                    final dia = idx + 1;
                    final selecionado = _diasDaSemana.contains(dia);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (_recorrencia == TipoRecorrenciaGasto.semanal) {
                            _diasDaSemana.clear();
                            _diasDaSemana.add(dia);
                          } else {
                            if (selecionado) {
                              if (_diasDaSemana.length > 1) _diasDaSemana.remove(dia);
                            } else {
                              _diasDaSemana.add(dia);
                            }
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? (theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.35))
                              : theme.backgroundColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selecionado ? theme.textColor : theme.borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          nomesDias[dia]!,
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              if (_recorrencia == TipoRecorrenciaGasto.mensal) ...[
                const SizedBox(height: 10),
                Text(
                  'Dia de vencimento no mês (1 a 31):',
                  style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _diaMesController,
                    keyboardType: TextInputType.number,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: borda(theme.borderColor.withValues(alpha: 0.6)),
                      focusedBorder: borda(theme.textColor),
                    ),
                  ),
                ),
              ],
              if (widget.membros.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Vincular a Funcionário (opcional para diárias/salários):',
                  style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _cpfFuncionarioSelecionado,
                      dropdownColor: theme.cardBackgroundColor,
                      isExpanded: true,
                      style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhum funcionário vinculado')),
                        ...widget.membros.map((m) {
                          return DropdownMenuItem(
                            value: m.cpf,
                            child: Text('${m.nome.isNotEmpty ? m.nome : "Sem nome"} (${m.papel.name})'),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _cpfFuncionarioSelecionado = v),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
            foregroundColor: theme.textColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _salvar,
          child: Text('Salvar Gasto Fixo', style: theme.getTextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
