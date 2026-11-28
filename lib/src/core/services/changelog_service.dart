import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ItemNovidadeChangelog {
  final String versao;
  final String data;
  final List<String> alteracoes;

  const ItemNovidadeChangelog({
    required this.versao,
    required this.data,
    required this.alteracoes,
  });
}

class ChangelogService {
  static List<ItemNovidadeChangelog>? _cacheItens;

  /// Inicializa o carregamento dinâmico do changelog a partir dos assets do app
  static Future<void> inicializar() async {
    if (_cacheItens != null && _cacheItens!.isNotEmpty) return;
    try {
      final conteudo = await rootBundle.loadString('CHANGELOG.md');
      final parseado = _parsearChangelog(conteudo);
      if (parseado.isNotEmpty) {
        _cacheItens = parseado;
        debugPrint('[ChangelogService] ${parseado.length} versões carregadas dinamicamente via rootBundle.');
        return;
      }
    } catch (_) {}

    _carregarDeArquivoLocal();
  }

  /// Tenta ler de caminhos físicos locais
  static void _carregarDeArquivoLocal() {
    final caminhosPossiveis = [
      'CHANGELOG.md',
      '../CHANGELOG.md',
      '../../CHANGELOG.md',
      if (!kIsWeb) ...[
        '${File(Platform.resolvedExecutable).parent.path}/CHANGELOG.md',
        '${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/CHANGELOG.md',
      ],
    ];

    for (final caminho in caminhosPossiveis) {
      try {
        final f = File(caminho);
        if (f.existsSync()) {
          final conteudo = f.readAsStringSync();
          final parseado = _parsearChangelog(conteudo);
          if (parseado.isNotEmpty) {
            _cacheItens = parseado;
            debugPrint('[ChangelogService] ${parseado.length} versões lidas do arquivo $caminho.');
            return;
          }
        }
      } catch (_) {}
    }
  }

  /// Obtém o resumo das últimas alterações para exibição em tela.
  static List<ItemNovidadeChangelog> obterNovidadesSintetizadas() {
    if (_cacheItens != null && _cacheItens!.isNotEmpty) {
      return _cacheItens!;
    }

    _carregarDeArquivoLocal();
    if (_cacheItens != null && _cacheItens!.isNotEmpty) {
      return _cacheItens!;
    }

    return _novidadesPadrao;
  }

  /// Retorna as alterações da versão especificada ou da versão mais recente encontrada no CHANGELOG.md
  static ItemNovidadeChangelog? obterUltimaVersao([String? versaoAlvo]) {
    final novidades = obterNovidadesSintetizadas();
    if (versaoAlvo != null && versaoAlvo.trim().isNotEmpty) {
      final limpa = versaoAlvo.replaceAll('v', '').trim();
      final padrao = RegExp('(?:^|\\b)v?${RegExp.escape(limpa)}(?:\\b|\\s|\\(|\\\$)');
      for (final item in novidades) {
        if (padrao.hasMatch(item.versao)) return item;
      }
    }
    return novidades.isNotEmpty ? novidades.first : null;
  }

