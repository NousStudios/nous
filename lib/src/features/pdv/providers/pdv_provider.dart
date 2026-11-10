import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/gasto_diario.dart';
import 'package:nous/src/features/pdv/models/gasto_fixo.dart';
import 'package:nous/src/features/pdv/models/contrato_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_programado.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_permissoes_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_caixa_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_pedidos_programados_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_membros_cargos_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_estoque_financeiro_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_lojas_cofre_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_gastos_ponto_helper.dart';
import 'package:nous/src/features/pdv/providers/helpers/pdv_layout_impressora_helper.dart';

class PdvProvider extends ChangeNotifier {
  final List<Loja> _lojas = [];
  String? _cpfAtual;
  bool _layoutDesktopGlobal = false;
  String _tipoLayoutDesktopGlobal = 'balcao_operacional';

  String? get cpfAtual => _cpfAtual;
  List<Loja> get lojas => List.unmodifiable(_lojas);
  bool get layoutDesktopGlobal => _layoutDesktopGlobal;
  String get tipoLayoutDesktopGlobal => _tipoLayoutDesktopGlobal;

  void notificarMudanca() => notifyListeners();

  bool layoutDesktopAtivo([String? lojaId, double? larguraTela]) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return false;
    }
    if (larguraTela != null && larguraTela <= 850) {
      return false;
    }
    if (lojaId != null && lojaId.isNotEmpty) {
      final loja = buscarPorId(lojaId);
      if (loja != null) return loja.layoutExpandidoEfetivo;
    }
    return _layoutDesktopGlobal;
  }

  String tipoLayoutAtivo([String? lojaId]) {
    if (lojaId != null && lojaId.isNotEmpty) {
      final loja = buscarPorId(lojaId);
      if (loja != null && loja.tipoLayoutMaior.isNotEmpty) {
        return loja.tipoLayoutMaior;
      }
    }
    return _tipoLayoutDesktopGlobal;
  }

  bool get temLojaSalva => _lojas.isNotEmpty;

  static bool _mesmoCpf(String? a, String? b) {
    if (a == null || b == null) return false;
    final aDigitos = a.replaceAll(RegExp(r'\D'), '');
    final bDigitos = b.replaceAll(RegExp(r'\D'), '');
    if (aDigitos.isEmpty || bDigitos.isEmpty) return a.trim() == b.trim();
    return aDigitos == bDigitos;
  }

  static const String idLojaColetivaNous = 'loja_nous_coletiva';

  List<Loja> get lojasQueAdministro {
    final cpf = _cpfAtual;
    if (cpf == null) return [];
    return _lojas.where((l) {
      if (l.id == idLojaColetivaNous) return false;
      return l.membros.any((m) =>
          _mesmoCpf(m.cpf, cpf) &&
          (m.papel == PapelMembro.dono || m.papel == PapelMembro.socio));
    }).toList();
  }

  List<Loja> get lojasQueParticipo {
    final cpf = _cpfAtual;
    if (cpf == null) return [];
    final lista = _lojas.where((l) {
      if (l.id == idLojaColetivaNous) {
        return l.membros.any((m) => _mesmoCpf(m.cpf, cpf));
      }
      return l.membros.any((m) =>
          _mesmoCpf(m.cpf, cpf) &&
          (m.papel == PapelMembro.admin ||
              m.papel == PapelMembro.funcionario));
    }).toList();

    final lojaNous =
        _lojas.where((l) => l.id == idLojaColetivaNous).firstOrNull;
    if (lojaNous != null && !lista.any((l) => l.id == idLojaColetivaNous)) {
      lista.insert(0, lojaNous);
    }
    return lista;
  }

  List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      get todosItensEstoqueBaixo {
    final alertas =
        <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[];
    for (final loja in _lojas) {
      for (final item in loja.itensLoja) {
        if (item.tipo == TipoItemLoja.servico) continue;
        var saldo = 0.0;
        var temMovimento = false;
        for (final m in loja.movimentosEstoque) {
          if (m.itemId == item.id) {
            saldo += m.quantidadeComSinal;
            temMovimento = true;
          }
        }
        if (temMovimento && saldo < 10) {
          alertas.add((
            item: item,
            saldo: saldo,
            lojaNome: loja.nome,
            lojaId: loja.id,
          ));
        }
      }
    }
    return alertas;
  }

  /// Retorna os itens com estoque baixo ou esgotado restritos a uma loja específica
  List<({ItemLoja item, double saldo, String lojaNome, String lojaId})>
      itensEstoqueBaixoPorLoja(String lojaId) {
    final alertas =
        <({ItemLoja item, double saldo, String lojaNome, String lojaId})>[];
    final loja = _lojas.where((l) => l.id == lojaId).firstOrNull;
    if (loja == null) return alertas;

    for (final item in loja.itensLoja) {
      if (item.tipo == TipoItemLoja.servico) continue;
      var saldo = 0.0;
      var temMovimento = false;
      for (final m in loja.movimentosEstoque) {
        if (m.itemId == item.id) {
          saldo += m.quantidadeComSinal;
          temMovimento = true;
        }
      }
      if (temMovimento && saldo < 10) {
        alertas.add((
          item: item,
          saldo: saldo,
          lojaNome: loja.nome,
          lojaId: loja.id,
        ));
      }
    }
    return alertas;
  }

  int get totalItensEstoqueBaixo => todosItensEstoqueBaixo.length;

  String? buscarFotoClientePorCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in _lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos &&
            cliente.foto.isNotEmpty &&
            (loja.logo.isEmpty || cliente.foto != loja.logo) &&
            File(cliente.foto).existsSync()) {
          return cliente.foto;
        }
      }
    }
    return null;
  }

  Cliente? buscarClientePorCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;
    for (final loja in _lojas) {
      for (final cliente in loja.clientesLoja) {
        final cDigits = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos) {
          return cliente;
        }
      }
    }
    return null;
  }

  void sincronizarFotoUsuarioEmClientes(String cpf, String novaFoto) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return;
    for (int i = 0; i < _lojas.length; i++) {
      final loja = _lojas[i];
      var alterou = false;
      final novosClientes = loja.clientesLoja.map((c) {
        final cDigits = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos && c.foto != novaFoto) {
          alterou = true;
          return c.copyWith(foto: novaFoto);
        }
        return c;
      }).toList();

      final novosFornecedores = loja.fornecedoresLoja.map((f) {
        final fDigits = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (fDigits == digitos && f.foto != novaFoto) {
          alterou = true;
          return f.copyWith(foto: novaFoto);
        }
        return f;
      }).toList();

      if (alterou) {
        final atualizada = loja.copyWith(
          clientesLoja: novosClientes,
          fornecedoresLoja: novosFornecedores,
        );
        _lojas[i] = atualizada;
        _salvarLojaNoCofreCorreto(atualizada);
      }
    }
    notifyListeners();
  }

  void sincronizarDadosUsuarioEmLojas(UsuarioNous usuario) {
    final digitos = usuario.cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return;
    final nomeValido = usuario.nome.trim();
    final ehNomeSpurio = nomeValido.isEmpty ||
        nomeValido.toLowerCase() == 'blackview' ||
        nomeValido.toLowerCase() == 'celular';

    for (int i = 0; i < _lojas.length; i++) {
      final loja = _lojas[i];
      var alterou = false;

      final novosMembros = loja.membros.map((m) {
        final mDigits = m.cpf.replaceAll(RegExp(r'[^0-9]'), '');
        if (mDigits == digitos) {
          if (!ehNomeSpurio && m.nome != nomeValido) {
            alterou = true;
            return m.copyWith(nome: nomeValido);
          }
        }
        return m;
      }).toList();

      final novosClientes = loja.clientesLoja.map((c) {
        final cDigits = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (cDigits == digitos) {
          var clienteAtualizado = c;
          if (usuario.foto.isNotEmpty && c.foto != usuario.foto) {
            alterou = true;
            clienteAtualizado = clienteAtualizado.copyWith(foto: usuario.foto);
          }
          if (!ehNomeSpurio && c.nome != nomeValido) {
            alterou = true;
            clienteAtualizado = clienteAtualizado.copyWith(nome: nomeValido);
          }
          return clienteAtualizado;
        }
        return c;
      }).toList();

      final novosFornecedores = loja.fornecedoresLoja.map((f) {
        final fDigits = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
        if (fDigits == digitos &&
            usuario.foto.isNotEmpty &&
            f.foto != usuario.foto) {
          alterou = true;
          return f.copyWith(foto: usuario.foto);
        }
        return f;
      }).toList();

      if (alterou) {
        final atualizada = loja.copyWith(
          membros: novosMembros,
          clientesLoja: novosClientes,
          fornecedoresLoja: novosFornecedores,
        );
        _lojas[i] = atualizada;
        _salvarLojaNoCofreCorreto(atualizada);
      }
    }
    notifyListeners();
  }

  MembroLoja? meuMembro(String lojaId) =>
      PdvPermissoesHelper.resolverMeuMembro(buscarPorId(lojaId), _cpfAtual);

  PapelMembro? meuPapel(String lojaId) => meuMembro(lojaId)?.papel;

  CargoLoja? meuCargoPersonalizado(String lojaId) {
    final loja = buscarPorId(lojaId);
    final m = PdvPermissoesHelper.resolverMeuMembro(loja, _cpfAtual);
    return PdvPermissoesHelper.resolverMeuCargoPersonalizado(loja, m);
  }

  bool possoEditarAbaLoja(String lojaId) =>
      PdvPermissoesHelper.podeEditarAbaLoja(buscarPorId(lojaId), _cpfAtual);

  bool possoUsarImpressora(String lojaId) =>
      PdvPermissoesHelper.podeUsarImpressora(buscarPorId(lojaId), _cpfAtual);

  bool possoEditarDadosLoja(String lojaId) =>
      PdvPermissoesHelper.podeEditarDadosLoja(buscarPorId(lojaId), _cpfAtual);

  bool possoUsarFinanceiro(String lojaId) =>
      PdvPermissoesHelper.podeUsarFinanceiro(buscarPorId(lojaId), _cpfAtual);

  bool possoRegistrarPagamento(String lojaId) =>
      PdvPermissoesHelper.podeRegistrarPagamento(buscarPorId(lojaId), _cpfAtual);

  bool possoGerenciarMembros(String lojaId) =>
      PdvPermissoesHelper.podeGerenciarMembros(buscarPorId(lojaId), _cpfAtual);

  bool possoResetarTransacoes(String lojaId) =>
      PdvPermissoesHelper.podeResetarTransacoes(buscarPorId(lojaId), _cpfAtual);

  bool possoExcluirLoja(String lojaId) =>
      PdvPermissoesHelper.podeExcluirLoja(buscarPorId(lojaId), _cpfAtual);

  Future<void> entrarComCpf(String cpf) async {
    _cpfAtual = cpf;
    final lojasCompletas = await PdvLojasCofreHelper.carregarLojasCompletas(cpf);
    _lojas
      ..clear()
      ..addAll(lojasCompletas);
    await _herdarCalibracaoImpressoraEntreLojasLocais();
    notifyListeners();

    unawaited(() async {
      try {
        if (!ServidorRedeLocal().ativo) {
          final prefs = await SharedPreferences.getInstance();
          final ultimoIp = prefs.getString('nous_ultimo_ip_balcao');
          if (ultimoIp != null && ultimoIp.isNotEmpty) {
            await ClienteRedeLocal().tentarAutoConectarSeDisponivel(this);
          }
        }
      } catch (_) {}
    }());
  }

  Future<void> _herdarCalibracaoImpressoraEntreLojasLocais() async {
    Loja? referenciaCalibrada;
    for (final l in _lojas) {
      if (l.id == idLojaColetivaNous) continue;
      final c = l.configuracoesImpressora;
      if (PdvLayoutImpressoraHelper.temCalibracaoTipografiaOuMargem(c) ||
          c.camposClientePersonalizados) {
        referenciaCalibrada = l;
        break;
      }
    }
    referenciaCalibrada ??= _lojas
        .where((l) =>
            l.id != idLojaColetivaNous &&
            l.configuracoesImpressora.nomeImpressora.isNotEmpty)
        .firstOrNull;

    if (referenciaCalibrada == null) return;
    final ref = referenciaCalibrada.configuracoesImpressora;

    for (int i = 0; i < _lojas.length; i++) {
      final loja = _lojas[i];
      if (loja.id == idLojaColetivaNous ||
          loja.id == referenciaCalibrada.id) {
        continue;
      }
      final atual = loja.configuracoesImpressora;
      final semCalibracaoFisica = !PdvLayoutImpressoraHelper.temCalibracaoTipografiaOuMargem(atual);
      final semImpressoraDefinida =
          atual.nomeImpressora.isEmpty && ref.nomeImpressora.isNotEmpty;
      final semCamposPersonalizados =
          !atual.camposClientePersonalizados && ref.camposClientePersonalizados;

      if (semCalibracaoFisica ||
          semImpressoraDefinida ||
          semCamposPersonalizados) {
        final novaConfig = atual.copyWith(
          larguraPapelMm:
              semCalibracaoFisica ? ref.larguraPapelMm : atual.larguraPapelMm,
          tamanhoFonte:
              semCalibracaoFisica ? ref.tamanhoFonte : atual.tamanhoFonte,
          modeloFonte:
              semCalibracaoFisica ? ref.modeloFonte : atual.modeloFonte,
          margemEsquerdaMm: semCalibracaoFisica
              ? ref.margemEsquerdaMm
              : atual.margemEsquerdaMm,
          margemDireitaMm:
              semCalibracaoFisica ? ref.margemDireitaMm : atual.margemDireitaMm,
          nomeImpressora:
              atual.nomeImpressora.isEmpty ? ref.nomeImpressora : atual.nomeImpressora,
          tipoConexao:
              atual.nomeImpressora.isEmpty ? ref.tipoConexao : atual.tipoConexao,
          enderecoRede:
              atual.enderecoRede.isEmpty ? ref.enderecoRede : atual.enderecoRede,
          camposClienteComanda: semCamposPersonalizados
              ? List<String>.from(ref.camposClienteComanda)
              : atual.camposClienteComanda,
          camposClientePersonalizados: semCamposPersonalizados
              ? ref.camposClientePersonalizados
              : atual.camposClientePersonalizados,
        );
        final lojaAtualizada =
            loja.copyWith(configuracoesImpressora: novaConfig);
        _lojas[i] = lojaAtualizada;
        await _salvarLojaNoCofreCorreto(lojaAtualizada);
      }
    }
  }


  /// Alterna a função de Desenvolvedor para um membro na Loja Coletiva Nous
  Future<void> alternarFuncaoDesenvolvedorNous(String cpf) async {
    final digitos = cpf.replaceAll(RegExp(r'\D'), '');
    final idxLoja = _lojas.indexWhere((l) => l.id == idLojaColetivaNous);
    if (idxLoja == -1) return;

    final loja = _lojas[idxLoja];
    final novosMembros = loja.membros.map((m) {
      if (m.cpf.replaceAll(RegExp(r'\D'), '') == digitos) {
        final ehDev = m.cargoPersonalizadoId == 'desenvolvedor';
        return m.copyWith(
          cargoPersonalizadoId: ehDev ? null : 'desenvolvedor',
          limparCargoPersonalizado: ehDev,
        );
      }
      return m;
    }).toList();

    final lojaAtualizada = loja.copyWith(membros: novosMembros);
    _lojas[idxLoja] = lojaAtualizada;
    await LojasService.salvarLojaIndividual(lojaAtualizada);
    notifyListeners();

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarLojaAtualizada(lojaAtualizada, imediato: true);
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'loja_atualizada',
        'loja': lojaAtualizada.toJson(),
      });
    }
  }

  void entrarComoVisitante() {
    limparSessao();
  }

  void limparSessao() {
    _cpfAtual = null;
    _lojas.clear();
    notifyListeners();
  }

  Future<void> _salvarLojaNoCofreCorreto(Loja loja) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;
    final dono =
        loja.cpfDonoOriginal.isEmpty ? cpf : loja.cpfDonoOriginal;

    await LojasService.salvarLojaIndividual(loja.copyWith(cpfDonoOriginal: dono));

    // Se o Servidor de Rede Local estiver ativo para esta loja, notifica imediatamente os terminais conectados
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarLojaAtualizada(loja);
    }

    // Se este terminal estiver conectado como cliente ao balcão e não estiver aplicando atualização da rede
    if (ClienteRedeLocal().conectado && !ClienteRedeLocal().aplicandoAtualizacaoRemota) {
      ClienteRedeLocal().enviarLojaAtualizada(loja);
    }
  }

  Future<void> _salvarEAtualizar(Loja atualizada) async {
    final indice = _lojas.indexWhere((l) => l.id == atualizada.id);
    if (indice != -1) {
      _lojas[indice] = atualizada;
      notifyListeners();
      await _salvarLojaNoCofreCorreto(atualizada);
    }
  }

  void salvarLoja({
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    String redesSociais = '',
    required String categorias,
    required String tags,
    String logo = '',
  }) {
    final cpf = _cpfAtual;
    final novaLoja = Loja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfDonoOriginal: cpf ?? '',
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo,
    );

    _lojas.add(novaLoja);
    _herdarCalibracaoImpressoraEntreLojasLocais();
    notifyListeners();
    _salvarLojaNoCofreCorreto(_lojas.last);
  }

  Future<void> adicionarOuAtualizarLoja(Loja loja) async {
    if (LojasService.ehLojaHostFalsa(loja.id, loja.tags, loja.nome)) return;
    final indice = _lojas.indexWhere((l) => l.id == loja.id);
    final lojaConsolidada = LojasService.consolidarLojaComImagensLocais(
      loja,
      indice != -1 ? _lojas[indice] : null,
    );
    if (indice != -1) {
      _lojas[indice] = lojaConsolidada;
    } else {
      _lojas.add(lojaConsolidada);
    }
    notifyListeners();
    await _salvarLojaNoCofreCorreto(lojaConsolidada);
  }

  static String normalizarIdLoja(String id) {
    var limpo = id.trim();
    if (limpo.startsWith('loja_') && limpo != idLojaColetivaNous) {
      limpo = limpo.substring(5);
    }
    if (limpo.contains('_usuario_')) {
      limpo = limpo.split('_usuario_').first;
    }
    return limpo;
  }

  Loja? buscarPorId(String id) {
    final idLimpo = normalizarIdLoja(id);
    for (final loja in _lojas) {
      if (loja.id == id || loja.id == idLimpo) return loja;
    }
    return null;
  }

  Future<void> excluirLoja(String id, {bool originadaDaRede = false}) async {
    final loja = buscarPorId(id);
    _lojas.removeWhere((l) => l.id == id);
    notifyListeners();

    if (loja == null) return;

    final dono = loja.cpfDonoOriginal.isEmpty
        ? (_cpfAtual ?? '')
        : loja.cpfDonoOriginal;
    if (dono.isNotEmpty) {
      final cofre = await LojasService.carregar(dono);
      await LojasService.salvar(
        dono,
        cofre.where((l) => l.id != id).toList(),
      );
    }

    if (_cpfAtual != null && _cpfAtual!.isNotEmpty && _cpfAtual != dono) {
      final cofreAtual = await LojasService.carregar(_cpfAtual!);
      await LojasService.salvar(
        _cpfAtual!,
        cofreAtual.where((l) => l.id != id).toList(),
      );
    }

    for (final membro in loja.membros) {
      await LojasService.removerReferencia(membro.cpf, id);
    }
    if (_cpfAtual != null) {
      await LojasService.removerReferencia(_cpfAtual!, id);
    }

    // Excluir conversas da loja
    await ChatService.excluirConversaLocal('loja_${id}_geral');

    // Propagar evento de rede para evitar que outro dispositivo restaure a loja excluída
    if (!originadaDaRede) {
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarMensagemRaw({
          'tipo': 'loja_excluida',
          'lojaId': id,
          'cpfDono': dono,
        });
      }
      if (ServidorRedeLocal().ativo) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'loja_excluida',
          'lojaId': id,
          'cpfDono': dono,
        });
      }
    }
  }

  Future<void> excluirDadosDoCpf(String cpf) async {
    await LojasService.excluirTodas(cpf);
    if (_cpfAtual == cpf) {
      _cpfAtual = null;
      _lojas.clear();
      notifyListeners();
    }
  }

  void atualizarDadosLoja(
    String id, {
    required String nome,
    required String cnpj,
    required String telefone,
    required String endereco,
    required String numero,
    required String email,
    required String redesSociais,
    required String categorias,
    required String tags,
    String? logo,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(
      nome: nome,
      cnpj: cnpj,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      redesSociais: redesSociais,
      categorias: categorias,
      tags: tags,
      logo: logo ?? _lojas[indice].logo,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarAnexosLoja(
    String id, {
    List<String>? galeria,
    List<String>? arquivos,
    List<String>? musicas,
    List<String>? videos,
    List<String>? arquivosAudio,
    Map<String, String>? descricoesAnexos,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = PdvLayoutImpressoraHelper.atualizarAnexosLoja(
      _lojas[indice],
      galeria: galeria,
      arquivos: arquivos,
      musicas: musicas,
      videos: videos,
      arquivosAudio: arquivosAudio,
      descricoesAnexos: descricoesAnexos,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarTempoConclusao(String id, int minutos) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = PdvLayoutImpressoraHelper.atualizarTempoConclusao(
      _lojas[indice],
      minutos,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarDescricaoAnexo(String id, String caminho, String descricao) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = PdvLayoutImpressoraHelper.atualizarDescricaoAnexo(
      _lojas[indice],
      caminho,
      descricao,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarSomAlerta(String id, String evento, String som) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = PdvLayoutImpressoraHelper.atualizarSomAlerta(
      _lojas[indice],
      evento,
      som,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarAtalhoTeclado(String id, String tecla, String acao) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = PdvLayoutImpressoraHelper.atualizarAtalhoTeclado(
      _lojas[indice],
      tecla,
      acao,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void alternarLayoutExpandido([String? id]) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    bool novoValor = !_layoutDesktopGlobal;
    if (id != null && id.isNotEmpty) {
      final indice = _lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        novoValor = !_lojas[indice].layoutExpandido;
        _layoutDesktopGlobal = novoValor;
        final atualizada = _lojas[indice].copyWith(layoutExpandido: novoValor);
        _lojas[indice] = atualizada;
        notifyListeners();
        _salvarLojaNoCofreCorreto(atualizada);
        return;
      }
    }
    _layoutDesktopGlobal = novoValor;
    notifyListeners();
  }

  void definirLayoutExpandido(bool ativo, [String? id]) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }
    _layoutDesktopGlobal = ativo;
    if (id != null && id.isNotEmpty) {
      final indice = _lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        final atualizada = _lojas[indice].copyWith(layoutExpandido: ativo);
        _lojas[indice] = atualizada;
        _salvarLojaNoCofreCorreto(atualizada);
      }
    }
    notifyListeners();
  }

  void definirTipoLayoutMaior(String tipo, [String? id]) {
    _tipoLayoutDesktopGlobal = tipo;
    if (id != null && id.isNotEmpty) {
      final indice = _lojas.indexWhere((loja) => loja.id == id);
      if (indice != -1) {
        final atualizada = _lojas[indice].copyWith(tipoLayoutMaior: tipo);
        _lojas[indice] = atualizada;
        _salvarLojaNoCofreCorreto(atualizada);
      }
    }
    notifyListeners();
  }

  void atualizarListasLoja(
    String id, {
    List<CategoriaLoja>? categorias,
    List<ItemLoja>? itens,
    List<GrupoComponentesLoja>? gruposComponentes,
    List<Cliente>? clientes,
    List<Fornecedor>? fornecedores,
    List<PedidoLoja>? pedidos,
    List<MesaLoja>? mesas,
    List<MovimentoEstoque>? movimentosEstoque,
    List<PagamentoFuncionario>? pagamentosFuncionarios,
  }) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(
      categoriasLoja: categorias,
      itensLoja: itens,
      gruposComponentesLoja: gruposComponentes,
      clientesLoja: clientes,
      fornecedoresLoja: fornecedores,
      pedidosLoja: pedidos,
      mesas: mesas,
      movimentosEstoque: movimentosEstoque,
      pagamentosFuncionarios: pagamentosFuncionarios,
    );

    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  /// Consulta pedidos da loja sob demanda de forma paginada para relatórios e análises sem sobrecarregar a memória
  Future<List<PedidoLoja>> obterHistoricoPedidosPaginado({
    required String lojaId,
    int limite = 100,
    int offset = 0,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) {
    return LojasService.carregarPedidosPaginados(
      lojaId: lojaId,
      limite: limite,
      offset: offset,
      dataInicio: dataInicio,
      dataFim: dataFim,
      status: status,
    );
  }

  /// Retorna a contagem total de pedidos da loja no SQLite
  Future<int> obterTotalPedidos({
    required String lojaId,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusPedido? status,
  }) {
    return LojasService.contarTotalPedidos(
      lojaId: lojaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      status: status,
    );
  }

  Future<void> resetarTransacoesLoja(
    String lojaId, {
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvEstoqueFinanceiroHelper.resetarTransacoes(
      loja,
      autorCpf: autorCpf,
      autorNome: autorNome,
      autorEmail: autorEmail,
    );
    await LojasService.limparTransacoesBancoLoja(lojaId);
    await _salvarEAtualizar(atualizada);
  }

  void quitarPedidoLoja(
    String lojaId,
    String pedidoId, {
    String formaRecebimento = 'Dinheiro',
    String autorCpf = '',
    String autorNome = '',
    String autorEmail = '',
  }) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvEstoqueFinanceiroHelper.quitarPedido(loja, pedidoId);
    if (res == null) return;

    _salvarEAtualizar(res.loja);

    if (formaRecebimento.trim().toLowerCase() == 'dinheiro' &&
        res.valorQuitado > 0) {
      registrarMovimentoCaixa(
        lojaId,
        tipo: TipoMovimentoCaixa.suprimento,
        valor: res.valorQuitado,
        motivo: 'Recebimento de prazo - Pedido #${res.pedidoQuitado?.numero}',
        cpf: autorCpf,
        nome: autorNome,
      );
    }

    registrarAcao(
      lojaId,
      RegistroAcao(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dataHora: DateTime.now(),
        tipo: TipoAcao.pagamentoPrazoRecebido,
        descricao:
            'Pedido #${res.pedidoQuitado?.numero} quitado ($formaRecebimento) - R\$ ${res.valorQuitado.toStringAsFixed(2).replaceAll('.', ',')}',
        cpfAutor: autorCpf,
        nomeAutor: autorNome,
        emailAutor: autorEmail,
      ),
    );
  }

  void atualizarMesasLoja(String id, List<MesaLoja> mesas) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(mesas: mesas);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  Future<void> alternarLojaAberta(String id, bool aberta) async {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(aberta: aberta);
    _lojas[indice] = atualizada;
    notifyListeners();
    await _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarAcoes(String id, List<RegistroAcao> acoes) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada = _lojas[indice].copyWith(acoes: acoes);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void registrarAcao(String lojaId, RegistroAcao acao) {
    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;

    final atual = _lojas[indice].acoes;
    final atualizada = _lojas[indice].copyWith(acoes: [acao, ...atual]);
    _lojas[indice] = atualizada;
    notifyListeners();
    _salvarLojaNoCofreCorreto(atualizada);
  }

  void atualizarConfiguracoesImpressora(
    String id,
    ConfiguracoesImpressora configuracoes,
  ) {
    final indice = _lojas.indexWhere((loja) => loja.id == id);
    if (indice == -1) return;

    final atualizada =
        _lojas[indice].copyWith(configuracoesImpressora: configuracoes);
    _lojas[indice] = atualizada;
    _salvarLojaNoCofreCorreto(atualizada);

    // Propaga a calibração física da impressora da estação para as demais lojas locais
    for (int i = 0; i < _lojas.length; i++) {
      final outra = _lojas[i];
      if (outra.id == id || outra.id == idLojaColetivaNous) continue;
      final outraAtualizada = PdvLayoutImpressoraHelper.propagarConfiguracoesImpressora(
        outra,
        configuracoes,
      );
      _lojas[i] = outraAtualizada;
      _salvarLojaNoCofreCorreto(outraAtualizada);
    }

    notifyListeners();
  }

  void adicionarGastoDiario(String lojaId, GastoDiario gasto) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.adicionarGastoDiario(loja, gasto);
    _salvarEAtualizar(atualizada);
  }

  void removerGastoDiario(String lojaId, String gastoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.removerGastoDiario(loja, gastoId);
    _salvarEAtualizar(atualizada);
  }

  void quitarGastoDiario(String lojaId, String gastoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.quitarGastoDiario(loja, gastoId);
    _salvarEAtualizar(atualizada);
  }

  void adicionarGastoFixo(String lojaId, GastoFixo gasto) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.adicionarGastoFixo(loja, gasto);
    _salvarEAtualizar(atualizada);
  }

  void removerGastoFixo(String lojaId, String gastoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.removerGastoFixo(loja, gastoId);
    _salvarEAtualizar(atualizada);
  }

  void alternarAtivoGastoFixo(String lojaId, String gastoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.alternarAtivoGastoFixo(loja, gastoId);
    _salvarEAtualizar(atualizada);
  }

  void salvarContratoTrabalho(String lojaId, ContratoTrabalhoMembro contrato) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.salvarContratoTrabalho(loja, contrato);
    _salvarEAtualizar(atualizada);
  }

  void registrarPonto(String lojaId, RegistroPontoMembro ponto) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.registrarPonto(loja, ponto);
    _salvarEAtualizar(atualizada);
  }

  void finalizarPonto(String lojaId, String pontoId, DateTime dataHoraSaida) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.finalizarPonto(loja, pontoId, dataHoraSaida);
    _salvarEAtualizar(atualizada);
  }

  void salvarEscalaTrabalho(String lojaId, EscalaTrabalhoMembro escala) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.salvarEscalaTrabalho(loja, escala);
    _salvarEAtualizar(atualizada);
  }

  void quitarPagamentoFuncionario(String lojaId, String pagamentoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.quitarPagamentoFuncionario(loja, pagamentoId);
    _salvarEAtualizar(atualizada);
  }

  void quitarCompraEstoque(String lojaId, String movimentoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvGastosPontoHelper.quitarCompraEstoque(loja, movimentoId);
    _salvarEAtualizar(atualizada);
  }

  void adicionarMovimentoEstoque(String lojaId, MovimentoEstoque movimento) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvEstoqueFinanceiroHelper.adicionarMovimentoEstoque(loja, movimento);
    _salvarEAtualizar(atualizada);
  }

  void removerMovimentoEstoque(String lojaId, String movimentoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvEstoqueFinanceiroHelper.removerMovimentoEstoque(loja, movimentoId);
    LojasService.excluirMovimentoEstoqueIndividual(lojaId, movimentoId);
    _salvarEAtualizar(atualizada);
  }

  void adicionarPagamentoFuncionario(String lojaId, PagamentoFuncionario pagamento) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvEstoqueFinanceiroHelper.adicionarPagamentoFuncionario(loja, pagamento);
    _salvarEAtualizar(atualizada);
  }

  void removerPagamentoFuncionario(String lojaId, String pagamentoId) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvEstoqueFinanceiroHelper.removerPagamentoFuncionario(loja, pagamentoId);
    LojasService.excluirPagamentoFuncionarioIndividual(lojaId, pagamentoId);
    _salvarEAtualizar(atualizada);
  }

  void garantirDono(
    String lojaId, {
    required String cpf,
    required String nome,
  }) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.garantirDono(loja, cpf: cpf, nome: nome);
    if (atualizada != null) {
      _salvarEAtualizar(atualizada);
    }
  }

  void adicionarMembro(String lojaId, MembroLoja membro) {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.adicionarMembro(loja, membro);
    if (atualizada != null) {
      _salvarEAtualizar(atualizada);
    }
  }

  Future<void> removerMembro(String lojaId, String cpfMembro) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.removerMembro(loja, cpfMembro);
    await _salvarEAtualizar(atualizada);
    await LojasService.removerReferencia(cpfMembro, lojaId);
  }

  Future<void> atualizarPapelMembro(
    String lojaId,
    String cpf,
    PapelMembro papel,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.atualizarPapelMembro(loja, cpf, papel);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> adicionarCargoLoja(String lojaId, CargoLoja cargo) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.adicionarCargoLoja(loja, cargo);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> atualizarCargoLoja(String lojaId, CargoLoja cargo) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.atualizarCargoLoja(loja, cargo);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> removerCargoLoja(String lojaId, String cargoId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.removerCargoLoja(loja, cargoId);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> vincularCargoAoMembro(
    String lojaId,
    String cpf,
    String? cargoId,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.vincularCargoAoMembro(loja, cpf, cargoId);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> atualizarPermissoesCargoNativo(
    String lojaId,
    String papel,
    Map<String, bool> permissoes,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvMembrosCargosHelper.atualizarPermissoesCargoNativo(loja, papel, permissoes);
    await _salvarEAtualizar(atualizada);
  }

  Future<void> sairDaLoja(String lojaId) async {
    final cpf = _cpfAtual;
    if (cpf == null) return;

    final indice = _lojas.indexWhere((loja) => loja.id == lojaId);
    if (indice == -1) return;
    final loja = _lojas[indice];

    _lojas.removeAt(indice);
    notifyListeners();

    await PdvLojasCofreHelper.processarSaidaLoja(loja: loja, cpfUsuario: cpf);
  }

  TurnoCaixa? turnoCaixaAberto(String lojaId) =>
      buscarPorId(lojaId)?.turnoCaixaAberto;

  Future<void> abrirCaixa(
    String lojaId,
    double saldoInicial, {
    required String cpf,
    required String nome,
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvCaixaHelper.abrirCaixa(
      loja,
      saldoInicial: saldoInicial,
      cpf: cpf,
      nome: nome,
    );
    await _salvarEAtualizar(atualizada);
  }

  Future<void> registrarMovimentoCaixa(
    String lojaId, {
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required String cpf,
    required String nome,
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvCaixaHelper.registrarMovimentoCaixa(
      loja,
      tipo: tipo,
      valor: valor,
      motivo: motivo,
      cpf: cpf,
      nome: nome,
    );
    if (atualizada != null) {
      await _salvarEAtualizar(atualizada);
    }
  }

  Future<void> fecharCaixa(
    String lojaId,
    double saldoInformado, {
    required String cpf,
    required String nome,
    String observacao = '',
  }) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvCaixaHelper.fecharCaixa(
      loja,
      saldoInformado: saldoInformado,
      cpf: cpf,
      nome: nome,
      observacao: observacao,
    );
    if (atualizada != null) {
      await _salvarEAtualizar(atualizada);
    }
  }

  Future<void> excluirTurnoCaixa(String lojaId, String turnoId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvCaixaHelper.excluirTurnoCaixa(loja, turnoId);
    await _salvarEAtualizar(atualizada);
  }

  List<PedidoProgramado> pedidosProgramadosDoDia(String lojaId, [DateTime? data]) =>
      PdvPedidosProgramadosHelper.pedidosProgramadosDoDia(buscarPorId(lojaId), data);

  Future<void> adicionarPedidoProgramado(
    String lojaId,
    PedidoProgramado pedido,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final atualizada = PdvPedidosProgramadosHelper.adicionarPedidoProgramado(loja, pedido);
    await _salvarEAtualizar(atualizada);
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<void> atualizarPedidoProgramado(
    String lojaId,
    PedidoProgramado pedido,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.atualizarPedidoProgramado(loja, pedido);
    for (final pid in res.idsPedidosRemovidos) {
      await LojasService.excluirPedidoIndividual(lojaId, pid);
    }
    await _salvarEAtualizar(res.loja);
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<void> removerPedidoProgramado(String lojaId, String pedidoId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.removerPedidoProgramado(loja, pedidoId);
    for (final pid in res.idsPedidosRemovidos) {
      await LojasService.excluirPedidoIndividual(lojaId, pid);
    }
    await _salvarEAtualizar(res.loja);
  }

  Future<void> alternarAtivoPedidoProgramado(
    String lojaId,
    String pedidoId,
  ) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return;
    final res = PdvPedidosProgramadosHelper.alternarAtivoPedidoProgramado(loja, pedidoId);
    for (final pid in res.idsPedidosRemovidos) {
      await LojasService.excluirPedidoIndividual(lojaId, pid);
    }
    await _salvarEAtualizar(res.loja);
    if (!ClienteRedeLocal().conectado) {
      await verificarEGerarPedidosProgramados(lojaId);
    }
  }

  Future<bool> verificarEGerarPedidosProgramados(String lojaId) async {
    final loja = buscarPorId(lojaId);
    if (loja == null) return false;
    final res = PdvPedidosProgramadosHelper.verificarEGerar(loja);
    if (res.alterou) {
      await _salvarEAtualizar(res.loja);
      for (final novo in res.pedidosGerados) {
        if (ServidorRedeLocal().ativo) {
          ServidorRedeLocal().notificarTodos({
            'tipo': 'pedido_adicionado',
            'lojaId': lojaId,
            'pedido': novo.toJson(),
          });
        }
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarPedido(novo);
        }
      }
      return res.pedidosGerados.isNotEmpty;
    }
    return false;
  }
}