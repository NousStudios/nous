import 'dart:io';

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
  /// Versão sintetizada de fallback integrada diretamente no app
  /// Garante que o changelog esteja disponível 100% offline mesmo em APK ou executável instalado.
  static const List<ItemNovidadeChangelog> _novidadesPadrao = [
    ItemNovidadeChangelog(
      versao: 'v1.0.25 (build 26)',
      data: '22/10/2026',
      alteracoes: [
        'Aprovação obrigatória de novos terminais Wi-Fi no balcão com seleção de Cliente ou Novo Membro da Loja.',
        'Fluxo de triagem de e-mails restaurado após login para seleção soberana da conta.',
        'Edição do próprio nome permitida na Identidade do Usuário (preservando CPF inalterável).',
        'Novo menu do Usuário em Configurações com acesso à tela Conta Nous (Identidade, E-mails, Backup e Exclusão).',
        'Correção de presença no balcão: o terminal agora reflete o CPF real do operador logado, eliminando status falso do dono.',
        'Container "Nova Atualização" atualizado com resumo sintetizado do CHANGELOG e botão minimizar/maximizar.',
      ],
    ),
    ItemNovidadeChangelog(
      versao: 'v1.0.24 (build 25)',
      data: '22/10/2026',
      alteracoes: [
        'Aprovação obrigatória de novos terminais Wi-Fi no balcão com seleção de Cliente ou Membro da Loja.',
        'Fluxo de triagem de e-mails restaurado após login para seleção soberana da conta.',
        'Edição do próprio nome permitida na Identidade do Usuário (preservando CPF inalterável).',
        'Novo menu do Usuário em Configurações com acesso à tela Conta Nous (Identidade, E-mails, Backup e Exclusão).',
        'Correção de presença no balcão: o terminal agora reflete o CPF real do operador logado, eliminando status falso do dono.',
        'Container "Nova Atualização" atualizado com resumo sintetizado do CHANGELOG e botão minimizar/maximizar.',
        'Envio físico e autocura de fotos na rede local via WebSocket e REST.',
        'Separação soberana entre Identidade do Usuário e Perfil Social público.',
      ],
    ),
    ItemNovidadeChangelog(
      versao: 'v1.0.23 (build 24)',
      data: '21/10/2026',
      alteracoes: [
        'Ordem de mensagens ancorada na base no chat com rolagem fluida.',
        'Envio de fotos e documentos com leitor nativo e pré-visualização.',
        'Compartilhamento interativo de comandas de pedidos no chat com a equipe e clientes.',
        'Persistência completa de anexos e mídias no banco de dados SQLite.',
      ],
    ),
    ItemNovidadeChangelog(
      versao: 'v1.0.22 (build 23)',
      data: '21/10/2026',
      alteracoes: [
        'Barra de navegação universal dupla com rolagem vertical inteligente.',
        'Nova tela de Compras & Carteira Soberana para clientes e membros.',
        'Notificações nativas no Android no estilo mensageiro instantâneo com Direct Reply.',
      ],
    ),
  ];

  /// Obtém o resumo sintetizado das últimas alterações para exibição em tela.
  /// Tenta ler o arquivo CHANGELOG.md local quando disponível em ambiente de desenvolvimento,
  /// com fallback imediato para o catálogo padrão embutido.
  static List<ItemNovidadeChangelog> obterNovidadesSintetizadas() {
    try {
      final arquivo = File('CHANGELOG.md');
      if (arquivo.existsSync()) {
        final conteudo = arquivo.readAsStringSync();
        final parseado = _parsearChangelog(conteudo);
        if (parseado.isNotEmpty) return parseado;
      }
    } catch (_) {}

    return _novidadesPadrao;
  }

  /// Retorna as alterações da versão mais recente ou da versão especificada
  static ItemNovidadeChangelog? obterUltimaVersao([String? versaoAlvo]) {
    final novidades = obterNovidadesSintetizadas();
    if (versaoAlvo != null && versaoAlvo.isNotEmpty) {
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
      if (linha.startsWith('## v')) {
        if (versaoAtual != null && alteracoes.isNotEmpty) {
          itens.add(ItemNovidadeChangelog(
            versao: versaoAtual,
            data: dataAtual ?? '',
            alteracoes: List.from(alteracoes),
          ));
          alteracoes.clear();
        }

        // Ex: ## v1.0.24 (build 25) — 22/10/2026
        final partes = linha.replaceAll('##', '').trim().split('—');
        versaoAtual = partes.first.trim();
        dataAtual = partes.length > 1 ? partes[1].trim() : '';
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
}
