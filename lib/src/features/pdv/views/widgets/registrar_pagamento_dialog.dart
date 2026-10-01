import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

class ResultadoPagamento {
  final String cpf;
  final String nome;
  final double valor;
  final String descricao;

  const ResultadoPagamento({
    required this.cpf,
    required this.nome,
    required this.valor,
    required this.descricao,
  });
}

class RegistrarPagamentoDialog {
  static Future<ResultadoPagamento?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<MembroLoja> membros,
    required double sugestaoPorMembro,
    required double disponivelNoPeriodo,
    required int numeroMembros,
  }) {
    return showDialog<ResultadoPagamento>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _RegistrarPagamentoConteudo(
              theme: theme,
              membros: membros,
              sugestaoPorMembro: sugestaoPorMembro,
              disponivelNoPeriodo: disponivelNoPeriodo,
              numeroMembros: numeroMembros,
            ),
          ),
        );
      },
    );
  }
}

class _RegistrarPagamentoConteudo extends StatefulWidget {
  final AppTheme theme;
  final List<MembroLoja> membros;
  final double sugestaoPorMembro;
  final double disponivelNoPeriodo;
  final int numeroMembros;

  const _RegistrarPagamentoConteudo({
    required this.theme,
    required this.membros,
    required this.sugestaoPorMembro,
    required this.disponivelNoPeriodo,
    required this.numeroMembros,
  });

  @override
  State<_RegistrarPagamentoConteudo> createState() =>
      _RegistrarPagamentoConteudoState();
}

class _RegistrarPagamentoConteudoState
    extends State<_RegistrarPagamentoConteudo> {
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  MembroLoja? _selecionado;
  String? _aviso;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  String _valorFormatado(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  String _rotuloPapel(PapelMembro p) {
    switch (p) {
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

  void _usarSugestao() {
    if (widget.sugestaoPorMembro <= 0) return;
    _valorController.text =
        widget.sugestaoPorMembro.toStringAsFixed(2).replaceAll('.', ',');
    setState(() {});
  }

  void _confirmar() {
    final membro = _selecionado;
    if (membro == null) {
      setState(() => _aviso = 'Selecione o membro.');
      return;
    }
    final texto = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null || valor <= 0) {
      setState(() => _aviso = 'Informe um valor válido.');
      return;
    }
    Navigator.of(context).pop(
      ResultadoPagamento(
        cpf: membro.cpf,
        nome: membro.nome,
        valor: valor,
        descricao: _descricaoController.text.trim(),
      ),
    );
  }

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _linhaSugestao() {
    if (widget.numeroMembros == 0) {
      return Text(
        'A loja ainda não tem membros ativos.',
        style: theme.getTextStyle(
          fontSize: 11,
          color: theme.secondaryTextColor,
        ),
      );
    }

    if (widget.disponivelNoPeriodo <= 0) {
      return Text(
        'Não há saldo disponível no período (disponível: '
        '${_valorFormatado(widget.disponivelNoPeriodo)}).',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 11,
          color: Colors.redAccent,
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Sugestão de divisão igualitária',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Saldo disponível ${_valorFormatado(widget.disponivelNoPeriodo)} ÷ '
          '${widget.numeroMembros} ${widget.numeroMembros == 1 ? 'membro' : 'membros'}',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 10,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _valorFormatado(widget.sugestaoPorMembro),
          style: theme.getTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textColor,
            side: BorderSide(color: theme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _usarSugestao,
          child: Text(
            'Usar esse valor',
            style: theme.getTextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Registrar Pagamento',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: _decoracaoDoBloco,
                  child: _linhaSugestao(),
                ),
                const SizedBox(height: 16),
                _tituloDoBloco('Membro'),
                if (widget.membros.isEmpty)
                  Text(
                    'Nenhum membro na loja.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MembroLoja>(
                        value: _selecionado,
                        isExpanded: true,
                        dropdownColor: theme.cardBackgroundColor,
                        hint: Text(
                          'Selecione o membro',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        items: widget.membros
                            .map(
                              (m) => DropdownMenuItem<MembroLoja>(
                                value: m,
                                child: Text(
                                  '${m.nome} • ${_rotuloPapel(m.papel)}',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) =>
                            setState(() => _selecionado = valor),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _tituloDoBloco('Valor (R\$)'),
                TextField(
                  controller: _valorController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Ex: 250,00'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _tituloDoBloco('Descrição (opcional)'),
                TextField(
                  controller: _descricaoController,
                  maxLines: 3,
                  cursorColor: theme.textColor,
                  style: theme.getTextStyle(fontSize: 12),
                  decoration: _decoracaoCampo('Ex: referente à semana'),
                ),
                if (_aviso != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _aviso!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      side: BorderSide(color: theme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _confirmar,
                    child: Text(
                      'Registrar',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}