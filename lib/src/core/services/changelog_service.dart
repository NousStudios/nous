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
      for (final item in novidades) {
        if (item.versao.contains(limpa)) return item;
      }
    }
    return novidades.isNotEmpty ? novidades.first : null;
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
        var texto = linha.substring(2).trim();
        // Remove markdown em negrito do início para leitura sintetizada limpa
        texto = texto.replaceAll(RegExp(r'\*\*([^*]+)\*\*:\s*'), r'$1: ');
        texto = texto.replaceAll('**', '');
        if (texto.isNotEmpty) {
          alteracoes.add(texto);
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

