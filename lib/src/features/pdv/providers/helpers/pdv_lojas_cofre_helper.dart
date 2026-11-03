import 'package:flutter/foundation.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/referencia_loja.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

/// Helper especialista responsável pelo ciclo de vida, cofre de persistência,
/// resolução de referências e loja coletiva Nous.
class PdvLojasCofreHelper {
  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  static bool mesmoCpf(String? a, String? b) {
    if (a == null || b == null) return false;
    final aDigitos = a.replaceAll(RegExp(r'\D'), '');
    final bDigitos = b.replaceAll(RegExp(r'\D'), '');
    if (aDigitos.isEmpty || bDigitos.isEmpty) return a.trim() == b.trim();
    return aDigitos == bDigitos;
  }

  /// Carrega as lojas que o usuário é dono e as referências em que participa,
  /// expurgando referências órfãs e lojas host falsas.
  static Future<List<Loja>> carregarLojasCompletas(String cpf) async {
    await LojasService.expurgarLojasHostFalsas();

    final minhasLojasBrutas = await LojasService.carregar(cpf);
    final minhasLojasDesduplicadas =
        BackupService.desduplicarLojas(minhasLojasBrutas);
    final minhasLojas = minhasLojasDesduplicadas
        .map((l) => l.cpfDonoOriginal.isEmpty
            ? l.copyWith(cpfDonoOriginal: cpf)
            : l)
        .where((l) =>
            mesmoCpf(l.cpfDonoOriginal, cpf) ||
            l.membros.any((m) => mesmoCpf(m.cpf, cpf)))
        .toList();
    if (minhasLojas.length != minhasLojasBrutas.length) {
      await LojasService.salvar(cpf, minhasLojas);
    }

    final referencias = await LojasService.carregarReferencias(cpf);
    final lojasReferenciadas = <Loja>[];
    final referenciasOrfas = <ReferenciaLoja>[];

    for (final ref in referencias) {
      if (mesmoCpf(ref.cpfDonoOriginal, cpf) ||
          minhasLojas.any((l) => l.id == ref.lojaId)) {
        referenciasOrfas.add(ref);
        continue;
      }
      final cofre = await LojasService.carregar(ref.cpfDonoOriginal);
      Loja? encontrada;
      for (final l in cofre) {
        if (l.id == ref.lojaId) {
          encontrada = l;
          break;
        }
      }
      encontrada ??= await LojasService.carregarLojaPorId(ref.lojaId);

      if (encontrada == null ||
          (!mesmoCpf(encontrada.cpfDonoOriginal, cpf) &&
           !encontrada.membros.any((m) => mesmoCpf(m.cpf, cpf)))) {
        referenciasOrfas.add(ref);
        continue;
      }
      lojasReferenciadas.add(encontrada);
    }

    for (final ref in referenciasOrfas) {
      await LojasService.removerReferencia(cpf, ref.lojaId);
    }

    final resultado = <Loja>[];
    resultado.addAll(
      minhasLojas.where((l) => !LojasService.ehLojaHostFalsa(l.id, l.tags, l.nome)),
    );

    for (final refLoja in lojasReferenciadas) {
      if (!LojasService.ehLojaHostFalsa(refLoja.id, refLoja.tags, refLoja.nome) &&
          !resultado.any((l) => l.id == refLoja.id)) {
        resultado.add(refLoja);
      }
    }

    final lojaColetiva = await consolidarLojaColetivaNous(cpf);
    if (lojaColetiva != null) {
      final idx = resultado.indexWhere((l) => l.id == idLojaColetivaNous);
      if (idx == -1) {
        resultado.add(lojaColetiva);
      } else {
        resultado[idx] = lojaColetiva;
      }
    }

    return resultado;
  }

