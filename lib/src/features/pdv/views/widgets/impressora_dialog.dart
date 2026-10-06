import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';

const Map<String, String> _rotulosCamposCliente = {
  'cnpj': 'CNPJ',
  'telefone': 'Telefone',
  'endereco': 'Endereço',
  'email': 'Email',
  'redesSociais': 'Redes sociais',
  'descricao': 'Descrição',
};

class ImpressoraDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required ConfiguracoesImpressora configuracoes,
    required ValueChanged<ConfiguracoesImpressora> onSalvar,
  }) {
    return showDialog<void>(
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: _ImpressoraConteudo(
              theme: theme,
              configuracoesIniciais: configuracoes,
              onSalvar: onSalvar,
            ),
          ),
        );
      },
    );
  }
}

class _ImpressoraConteudo extends StatefulWidget {
  final AppTheme theme;
  final ConfiguracoesImpressora configuracoesIniciais;
  final ValueChanged<ConfiguracoesImpressora> onSalvar;

  const _ImpressoraConteudo({
    required this.theme,
    required this.configuracoesIniciais,
    required this.onSalvar,
  });

  @override
  State<_ImpressoraConteudo> createState() => _ImpressoraConteudoState();
}

class _ImpressoraConteudoState extends State<_ImpressoraConteudo> {
  late final TextEditingController _rodapeController;
  late final TextEditingController _enderecoRedeController;
  late final TextEditingController _nomeImpressoraController;

  late String _tamanhoFonte;
  late String _tipoConexao;
  late List<String> _camposClienteComanda;

  bool _carregandoImpressoras = false;
  bool _imprimindo = false;
  List<Printer> _impressoras = const [];

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    final c = widget.configuracoesIniciais;
    _rodapeController = TextEditingController(text: c.rodape);
    _enderecoRedeController = TextEditingController(text: c.enderecoRede);
    _nomeImpressoraController = TextEditingController(text: c.nomeImpressora);
    _tamanhoFonte = c.tamanhoFonte;
    _tipoConexao = c.tipoConexao;
    final camposConfig = c.camposClienteComanda;
    final ehPadraoAntigoCompleto = !c.camposClientePersonalizados &&
        camposConfig.length == kCamposClienteComanda.length &&
        kCamposClienteComanda.every((ch) => camposConfig.contains(ch));

