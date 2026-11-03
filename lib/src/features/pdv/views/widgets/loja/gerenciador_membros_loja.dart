import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/dados_locais_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

/// Controlador desacoplado para a gestão de membros, permissões, papéis,
/// busca unificada de usuários e convites da loja no PDV.
class GerenciadorMembrosLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<MembroLoja> Function() obterMembros;
  final void Function(List<MembroLoja> membros) definirMembros;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final void Function(String mensagem) avisar;

  GerenciadorMembrosLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterMembros,
    required this.definirMembros,
    required this.registrarAcao,
    required this.avisar,
  });

  String rotuloPapelCurto(PapelMembro papel) {
    switch (papel) {
      case PapelMembro.dono:
        return 'Dono';
      case PapelMembro.socio:
        return 'Sócio';
      case PapelMembro.admin:
        return 'Admin';
      case PapelMembro.funcionario:
        return 'Funcionário';
    }
  }

  Future<UsuarioNous?> buscarContaPorCpf(String cpf) async {
    var conta = await ContasNousService.buscarPorCpf(cpf);

    // Se conectado como terminal móvel ao balcão, consulta a ficha cadastral unificada e completa
    if (ClienteRedeLocal().conectado) {
      try {
        final remota = await ClienteRedeLocal().buscarUsuarioRemoto(cpf);
        if (remota != null) {
          conta = remota;
        }
      } catch (_) {}
    }

    if (conta == null) {
      try {
        final dadosAuto = await DadosLocaisService.buscarPorDocumento(cpf);
        if (dadosAuto != null && dadosAuto.nome.isNotEmpty) {
          conta = UsuarioNous(
            cpf: cpf,
            nome: dadosAuto.nome,
            apelido: dadosAuto.apelido.isNotEmpty ? dadosAuto.apelido : dadosAuto.nome,
            dataNascimento: dadosAuto.dataNascimento,
            foto: dadosAuto.foto,
          );
        }
      } catch (_) {}
    }

    if (conta == null) {
      try {
        conta = await ClienteRedeLocal().buscarUsuarioRemoto(cpf);
      } catch (_) {}
    }
    return conta;
  }

  Future<void> enviarConvite(UsuarioNous conta, PapelMembro papel) async {
    final context = obterContext();
    final auth = context.read<AuthProvider>();
    final autor = auth.contaAtual;
    if (autor == null) return;

    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    if (loja == null) return;

    final convite = ConviteLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfConvidante: autor.cpf,
      nomeConvidante: autor.nome,
      cpfDonoOriginal: loja.cpfDonoOriginal.isNotEmpty ? loja.cpfDonoOriginal : autor.cpf,
      cpfConvidado: conta.cpf,
      lojaId: loja.id,
      nomeLoja: loja.nome,
      papel: papel,
      dataHora: DateTime.now(),
    );

    await context.read<NotificacoesProvider>().enviarConvite(convite, loja: loja);

    registrarAcao(
      TipoAcao.conviteEnviado,
      'Convite enviado para "${conta.nome}" como ${rotuloPapelCurto(papel)}',
    );
  }

  Future<void> removerMembro(String cpf) async {
    final context = obterContext();
    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    final membro = loja?.membros.firstWhere(
      (m) => m.cpf == cpf,
      orElse: () => MembroLoja(
        cpf: cpf,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );

    final auth = context.read<AuthProvider>();
    final autor = auth.contaAtual;
    if (membro == null || autor == null || loja == null) return;

    final notificacoes = context.read<NotificacoesProvider>();
    final pdv = context.read<PdvProvider>();
    final donoOriginal = loja.cpfDonoOriginal.isNotEmpty ? loja.cpfDonoOriginal : autor.cpf;

    // Regra do Manifesto: Sócios NÃO podem excluir outros Sócios nem Donos
    final autorMembro = loja.membros.where((m) => m.cpf == autor.cpf).firstOrNull;
    if (autorMembro?.papel == PapelMembro.socio &&
        (membro.papel == PapelMembro.socio || membro.papel == PapelMembro.dono)) {
      avisar('Sócios não possuem permissão para excluir outros sócios ou donos.');
      return;
    }

    // Se o membro alvo for outro Dono, não remove diretamente: envia solicitação de consentimento
    if (membro.papel == PapelMembro.dono && membro.cpf != autor.cpf) {
      final notificacao = ConviteLoja(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cpfConvidante: autor.cpf,
        nomeConvidante: autor.nome,
        cpfDonoOriginal: donoOriginal,
        cpfConvidado: membro.cpf,
        lojaId: loja.id,
        nomeLoja: loja.nome,
        papel: PapelMembro.dono,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoExclusaoDono,
      );

      await notificacoes.enviarConvite(notificacao, loja: loja);
      if (!estaMontado()) return;
      avisar(
        'Solicitação de saída enviada para ${membro.nome}. Como se trata de um dono, exige consentimento.',
      );
      registrarAcao(
        TipoAcao.membroRemovido,
        'Solicitação de saída do dono "${membro.nome}" enviada para consentimento',
      );
      return;
    }

    await pdv.removerMembro(lojaId, cpf);
    if (!estaMontado()) return;
    definirMembros(obterMembros().where((m) => m.cpf != cpf).toList());

    // Se conectado como terminal móvel ao balcão, garante envio prioritário imediato da exclusão
    if (ClienteRedeLocal().conectado &&
        ClienteRedeLocal().lojaSincronizada?.id == lojaId) {
      final lojaAtual = pdv.buscarPorId(lojaId);
      if (lojaAtual != null) {
        ClienteRedeLocal().enviarLojaAtualizada(lojaAtual, imediato: true);
      }
    }

    // Enviar notificação avisando o membro removido
    final notificacaoRemocao = ConviteLoja(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cpfConvidante: autor.cpf,
      nomeConvidante: autor.nome,
      cpfDonoOriginal: donoOriginal,
      cpfConvidado: membro.cpf,
      lojaId: loja.id,
      nomeLoja: loja.nome,
      papel: membro.papel,
      dataHora: DateTime.now(),
      tipo: TipoNotificacao.remocaoLoja,
    );
    await notificacoes.enviarConvite(notificacaoRemocao, loja: loja);

    registrarAcao(
      TipoAcao.membroRemovido,
      'Membro "${membro.nome}" removido da loja por "${autor.nome}"',
    );
  }

  Future<void> atualizarPapelMembro(String cpf, PapelMembro papel) async {
    final context = obterContext();
    final loja = context.read<PdvProvider>().buscarPorId(lojaId);
    final membro = loja?.membros.firstWhere(
      (m) => m.cpf == cpf,
      orElse: () => MembroLoja(
        cpf: cpf,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );

    // Um sócio não pode ter seu papel alterado sem seu consentimento.
    if (membro != null &&
        membro.papel == PapelMembro.socio &&
        papel != PapelMembro.socio) {
      final auth = context.read<AuthProvider>();
      final conta = auth.contaAtual;
      if (conta != null) {
        final donoOriginal = loja?.cpfDonoOriginal.isNotEmpty == true
            ? loja!.cpfDonoOriginal
            : conta.cpf;
        final notificacao = ConviteLoja(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cpfConvidante: conta.cpf,
          nomeConvidante: conta.nome,
          cpfDonoOriginal: donoOriginal,
          cpfConvidado: membro.cpf,
          lojaId: lojaId,
          nomeLoja: loja?.nome ?? '',
          papel: papel,
          dataHora: DateTime.now(),
          tipo: TipoNotificacao.alteracaoPapel,
        );

        await context.read<NotificacoesProvider>().enviarConvite(notificacao, loja: loja);
        if (!estaMontado()) return;
        avisar(
          'Solicitação enviada para ${membro.nome}. A alteração de papel exige o consentimento do sócio.',
        );
        registrarAcao(
          TipoAcao.papelAlterado,
          'Solicitação de alteração de papel de "${membro.nome}" enviada para consentimento',
        );
        return;
      }
    }

    await context.read<PdvProvider>().atualizarPapelMembro(
          lojaId,
          cpf,
          papel,
        );
    definirMembros(
      obterMembros()
          .map((m) => m.cpf == cpf ? m.copyWith(papel: papel) : m)
          .toList(),
    );

    registrarAcao(
      TipoAcao.papelAlterado,
      'Papel de "${membro?.nome ?? ''}" alterado para '
          '${rotuloPapelCurto(papel)}',
    );
  }

  Future<void> sairDaLoja() async {
    final context = obterContext();
    await context.read<PdvProvider>().sairDaLoja(lojaId);
    if (!estaMontado()) return;
    Navigator.of(obterContext()).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PerfisPdvView()),
      (route) => false,
    );
  }
}
