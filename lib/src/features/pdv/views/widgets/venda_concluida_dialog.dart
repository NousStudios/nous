import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido.dart';

const Map<String, String> _rotulosCamposCliente = {
  'cnpj': 'CNPJ',
  'telefone': 'Telefone',
  'endereco': 'Endereço',
  'email': 'Email',
  'redesSociais': 'Redes sociais',
  'descricao': 'Descrição',
};

class VendaConcluidaDialog {
  static Future<bool> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PedidoLoja pedido,
    required ConfiguracoesImpressora configuracoesImpressora,
    Cliente? cliente,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final querRegistrar =
                await _confirmarRegistroVenda(dialogContext, theme);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(querRegistrar);
            }
          },
          child: Dialog(
            backgroundColor: theme.cardBackgroundColor,
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.borderColor),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _VendaConcluidaConteudo(
                theme: theme,
                pedido: pedido,
                configuracoesImpressora: configuracoesImpressora,
                cliente: cliente,
              ),
            ),
          ),
        );
      },
    );
    return resultado ?? false;
  }
}

Future<bool> _confirmarRegistroVenda(
    BuildContext context, AppTheme theme) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'Registrar Venda?',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: Text(
        'Deseja registrar e salvar esta venda no sistema ou descartá-la?',
        textAlign: TextAlign.center,
        style:
            theme.getTextStyle(fontSize: 13, color: theme.secondaryTextColor),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Descartar venda',
            style: theme.getTextStyle(fontSize: 12, color: Colors.redAccent),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor,
            foregroundColor: theme.buttonTextColor,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Sim, registrar venda',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.buttonTextColor,
            ),
          ),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

class _VendaConcluidaConteudo extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final ConfiguracoesImpressora configuracoesImpressora;
  final Cliente? cliente;

  const _VendaConcluidaConteudo({
    required this.theme,
    required this.pedido,
    required this.configuracoesImpressora,
    this.cliente,
  });

  @override
  State<_VendaConcluidaConteudo> createState() =>
      _VendaConcluidaConteudoState();
}

class _VendaConcluidaConteudoState extends State<_VendaConcluidaConteudo> {
  bool _imprimindo = false;
  late List<String> _camposClienteComanda;

  AppTheme get theme => widget.theme;
  PedidoLoja get pedido => widget.pedido;

  @override
  void initState() {
    super.initState();
    final config = widget.configuracoesImpressora;
    final configCampos = config.camposClienteComanda;
    final ehPadraoAntigoCompleto = !config.camposClientePersonalizados &&
        configCampos.length == kCamposClienteComanda.length &&
        kCamposClienteComanda.every((ch) => configCampos.contains(ch));

    _camposClienteComanda = ehPadraoAntigoCompleto
        ? List.of(kCamposClienteComandaPadrao)
        : List.of(configCampos);

    if (config.imprimirAutomaticoAoConcluir) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _imprimir();
        }
      });
    }
  }

  Future<void> _imprimir() async {
    if (_imprimindo) return;

    setState(() => _imprimindo = true);
    try {
      final config = widget.configuracoesImpressora.copyWith(
        camposClienteComanda: List.of(_camposClienteComanda),
      );
      await ImpressaoService.imprimirComanda(
        config: config,
        pedido: pedido,
        cliente: widget.cliente,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Comanda enviada para a impressora.',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Falha ao imprimir: $e',
            style: theme.getTextStyle(color: theme.textColor),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Widget _linhaCheckbox(String chave) {
    final marcado = _camposClienteComanda.contains(chave);
    final rotulo = _rotulosCamposCliente[chave] ?? chave;
    return InkWell(
      onTap: () {
        setState(() {
          if (marcado) {
            _camposClienteComanda.remove(chave);
          } else {
            _camposClienteComanda.add(chave);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: marcado,
                activeColor: theme.buttonColor,
                checkColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      if (!_camposClienteComanda.contains(chave)) {
                        _camposClienteComanda.add(chave);
                      }
                    } else {
                      _camposClienteComanda.remove(chave);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              rotulo,
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoCamposCliente() {
    if (widget.cliente == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Cliente não cadastrado — nada além do nome aparecerá na comanda.',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Dados do cliente na comanda',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: [
              for (final chave in kCamposClienteComanda)
                _linhaCheckbox(chave),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Venda concluída',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${pedido.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: ComandaPedido(
                theme: theme,
                pedido: pedido,
                mostrarTitulo: false,
                cliente: widget.cliente,
                camposClienteComanda: _camposClienteComanda,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _blocoCamposCliente(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _imprimindo ? null : _imprimir,
                  child: _imprimindo
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.textColor,
                          ),
                        )
                      : Text(
                          'Imprimir',
                          style: theme.getTextStyle(fontSize: 13),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Concluído',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}