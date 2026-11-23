import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Diálogo para editar uma publicação existente, seguindo a ordem visual:
/// Imagem (dimensão atual) -> Enquadramento -> Música -> Colaboradores ->
/// Legenda -> Permitir download.
class DialogEditarPublicacao extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;

  const DialogEditarPublicacao({
    super.key,
    required this.theme,
    required this.publicacao,
  });

  static Future<PublicacaoSocial?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
  }) {
    return showDialog<PublicacaoSocial>(
      context: context,
      builder: (_) => DialogEditarPublicacao(
        theme: theme,
        publicacao: publicacao,
      ),
    );
  }

  @override
  State<DialogEditarPublicacao> createState() => _DialogEditarPublicacaoState();
}

class _DialogEditarPublicacaoState extends State<DialogEditarPublicacao> {
  late final TextEditingController _textoCtrl;
  late List<String> _coautoresCpfs;
  late List<MidiaPublicacao> _midias;
  late PadraoExibicaoMidia _padrao;
  late bool _permitirDownload;
  List<UsuarioNous> _todasContas = const [];
  int _indiceFotoAtiva = 0;
  double _zoomInicioGesto = 1.0;
  bool _interacaoFotoAtiva = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _textoCtrl = TextEditingController(text: widget.publicacao.texto);
    _coautoresCpfs = List<String>.from(widget.publicacao.coautoresCpfs);
    _midias = List<MidiaPublicacao>.from(widget.publicacao.midias);
    _padrao = widget.publicacao.padraoExibicao;
    _permitirDownload = widget.publicacao.permitirDownload;
    _carregarContas();
  }

  Future<void> _carregarContas() async {
    final contas = await ContasNousService.carregarTodas();
    if (!mounted) return;
    setState(() => _todasContas = contas);
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  bool _ehImagem(MidiaPublicacao m) {
    final ext = m.mimeTipo.toLowerCase();
    return ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png' ||
        ext == 'webp' ||
        ext == 'gif' ||
        ext.isEmpty;
  }

  double? _aspectRatioParaPadrao(PadraoExibicaoMidia padrao) {
    switch (padrao) {
      case PadraoExibicaoMidia.original:
        return widget.publicacao.proporcaoCustom;
      case PadraoExibicaoMidia.quadrado1x1:
        return 1.0;
      case PadraoExibicaoMidia.retrato4x5:
        return 4 / 5;
      case PadraoExibicaoMidia.paisagem16x9:
        return 16 / 9;
      case PadraoExibicaoMidia.vertical9x16:
        return 9 / 16;
      case PadraoExibicaoMidia.mosaico:
      case PadraoExibicaoMidia.personalizado:
        return widget.publicacao.proporcaoCustom;
    }
  }

  String _nomeColaborador(String cpf) {
    final limpo = cpf.replaceAll(RegExp(r'\D'), '');
    for (final c in _todasContas) {
      if (c.cpf.replaceAll(RegExp(r'\D'), '') == limpo) {
        return c.nomeExibicao.isNotEmpty ? c.nomeExibicao : cpf;
      }
    }
    return cpf;
  }

  Future<void> _abrirSeletorColaborador() async {
    final autorLimpo =
        widget.publicacao.autorCpf.replaceAll(RegExp(r'\D'), '');
    final selecionados = _coautoresCpfs
        .map((c) => c.replaceAll(RegExp(r'\D'), ''))
        .toSet();
    final buscaCtrl = TextEditingController();
    String termo = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setModalState) {
          final theme = widget.theme;
          final candidatos = _todasContas.where((u) {
            final uCpf = u.cpf.replaceAll(RegExp(r'\D'), '');
            if (uCpf.isEmpty || uCpf == autorLimpo) return false;
            if (termo.trim().isEmpty) return true;
            final t = termo.trim().toLowerCase();
            return u.nomeExibicao.toLowerCase().contains(t) ||
                u.usernameExibicao.toLowerCase().contains(t);
          }).toList();

          return Dialog(
            backgroundColor: theme.cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.borderColor),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 380,
                maxHeight: MediaQuery.sizeOf(dCtx).height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Marcar Colaboradores',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: buscaCtrl,
                      onChanged: (v) => setModalState(() => termo = v),
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou @usuario...',
                        hintStyle: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: theme.secondaryTextColor,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: candidatos.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'Nenhum usuário encontrado.',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: candidatos.length,
                              itemBuilder: (_, i) {
                                final u = candidatos[i];
                                final uCpf =
                                    u.cpf.replaceAll(RegExp(r'\D'), '');
                                final marcado = selecionados.contains(uCpf);
                                return CheckboxListTile(
                                  dense: true,
                                  value: marcado,
                                  activeColor: theme.buttonColor,
                                  checkColor: theme.buttonTextColor,
                                  title: Text(
                                    u.nomeExibicao,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  subtitle: u.usernameExibicao.isNotEmpty
                                      ? Text(
                                          u.usernameExibicao,
                                          style: theme.getTextStyle(
                                            fontSize: 11,
                                            color: theme.secondaryTextColor,
                                          ),
                                        )
                                      : null,
                                  onChanged: (v) {
                                    setModalState(() {
                                      if (v == true) {
                                        selecionados.add(uCpf);
                                      } else {
                                        selecionados.remove(uCpf);
                                      }
                                    });
                                    setState(() {
                                      _coautoresCpfs = selecionados.toList();
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Concluir',
                          style: theme.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.buttonColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    buscaCtrl.dispose();
  }

  void _atualizarMidiaAtiva({
    required double x,
    required double y,
    required double zoom,
  }) {
    if (_midias.isEmpty) return;
    final idx = _indiceFotoAtiva.clamp(0, _midias.length - 1);
    final atual = _midias[idx];
    setState(() {
      _midias[idx] = atual.copyWith(
        alinhamentoX: x.clamp(-1.0, 1.0),
        alinhamentoY: y.clamp(-1.0, 1.0),
        escalaZoom: zoom.clamp(1.0, 3.0),
      );
    });
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final atualizada = await TimelineService.editarPublicacao(
      widget.publicacao,
      novoTexto: _textoCtrl.text,
      permitirDownload: _permitirDownload,
      coautoresCpfs: _coautoresCpfs,
      midias: _midias,
      padraoExibicao: _padrao,
    );
    if (!mounted) return;
    Navigator.of(context).pop(atualizada);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final fotosIdx = <int>[
      for (int i = 0; i < _midias.length; i++)
        if (_ehImagem(_midias[i])) i,
    ];
    if (fotosIdx.isNotEmpty && !fotosIdx.contains(_indiceFotoAtiva)) {
      _indiceFotoAtiva = fotosIdx.first;
    }

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            physics: _interacaoFotoAtiva
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: theme.textColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editar Publicação',
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 1. Imagem acima na dimensão atual + seletor de foto se carrossel
                if (fotosIdx.isNotEmpty) ...[
                  if (fotosIdx.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (int k = 0; k < fotosIdx.length; k++)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: InkWell(
                                onTap: () => setState(
                                  () => _indiceFotoAtiva = fotosIdx[k],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _indiceFotoAtiva == fotosIdx[k]
                                        ? theme.buttonColor
                                        : theme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.borderColor
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '${k + 1}',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: _indiceFotoAtiva == fotosIdx[k]
                                          ? theme.buttonTextColor
                                          : theme.textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  _buildEditorFotoAtiva(theme, _midias[_indiceFotoAtiva]),
                  const SizedBox(height: 12),

                  // 2. Menu de Enquadramento (idêntico ao de criação)
                  _buildSeletorFormatoVisual(theme),
                  const SizedBox(height: 14),
                ],

                // 3. Música (espaço reservado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trocar música (em breve)',
                          style: theme.getTextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Colaboradores
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Colaboradores',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _abrirSeletorColaborador,
                      icon: Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 16,
                        color: theme.textColor,
                      ),
                      label: Text(
                        'Marcar',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_coautoresCpfs.isEmpty)
                  Text(
                    'Nenhum colaborador marcado.',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.secondaryTextColor,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final cpf in _coautoresCpfs)
                        Chip(
                          backgroundColor:
                              theme.backgroundColor.withValues(alpha: 0.6),
                          side: BorderSide(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                          label: Text(
                            _nomeColaborador(cpf),
                            style: theme.getTextStyle(
                              fontSize: 11.5,
                              color: theme.textColor,
                            ),
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                          onDeleted: () {
                            setState(() => _coautoresCpfs.remove(cpf));
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 14),

                // 5. Legenda
                ThemedTextField(
                  theme: theme,
                  controller: _textoCtrl,
                  linhas: 3,
                  label: 'Legenda',
                ),

                // 6. Permitir download (por último)
                if (_midias.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Permitir download da mídia',
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.textColor,
                        ),
                      ),
                      ThemedSwitch(
                        theme: theme,
                        value: _permitirDownload,
                        onChanged: (v) =>
                            setState(() => _permitirDownload = v),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _salvando ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: theme.getTextStyle(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvando ? null : _salvar,
                      child: Text(
                        _salvando ? 'Salvando...' : 'Salvar',
                        style: theme.getTextStyle(
                          fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildSeletorFormatoVisual(AppTheme theme) {
    final opcoes = <(PadraoExibicaoMidia, IconData, String)>[
      (PadraoExibicaoMidia.original, Icons.crop_free_rounded, 'Original'),
      (PadraoExibicaoMidia.quadrado1x1, Icons.crop_square_rounded, '1:1'),
      (PadraoExibicaoMidia.retrato4x5, Icons.crop_portrait_rounded, '4:5'),
      (PadraoExibicaoMidia.paisagem16x9, Icons.crop_16_9_rounded, '16:9'),
      (PadraoExibicaoMidia.vertical9x16, Icons.smartphone_rounded, '9:16'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enquadramento',
          style: theme.getTextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: opcoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (padrao, icone, rotulo) = opcoes[i];
              final ativo = _padrao == padrao;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _padrao = padrao),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: ativo
                        ? theme.buttonColor
                        : theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ativo
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.5),
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icone,
                        size: 18,
                        color: ativo ? theme.buttonTextColor : theme.textColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rotulo,
                        style: theme.getTextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              ativo ? FontWeight.bold : FontWeight.normal,
                          color:
                              ativo ? theme.buttonTextColor : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditorFotoAtiva(AppTheme theme, MidiaPublicacao midia) {
    final caminhoResolvido =
        ImagemService.resolverCaminhoExistente(midia.caminhoRelativo);
    if (caminhoResolvido == null || !File(caminhoResolvido).existsSync()) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    final align = Alignment(midia.alinhamentoX, midia.alinhamentoY);
    final zoom = midia.escalaZoom.clamp(1.0, 3.0);
    final aspectRatio = _aspectRatioParaPadrao(_padrao);

    final imgWidget = ClipRect(
      child: Transform.scale(
        scale: zoom,
        alignment: Alignment.center,
        child: Image.file(
          File(caminhoResolvido),
          fit: aspectRatio != null ? BoxFit.cover : BoxFit.contain,
          alignment: align,
          cacheWidth: 900,
        ),
      ),
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            width: double.infinity,
            color: theme.backgroundColor.withValues(alpha: 0.5),
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  final delta = -event.scrollDelta.dy * 0.002;
                  _atualizarMidiaAtiva(
                    x: midia.alinhamentoX,
                    y: midia.alinhamentoY,
                    zoom: zoom + delta,
                  );
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) {
                  if (!_interacaoFotoAtiva) {
                    setState(() => _interacaoFotoAtiva = true);
                  }
                  _zoomInicioGesto = zoom;
                },
                onScaleUpdate: (details) {
                  final novoZoom =
                      (_zoomInicioGesto * details.scale).clamp(1.0, 3.0);
                  final divisor = 130.0 * novoZoom;
                  final dx = details.focalPointDelta.dx / divisor;
                  final dy = details.focalPointDelta.dy / divisor;
                  _atualizarMidiaAtiva(
                    x: midia.alinhamentoX - dx,
                    y: midia.alinhamentoY - dy,
                    zoom: novoZoom,
                  );
                },
                onScaleEnd: (_) {
                  if (_interacaoFotoAtiva) {
                    setState(() => _interacaoFotoAtiva = false);
                  }
                },
                child: Center(
                  child: aspectRatio != null
                      ? AspectRatio(aspectRatio: aspectRatio, child: imgWidget)
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 270),
                          child: imgWidget,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (zoom > 1.05 ||
            midia.alinhamentoX.abs() > 0.02 ||
            midia.alinhamentoY.abs() > 0.02)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _atualizarMidiaAtiva(x: 0.0, y: 0.0, zoom: 1.0),
              child: Text(
                'Centralizar',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  color: theme.buttonColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
