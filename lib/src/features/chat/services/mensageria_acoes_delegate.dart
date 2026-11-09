import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/chat/views/dialogs/dialog_compartilhar_comanda.dart';
import 'package:nous/src/features/chat/views/widgets/visualizador_imagem_chat_dialog.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido_dialog.dart';

/// Delegado responsável por orquestrar ações de anexar arquivos, câmeras,
/// comandas, backups e modais da Mensageria Nous.
class MensageriaAcoesDelegate {
  static Future<void> capturarFotoCamera({
    required BuildContext context,
    required MensageriaController controller,
  }) async {
    final auth = context.read<AuthProvider>();
    try {
      String? caminhoFoto;
      try {
        final picker = ImagePicker();
        final foto = await picker.pickImage(source: ImageSource.camera);
        if (foto != null) {
          caminhoFoto = foto.path;
        }
      } catch (e) {
        debugPrint(
          '[Mensageria] Falha ao abrir câmera via ImagePicker, tentando fallback: $e',
        );
      }

      if (caminhoFoto == null) {
        const grupo = XTypeGroup(
          label: 'Câmera / Imagens',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
        );
        final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
        if (arquivo == null) return;
        caminhoFoto = arquivo.path;
      }

      final salvo = await ImagemService.salvarImagemLocal(caminhoFoto);
      if (salvo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível carregar a imagem da câmera.'),
            ),
          );
        }
        return;
      }

      final tamanho = await File(salvo).length();
      await controller.enviarMensagem(
        texto: '',
        tipo: 'imagem',
        caminhoAnexo: salvo,
        nomeAnexo: p.basename(caminhoFoto),
        tamanhoAnexo: tamanho,
        auth: auth,
      );
    } catch (e) {
      debugPrint('[Mensageria] Erro ao capturar foto: $e');
    }
  }

  static Future<void> anexarFoto({
    required BuildContext context,
    required MensageriaController controller,
  }) async {
    final auth = context.read<AuthProvider>();
    try {
      const grupo = XTypeGroup(
        label: 'Imagens',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
      );
      final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
      if (arquivo == null) return;

      final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
      if (salvo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível anexar esta imagem.'),
            ),
          );
        }
        return;
      }

      final tamanho = await File(salvo).length();
      await controller.enviarMensagem(
        texto: '',
        tipo: 'imagem',
        caminhoAnexo: salvo,
        nomeAnexo: p.basename(arquivo.path),
        tamanhoAnexo: tamanho,
        auth: auth,
      );
    } catch (e) {
      debugPrint('[Mensageria] Erro ao anexar foto: $e');
    }
  }

  static Future<void> anexarArquivo({
    required BuildContext context,
    required MensageriaController controller,
  }) async {
    final auth = context.read<AuthProvider>();
    try {
      const grupo = XTypeGroup(
        label: 'Documentos e Arquivos',
        extensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'csv'],
      );
      final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
      if (arquivo == null) return;

      final salvo = await ChatService.salvarArquivoAnexo(arquivo.path);
      if (salvo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível anexar este arquivo.'),
            ),
          );
        }
        return;
      }

      final tamanho = await File(salvo).length();
      await controller.enviarMensagem(
        texto: '',
        tipo: 'arquivo',
        caminhoAnexo: salvo,
        nomeAnexo: p.basename(arquivo.path),
        tamanhoAnexo: tamanho,
        auth: auth,
      );
    } catch (e) {
      debugPrint('[Mensageria] Erro ao anexar arquivo: $e');
    }
  }

  static void abrirDialogCompartilharComanda({
    required BuildContext context,
    required AppTheme theme,
    required MensageriaController controller,
    required bool modoLoja,
    required String? lojaId,
  }) {
    final pdv = context.read<PdvProvider>();
    List<PedidoLoja> pedidos = [];

    if (modoLoja && lojaId != null) {
      final loja = pdv.buscarPorId(lojaId);
      if (loja != null) {
        pedidos = List<PedidoLoja>.from(loja.pedidosLoja);
      }
    } else {
      final todasLojas = [...pdv.lojasQueAdministro, ...pdv.lojasQueParticipo];
      for (final l in todasLojas) {
        pedidos.addAll(l.pedidosLoja);
      }
    }

    pedidos.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    DialogCompartilharComanda.mostrar(
      context,
      theme: theme,
      pedidos: pedidos,
      onCompartilhar: (p) {
        final numStr = p.numero.toString().padLeft(4, '0');
        final auth = context.read<AuthProvider>();
        controller.enviarMensagem(
          texto: 'Pedido #$numStr • R\$ ${p.valor.toStringAsFixed(2)}',
          tipo: 'comanda',
          pedidoId: p.id,
          dadosPedidoJson: jsonEncode(p.toJson()),
          auth: auth,
        );
      },
    );
  }

  static void abrirComandaDoChat({
    required BuildContext context,
    required MensagemChat msg,
    required String? lojaId,
  }) {
    final pdv = context.read<PdvProvider>();
    PedidoLoja? pedidoEfetivo;
    String lojaIdEfetiva = lojaId ?? '';

    if (msg.dadosPedidoJson.isNotEmpty) {
      try {
        final mapa = jsonDecode(msg.dadosPedidoJson) as Map<String, dynamic>;
        pedidoEfetivo = PedidoLoja.fromJson(mapa);
      } catch (_) {}
    }

    if (pedidoEfetivo == null && msg.pedidoId.isNotEmpty) {
      final todasLojas = [...pdv.lojasQueAdministro, ...pdv.lojasQueParticipo];
      for (final l in todasLojas) {
        final achado = l.pedidosLoja.cast<PedidoLoja?>().firstWhere(
          (p) => p?.id == msg.pedidoId,
          orElse: () => null,
        );
        if (achado != null) {
          pedidoEfetivo = achado;
          lojaIdEfetiva = l.id;
          break;
        }
      }
    }

    if (pedidoEfetivo != null) {
      ComandaPedidoDialog.mostrar(
        context,
        lojaId: lojaIdEfetiva,
        pedido: pedidoEfetivo,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados da comanda não disponíveis.')),
      );
    }
  }

  static Future<void> abrirArquivo(BuildContext context, String caminho) async {
    try {
      final resolvido =
          ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
      final f = File(resolvido);
      if (!f.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo não encontrado no disco local.'),
            ),
          );
        }
        return;
      }
      if (Platform.isWindows) {
        await Process.run('explorer', [f.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [f.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [f.path]);
      }
    } catch (e) {
      debugPrint('[Mensageria] Erro ao abrir arquivo: $e');
    }
  }

  static void visualizarFotoAmpliada({
    required BuildContext context,
    required AppTheme theme,
    required String caminho,
  }) {
    VisualizadorImagemChatDialog.abrir(context, caminho: caminho, theme: theme);
  }

  static Future<void> exportarBackupConversa(
    BuildContext context,
    ConversaChat conversa,
  ) async {
    try {
      final mapa = {
        'conversa': conversa.toJson(),
        'mensagens': conversa.mensagens.map((m) => m.toJson()).toList(),
        'exportadoEm': DateTime.now().toIso8601String(),
      };
      final textoJson = const JsonEncoder.withIndent('  ').convert(mapa);
      const grupo = XTypeGroup(
        label: 'Backup Conversa JSON',
        extensions: ['json'],
      );
      final local = await getSaveLocation(
        suggestedName: 'chat_backup_${conversa.id}.json',
        acceptedTypeGroups: const [grupo],
      );
      if (local == null) return;

      final arquivo = File(local.path);
      await arquivo.writeAsString(textoJson);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup da conversa salvo em: ${local.path}')),
        );
      }
    } catch (e) {
      debugPrint('[Mensageria] Erro ao exportar backup da conversa: $e');
    }
  }

  static void solicitarExclusaoConversa({
    required BuildContext context,
    required MensageriaController controller,
    required ConversaChat conversa,
    required String? lojaId,
  }) {
    final auth = context.read<AuthProvider>();
    final notif = context.read<NotificacoesProvider>();
    final contaLogada = auth.contaAtual;

    if (!conversa.ehGrupo && !conversa.ehLoja) {
      final cpfDest = ChatService.normalizarCpf(conversa.identificador);
      if (cpfDest.isNotEmpty &&
          cpfDest != ChatService.normalizarCpf(contaLogada?.cpf ?? '')) {
        final convite = ConviteLoja(
          id: 'exc_conv_${DateTime.now().millisecondsSinceEpoch}',
          lojaId: lojaId ?? 'nous_chat',
          nomeLoja: conversa.titulo,
          cpfConvidante: contaLogada?.cpf ?? '',
          nomeConvidante: contaLogada?.nomeExibicao ?? 'Usuário',
          cpfConvidado: cpfDest,
          papel: PapelMembro.funcionario,
          dataHora: DateTime.now(),
          tipo: TipoNotificacao.solicitacaoExclusaoConversa,
        );
        notif.enviarConvite(convite);
      }
    }

    ChatService.excluirConversaLocal(conversa.id).then((_) {
      if (context.mounted) {
        if (controller.conversaSelecionada?.id == conversa.id) {
          controller.selecionarConversa(null);
        }
        final pdv = context.read<PdvProvider>();
        controller.recarregarConversas(
          auth: auth,
          pdv: pdv,
          manterSelecionada: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversa excluída localmente.')),
        );
      }
    });
  }

  static void solicitarSaidaDoGrupo({
    required BuildContext context,
    required MensageriaController controller,
    required ConversaChat conversa,
  }) {
    final auth = context.read<AuthProvider>();
    final contaLogada = auth.contaAtual;
    final meuCpf = ChatService.normalizarCpf(contaLogada?.cpf ?? '');
    final meuNome = contaLogada?.nomeExibicao ?? 'Usuário';

    final msgSaida = MensagemChat(
      id: 'msg_saida_${DateTime.now().millisecondsSinceEpoch}_${gerarIdUnico()}',
      conversaId: conversa.id,
      remetenteId: 'sistema',
      remetenteNome: 'Sistema',
      destinatarioId: 'todos',
      texto: '$meuNome saiu do grupo',
      dataHora: DateTime.now(),
      statusEnvio: 'entregue',
      entregue: true,
    );
    ChatService.salvarMensagem(msgSaida);

    final novosParticipantes = List<String>.from(conversa.participantesIds);
    novosParticipantes.removeWhere(
      (p) => ChatService.normalizarCpf(p) == meuCpf,
    );

    final grupoAtualizado = conversa.copyWith(
      participantesIds: novosParticipantes,
      ultimaMensagem: '$meuNome saiu do grupo',
      dataHoraUltimaMensagem: DateTime.now(),
    );
    ChatService.despacharConversaAtualizada(grupoAtualizado);
    ChatService.excluirConversaLocal(conversa.id).then((_) {
      if (context.mounted) {
        if (controller.conversaSelecionada?.id == conversa.id) {
          controller.selecionarConversa(null);
        }
        final pdv = context.read<PdvProvider>();
        controller.recarregarConversas(
          auth: auth,
          pdv: pdv,
          manterSelecionada: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você saiu do grupo "${conversa.titulo}".')),
        );
      }
    });
  }

  static Future<String?> selecionarFotoGrupo() async {
    try {
      const grupo = XTypeGroup(
        label: 'Imagens',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
      if (arquivo == null) return null;
      return await ImagemService.salvarImagemLocal(arquivo.path);
    } catch (e) {
      debugPrint('[Mensageria] Erro ao selecionar foto do grupo: $e');
      return null;
    }
  }

  static Future<void> encaminharMensagem({
    required MensagemChat msgOriginal,
    required ConversaChat destino,
    required AuthProvider auth,
    required bool modoLoja,
    String? lojaId,
    String? nomeLoja,
    String? logoLoja,
    String? usuarioCpf,
    String? usuarioNome,
  }) async {
    final conta = auth.contaAtual;
    final remetenteId = modoLoja
        ? (lojaId ?? 'loja')
        : (usuarioCpf ?? conta?.cpf ?? 'usuario');
    final remetenteNome = modoLoja
        ? (nomeLoja ?? 'Loja')
        : (usuarioNome ?? conta?.nomeExibicao ?? 'Usuário');
    final remetenteFoto = modoLoja
        ? (logoLoja ?? '')
        : (conta?.fotoExibicao ?? auth.buscarFotoPorCpf(conta?.cpf ?? ''));

    final agora = DateTime.now();
    final encaminhada = MensagemChat(
      id: 'msg_${agora.millisecondsSinceEpoch}_${msgOriginal.id.hashCode.abs()}',
      conversaId: destino.id,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      remetenteFoto: remetenteFoto,
      destinatarioId: destino.identificador,
      texto: msgOriginal.texto,
      dataHora: agora,
      enviadaPorMim: true,
      tipo: msgOriginal.tipo,
      caminhoAnexo: msgOriginal.caminhoAnexo,
      nomeAnexo: msgOriginal.nomeAnexo,
      tamanhoAnexo: msgOriginal.tamanhoAnexo,
      pedidoId: msgOriginal.pedidoId,
      dadosPedidoJson: msgOriginal.dadosPedidoJson,
      statusEnvio: 'pendente',
    );

    await ChatService.salvarConversa(
      destino.copyWith(
        ultimaMensagem: encaminhada.texto.isNotEmpty
            ? encaminhada.texto
            : (encaminhada.caminhoAnexo.isNotEmpty ? '📷 Foto' : 'Mensagem'),
        dataHoraUltimaMensagem: agora,
      ),
    );

    await ChatService.enviarMensagemInstantanea(encaminhada);
  }
}
