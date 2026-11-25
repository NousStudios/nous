import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/editar_publicacao/secao_colaboradores_editar_pub_widget.dart';
import 'package:nous/src/features/timeline/views/dialogs/widgets/editar_publicacao/secao_midia_editar_pub_widget.dart';

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

                // 1 e 2. Imagem (dimensão atual) + Menu de Enquadramento
                if (fotosIdx.isNotEmpty) ...[
                  SecaoMidiaEditarPubWidget(
                    theme: theme,
                    midias: _midias,
                    fotosIdx: fotosIdx,
                    indiceFotoAtiva: _indiceFotoAtiva,
                    padrao: _padrao,
                    proporcaoCustom: widget.publicacao.proporcaoCustom,
                    onSelecionarFoto: (idx) =>
                        setState(() => _indiceFotoAtiva = idx),
                    onAlterarPadrao: (novoPadrao) =>
                        setState(() => _padrao = novoPadrao),
                    onAtualizarMidiaAtiva: _atualizarMidiaAtiva,
                    onInteracaoFotoChanged: (ativa) {
                      if (_interacaoFotoAtiva != ativa) {
                        setState(() => _interacaoFotoAtiva = ativa);
                      }
                    },
                  ),
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
                SecaoColaboradoresEditarPubWidget(
                  theme: theme,
                  autorCpf: widget.publicacao.autorCpf,
                  coautoresCpfs: _coautoresCpfs,
                  todasContas: _todasContas,
                  onAlterarCoautores: (novos) =>
                      setState(() => _coautoresCpfs = novos),
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
}
