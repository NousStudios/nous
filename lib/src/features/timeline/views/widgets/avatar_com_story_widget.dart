import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_stories.dart';

/// Avatar reutilizável que exibe automaticamente um círculo colorido ao redor
/// da foto de perfil quando o usuário possui um Story ativo (24h).
/// Ao tocar (por qualquer usuário, em qualquer tela), abre o Story em questão.
class AvatarComStoryWidget extends StatefulWidget {
  final AppTheme theme;
  final String cpf;
  final String nome;
  final String foto;
  final double radius;
  final UsuarioNous? usuario;
  final VoidCallback? onTapSemStory;

  const AvatarComStoryWidget({
    super.key,
    required this.theme,
    required this.cpf,
    required this.nome,
    this.foto = '',
    this.radius = 20,
    this.usuario,
    this.onTapSemStory,
  });

  @override
  State<AvatarComStoryWidget> createState() => _AvatarComStoryWidgetState();
}

class _AvatarComStoryWidgetState extends State<AvatarComStoryWidget> {
  static Map<String, List<StorySocial>>? _cacheStoriesAtivos;
  static Map<String, UsuarioNous>? _cacheContasPorCpf;
  static Future<void>? _carregamentoEmCurso;
  static int _ultimaVersaoNotifier = -1;

  List<StorySocial> _storiesAtivos = const [];
  String _corHex = '#2E7D32';
  String? _ultimaFotoTentada;

  static Future<void> _garantirCacheCompartilhado() async {
    final versaoAtual = TimelineService.alteracoesTimelineNotifier.value;
    if (_cacheStoriesAtivos != null &&
        _cacheContasPorCpf != null &&
        _ultimaVersaoNotifier == versaoAtual) {
      return;
    }
    if (_carregamentoEmCurso != null) {
      await _carregamentoEmCurso;
      return;
    }
    final futuro = () async {
      try {
        final resultados = await Future.wait([
          TimelineService.listarStoriesAtivosDaRede(),
          ContasNousService.carregarTodas(),
        ]);
        final stories = resultados[0] as List<StorySocial>;
        final contas = resultados[1] as List<UsuarioNous>;
        final mapaStories = <String, List<StorySocial>>{};
        for (final s in stories) {
          final c = s.autorCpf.replaceAll(RegExp(r'\D'), '');
          if (c.isEmpty) continue;
          mapaStories.putIfAbsent(c, () => []).add(s);
        }
        for (final lista in mapaStories.values) {
          lista.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
        }
        final mapaContas = <String, UsuarioNous>{
          for (final u in contas)
            if (u.cpf.replaceAll(RegExp(r'\D'), '').isNotEmpty)
              u.cpf.replaceAll(RegExp(r'\D'), ''): u,
        };
        _cacheStoriesAtivos = mapaStories;
        _cacheContasPorCpf = mapaContas;
        _ultimaVersaoNotifier = TimelineService.alteracoesTimelineNotifier.value;
      } finally {
        _carregamentoEmCurso = null;
      }
    }();
    _carregamentoEmCurso = futuro;
    await futuro;
  }

  @override
  void initState() {
    super.initState();
    _carregar();
    TimelineService.alteracoesTimelineNotifier.addListener(_onMudou);
  }

  @override
  void didUpdateWidget(covariant AvatarComStoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cpf != widget.cpf ||
        oldWidget.usuario?.coresPerfil['story'] !=
            widget.usuario?.coresPerfil['story']) {
      _carregar();
    }
  }

  @override
  void dispose() {
    TimelineService.alteracoesTimelineNotifier.removeListener(_onMudou);
    super.dispose();
  }

  void _onMudou() {
    if (mounted) _carregar();
  }

  Future<void> _carregar() async {
    final cpfLimpo = widget.cpf.replaceAll(RegExp(r'\D'), '');
    if (cpfLimpo.isEmpty) return;

    await _garantirCacheCompartilhado();
    final stories = _cacheStoriesAtivos?[cpfLimpo] ?? const <StorySocial>[];
    String cor = widget.usuario?.corStoryHex ?? '';
    if (cor.isEmpty) {
      cor = _cacheContasPorCpf?[cpfLimpo]?.corStoryHex ?? '';
    }
    if (cor.isEmpty) cor = '#2E7D32';

    if (!mounted) return;
    setState(() {
      _storiesAtivos = stories;
      _corHex = cor;
    });
  }

  Color _parseColor(String hex) {
    final limpo = hex.replaceAll('#', '').trim();
    final val = int.tryParse(limpo, radix: 16);
    if (val == null) return const Color(0xFF2E7D32);
    return Color(limpo.length == 6 ? (0xFF000000 | val) : val);
  }

  void _abrirStory() {
    if (_storiesAtivos.isEmpty) {
      widget.onTapSemStory?.call();
      return;
    }

    UsuarioNous? logado;
    try {
      logado = context.read<AuthProvider>().contaAtual;
    } catch (_) {}

    final cpfAlvo = widget.cpf.replaceAll(RegExp(r'\D'), '');
    final meuCpf = (logado?.cpf ?? '').replaceAll(RegExp(r'\D'), '');

    DialogVisualizarStory.mostrar(
      context,
      theme: widget.theme,
      story: _storiesAtivos.first,
      stories: _storiesAtivos,
      ehAutor: meuCpf.isNotEmpty && meuCpf == cpfAlvo,
      usuarioLogado: logado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cpfLimpo = widget.cpf.replaceAll(RegExp(r'\D'), '');
    final contaWatch = context.watch<AuthProvider?>()?.buscarContaPorCpf(
      cpfLimpo,
    );
    final corEfetivaHex =
        (contaWatch?.corStoryHex.isNotEmpty ?? false)
            ? contaWatch!.corStoryHex
            : _corHex;
    final fotoBruta = (contaWatch?.fotoExibicao.isNotEmpty ?? false)
        ? contaWatch!.fotoExibicao
        : widget.foto;
    final caminhoFoto = ImagemService.resolverCaminhoExistente(fotoBruta);
    if (caminhoFoto == null &&
        fotoBruta.isNotEmpty &&
        _ultimaFotoTentada != fotoBruta) {
      _ultimaFotoTentada = fotoBruta;
      TimelineService.resolverCaminhoMidia(fotoBruta).then((resolvido) {
        if (resolvido != null && mounted) {
          setState(() {});
        }
      });
    }
    final temStory = _storiesAtivos.isNotEmpty;
    final corAnel = _parseColor(corEfetivaHex);
    final espessuraAnel = widget.radius >= 30 ? 2.8 : 2.0;

    final avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.theme.borderColor.withValues(alpha: 0.25),
      backgroundImage: caminhoFoto != null
          ? ImagemService.obterImageProvider(
              caminhoFoto,
              cacheWidth: (widget.radius * 4).round().clamp(96, 320),
            )
          : null,
      child: caminhoFoto == null
          ? Text(
              widget.nome.isNotEmpty ? widget.nome[0].toUpperCase() : '?',
              style: widget.theme.getTextStyle(
                fontSize: (widget.radius * 0.65).clamp(10.0, 24.0),
                fontWeight: FontWeight.bold,
                color: widget.theme.textColor,
              ),
            )
          : null,
    );

    final widgetFinal = temStory
        ? Container(
            padding: EdgeInsets.all(widget.radius >= 30 ? 2.5 : 1.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: corAnel, width: espessuraAnel),
            ),
            child: avatar,
          )
        : avatar;

    if (!temStory && widget.onTapSemStory == null) {
      return widgetFinal;
    }

    return GestureDetector(
      onTap: _abrirStory,
      child: widgetFinal,
    );
  }
}
