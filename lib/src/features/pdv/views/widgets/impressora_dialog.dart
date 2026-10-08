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
  late String _modeloFonte;
  late String _tipoConexao;
  late double _margemEsquerdaMm;
  late double _margemDireitaMm;
  late List<String> _camposClienteComanda;

  bool _carregandoImpressoras = false;
  bool _imprimindo = false;
  List<Printer> _impressoras = const [];

  AppTheme get theme => widget.theme;

  void _onRodapeMudou() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final c = widget.configuracoesIniciais;
    _rodapeController = TextEditingController(text: c.rodape);
    _rodapeController.addListener(_onRodapeMudou);
    _enderecoRedeController = TextEditingController(text: c.enderecoRede);
    _nomeImpressoraController = TextEditingController(text: c.nomeImpressora);
    _tamanhoFonte = c.tamanhoFonte;
    _modeloFonte = c.modeloFonte;
    _tipoConexao = c.tipoConexao;
    _margemEsquerdaMm = c.margemEsquerdaMm;
    _margemDireitaMm = c.margemDireitaMm;
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
    _rodapeController.removeListener(_onRodapeMudou);
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
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionado ? fundoAtivo : Colors.transparent,
        foregroundColor: selecionado ? textoAtivo : theme.secondaryTextColor,
        side: BorderSide(
          color: selecionado
              ? theme.textColor
              : theme.borderColor.withValues(alpha: 0.45),
          width: selecionado ? 1.6 : 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => aoSelecionar(valor),
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 12,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          color: selecionado ? textoAtivo : theme.textColor,
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
          _tituloDoBloco('Tipografia da Comanda'),
          Text(
            'Personalize o modelo da letra e o tamanho da fonte da impressão.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Modelo da Letra (Família)',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('Belleza (Nous)', 'belleza', _modeloFonte,
                  (v) => setState(() => _modeloFonte = v)),
              _botaoSelecao('Sem Serifa (Moderna)', 'padrao', _modeloFonte,
                  (v) => setState(() => _modeloFonte = v)),
              _botaoSelecao('Monoespaçada (Recibo)', 'mono', _modeloFonte,
                  (v) => setState(() => _modeloFonte = v)),
              _botaoSelecao('Serifada (Times)', 'serifada', _modeloFonte,
                  (v) => setState(() => _modeloFonte = v)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tamanho da Fonte',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _botaoSelecao('Pequena (8pt)', 'pequena', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
              _botaoSelecao('Normal (10pt)', 'normal', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
              _botaoSelecao('Grande (12pt)', 'grande', _tamanhoFonte,
                  (v) => setState(() => _tamanhoFonte = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoCalibracao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Calibração Bilateral de Recuo (58mm)'),
          Text(
            'Ajuste fino em milímetros caso o texto sofra cortes mecânicos '
            'na borda esquerda ou na borda direita da bobina térmica.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _colunaRecuo(
                titulo: 'Recuo Esquerdo',
                subtitulo: 'Início do texto',
                valor: _margemEsquerdaMm,
                aoMudar: (v) => setState(() => _margemEsquerdaMm = v),
                atalhos: const [3.0, 5.0, 6.5, 8.0],
                padrao: 5.0,
              ),
              const SizedBox(width: 10),
              _colunaRecuo(
                titulo: 'Recuo Direito',
                subtitulo: 'Fim dos preços',
                valor: _margemDireitaMm,
                aoMudar: (v) => setState(() => _margemDireitaMm = v),
                atalhos: const [1.5, 3.0, 4.5, 6.0],
                padrao: 3.0,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _blocoPreviewComanda(),
        ],
      ),
    );
  }

  Widget _colunaRecuo({
    required String titulo,
    required String subtitulo,
    required double valor,
    required ValueChanged<double> aoMudar,
    required List<double> atalhos,
    required double padrao,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.borderColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            Text(
              subtitulo,
              style: theme.getTextStyle(
                fontSize: 10,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: valor > 0.5
                      ? () => aoMudar((valor - 0.5).clamp(0.5, 15.0))
                      : null,
                  child: Icon(Icons.remove, size: 16, color: theme.textColor),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.textColor, width: 1.4),
                  ),
                  child: Text(
                    '${valor.toStringAsFixed(1)} mm',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: theme.borderColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: valor < 15.0
                      ? () => aoMudar((valor + 0.5).clamp(0.5, 15.0))
                      : null,
                  child: Icon(Icons.add, size: 16, color: theme.textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final a in atalhos)
                  _botaoAtalhoMargemCustom(
                    '${a.toStringAsFixed(1)}${a == padrao ? '*' : ''}',
                    a,
                    valor,
                    aoMudar,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoAtalhoMargemCustom(
    String rotulo,
    double valor,
    double valorAtual,
    ValueChanged<double> aoSelecionar,
  ) {
    final selecionado = (valorAtual - valor).abs() < 0.1;
    final fundoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);
    final textoAtivo = theme.buttonColor != Colors.transparent
        ? theme.buttonTextColor
        : theme.textColor;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionado ? fundoAtivo : Colors.transparent,
        foregroundColor: selecionado ? textoAtivo : theme.secondaryTextColor,
        side: BorderSide(
          color: selecionado
              ? theme.textColor
              : theme.borderColor.withValues(alpha: 0.45),
          width: selecionado ? 1.5 : 1.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: () => aoSelecionar(valor),
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 10,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          color: selecionado ? textoAtivo : theme.textColor,
        ),
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
              ? (theme.buttonColor != Colors.transparent
                  ? theme.buttonColor.withValues(alpha: 0.35)
                  : theme.borderColor.withValues(alpha: 0.25))
              : hover
                  ? theme.borderColor.withValues(alpha: 0.18)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selecionada || hover
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.45),
            width: selecionada ? 1.6 : 1.0,
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
                  fontWeight:
                      selecionada ? FontWeight.bold : FontWeight.normal,
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


  void _salvar() {
    final novas = ConfiguracoesImpressora(
      rodape: _rodapeController.text.trim(),
      tamanhoFonte: _tamanhoFonte,
      modeloFonte: _modeloFonte,
      tipoConexao: _tipoConexao,
      enderecoRede: _enderecoRedeController.text.trim(),
      nomeImpressora: _nomeImpressoraController.text.trim(),
      camposClienteComanda: List.of(_camposClienteComanda),
      camposClientePersonalizados: true,
      margemEsquerdaMm: _margemEsquerdaMm,
      margemDireitaMm: _margemDireitaMm,
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
          modeloFonte: _modeloFonte,
          tipoConexao: _tipoConexao,
          enderecoRede: _enderecoRedeController.text.trim(),
          nomeImpressora: nome,
          camposClienteComanda: List.of(_camposClienteComanda),
          camposClientePersonalizados: true,
          margemEsquerdaMm: _margemEsquerdaMm,
          margemDireitaMm: _margemDireitaMm,
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

  Widget _blocoPreviewComanda() {
    final rodape = _rodapeController.text.trim();
    final double escalaFonte = _tamanhoFonte == 'pequena'
        ? 0.88
        : _tamanhoFonte == 'grande'
            ? 1.15
            : 1.0;

    String? familiaFonte;
    switch (_modeloFonte) {
      case 'belleza':
        familiaFonte = 'Belleza';
        break;
      case 'mono':
        familiaFonte = 'monospace';
        break;
      case 'serifada':
        familiaFonte = 'serif';
        break;
      case 'padrao':
      default:
        familiaFonte = null;
        break;
    }

    TextStyle estilo({
      required double fontSize,
      Color? color,
      FontWeight fontWeight = FontWeight.normal,
    }) {
      return theme
          .getTextStyle(
            fontSize: fontSize * escalaFonte,
            color: color ?? theme.textColor,
            fontWeight: fontWeight,
          )
          .copyWith(
            fontFamily: familiaFonte,
          );
    }

    Widget linhaComanda(String esquerda, String direita,
        {bool destaque = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                esquerda,
                style: estilo(
                  fontSize: 12,
                  color: destaque ? theme.textColor : theme.secondaryTextColor,
                  fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              direita,
              style: estilo(
                fontSize: 12,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    final double padEsq = 14.0 + (_margemEsquerdaMm * 1.5);
    final double padDir = 14.0 + (_margemDireitaMm * 1.5);

    return Column(
      children: [
        Divider(color: theme.borderColor.withValues(alpha: 0.4)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 15, color: theme.secondaryTextColor),
            const SizedBox(width: 6),
            Text(
              'Prévia da Comanda',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: EdgeInsets.fromLTRB(padEsq, 14, padDir, 16),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'NOUS COMÉRCIO & SERVIÇOS',
                    textAlign: TextAlign.center,
                    style: estilo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'CNPJ: 12.345.678/0001-90',
                    textAlign: TextAlign.center,
                    style: estilo(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Pedido #0042',
                    textAlign: TextAlign.center,
                    style: estilo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Data: 08/10/2026 14:30',
                    textAlign: TextAlign.center,
                    style: estilo(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_camposClienteComanda.isNotEmpty) ...[
                  if (_camposClienteComanda.contains('nome'))
                    linhaComanda('Cliente', 'Carlos Eduardo da Silva'),
                  if (_camposClienteComanda.contains('telefone'))
                    linhaComanda('Telefone', '(11) 98765-4321'),
                  if (_camposClienteComanda.contains('endereco'))
                    linhaComanda('Endereço', 'Rua das Palmeiras, 740'),
                  if (_camposClienteComanda.contains('bairro'))
                    linhaComanda('Bairro', 'Jardim América'),
                  if (_camposClienteComanda.contains('complemento'))
                    linhaComanda('Complemento', 'Bloco B, Apto 102'),
                  if (_camposClienteComanda.contains('cidade'))
                    linhaComanda('Cidade', 'São Paulo - SP'),
                  if (_camposClienteComanda.contains('pontoReferencia'))
                    linhaComanda('Ponto de ref.', 'Em frente à praça central'),
                  if (_camposClienteComanda.contains('observacoes'))
                    linhaComanda('Observações', 'Tocar interfone 102 duas vezes'),
                  const SizedBox(height: 6),
                ],
                Center(
                  child: Text(
                    'ITENS',
                    style: estilo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                linhaComanda('1x X-Tudo Artesanal Completo', 'R\$ 32,00'),
                linhaComanda('2x Suco Natural Laranja 500ml', 'R\$ 16,00'),
                const SizedBox(height: 8),
                Divider(color: theme.borderColor.withValues(alpha: 0.6)),
                linhaComanda('Subtotal', 'R\$ 48,00'),
                linhaComanda('TOTAL', 'R\$ 48,00', destaque: true),
                const SizedBox(height: 4),
                linhaComanda('Pagamento', 'Pix / Cartão'),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    rodape.isNotEmpty ? rodape : 'linktr.ee/nous72',
                    textAlign: TextAlign.center,
                    style: estilo(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _blocoConexao(),
                const SizedBox(height: 12),
                _blocoFonte(),
                const SizedBox(height: 12),
                _blocoCalibracao(),
                const SizedBox(height: 12),
                _blocoDadosCliente(),
                const SizedBox(height: 12),
                _blocoRodape(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
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
                      icon: _imprimindo
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.textColor,
                              ),
                            )
                          : Icon(Icons.print_outlined, size: 16, color: theme.textColor),
                      label: Text(
                        'Imprimir Teste',
                        style: theme.getTextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvar,
                      icon: Icon(Icons.check, size: 16, color: theme.buttonTextColor),
                      label: Text(
                        'Salvar Configurações',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.buttonTextColor,
                          fontWeight: FontWeight.bold,
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