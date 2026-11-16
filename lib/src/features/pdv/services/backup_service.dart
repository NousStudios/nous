import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/backup_merge_helper.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ResultadoImportacao {
  final int contasImportadas;
  final int lojasImportadas;
  final int referenciasImportadas;
  final int convitesImportados;
  final int conversasImportadas;
  final int mensagensImportadas;
  final int midiasImportadas;

  const ResultadoImportacao({
    required this.contasImportadas,
    required this.lojasImportadas,
    required this.referenciasImportadas,
    required this.convitesImportados,
    this.conversasImportadas = 0,
    this.mensagensImportadas = 0,
    this.midiasImportadas = 0,
  });

  int get total =>
      contasImportadas +
      lojasImportadas +
      referenciasImportadas +
      convitesImportados +
      conversasImportadas +
      mensagensImportadas +
      midiasImportadas;

  bool get vazio => total == 0;
}

class BackupService {
  BackupService._();

  static Future<Map<String, dynamic>> gerarJson({
    bool incluirMidias = true,
  }) async {
    final contas = await ContasNousService.carregarTodas();
    final db = await BancoDadosService.db;

    final cpfs = <String>{};
    for (final c in contas) {
      if (c.cpf.isNotEmpty) cpfs.add(c.cpf);
    }

    final rowsLojas = await db.rawQuery('SELECT DISTINCT cpf_dono FROM lojas');
    for (final r in rowsLojas) {
      final cpf = r['cpf_dono']?.toString() ?? '';
      if (cpf.isNotEmpty) cpfs.add(cpf);
    }

    final rowsRefs = await db.rawQuery('SELECT DISTINCT cpf FROM referencias_loja');
    for (final r in rowsRefs) {
      final cpf = r['cpf']?.toString() ?? '';
      if (cpf.isNotEmpty) cpfs.add(cpf);
    }

    final cofres = <Map<String, dynamic>>[];
    for (final cpf in cpfs) {
      final lojas = await LojasService.carregar(cpf);
      final refs = await LojasService.carregarReferencias(cpf);
      if (lojas.isNotEmpty || refs.isNotEmpty) {
        cofres.add({
          'cpf': cpf,
          'lojas': lojas.map((l) => l.toJson()).toList(),
          'referencias': refs.map((r) => r.toJson()).toList(),
        });
      }
    }

    final rowsConvites =
        await db.rawQuery('SELECT DISTINCT cpf_destinatario FROM convites');
    final convites = <Map<String, dynamic>>[];
    for (final r in rowsConvites) {
      final cpf = r['cpf_destinatario']?.toString() ?? '';
      if (cpf.isEmpty) continue;
      final lista = await ConvitesService.carregar(cpf);
      if (lista.isNotEmpty) {
        convites.add({
          'cpf': cpf,
          'convites': lista.map((c) => c.toJson()).toList(),
        });
      }
    }

    // Exportação do Chat (Conversas e Mensagens) e Chaves/Validações Soberanas
    List<Map<String, dynamic>> conversasChat = [];
    List<Map<String, dynamic>> mensagensChat = [];
    List<Map<String, dynamic>> chavesSeguras = [];
    List<Map<String, dynamic>> chavesTroca = [];
    List<Map<String, dynamic>> validacoesIdentidade = [];
    try {
      conversasChat = await db.query('conversas_chat');
      mensagensChat = await db.query('mensagens_chat');
    } catch (_) {}
    try {
      chavesSeguras = await db.query('cofre_chaves_seguras');
    } catch (_) {}
    try {
      chavesTroca = await db.query('cofre_chaves_troca');
    } catch (_) {}
    try {
      validacoesIdentidade = await db.query('validacoes_identidade');
    } catch (_) {}

    // Exportação de Mídias Físicas (Fotos, Logos, Áudios) em Base64
    final midias = <String, String>{};
    if (incluirMidias) {
      try {
        const limiteTotalMidiasBytes = 150 * 1024 * 1024;
        var bytesAcumulados = 0;
        final baseDir = await ImagemService.obterDiretorioBase();
        final subPastas = [
          Directory('${baseDir.path}/imagens'),
          Directory('${baseDir.path}/audios'),
          Directory('${baseDir.path}/anexos'),
        ];
        for (final dir in subPastas) {
          if (!await dir.exists()) continue;
          await for (final item
              in dir.list(recursive: true, followLinks: false)) {
            if (bytesAcumulados >= limiteTotalMidiasBytes) break;
            if (item is File && await item.exists()) {
              final tamanho = await item.length();
              if (tamanho > 0 &&
                  tamanho <= 8 * 1024 * 1024 &&
                  bytesAcumulados + tamanho <= limiteTotalMidiasBytes) {
                final nome = p.basename(item.path);
                if (!midias.containsKey(nome)) {
                  try {
                    final bytes = await item.readAsBytes();
                    midias[nome] = base64Encode(bytes);
                    bytesAcumulados += tamanho;
                  } catch (_) {}
                }
              }
            }
          }
          if (bytesAcumulados >= limiteTotalMidiasBytes) break;
        }
      } catch (_) {}
    }

    final preferenciasUsuario = await PreferenciasSoberanasService.exportarTodas();

    return {
      'versao': 2,
      'exportadoEm': DateTime.now().toIso8601String(),
      'contas': contas.map((c) => c.toJson()).toList(),
      'cofres': cofres,
      'convites': convites,
      'conversas': conversasChat,
      'mensagens': mensagensChat,
      'chavesSeguras': chavesSeguras,
      'chavesTroca': chavesTroca,
      'validacoesIdentidade': validacoesIdentidade,
      'preferenciasUsuario': preferenciasUsuario,
      'midias': midias,
    };
  }