    _camposClienteComanda = ehPadraoAntigoCompleto
        ? List.of(kCamposClienteComandaPadrao)
        : List.of(camposConfig);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarImpressoras();
    });
  }

  @override
  void dispose() {
    _rodapeController.dispose();
    _enderecoRedeController.dispose();
    _nomeImpressoraController.dispose();
    super.dispose();
  }

  Future<void> _carregarImpressoras() async {
    setState(() => _carregandoImpressoras = true);
    final lista = await ImpressaoService.listarImpressoras();
    if (!mounted) return;
    setState(() {
      _impressoras = lista;
      _carregandoImpressoras = false;
    });
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

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _botaoSelecao(
    String rotulo,
    String valor,
    String valorAtual,
    ValueChanged<String> aoSelecionar,
  ) {
    final selecionado = valor == valorAtual;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionado ? theme.buttonColor : Colors.transparent,
        foregroundColor: selecionado ? theme.buttonTextColor : theme.textColor,
        side: BorderSide(color: theme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => aoSelecionar(valor),
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 12,
          color: selecionado ? theme.buttonTextColor : theme.textColor,
        ),
      ),
    );
  }

  Widget _blocoRodape() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Rodapé da Comanda'),
          TextField(
            controller: _rodapeController,
            maxLines: 3,
            textAlign: TextAlign.center,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Ex: linktr.ee/nous72'),
          ),
        ],
      ),
    );
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

  Widget _blocoDadosCliente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Dados do Cliente na Comanda'),
          Text(
            'Marque o que deve aparecer na comanda quando o cliente '
            'estiver cadastrado e o campo estiver preenchido.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: [
              for (final chave in kCamposClienteComanda)
                _linhaCheckbox(chave),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _camposClienteComanda =
                        List.of(kCamposClienteComanda);
                  });
                },
                child: Text(
                  'Marcar todos',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  setState(() => _camposClienteComanda = []);
                },
                child: Text(
                  'Desmarcar todos',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoFonte() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Tamanho da Fonte'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('Pequena', 'pequena', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
              _botaoSelecao('Normal', 'normal', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
              _botaoSelecao('Grande', 'grande', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaImpressora(Printer printer) {
    final selecionada =
        _nomeImpressoraController.text.trim() == printer.name;

    return _LinhaComHover(
      aoClicar: () {
        setState(() {
          _nomeImpressoraController.text = printer.name;
        });
      },
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selecionada
              ? theme.buttonColor.withValues(alpha: 0.25)
              : hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionada || hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              printer.isAvailable
                  ? Icons.print_outlined
                  : Icons.print_disabled_outlined,
              size: 18,
              color: theme.textColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                printer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.textColor,
                ),
              ),
            ),
            if (selecionada)
              Icon(Icons.check, size: 18, color: theme.textColor),
          ],
        ),
      ),
    );
  }

  Widget _listaDeImpressoras() {
    if (_carregandoImpressoras) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.textColor,
            ),
          ),
        ),
      );
    }

    if (_impressoras.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhuma impressora encontrada.',
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _impressoras.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) =>
            _linhaImpressora(_impressoras[index]),
      ),
    );
  }

  Widget _blocoConexao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Conexão'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('USB', 'usb', _tipoConexao,
                  (v) => setState(() => _tipoConexao = v)),
              _botaoSelecao('Bluetooth', 'bluetooth', _tipoConexao,
                  (v) => setState(() => _tipoConexao = v)),
              _botaoSelecao('Rede', 'rede', _tipoConexao,
                  (v) => setState(() => _tipoConexao = v)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nomeImpressoraController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo(
              'Nome da impressora (escolha abaixo ou digite)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_tipoConexao == 'rede') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _enderecoRedeController,
              cursorColor: theme.textColor,
              style: theme.getTextStyle(fontSize: 12),
              keyboardType: TextInputType.number,
              decoration: _decoracaoCampo('Endereço IP (ex: 192.168.0.50)'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Impressoras encontradas',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: theme.textColor,
                ),
                onPressed:
                    _carregandoImpressoras ? null : _carregarImpressoras,
              ),
            ],
          ),
          _listaDeImpressoras(),
        ],
      ),
    );
  }

  Widget _blocoLargura() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Largura do Papel'),
          Text(
            '58mm',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Padrão das mini impressoras térmicas.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _salvar() {
    final novas = ConfiguracoesImpressora(
      rodape: _rodapeController.text.trim(),
      tamanhoFonte: _tamanhoFonte,
      tipoConexao: _tipoConexao,
      enderecoRede: _enderecoRedeController.text.trim(),
      nomeImpressora: _nomeImpressoraController.text.trim(),
      camposClienteComanda: List.of(_camposClienteComanda),
      camposClientePersonalizados: true,
    );

    widget.onSalvar(novas);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Configurações salvas.',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _imprimirTeste() async {
    if (_imprimindo) return;

    final nome = _nomeImpressoraController.text.trim();

    setState(() => _imprimindo = true);
    try {
      await ImpressaoService.imprimirTeste(
        config: ConfiguracoesImpressora(
          rodape: _rodapeController.text.trim(),
          tamanhoFonte: _tamanhoFonte,
          tipoConexao: _tipoConexao,
          enderecoRede: _enderecoRedeController.text.trim(),
          nomeImpressora: nome,
          camposClienteComanda: List.of(_camposClienteComanda),
          camposClientePersonalizados: true,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Teste enviado para a impressora.',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Impressora',
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _blocoRodape(),
                const SizedBox(height: 12),
                _blocoFonte(),
                const SizedBox(height: 12),
                _blocoConexao(),
                const SizedBox(height: 12),
                _blocoLargura(),
                const SizedBox(height: 12),
                _blocoDadosCliente(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _imprimindo ? null : _imprimirTeste,
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
                              'Imprimir Teste',
                              style: theme.getTextStyle(fontSize: 12),
                            ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvar,
                      child: Text(
                        'Salvar',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback aoClicar;

  const _LinhaComHover({required this.builder, required this.aoClicar});

  @override
  State<_LinhaComHover> createState() => _LinhaComHoverState();
}

class _LinhaComHoverState extends State<_LinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.aoClicar,
        child: widget.builder(_hover),
      ),
    );
  }
}