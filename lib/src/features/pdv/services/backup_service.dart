import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/services/convites_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';

class ResultadoImportacao {
  final int contasImportadas;
  final int lojasImportadas;
  final int referenciasImportadas;
  final int convitesImportados;

  const ResultadoImportacao({
    required this.contasImportadas,
    required this.lojasImportadas,
    required this.referenciasImportadas,
    required this.convitesImportados,
  });

  int get total =>
      contasImportadas +
      lojasImportadas +
      referenciasImportadas +
      convitesImportados;

  bool get vazio => total == 0;
}

class BackupService {
  BackupService._();

  static Future<Map<String, dynamic>> gerarJson() async {
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

    return {
      'versao': 1,
      'exportadoEm': DateTime.now().toIso8601String(),
      'contas': contas.map((c) => c.toJson()).toList(),
      'cofres': cofres,
      'convites': convites,
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

      if (arquivoHoje.existsSync()) return;

      final dados = await gerarJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(dados);
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
          if (l.id == nova.id) return true;
          return mesmoDocumento(l.cnpj, nova.cnpj);
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

    return ResultadoImportacao(
      contasImportadas: contasImportadas,
      lojasImportadas: lojasImportadas,
      referenciasImportadas: referenciasImportadas,
      convitesImportados: convitesImportados,
    );
  }

  static bool mesmoDocumento(String? docA, String? docB) {
    if (docA == null || docB == null) return false;
    final dA = docA.replaceAll(RegExp(r'\D'), '');
    final dB = docB.replaceAll(RegExp(r'\D'), '');
    return dA.isNotEmpty && dB.isNotEmpty && dA == dB;
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

        final mesmoDoc = mesmoDocumento(base.cnpj, comparada.cnpj);
        final mesmoId = base.id == comparada.id;

        if (mesmoDoc || mesmoId) {
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
  }) {
    final categoriasFinal = existente.categorias.trim().isNotEmpty
        ? existente.categorias
        : importada.categorias;

    final nomeFinal = existente.nome.trim().isNotEmpty
        ? existente.nome
        : importada.nome;
    final cnpjFinal = existente.cnpj.trim().isNotEmpty
        ? existente.cnpj
        : importada.cnpj;
    final telefoneFinal = existente.telefone.trim().isNotEmpty
        ? existente.telefone
        : importada.telefone;
    final enderecoFinal = existente.endereco.trim().isNotEmpty
        ? existente.endereco
        : importada.endereco;
    final numeroFinal = existente.numero.trim().isNotEmpty
        ? existente.numero
        : importada.numero;
    final emailFinal = existente.email.trim().isNotEmpty
        ? existente.email
        : importada.email;
    final redesSociaisFinal = existente.redesSociais.trim().isNotEmpty
        ? existente.redesSociais
        : importada.redesSociais;
    final tagsFinal = existente.tags.trim().isNotEmpty
        ? existente.tags
        : importada.tags;
    final logoFinal = existente.logo.trim().isNotEmpty
        ? existente.logo
        : importada.logo;

    final itensMesclados = <ItemLoja>[...existente.itensLoja];
    for (final itemImp in importada.itensLoja) {
      final idx = itensMesclados.indexWhere((i) {
        if (i.id == itemImp.id) return true;
        return i.nome.trim().isNotEmpty &&
            i.nome.trim().toLowerCase() == itemImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        itensMesclados.add(itemImp);
      } else {
        final atual = itensMesclados[idx];
        final imagensUnidas =
            <String>{...atual.imagens, ...itemImp.imagens}.toList();
        final variantesUnidas = <VarianteItem>[...atual.variantes];
        for (final v in itemImp.variantes) {
          if (!variantesUnidas.any((existenteV) =>
              existenteV.nome.trim().toLowerCase() ==
              v.nome.trim().toLowerCase())) {
            variantesUnidas.add(v);
          }
        }

        itensMesclados[idx] = atual.copyWith(
          tipo: atual.tipo ?? itemImp.tipo,
          preco: atual.preco.trim().isNotEmpty ? atual.preco : itemImp.preco,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : itemImp.descricao,
          estoqueMinimo: atual.estoqueMinimo.trim().isNotEmpty
              ? atual.estoqueMinimo
              : itemImp.estoqueMinimo,
          imagens: imagensUnidas,
          variantes: variantesUnidas,
          possuiDelivery: atual.possuiDelivery || itemImp.possuiDelivery,
        );
      }
    }

    final clientesMesclados = <Cliente>[...existente.clientesLoja];
    for (final cImp in importada.clientesLoja) {
      final idx = clientesMesclados.indexWhere((c) {
        if (c.id == cImp.id) return true;
        if (mesmoDocumento(c.cnpj, cImp.cnpj)) return true;
        return c.nome.trim().isNotEmpty &&
            c.nome.trim().toLowerCase() == cImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        clientesMesclados.add(cImp);
      } else {
        final atual = clientesMesclados[idx];
        clientesMesclados[idx] = atual.copyWith(
          cnpj: atual.cnpj.trim().isNotEmpty ? atual.cnpj : cImp.cnpj,
          telefone: atual.telefone.trim().isNotEmpty
              ? atual.telefone
              : cImp.telefone,
          endereco: atual.endereco.trim().isNotEmpty
              ? atual.endereco
              : cImp.endereco,
          numero: atual.numero.trim().isNotEmpty ? atual.numero : cImp.numero,
          email: atual.email.trim().isNotEmpty ? atual.email : cImp.email,
          redesSociais: atual.redesSociais.trim().isNotEmpty
              ? atual.redesSociais
              : cImp.redesSociais,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : cImp.descricao,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : cImp.foto,
        );
      }
    }

    final categoriasLojaMescladas =
        <CategoriaLoja>[...existente.categoriasLoja];
    for (final catImp in importada.categoriasLoja) {
      final idx = categoriasLojaMescladas.indexWhere((c) {
        if (c.id == catImp.id) return true;
        return c.nome.trim().isNotEmpty &&
            c.nome.trim().toLowerCase() == catImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        categoriasLojaMescladas.add(catImp);
      } else {
        final atual = categoriasLojaMescladas[idx];
        final itemIdsUnidos =
            <String>{...atual.itemIds, ...catImp.itemIds}.toList();
        final grupoIdsUnidos =
            <String>{...atual.grupoIds, ...catImp.grupoIds}.toList();
        categoriasLojaMescladas[idx] = atual.copyWith(
          itemIds: itemIdsUnidos,
          grupoIds: grupoIdsUnidos,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : catImp.foto,
          tipo: atual.tipo ?? catImp.tipo,
        );
      }
    }

    final fornecedoresMesclados = <Fornecedor>[...existente.fornecedoresLoja];
    for (final fImp in importada.fornecedoresLoja) {
      final idx = fornecedoresMesclados.indexWhere((f) {
        if (f.id == fImp.id) return true;
        if (mesmoDocumento(f.cnpj, fImp.cnpj)) return true;
        return f.nome.trim().isNotEmpty &&
            f.nome.trim().toLowerCase() == fImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        fornecedoresMesclados.add(fImp);
      } else {
        final atual = fornecedoresMesclados[idx];
        fornecedoresMesclados[idx] = atual.copyWith(
          cnpj: atual.cnpj.trim().isNotEmpty ? atual.cnpj : fImp.cnpj,
          telefone: atual.telefone.trim().isNotEmpty
              ? atual.telefone
              : fImp.telefone,
          endereco: atual.endereco.trim().isNotEmpty
              ? atual.endereco
              : fImp.endereco,
          numero: atual.numero.trim().isNotEmpty ? atual.numero : fImp.numero,
          email: atual.email.trim().isNotEmpty ? atual.email : fImp.email,
          redesSociais: atual.redesSociais.trim().isNotEmpty
              ? atual.redesSociais
              : fImp.redesSociais,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : fImp.descricao,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : fImp.foto,
        );
      }
    }

    final gruposMesclados =
        <GrupoComponentesLoja>[...existente.gruposComponentesLoja];
    for (final gImp in importada.gruposComponentesLoja) {
      final idx = gruposMesclados.indexWhere((g) {
        if (g.id == gImp.id) return true;
        return g.nome.trim().isNotEmpty &&
            g.nome.trim().toLowerCase() == gImp.nome.trim().toLowerCase();
      });
      if (idx == -1) {
        gruposMesclados.add(gImp);
      }
    }

    final acoesMescladas = <RegistroAcao>[...existente.acoes];
    for (final aImp in importada.acoes) {
      if (!acoesMescladas.any((a) => a.id == aImp.id)) {
        acoesMescladas.add(aImp);
      }
    }
    acoesMescladas.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final pedidosMesclados = <PedidoLoja>[...existente.pedidosLoja];
    for (final pImp in importada.pedidosLoja) {
      if (!pedidosMesclados.any((p) => p.id == pImp.id)) {
        pedidosMesclados.add(pImp);
      }
    }
    pedidosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final estoqueMesclado = <MovimentoEstoque>[...existente.movimentosEstoque];
    for (final mImp in importada.movimentosEstoque) {
      if (!estoqueMesclado.any((m) => m.id == mImp.id)) {
        estoqueMesclado.add(mImp);
      }
    }
    estoqueMesclado.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final pagamentosMesclados =
        <PagamentoFuncionario>[...existente.pagamentosFuncionarios];
    for (final pagImp in importada.pagamentosFuncionarios) {
      if (!pagamentosMesclados.any((pag) => pag.id == pagImp.id)) {
        pagamentosMesclados.add(pagImp);
      }
    }
    pagamentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final membrosMesclados = <MembroLoja>[...existente.membros];
    for (final mImp in importada.membros) {
      if (!membrosMesclados.any((m) => m.cpf == mImp.cpf)) {
        membrosMesclados.add(mImp);
      }
    }

    final mesasMescladas = <MesaLoja>[...existente.mesas];
    for (final mesaImp in importada.mesas) {
      if (!mesasMescladas.any((m) =>
          m.id == mesaImp.id ||
          (m.numero.trim().isNotEmpty &&
              m.numero.trim() == mesaImp.numero.trim()))) {
        mesasMescladas.add(mesaImp);
      }
    }

    final galeriaFinal =
        <String>{...existente.galeria, ...importada.galeria}.toList();
    final arquivosFinal =
        <String>{...existente.arquivos, ...importada.arquivos}.toList();
    final musicasFinal =
        <String>{...existente.musicas, ...importada.musicas}.toList();
    final videosFinal =
        <String>{...existente.videos, ...importada.videos}.toList();
    final audiosFinal =
        <String>{...existente.arquivosAudio, ...importada.arquivosAudio}
            .toList();
    final descricoesFinal = <String, String>{
      ...importada.descricoesAnexos,
      ...existente.descricoesAnexos,
    };

    final impressoraFinal = (existente.configuracoesImpressora.nomeImpressora.isNotEmpty ||
            existente.configuracoesImpressora.enderecoRede.isNotEmpty)
        ? existente.configuracoesImpressora
        : importada.configuracoesImpressora;

    final sonsFinal = <String, String>{
      ...importada.sonsAlertas,
      ...existente.sonsAlertas,
    };

    return existente.copyWith(
      nome: nomeFinal,
      cnpj: cnpjFinal,
      telefone: telefoneFinal,
      endereco: enderecoFinal,
      numero: numeroFinal,
      email: emailFinal,
      redesSociais: redesSociaisFinal,
      categorias: categoriasFinal,
      tags: tagsFinal,
      logo: logoFinal,
      categoriasLoja: categoriasLojaMescladas,
      itensLoja: itensMesclados,
      gruposComponentesLoja: gruposMesclados,
      clientesLoja: clientesMesclados,
      fornecedoresLoja: fornecedoresMesclados,
      pedidosLoja: pedidosMesclados,
      acoes: acoesMescladas,
      membros: membrosMesclados,
      mesas: mesasMescladas,
      movimentosEstoque: estoqueMesclado,
      pagamentosFuncionarios: pagamentosMesclados,
      galeria: galeriaFinal,
      arquivos: arquivosFinal,
      musicas: musicasFinal,
      videos: videosFinal,
      arquivosAudio: audiosFinal,
      descricoesAnexos: descricoesFinal,
      configuracoesImpressora: impressoraFinal,
      sonsAlertas: sonsFinal,
    );
  }
}