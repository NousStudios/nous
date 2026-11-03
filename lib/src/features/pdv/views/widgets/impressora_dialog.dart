import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/janela_windows_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/calibracao_e_preview_comanda_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/conexao_impressora_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/dados_teste_impressora.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/opcoes_comanda_widget.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class ImpressoraDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    String? lojaId,
    required ConfiguracoesImpressora configuracoes,
    required ValueChanged<ConfiguracoesImpressora> onSalvar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f11): () {
              JanelaWindowsService.alternarTelaCheia();
            },
          },
          child: Consumer<PdvProvider>(
            builder: (ctx, pdv, child) {
              final expandido = pdv.layoutDesktopAtivo(lojaId);
              final larguraTela = MediaQuery.sizeOf(ctx).width;
              final maxWidth = expandido
                  ? (larguraTela > 1150 ? 1050.0 : larguraTela * 0.92)
                  : 500.0;

              final alturaTela = MediaQuery.sizeOf(ctx).height;
              return Dialog(
                backgroundColor: theme.cardBackgroundColor,
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.borderColor),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: alturaTela * 0.90,
                  ),
                  child: _ImpressoraConteudo(
                    theme: theme,
                    expandido: expandido,
                    configuracoesIniciais: configuracoes,
                    onSalvar: onSalvar,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ImpressoraConteudo extends StatefulWidget {
  final AppTheme theme;
  final bool expandido;
  final ConfiguracoesImpressora configuracoesIniciais;
  final ValueChanged<ConfiguracoesImpressora> onSalvar;

  const _ImpressoraConteudo({
    required this.theme,
    this.expandido = false,
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
  late double _larguraPapelMm;
  late double _margemEsquerdaMm;
  late double _margemDireitaMm;
  late bool _imprimirAutomaticoAoConcluir;
  late List<String> _camposClienteComanda;
  late final PerfilHistoricoAnarquista _perfilHistorico;

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
    _perfilHistorico = kPerfisHistoricosAnarquistas[
        Random().nextInt(kPerfisHistoricosAnarquistas.length)];
    final c = widget.configuracoesIniciais;
    _rodapeController = TextEditingController(text: c.rodape);
    _rodapeController.addListener(_onRodapeMudou);
    _enderecoRedeController = TextEditingController(text: c.enderecoRede);
    _nomeImpressoraController = TextEditingController(text: c.nomeImpressora);
    _tamanhoFonte = c.tamanhoFonte;
    _modeloFonte = c.modeloFonte;
    _tipoConexao = c.tipoConexao;
    _larguraPapelMm = c.larguraPapelMm;
    _margemEsquerdaMm = c.margemEsquerdaMm;
    _margemDireitaMm = c.margemDireitaMm;
    _imprimirAutomaticoAoConcluir = c.imprimirAutomaticoAoConcluir;
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

  void _salvar() {
    final novas = ConfiguracoesImpressora(
      larguraPapelMm: _larguraPapelMm,
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
      imprimirAutomaticoAoConcluir: _imprimirAutomaticoAoConcluir,
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

  Future<void> _imprimirExemplo() async {
    if (_imprimindo) return;

    final nome = _nomeImpressoraController.text.trim();

    setState(() => _imprimindo = true);
    try {
      await ImpressaoService.imprimirExemploComanda(
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
        cliente: _perfilHistorico.cliente,
        cnpj: _camposClienteComanda.contains('cnpj')
            ? _perfilHistorico.cnpj
            : null,
        telefone: _camposClienteComanda.contains('telefone')
            ? _perfilHistorico.telefone
            : null,
        endereco: _camposClienteComanda.contains('endereco')
            ? _perfilHistorico.endereco
            : null,
        email: _camposClienteComanda.contains('email')
            ? 'nousstudios72@gmail.com'
            : null,
        redesSociais: _camposClienteComanda.contains('redesSociais')
            ? '@nous.studios72'
            : null,
        descricao: _camposClienteComanda.contains('descricao')
            ? _perfilHistorico.descricao
            : null,
        itens: _perfilHistorico.itens,
        pagamento: 'Crédito Mútuo / Autogestão',
        rodape: _rodapeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'Exemplo enviado para a impressora.',
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
            'Falha ao imprimir exemplo: $e',
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
    final colunaHardware = Column(
      children: [
        ConexaoImpressoraWidget(
          theme: theme,
          tipoConexao: _tipoConexao,
          nomeImpressoraController: _nomeImpressoraController,
          enderecoRedeController: _enderecoRedeController,
          impressoras: _impressoras,
          carregandoImpressoras: _carregandoImpressoras,
          onTipoConexaoAlterado: (v) => setState(() => _tipoConexao = v),
          onRecarregarImpressoras: _carregarImpressoras,
          onNomeAlterado: () => setState(() {}),
        ),
        const SizedBox(height: 12),
        CalibracaoEPreviewComandaWidget(
          theme: theme,
          larguraPapelMm: _larguraPapelMm,
          modeloFonte: _modeloFonte,
          tamanhoFonte: _tamanhoFonte,
          margemEsquerdaMm: _margemEsquerdaMm,
          margemDireitaMm: _margemDireitaMm,
          camposClienteComanda: _camposClienteComanda,
          perfilHistorico: _perfilHistorico,
          rodape: _rodapeController.text.trim(),
          imprimindo: _imprimindo,
          onLarguraPapelAlterada: (v) => setState(() => _larguraPapelMm = v),
          onModeloFonteAlterado: (v) => setState(() => _modeloFonte = v),
          onTamanhoFonteAlterado: (v) => setState(() => _tamanhoFonte = v),
          onMargemEsquerdaAlterada: (v) => setState(() => _margemEsquerdaMm = v),
          onMargemDireitaAlterada: (v) => setState(() => _margemDireitaMm = v),
          onImprimirExemplo: _imprimirExemplo,
        ),
      ],
    );

    final colunaOpcoes = OpcoesComandaWidget(
      theme: theme,
      camposClienteComanda: _camposClienteComanda,
      imprimirAutomaticoAoConcluir: _imprimirAutomaticoAoConcluir,
      rodapeController: _rodapeController,
      imprimindo: _imprimindo,
      onCamposClienteAlterados: (lista) =>
          setState(() => _camposClienteComanda = lista),
      onAutomacaoAlterada: (val) =>
          setState(() => _imprimirAutomaticoAoConcluir = val),
      onImprimirTeste: _imprimirTeste,
      onSalvar: _salvar,
    );

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
            child: widget.expandido
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: colunaHardware),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: colunaOpcoes),
                    ],
                  )
                : Column(
                    children: [
                      colunaHardware,
                      const SizedBox(height: 12),
                      colunaOpcoes,
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}