  /// Filtra e traduz itens técnicos do CHANGELOG em linguagem humana e acessível para o usuário comum.
  static String? sanitizarLinhaParaUsuario(String textoBruto) {
    var texto = textoBruto.trim();
    if (texto.isEmpty) return null;

    // Desconsidera linhas com metas puramente internas ou de documentação de agentes
    final lower = texto.toLowerCase();
    if (lower.contains('agents.md') ||
        lower.contains('mapa_do_app.md') ||
        lower.contains('subagente') ||
        lower.contains('skill ') ||
        lower.contains('copywith') ||
        lower.contains('fromjson') ||
        lower.contains('tojson') ||
        lower.contains('lww em listas') ||
        lower.contains('handler duplicado') ||
        lower.contains('condição de corrida de eco') ||
        lower.contains('rate limit no segurancaservidorrelay')) {
      return null;
    }

    // Remove listas entre parênteses contendo apenas links/nomes de arquivos técnicos
    texto = texto.replaceAll(
      RegExp(
        r'\(\s*(?:\[?[a-zA-Z0-9_\-]+\.(?:dart|md|ps1|json|yaml|xml|sql)\]?(?:\([^)]+\))?\s*(?:,|e)?\s*)+\)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove preposição órfã seguida de link ou nome de arquivo técnico
    // Ex: "em [arquivo.dart](...) e [outro.dart](...)" -> ""
    texto = texto.replaceAll(
      RegExp(
        r'\b(?:em|no|na|nos|nas|de|do|da|dos|das|via|pelo|pela|com|para)\s+(?:\[?[a-zA-Z0-9_\-]+\.(?:dart|md|ps1|json|yaml|xml|sql)\]?(?:\([^)]+\))?(?:\s*(?:,|e)\s*)?)+',
        caseSensitive: false,
      ),
      ' ',
    );

    // Remove referências avulsas a arquivos técnicos (.dart, .md, .ps1, etc.)
    texto = texto.replaceAll(
      RegExp(
        r'\[?[a-zA-Z0-9_\-]+\.(?:dart|md|ps1|json|yaml|xml|sql)\]?(?:\([^)]+\))?',
        caseSensitive: false,
      ),
      '',
    );

    // Converte demais links markdown [texto](url) mantendo apenas o texto legível
    texto = texto.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (m) => m.group(1) ?? '',
    );

    // Remove tags de escopo técnico entre parênteses, ex: (`chat`, `pdv`)
    texto = texto.replaceAll(
      RegExp(r'\(\s*(`[a-zA-Z0-9_\-]+`\s*(?:,\s*)?)+\s*\)'),
      '',
    );

    // Remove formatação markdown residual
    texto = texto.replaceAll('`', '');
    texto = texto.replaceAll('**', '');
    texto = texto.replaceAll('__', '');

    // Limpa preposições ou conectivos que ficaram pendurados antes de pontuação
    texto = texto.replaceAll(
      RegExp(r'\s+\b(?:em|no|na|de|do|da|via|pelo|pela|e)\s*(?=[.,;:]|$)'),
      '',
    );

    // Se for cabeçalho de categoria (ex: "Mensageria Estilo WhatsApp + Discord:"), limpa dois-pontos isolado
    if (texto.endsWith(':')) {
      texto = texto.substring(0, texto.length - 1).trim();
    }

    // Remove parênteses vazios residuais e normaliza espaços e pontuação
    texto = texto.replaceAll(RegExp(r'\(\s*\)'), '');
    texto = texto.replaceAll(RegExp(r'\s+'), ' ');
    texto = texto.replaceAll(' ,', ',');
    texto = texto.replaceAll(' ;', ';');
    texto = texto.replaceAll(' :', ':');
    texto = texto.replaceAll(' .', '.');
    texto = texto.replaceAll(',.', '.');
    texto = texto.trim();

    if (texto.length < 10) return null;

    if (!texto.endsWith('.') && !texto.endsWith('!') && !texto.endsWith(':')) {
      texto = '$texto.';
    }

    return texto;
  }

  static List<ItemNovidadeChangelog> _parsearChangelog(String markdown) {
    final itens = <ItemNovidadeChangelog>[];
    final linhas = markdown.split('\n');

    String? versaoAtual;
    String? dataAtual;
    List<String> alteracoes = [];

    for (var linha in linhas) {
      linha = linha.trim();
      if (linha.startsWith('## v') || linha.startsWith('## [v') || linha.startsWith('## ')) {
        // Se for um título de versão válido (ex: ## v1.0.40 ...)
        final textoTitulo = linha.replaceFirst('##', '').trim();
        if (textoTitulo.toLowerCase().startsWith('v') || RegExp(r'^\d+\.').hasMatch(textoTitulo)) {
          if (versaoAtual != null && alteracoes.isNotEmpty) {
            itens.add(ItemNovidadeChangelog(
              versao: versaoAtual,
              data: dataAtual ?? '',
              alteracoes: List.from(alteracoes),
            ));
            alteracoes.clear();
          }

          // Divide entre versão e data (suporta travessão —, travessão curto – e hífen -)
          final partes = textoTitulo.split(RegExp(r'[—–-]'));
          versaoAtual = partes.first.trim();
          dataAtual = partes.length > 1 ? partes[1].trim() : '';
        }
      } else if (linha.startsWith('- ') && versaoAtual != null) {
        final textoBruto = linha.substring(2).trim();
        final textoAmigavel = sanitizarLinhaParaUsuario(textoBruto);
        if (textoAmigavel != null && textoAmigavel.isNotEmpty) {
          alteracoes.add(textoAmigavel);
        }
      }
    }

    if (versaoAtual != null && alteracoes.isNotEmpty) {
      itens.add(ItemNovidadeChangelog(
        versao: versaoAtual,
        data: dataAtual ?? '',
        alteracoes: alteracoes,
      ));
    }

    return itens;
  }

  /// Fallback offline básico de segurança
  static const List<ItemNovidadeChangelog> _novidadesPadrao = [
    ItemNovidadeChangelog(
      versao: 'v1.0.40 (build 41)',
      data: '28/10/2026',
      alteracoes: [
        'Conexão ubíqua na rede Wi-Fi sem dependência de loja aberta no balcão.',
        'Espelhamento bidirecional de mensagens e grupos em tempo real.',
        'Silenciamento inteligente de auto-notificação de mensagens enviadas por mim.',
        'Envio com tecla Enter no computador físico e quebra de linha com Shift+Enter.',
      ],
    ),
  ];
}