  /// Consolida a organização coletiva Nous como membro sócio
  static Future<Loja?> consolidarLojaColetivaNous(String cpfUsuario) async {
    try {
      final contas = await ContasNousService.carregarTodas();
      final membrosSocios = <MembroLoja>[];

      for (final conta in contas) {
        final cpfLimpo = conta.cpf.replaceAll(RegExp(r'\D'), '');
        if (cpfLimpo.length == 11 && conta.nome.trim().toLowerCase() != 'blackview') {
          membrosSocios.add(
            MembroLoja(
              cpf: conta.cpf,
              nome: conta.nome.isNotEmpty ? conta.nome : 'Usuário Nous',
              papel: PapelMembro.socio,
              desde: DateTime.now(),
            ),
          );
        }
      }

      if (!membrosSocios.any((m) => mesmoCpf(m.cpf, cpfUsuario))) {
        final contaAtual = await ContasNousService.buscarPorCpf(cpfUsuario);
        membrosSocios.add(
          MembroLoja(
            cpf: cpfUsuario,
            nome: (contaAtual != null && contaAtual.nome.trim().isNotEmpty)
                ? contaAtual.nome.trim()
                : 'Usuário Nous',
            papel: PapelMembro.socio,
            desde: DateTime.now(),
          ),
        );
      }

      var lojaColetiva = await LojasService.carregarLojaPorId(idLojaColetivaNous);
      if (lojaColetiva == null) {
        lojaColetiva = Loja(
          id: idLojaColetivaNous,
          nome: 'Nous',
          cpfDonoOriginal: '00000000000',
          cnpj: '00.000.000/0001-00',
          telefone: '',
          endereco: 'Rede Local Soberana',
          numero: 'S/N',
          email: 'nousstudios72@gmail.com',
          redesSociais: '@nous.studios72',
          categorias: 'Autogestão, Comunidade, Software Livre',
          tags: 'Software Universal de Autogestão Comercial e Social',
          logo: 'assets/images/logo.png',
          membros: membrosSocios,
        );
      } else {
        final mapaMembros = {for (final m in lojaColetiva.membros) m.cpf: m};
        for (final novo in membrosSocios) {
          if (!mapaMembros.containsKey(novo.cpf)) {
            mapaMembros[novo.cpf] = novo;
          }
        }
        lojaColetiva = lojaColetiva.copyWith(
          nome: 'Nous',
          email: 'nousstudios72@gmail.com',
          redesSociais: '@nous.studios72',
          categorias: 'Autogestão, Comunidade, Software Livre',
          tags: 'Software Universal de Autogestão Comercial e Social',
          logo: 'assets/images/logo.png',
          membros: mapaMembros.values.toList(),
        );
      }

      await LojasService.salvarLojaIndividual(lojaColetiva);
      await LojasService.adicionarReferencia(
        cpfUsuario,
        const ReferenciaLoja(
          lojaId: idLojaColetivaNous,
          cpfDonoOriginal: '00000000000',
        ),
      );

      return lojaColetiva;
    } catch (e) {
      debugPrint('[PdvLojasCofreHelper] Erro ao consolidar loja coletiva Nous: $e');
      return null;
    }
  }

  /// Processa a saída de um membro de uma loja, lidando com sucessão do dono
  static Future<void> processarSaidaLoja({
    required Loja loja,
    required String cpfUsuario,
  }) async {
    final souDonoOriginal = mesmoCpf(loja.cpfDonoOriginal, cpfUsuario);
    final outros = loja.membros.where((m) => !mesmoCpf(m.cpf, cpfUsuario)).toList();

    if (outros.isEmpty) {
      if (souDonoOriginal) {
        final cofre = await LojasService.carregar(cpfUsuario);
        await LojasService.salvar(
          cpfUsuario,
          cofre.where((l) => l.id != loja.id).toList(),
        );
      } else {
        await LojasService.removerReferencia(cpfUsuario, loja.id);
        final db = await BancoDadosService.db;
        await db.delete('lojas', where: 'id = ?', whereArgs: [loja.id]);
        if (ClienteRedeLocal().conectado) {
          await ClienteRedeLocal().notificarSaidaLoja(loja.id, cpfUsuario);
        }
      }
      return;
    }

    int peso(PapelMembro p) {
      if (p == PapelMembro.socio) return 0;
      if (p == PapelMembro.admin) return 1;
      if (p == PapelMembro.funcionario) return 2;
      return 3;
    }

    final ordenados = [...outros]
      ..sort((a, b) => peso(a.papel).compareTo(peso(b.papel)));
    final sucessor = ordenados.first;

    if (souDonoOriginal) {
      final lojaTransferida = loja.copyWith(
        cpfDonoOriginal: sucessor.cpf,
        membros: outros
            .map((m) => m.cpf == sucessor.cpf
                ? m.copyWith(papel: PapelMembro.dono)
                : m)
            .toList(),
      );

      final cofreSucessor = await LojasService.carregar(sucessor.cpf);
      final jaTem = cofreSucessor.any((l) => l.id == lojaTransferida.id);
      if (jaTem) {
        await LojasService.salvar(
          sucessor.cpf,
          cofreSucessor
              .map((l) => l.id == lojaTransferida.id ? lojaTransferida : l)
              .toList(),
        );
      } else {
        await LojasService.salvar(
          sucessor.cpf,
          [...cofreSucessor, lojaTransferida],
        );
      }

      final cofreAntigo = await LojasService.carregar(cpfUsuario);
      await LojasService.salvar(
        cpfUsuario,
        cofreAntigo.where((l) => l.id != loja.id).toList(),
      );
    } else {
      final lojaAtualizada = loja.copyWith(membros: outros);
      await LojasService.salvarLojaIndividual(lojaAtualizada);
      await LojasService.removerReferencia(cpfUsuario, loja.id);
      final db = await BancoDadosService.db;
      await db.delete('lojas', where: 'id = ?', whereArgs: [loja.id]);
      if (ClienteRedeLocal().conectado) {
        await ClienteRedeLocal().notificarSaidaLoja(loja.id, cpfUsuario);
      }
    }
  }
}