  static Future<void> realizarBackupAutomaticoSeNecessario() async {
    try {
      await BancoDadosService.db;
      final dir = await getApplicationSupportDirectory();
      final pastaBackups = Directory(p.join(dir.path, 'Nous', 'backups'));
      if (!pastaBackups.existsSync()) {
        await pastaBackups.create(recursive: true);
      }

      final agora = DateTime.now();
      String dois(int n) => n.toString().padLeft(2, '0');
      final nomeHoje =
          'nous_backup_${agora.year}_${dois(agora.month)}_${dois(agora.day)}.json';
      final arquivoHoje = File(p.join(pastaBackups.path, nomeHoje));

      if (arquivoHoje.existsSync() && arquivoHoje.lengthSync() > 0) return;

      final dados = await gerarJson(incluirMidias: false);
      final jsonStr = jsonEncode(dados);
      await arquivoHoje.writeAsString(jsonStr);

      final arquivos = pastaBackups
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      if (arquivos.length > 15) {
        arquivos.sort(
            (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        final excedentes = arquivos.length - 15;
        for (var i = 0; i < excedentes; i++) {
          try {
            arquivos[i].deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<String?> exportar() async {
    final json = await gerarJson();
    final texto = const JsonEncoder.withIndent('  ').convert(json);

    final agora = DateTime.now();
    String dois(int n) => n.toString().padLeft(2, '0');
    final sufixo = '${agora.year}${dois(agora.month)}${dois(agora.day)}_'
        '${dois(agora.hour)}${dois(agora.minute)}${dois(agora.second)}';

    const grupo = XTypeGroup(label: 'Backup Nous', extensions: ['json']);
    final local = await getSaveLocation(
      suggestedName: 'nous_backup_$sufixo.json',
      acceptedTypeGroups: const [grupo],
    );
    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsString(texto);
    return local.path;
  }

  static Future<ResultadoImportacao?> importar({
    required bool substituir,
  }) async {
    const grupo = XTypeGroup(label: 'Backup Nous', extensions: ['json']);
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return null;

    final texto = await arquivo.readAsString();
    final json = jsonDecode(texto) as Map<String, dynamic>;
    return aplicarJson(json, substituir: substituir);
  }

  static Future<ResultadoImportacao> aplicarJson(
    Map<String, dynamic> json, {
    required bool substituir,
  }) async {
    final db = await BancoDadosService.db;

    if (substituir) {
      await db.transaction((txn) async {
        await txn.delete('contas_usuarios');
        await txn.delete('lojas');
        await txn.delete('pedidos');
        await txn.delete('movimentos_estoque');
        await txn.delete('pagamentos_funcionarios');
        await txn.delete('referencias_loja');
        await txn.delete('convites');
      });
    }

    int contasImportadas = 0;
    int lojasImportadas = 0;
    int referenciasImportadas = 0;
    int convitesImportados = 0;

    final contasNovas = (json['contas'] as List<dynamic>? ?? const [])
        .map((item) => UsuarioNous.fromJson(item as Map<String, dynamic>))
        .toList();

    for (final nova in contasNovas) {
      final atual = await ContasNousService.buscarPorCpf(nova.cpf);
      if (atual == null) {
        await ContasNousService.salvar(nova);
      } else {
        final emailsUnicos = {
          ...atual.emails,
          ...nova.emails,
        }.toList();
        await ContasNousService.salvar(nova.copyWith(emails: emailsUnicos));
      }
      contasImportadas++;
    }

    final cofresJson = json['cofres'] as List<dynamic>? ?? const [];
    for (final item in cofresJson) {
      final mapa = item as Map<String, dynamic>;
      final cpf = mapa['cpf'] as String;

      final lojasNovas = (mapa['lojas'] as List<dynamic>? ?? const [])
          .map((e) => Loja.fromJson(e as Map<String, dynamic>))
          .toList();
      final refsNovas = (mapa['referencias'] as List<dynamic>? ?? const [])
          .map((e) => ReferenciaLoja.fromJson(e as Map<String, dynamic>))
          .toList();

      final lojasAtuais = await LojasService.carregar(cpf);
      final lojasMescladas = desduplicarLojas(lojasAtuais);
      final redirecionamentoIds = <String, String>{};

      for (final nova in lojasNovas) {
        final indice = lojasMescladas.indexWhere((l) {
          return _ehMesmaLojaParaDesduplicar(l, nova);
        });

        if (indice == -1) {
          lojasMescladas.add(nova);
        } else {
          final existente = lojasMescladas[indice];
          if (existente.id != nova.id) {
            redirecionamentoIds[nova.id] = existente.id;
          }
          final mesclada = mesclarLojas(existente: existente, importada: nova);
          lojasMescladas[indice] = mesclada;
        }
        lojasImportadas++;
      }

      final lojasFinais = desduplicarLojas(lojasMescladas);
      await LojasService.salvar(cpf, lojasFinais);

      final refsAtuais = await LojasService.carregarReferencias(cpf);
      final refsMescladas = <ReferenciaLoja>[...refsAtuais];

      for (final nova in refsNovas) {
        final lojaIdEfetivo = redirecionamentoIds[nova.lojaId] ?? nova.lojaId;
        final refAjustada = ReferenciaLoja(
          lojaId: lojaIdEfetivo,
          cpfDonoOriginal: nova.cpfDonoOriginal,
        );
        if (!refsMescladas.any((r) => r.lojaId == refAjustada.lojaId)) {
          refsMescladas.add(refAjustada);
          referenciasImportadas++;
        }
      }

      await LojasService.salvarReferencias(cpf, refsMescladas);
    }

    final convitesJson = json['convites'] as List<dynamic>? ?? const [];
    for (final item in convitesJson) {
      final mapa = item as Map<String, dynamic>;
      final cpf = mapa['cpf'] as String;

      final novos = (mapa['convites'] as List<dynamic>? ?? const [])
          .map((e) => ConviteLoja.fromJson(e as Map<String, dynamic>))
          .toList();

      final atuais = await ConvitesService.carregar(cpf);
      final mesclados = <ConviteLoja>[...atuais];

      for (final novo in novos) {
        if (!mesclados.any((c) => c.id == novo.id)) {
          mesclados.add(novo);
          convitesImportados++;
        }
      }

      await ConvitesService.salvar(cpf, mesclados);
    }

    int conversasImportadas = 0;
    int mensagensImportadas = 0;
    int midiasImportadas = 0;

    // Restauração das Mídias Físicas (Fotos, Logos, Áudios)
    final midiasJson = json['midias'] as Map<String, dynamic>? ?? const {};
    if (midiasJson.isNotEmpty) {
      try {
        final pastaBase = await ImagemService.obterDiretorioBase();
        final pastaImagens = Directory(p.join(pastaBase.path, 'imagens'));
        if (!pastaImagens.existsSync()) {
          await pastaImagens.create(recursive: true);
        }
        for (final entry in midiasJson.entries) {
          final nome = entry.key;
          final b64 = entry.value?.toString() ?? '';
          if (nome.isNotEmpty && b64.isNotEmpty) {
            final destino = File(p.join(pastaImagens.path, nome));
            if (!destino.existsSync()) {
              try {
                final bytes = base64Decode(b64);
                await destino.writeAsBytes(bytes);
                midiasImportadas++;
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    // Restauração das Conversas do Chat
    final conversasJson = json['conversas'] as List<dynamic>? ?? const [];
    for (final item in conversasJson) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          try {
            await db.insert(
              'conversas_chat',
              Map<String, dynamic>.from(item),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            conversasImportadas++;
          } catch (_) {}
        }
      }
    }

    // Restauração das Mensagens do Chat
    final mensagensJson = json['mensagens'] as List<dynamic>? ?? const [];
    for (final item in mensagensJson) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          try {
            await db.insert(
              'mensagens_chat',
              Map<String, dynamic>.from(item),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            mensagensImportadas++;
          } catch (_) {}
        }
      }
    }

    // Restauração das Chaves Criptográficas e Validações de Identidade
    Future<void> restaurarTabela(String tabela, String chaveJson) async {
      final lista = json[chaveJson] as List<dynamic>? ?? const [];
      for (final item in lista) {
        if (item is Map<String, dynamic>) {
          try {
            await db.insert(
              tabela,
              Map<String, dynamic>.from(item),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (_) {}
        }
      }
    }

    await restaurarTabela('cofre_chaves_seguras', 'chavesSeguras');
    await restaurarTabela('cofre_chaves_troca', 'chavesTroca');
    await restaurarTabela('validacoes_identidade', 'validacoesIdentidade');
    await PreferenciasSoberanasService.importarTodas(
      json['preferenciasUsuario'] as List<dynamic>? ?? const [],
    );

    return ResultadoImportacao(
      contasImportadas: contasImportadas,
      lojasImportadas: lojasImportadas,
      referenciasImportadas: referenciasImportadas,
      convitesImportados: convitesImportados,
      conversasImportadas: conversasImportadas,
      mensagensImportadas: mensagensImportadas,
      midiasImportadas: midiasImportadas,
    );
  }

  static bool mesmoDocumento(String? docA, String? docB) {
    if (docA == null || docB == null) return false;
    final dA = docA.replaceAll(RegExp(r'\D'), '');
    final dB = docB.replaceAll(RegExp(r'\D'), '');
    return dA.isNotEmpty && dB.isNotEmpty && dA == dB;
  }

  static bool _ehDocumentoPlaceholder(String? doc) {
    if (doc == null) return true;
    final digitos = doc.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return true;
    if (digitos == '00000000000100' || digitos == '00000000000000') {
      return true;
    }
    final primeiro = digitos[0];
    return digitos.split('').every((c) => c == primeiro);
  }

  static bool _ehMesmaLojaParaDesduplicar(Loja a, Loja b) {
    if (a.id == b.id) return true;
    if (!mesmoDocumento(a.cnpj, b.cnpj) || _ehDocumentoPlaceholder(a.cnpj)) {
      return false;
    }
    final nomeA = a.nome.trim().toLowerCase();
    final nomeB = b.nome.trim().toLowerCase();
    return nomeA.isNotEmpty && nomeA == nomeB;
  }

  static List<Loja> desduplicarLojas(List<Loja> lista) {
    if (lista.length <= 1) return lista;

    final resultado = <Loja>[];
    final processadas = <int>{};

    for (int i = 0; i < lista.length; i++) {
      if (processadas.contains(i)) continue;
      Loja base = lista[i];

      for (int j = i + 1; j < lista.length; j++) {
        if (processadas.contains(j)) continue;
        final comparada = lista[j];

        if (_ehMesmaLojaParaDesduplicar(base, comparada)) {
          processadas.add(j);
          final baseEhRestaurante =
              base.categorias.toLowerCase().contains('restaurante');
          final compEhRestaurante =
              comparada.categorias.toLowerCase().contains('restaurante');

          if (!baseEhRestaurante && compEhRestaurante) {
            base = mesclarLojas(existente: comparada, importada: base);
          } else {
            base = mesclarLojas(existente: base, importada: comparada);
          }
        }
      }
      processadas.add(i);
      resultado.add(base);
    }

    return resultado;
  }

  static Loja mesclarLojas({
    required Loja existente,
    required Loja importada,
  }) =>
      BackupMergeHelper.mesclarLojas(
        existente: existente,
        importada: importada,
      );
}