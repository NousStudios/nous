import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda o estado transitório da tela e credencial do operador antes de reiniciar o aplicativo para atualização.
class SessaoRetorno {
  final String cpf;
  final bool modoVisitante;
  final String? lojaId;
  final int? abaLoja;
  final int? slotPrincipal;
  final int? subIndicePrincipal;

  const SessaoRetorno({
    required this.cpf,
    this.modoVisitante = false,
    this.lojaId,
    this.abaLoja,
    this.slotPrincipal,
    this.subIndicePrincipal,
  });

  Map<String, dynamic> toJson() => {
        'cpf': cpf,
        'modoVisitante': modoVisitante,
        'lojaId': lojaId,
        'abaLoja': abaLoja,
        'slotPrincipal': slotPrincipal,
        'subIndicePrincipal': subIndicePrincipal,
      };

  factory SessaoRetorno.fromJson(Map<String, dynamic> json) => SessaoRetorno(
        cpf: json['cpf'] as String? ?? '',
        modoVisitante: json['modoVisitante'] as bool? ?? false,
        lojaId: json['lojaId'] as String?,
        abaLoja: json['abaLoja'] as int?,
        slotPrincipal: json['slotPrincipal'] as int?,
        subIndicePrincipal: json['subIndicePrincipal'] as int?,
      );
}

class SessaoRetornoService {
  SessaoRetornoService._();

  static const String _nomeArquivo = 'sessao_retorno.json';

  static Future<File> _obterArquivo() async {
    final dir = await getApplicationSupportDirectory();
    final caminhoPasta = p.join(dir.path, 'Nous');
    final pasta = Directory(caminhoPasta);
    if (!pasta.existsSync()) {
      await pasta.create(recursive: true);
    }
    return File(p.join(caminhoPasta, _nomeArquivo));
  }

  /// Salva os dados de onde o usuário parou antes de fechar para atualização
  static Future<void> salvarSessao(SessaoRetorno sessao) async {
    try {
      final arquivo = await _obterArquivo();
      final jsonStr = jsonEncode(sessao.toJson());
      await arquivo.writeAsString(jsonStr, flush: true);
      debugPrint('[SessaoRetornoService] Sessão de retorno salva: $jsonStr');
    } catch (e) {
      debugPrint('[SessaoRetornoService] Erro ao salvar sessão de retorno: $e');
    }
  }

  /// Recupera a sessão salva se houver
  static Future<SessaoRetorno?> recuperarSessao() async {
    try {
      final arquivo = await _obterArquivo();
      if (!arquivo.existsSync()) return null;
      final conteudo = await arquivo.readAsString();
      if (conteudo.trim().isEmpty) return null;
      final dados = jsonDecode(conteudo) as Map<String, dynamic>;
      return SessaoRetorno.fromJson(dados);
    } catch (e) {
      debugPrint('[SessaoRetornoService] Erro ao ler sessão de retorno: $e');
      return null;
    }
  }

  /// Remove o arquivo temporário após a restauração com sucesso
  static Future<void> limparSessao() async {
    try {
      final arquivo = await _obterArquivo();
      if (arquivo.existsSync()) {
        await arquivo.delete();
        debugPrint('[SessaoRetornoService] Arquivo de sessão limpo com sucesso.');
      }
    } catch (_) {}
  }
}
