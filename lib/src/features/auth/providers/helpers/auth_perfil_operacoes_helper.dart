import 'dart:async';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/timeline/services/outbox_midia_service.dart';

/// Helper responsável pelas operações de edição de perfil, fotos,
/// privacidade e moderação da conta Nous.
class AuthPerfilOperacoesHelper {
  AuthPerfilOperacoesHelper._();

  static Future<UsuarioNous> salvarEPropagar(
    UsuarioNous atualizado,
    void Function(UsuarioNous) propagarUsuarioAtualizado,
  ) async {
    await ContasNousService.salvar(atualizado);
    propagarUsuarioAtualizado(atualizado);
    return atualizado;
  }

  static Future<UsuarioNous> atualizarPerfilSocial({
    required UsuarioNous conta,
    required String nome,
    required String apelido,
    required String biografia,
    String? foto,
    List<String>? links,
    Map<String, String>? coresPerfil,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) {
    final atualizado = conta.copyWith(
      nomePublico: nome.trim(),
      apelidoPublico: apelido.trim(),
      biografia: biografia.trim(),
      fotoPublica: foto != null ? foto.trim() : conta.fotoPublica,
      links: links ?? conta.links,
      coresPerfil: coresPerfil ?? conta.coresPerfil,
    );
    return salvarEPropagar(atualizado, propagarUsuarioAtualizado);
  }

  static Future<UsuarioNous?> alternarListaCpf({
    required UsuarioNous conta,
    required String cpfAlvo,
    required bool bloquear,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final alvo = CpfValidator.onlyDigits(cpfAlvo);
    if (alvo.isEmpty || alvo == CpfValidator.onlyDigits(conta.cpf)) {
      return null;
    }

    final lista = List<String>.from(
      bloquear ? conta.contasBloqueadas : conta.contasSilenciadas,
    );
    final existe = lista.any((c) => CpfValidator.onlyDigits(c) == alvo);
    if (existe) {
      lista.removeWhere((c) => CpfValidator.onlyDigits(c) == alvo);
    } else {
      lista.add(alvo);
    }

    final atualizado = bloquear
        ? conta.copyWith(contasBloqueadas: lista)
        : conta.copyWith(contasSilenciadas: lista);
    return salvarEPropagar(atualizado, propagarUsuarioAtualizado);
  }

  static Future<UsuarioNous> alternarPrivacidadeDado({
    required UsuarioNous conta,
    required String chave,
    bool? privado,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) {
    final novaLista = List<String>.from(conta.dadosPrivados);
    final deveFicarPrivado = privado ?? !novaLista.contains(chave);
    if (deveFicarPrivado) {
      if (!novaLista.contains(chave)) novaLista.add(chave);
    } else {
      novaLista.remove(chave);
    }

    return salvarEPropagar(
      conta.copyWith(dadosPrivados: novaLista),
      propagarUsuarioAtualizado,
    );
  }

  static Future<UsuarioNous> autorizarAcessoDado({
    required UsuarioNous conta,
    required String cpfSolicitante,
    required String chave,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) {
    final solicitanteLimpo = cpfSolicitante.replaceAll(RegExp(r'\D'), '');
    final chavePermissao = '$solicitanteLimpo:$chave';
    final novaLista = List<String>.from(conta.dadosAutorizadosPorCpf);
    if (!novaLista.contains(chavePermissao)) {
      novaLista.add(chavePermissao);
    }

    return salvarEPropagar(
      conta.copyWith(dadosAutorizadosPorCpf: novaLista),
      propagarUsuarioAtualizado,
    );
  }

  static Future<UsuarioNous> atualizarFoto({
    required UsuarioNous conta,
    required String novaFoto,
    required bool ehFotoPublica,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) async {
    final caminho = ehFotoPublica ? novaFoto.trim() : novaFoto;
    final atualizado = ehFotoPublica
        ? conta.copyWith(fotoPublica: caminho)
        : conta.copyWith(foto: caminho);
    await ContasNousService.salvar(atualizado);

    if (caminho.isNotEmpty &&
        !ClienteRedeLocal().conectado &&
        !ServidorRedeLocal().ativo) {
      unawaited(
        OutboxMidiaService.enfileirar(
          entidadeTipo: 'usuario',
          entidadeId: conta.cpf,
          caminhoLocal: caminho,
        ),
      );
    }

    propagarUsuarioAtualizado(atualizado);
    return atualizado;
  }

  static Future<UsuarioNous> atualizarNotaPensamento({
    required UsuarioNous conta,
    required String texto,
    String musica = '',
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) {
    final limpo = texto.trim();
    final atualizado = conta.copyWith(
      notaPensamento: limpo,
      notaPensamentoCriadaEm:
          limpo.isEmpty ? '' : DateTime.now().toIso8601String(),
      notaPensamentoMusica: limpo.isEmpty ? '' : musica.trim(),
    );
    return salvarEPropagar(atualizado, propagarUsuarioAtualizado);
  }

  static Future<Set<String>> carregarDadosReveladosDono(String cpf) async {
    final digitos = CpfValidator.onlyDigits(cpf);
    if (digitos.isEmpty) return {};
    final lista = await PreferenciasSoberanasService.obterLista(
      'dados_revelados_$digitos',
    );
    return lista.toSet();
  }

  static Future<Set<String>> alternarRevelacaoParaDono({
    required String cpf,
    required Set<String> atuais,
    required String chave,
  }) async {
    final digitos = CpfValidator.onlyDigits(cpf);
    final novo = Set<String>.from(atuais);
    if (!novo.remove(chave)) {
      novo.add(chave);
    }
    await PreferenciasSoberanasService.salvarLista(
      'dados_revelados_$digitos',
      novo.toList(),
    );
    return novo;
  }

  static Future<UsuarioNous> atualizarDadosPessoais({
    required UsuarioNous conta,
    String? dataNascimento,
    String? nomePai,
    String? nomeMae,
    String? localNascimento,
    String? tipoSanguineo,
    String? estadoCivil,
    String? cepResidencial,
    String? enderecoResidencial,
    String? numeroResidencial,
    required void Function(UsuarioNous) propagarUsuarioAtualizado,
  }) {
    final atualizado = conta.copyWith(
      dataNascimento: dataNascimento,
      nomePai: nomePai,
      nomeMae: nomeMae,
      localNascimento: localNascimento,
      tipoSanguineo: tipoSanguineo,
      estadoCivil: estadoCivil,
      cepResidencial: cepResidencial,
      enderecoResidencial: enderecoResidencial,
      numeroResidencial: numeroResidencial,
    );
    return salvarEPropagar(atualizado, propagarUsuarioAtualizado);
  }
}
