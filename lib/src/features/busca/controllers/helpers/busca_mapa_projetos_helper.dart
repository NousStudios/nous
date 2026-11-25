import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/busca/services/projetos_comunitarios_service.dart';

class BuscaMapaProjetosHelper {
  const BuscaMapaProjetosHelper._();

  static Future<List<ProjetoComunitario>> criarProjeto(
    List<ProjetoComunitario> atuais,
    ProjetoComunitario projeto,
  ) async {
    await ProjetosComunitariosService.salvar(projeto);
    return [projeto, ...atuais];
  }

  static Future<({List<ProjetoComunitario> lista, ProjetoComunitario atualizado})>
      alternarApoio(
    List<ProjetoComunitario> atuais,
    ProjetoComunitario projeto,
    String cpfUsuario,
  ) async {
    final atualizado = await ProjetosComunitariosService.alternarApoio(
      projeto: projeto,
      cpfUsuario: cpfUsuario,
    );
    return (
      lista: substituirProjeto(atuais, atualizado),
      atualizado: atualizado,
    );
  }

  static Future<({List<ProjetoComunitario> lista, ProjetoComunitario atualizado})>
      assumirProjeto(
    List<ProjetoComunitario> atuais,
    ProjetoComunitario projeto,
    String cpfUsuario,
    String nomeUsuario,
  ) async {
    final atualizado =
        await ProjetosComunitariosService.assumirResponsabilidade(
      projeto: projeto,
      cpfUsuario: cpfUsuario,
      nomeUsuario: nomeUsuario,
    );
    return (
      lista: substituirProjeto(atuais, atualizado),
      atualizado: atualizado,
    );
  }

  static Future<({List<ProjetoComunitario> lista, ProjetoComunitario atualizado})>
      concluirProjeto(
    List<ProjetoComunitario> atuais,
    ProjetoComunitario projeto,
  ) async {
    final atualizado = await ProjetosComunitariosService.atualizarStatus(
      projeto: projeto,
      status: StatusProjetoComunitario.concluido,
    );
    return (
      lista: substituirProjeto(atuais, atualizado),
      atualizado: atualizado,
    );
  }

  static List<ProjetoComunitario> substituirProjeto(
    List<ProjetoComunitario> atuais,
    ProjetoComunitario atualizado,
  ) {
    final novaLista = List<ProjetoComunitario>.from(atuais);
    final idx = novaLista.indexWhere((p) => p.id == atualizado.id);
    if (idx != -1) {
      novaLista[idx] = atualizado;
    }
    return novaLista;
  }
}
