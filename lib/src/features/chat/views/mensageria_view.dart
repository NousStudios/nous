import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/models/mensagem_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/comanda_pedido_dialog.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';

class MensageriaView extends StatefulWidget {
  final bool modoLoja;
  final String? lojaId;
  final String? nomeLoja;
  final String? logoLoja;
  final String? operadorNome;
  final String? operadorCpf;
  final String? usuarioNome;
  final String? usuarioCpf;
  final String? usuarioFoto;
  final String? usuarioApelido;
  final bool mostrarBotaoVoltar;
  final String? conversaInicialId;

  const MensageriaView({
    super.key,
    this.modoLoja = false,
    this.lojaId,
    this.nomeLoja,
    this.logoLoja,
    this.operadorNome,
    this.operadorCpf,
    this.usuarioNome,
    this.usuarioCpf,
    this.usuarioFoto,
    this.usuarioApelido,
    this.mostrarBotaoVoltar = true,
    this.conversaInicialId,
  });

  @override
  State<MensageriaView> createState() => _MensageriaViewState();
}

class _MensageriaViewState extends State<MensageriaView> {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _mensagensScrollController = ScrollController();

  List<ConversaChat> _conversas = [];
  List<ConversaChat> _todosContatosDisponiveis = [];
  ConversaChat? _conversaSelecionada;
  String _termoBusca = '';
  bool _inicializado = false;
  final Set<String> _tentativasDownloadImagens = {};

  String get _idVisualizador {
    if (widget.modoLoja) {
      return widget.lojaId ?? 'loja';
    }
    final auth = context.read<AuthProvider>();
    return widget.usuarioCpf ?? auth.contaAtual?.cpf ?? 'usuario';
  }

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(() {
      setState(() {
        _termoBusca = _buscaController.text.trim().toLowerCase();
      });
    });

    ChatService.alteracoesChatNotifier.addListener(_aoAtualizarChat);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _inicializarConversas();
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    ChatService.alteracoesChatNotifier.removeListener(_aoAtualizarChat);
    _buscaController.dispose();
    _mensagemController.dispose();
    _mensagensScrollController.dispose();
    super.dispose();
  }

  String _resumoMensagem(MensagemChat msg) {
    if (msg.tipo == 'imagem') {
      return msg.texto.isNotEmpty ? '📷 ${msg.texto}' : '📷 Foto';
    } else if (msg.tipo == 'arquivo') {
      return msg.texto.isNotEmpty
          ? '📎 ${msg.texto}'
          : '📎 ${msg.nomeAnexo.isNotEmpty ? msg.nomeAnexo : "Arquivo"}';
    } else if (msg.tipo == 'comanda') {
      return msg.texto.isNotEmpty ? '🧾 ${msg.texto}' : '🧾 Comanda de Pedido';
    }
    return msg.texto;
  }

  void _aoAtualizarChat() {
    if (!mounted) return;
    _recarregarConversas(manterSelecionada: true);
  }

  Future<void> _inicializarConversas() async {
    await _recarregarConversas(manterSelecionada: false);
  }

  Future<void> _recarregarConversas({bool manterSelecionada = true}) async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final contaLogada = auth.contaAtual;
    final List<ConversaChat> lista = [];
    final List<ConversaChat> todosDisponiveis = [];

    if (widget.modoLoja && widget.lojaId != null) {
      // MODO LOJA
      final loja = pdv.buscarPorId(widget.lojaId!);
      if (loja != null) {
        final Map<String, _InfoContatoUnificado> contatosUnificados = {};
        final cpfLogadoNorm = ChatService.normalizarCpf(
          widget.operadorCpf ?? contaLogada?.cpf ?? '',
        );

        // 1. Membros da equipe da loja (identidade soberana por CPF com busca de foto)
        for (final membro in loja.membros) {
          final cpfMembro = ChatService.normalizarCpf(membro.cpf);
          if (cpfMembro.isEmpty) continue;

          final ehProprioOperador = cpfMembro == cpfLogadoNorm;
          String fotoMembro = auth.buscarFotoPorCpf(membro.cpf);
          if (fotoMembro.isEmpty) {
            fotoMembro = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
          }
          if (fotoMembro.isEmpty) {
            final contaMembro = await ContasNousService.buscarPorCpf(cpfMembro);
            if (contaMembro != null && contaMembro.foto.isNotEmpty) {
              fotoMembro = contaMembro.foto;
            }
          }

          contatosUnificados[cpfMembro] = _InfoContatoUnificado(
            identificador: membro.cpf,
            cpfNormalizado: cpfMembro,
            titulo: ehProprioOperador ? '${membro.nome} (Você)' : membro.nome,
            subtitulo: 'Equipe • ${membro.papel.name.toUpperCase()}',
            foto: fotoMembro,
            ehMembro: true,
            ehCliente: false,
          );
        }

        // 2. Clientes da loja (reconhecendo se o cliente é um membro ou a própria pessoa)
        for (final cliente in loja.clientesLoja) {
          final cpfCliente = ChatService.normalizarCpf(cliente.cnpj);
          final ehProprioOperador =
              cpfCliente.isNotEmpty && cpfCliente == cpfLogadoNorm;

          if (cpfCliente.length == 11) {
            if (contatosUnificados.containsKey(cpfCliente)) {
              // Já existe como membro ou operador! Mescla sem duplicar!
              final existente = contatosUnificados[cpfCliente]!;
              final fotoResolvida = (existente.foto.isNotEmpty &&
                      ImagemService.existe(existente.foto))
                  ? existente.foto
                  : (cliente.foto.isNotEmpty ? cliente.foto : existente.foto);
              contatosUnificados[cpfCliente] = existente.copyWith(
                foto: fotoResolvida,
                subtitulo: '${existente.subtitulo} | Cliente',
                ehCliente: true,
              );
            } else {
              // Cliente novo com CPF
              String fotoCliente = cliente.foto;
              if (fotoCliente.isEmpty) {
                fotoCliente = auth.buscarFotoPorCpf(cliente.cnpj);
              }
              if (fotoCliente.isEmpty) {
                fotoCliente = pdv.buscarFotoClientePorCpf(cliente.cnpj) ?? '';
              }
              if (fotoCliente.isEmpty) {
                final contaCli = await ContasNousService.buscarPorCpf(cpfCliente);
                if (contaCli != null && contaCli.foto.isNotEmpty) {
                  fotoCliente = contaCli.foto;
                }
              }

              contatosUnificados[cpfCliente] = _InfoContatoUnificado(
                identificador: cliente.cnpj,
                cpfNormalizado: cpfCliente,
                titulo: ehProprioOperador
                    ? '${cliente.nome} (Você)'
                    : cliente.nome,
                subtitulo: ehProprioOperador
                    ? 'Você (Cliente)'
                    : (cliente.telefone.isNotEmpty
                        ? cliente.telefone
                        : 'Cliente cadastrado'),
                foto: fotoCliente,
                ehMembro: false,
                ehCliente: true,
              );
            }
          } else {
            // Cliente sem CPF (apenas CNPJ ou avulso)
            final chave = 'cliente_${cliente.id}';
            contatosUnificados[chave] = _InfoContatoUnificado(
              identificador: cliente.id,
              cpfNormalizado: '',
              titulo: cliente.nome,
              subtitulo: cliente.telefone.isNotEmpty
                  ? cliente.telefone
                  : 'Cliente cadastrado',
              foto: cliente.foto,
              ehMembro: false,
              ehCliente: true,
            );
          }
        }

        // 3. Monta as conversas a partir dos contatos desduplicados
        for (final c in contatosUnificados.values) {
          final convId = c.cpfNormalizado.isNotEmpty
              ? ChatService.conversaIdLojaUsuario(loja.id, c.cpfNormalizado)
              : 'loja_${loja.id}_cliente_${c.identificador}';

          final msgs = await ChatService.carregarMensagens(
            convId,
            idVisualizador: _idVisualizador,
          );
          final naoLidas = await ChatService.contarNaoLidasNaConversa(
            convId,
            _idVisualizador,
          );

          final ultimaMsg = msgs.isNotEmpty
              ? _resumoMensagem(msgs.last)
              : (c.ehMembro
                  ? 'Canal direto da equipe com a loja.'
                  : 'Comandas e mensagens da loja.');

          final dataHoraUltima =
              msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now();

          final conversaItem = ConversaChat(
            id: convId,
            titulo: c.titulo,
            subtitulo: c.subtitulo,
            identificador: c.identificador,
            foto: c.foto,
            ehLoja: false,
            ultimaMensagem: ultimaMsg,
            dataHoraUltimaMensagem: dataHoraUltima,
            naoLidasCount: naoLidas,
            mensagens: msgs,
          );

          todosDisponiveis.add(conversaItem);

          // Só exibe na lista inicial se já houver mensagens trocadas ou se for a conversa atualmente aberta
          if (msgs.isNotEmpty ||
              (_conversaSelecionada != null &&
                  _conversaSelecionada!.id == convId)) {
            lista.add(conversaItem);
          }
        }
      }
    } else {
      // MODO USUÁRIO NOUS (SOCIAL)
      final todasLojas = [
        ...pdv.lojasQueAdministro,
        ...pdv.lojasQueParticipo,
      ];

      final cpfLogado = widget.usuarioCpf ?? contaLogada?.cpf ?? '';

      // Conversa com cada loja
      for (final loja in todasLojas) {
        final convId = ChatService.conversaIdLojaUsuario(loja.id, cpfLogado);
        final msgs = await ChatService.carregarMensagens(
          convId,
          idVisualizador: _idVisualizador,
        );
        final naoLidas = await ChatService.contarNaoLidasNaConversa(
          convId,
          _idVisualizador,
        );

        final conversaLoja = ConversaChat(
          id: convId,
          titulo: loja.nome,
          subtitulo: 'Loja Nous',
          foto: loja.logo,
          identificador: loja.id,
          ehLoja: true,
          ultimaMensagem: msgs.isNotEmpty
              ? _resumoMensagem(msgs.last)
              : 'Canal de atendimento da loja.',
          dataHoraUltimaMensagem:
              msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
          naoLidasCount: naoLidas,
          mensagens: msgs,
        );

        todosDisponiveis.add(conversaLoja);

        if (msgs.isNotEmpty ||
            (_conversaSelecionada != null &&
                _conversaSelecionada!.id == convId)) {
          lista.add(conversaLoja);
        }
      }

      // Conversas com outros membros e clientes conhecidos (desduplicados por CPF)
      final Map<String, ({String nome, String foto})> contatosUnicos = {};
      final cLogadoNorm = ChatService.normalizarCpf(cpfLogado);

      for (final loja in todasLojas) {
        for (final m in loja.membros) {
          final cMembro = ChatService.normalizarCpf(m.cpf);
          if (cMembro.isNotEmpty && cMembro != cLogadoNorm) {
            String fotoM = auth.buscarFotoPorCpf(m.cpf);
            if (fotoM.isEmpty) {
              fotoM = pdv.buscarFotoClientePorCpf(m.cpf) ?? '';
            }
            if (fotoM.isEmpty) {
              final contaM = await ContasNousService.buscarPorCpf(cMembro);
              if (contaM != null && contaM.foto.isNotEmpty) {
                fotoM = contaM.foto;
              }
            }
            contatosUnicos.putIfAbsent(cMembro, () => (nome: m.nome, foto: fotoM));
          }
        }
        for (final c in loja.clientesLoja) {
          final cCli = ChatService.normalizarCpf(c.cnpj);
          if (cCli.length == 11 && cCli != cLogadoNorm) {
            if (contatosUnicos.containsKey(cCli)) {
              final anterior = contatosUnicos[cCli]!;
              if (anterior.foto.isEmpty && c.foto.isNotEmpty) {
                contatosUnicos[cCli] = (nome: anterior.nome, foto: c.foto);
              }
            } else {
              String fotoCli = c.foto;
              if (fotoCli.isEmpty) {
                fotoCli = auth.buscarFotoPorCpf(c.cnpj);
              }
              if (fotoCli.isEmpty) {
                fotoCli = pdv.buscarFotoClientePorCpf(c.cnpj) ?? '';
              }
              contatosUnicos[cCli] = (nome: c.nome, foto: fotoCli);
            }
          }
        }
      }

      for (final entry in contatosUnicos.entries) {
        final convId =
            ChatService.conversaIdEntreUsuarios(cpfLogado, entry.key);
        final msgs = await ChatService.carregarMensagens(
          convId,
          idVisualizador: _idVisualizador,
        );
        final naoLidas = await ChatService.contarNaoLidasNaConversa(
          convId,
          _idVisualizador,
        );

        final conversaUsuario = ConversaChat(
          id: convId,
          titulo: entry.value.nome,
          subtitulo: 'Contato Nous',
          foto: entry.value.foto,
          identificador: entry.key,
          ehLoja: false,
          ultimaMensagem:
              msgs.isNotEmpty ? _resumoMensagem(msgs.last) : 'Toque para conversar.',
          dataHoraUltimaMensagem:
              msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
          naoLidasCount: naoLidas,
          mensagens: msgs,
        );

        todosDisponiveis.add(conversaUsuario);

        if (msgs.isNotEmpty ||
            (_conversaSelecionada != null &&
                _conversaSelecionada!.id == convId)) {
          lista.add(conversaUsuario);
        }
      }
    }

    // Carregar Grupos
    final grupos = await ChatService.carregarGrupos(
      cpfParticipante: widget.modoLoja ? null : contaLogada?.cpf,
    );
    lista.addAll(grupos);
    todosDisponiveis.addAll(grupos);

    // Ordenar conversas pela mais recente
    lista.sort(
      (a, b) => b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem),
    );

    if (!mounted) return;

    setState(() {
      _conversas = lista;
      _todosContatosDisponiveis = todosDisponiveis;
      if (manterSelecionada && _conversaSelecionada != null) {
        final index =
            _conversas.indexWhere((c) => c.id == _conversaSelecionada!.id);
        if (index != -1) {
          _conversaSelecionada = _conversas[index];
        } else {
          ChatService.carregarMensagens(
            _conversaSelecionada!.id,
            idVisualizador: _idVisualizador,
          ).then((msgs) {
            if (mounted && _conversaSelecionada != null) {
              setState(() {
                _conversaSelecionada = _conversaSelecionada!.copyWith(
                  mensagens: msgs,
                  ultimaMensagem:
                      msgs.isNotEmpty ? _resumoMensagem(msgs.last) : '',
                  dataHoraUltimaMensagem:
                      msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
                );
              });
            }
          });
        }
      } else if (_conversaSelecionada == null && widget.conversaInicialId != null) {
        final encontrada = _conversas.cast<ConversaChat?>().firstWhere(
              (c) => c?.id == widget.conversaInicialId || c?.identificador == widget.conversaInicialId,
              orElse: () => _todosContatosDisponiveis.cast<ConversaChat?>().firstWhere(
                    (c) => c?.id == widget.conversaInicialId || c?.identificador == widget.conversaInicialId,
                    orElse: () => null,
                  ),
            );
        if (encontrada != null) {
          _conversaSelecionada = encontrada;
          _marcarConversaComoLida(encontrada);
        }
      }
    });
  }

  bool _larguraDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 720;
  }

  Future<void> _marcarConversaComoLida(ConversaChat conversa) async {
    await ChatService.marcarComoLidas(conversa.id, _idVisualizador);
  }

  Future<void> _enviarMensagem({
    String? textoCustomizado,
    String tipo = 'texto',
    String caminhoAnexo = '',
    String nomeAnexo = '',
    int tamanhoAnexo = 0,
    String pedidoId = '',
    String dadosPedidoJson = '',
  }) async {
    final texto = (textoCustomizado ?? _mensagemController.text).trim();
    if (texto.isEmpty && tipo == 'texto') return;
    if (_conversaSelecionada == null) return;

    final agora = DateTime.now();
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;

    final remetenteId = widget.modoLoja
        ? (widget.lojaId ?? 'loja')
        : (widget.usuarioCpf ?? conta?.cpf ?? 'usuario');

    final remetenteNome = widget.modoLoja
        ? (widget.nomeLoja ?? 'Loja')
        : (widget.usuarioNome ?? conta?.nomeExibicao ?? 'Usuário');

    final atendenteNome = widget.modoLoja
        ? (widget.operadorNome ?? conta?.nomeExibicao ?? 'Atendente')
        : '';

    final remetenteFoto = widget.modoLoja
        ? (widget.logoLoja ?? '')
        : (widget.usuarioFoto ??
            conta?.fotoExibicao ??
            auth.buscarFotoPorCpf(conta?.cpf ?? ''));

    final destinatarioId = _conversaSelecionada!.identificador;

    final novaMensagem = MensagemChat(
      id: 'msg_${agora.millisecondsSinceEpoch}',
      conversaId: _conversaSelecionada!.id,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      remetenteFoto: remetenteFoto,
      destinatarioId: destinatarioId,
      texto: texto,
      dataHora: agora,
      enviadaPorMim: true,
      nomeAtendente: atendenteNome,
      cpfAtendente: widget.operadorCpf ?? conta?.cpf ?? '',
      lida: false,
      tipo: tipo,
      caminhoAnexo: caminhoAnexo,
      nomeAnexo: nomeAnexo,
      tamanhoAnexo: tamanhoAnexo,
      pedidoId: pedidoId,
      dadosPedidoJson: dadosPedidoJson,
    );

    if (textoCustomizado == null) {
      _mensagemController.clear();
    }
    await ChatService.salvarMensagem(novaMensagem);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mensagensScrollController.hasClients) {
        _mensagensScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _anexarFoto() async {
    try {
      const grupo = XTypeGroup(
        label: 'Imagens',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
      );
      final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
      if (arquivo == null) return;

      final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
      if (salvo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível anexar esta imagem.')),
          );
        }
        return;
      }

      final tamanho = await File(salvo).length();
      await _enviarMensagem(
        textoCustomizado: '',
        tipo: 'imagem',
        caminhoAnexo: salvo,
        nomeAnexo: p.basename(arquivo.path),
        tamanhoAnexo: tamanho,
      );
    } catch (e) {
      debugPrint('[Mensageria] Erro ao anexar foto: $e');
    }
  }

  Future<void> _anexarArquivo() async {
    try {
      const grupo = XTypeGroup(
        label: 'Documentos e Arquivos',
        extensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'csv'],
      );
      final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
      if (arquivo == null) return;

      final salvo = await ChatService.salvarArquivoAnexo(arquivo.path);
      if (salvo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível anexar este arquivo.')),
          );
        }
        return;
      }

      final tamanho = await File(salvo).length();
      await _enviarMensagem(
        textoCustomizado: '',
        tipo: 'arquivo',
        caminhoAnexo: salvo,
        nomeAnexo: p.basename(arquivo.path),
        tamanhoAnexo: tamanho,
      );
    } catch (e) {
      debugPrint('[Mensageria] Erro ao anexar arquivo: $e');
    }
  }

  Future<void> _abrirArquivo(String caminho) async {
    try {
      final resolvido = ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
      final f = File(resolvido);
      if (!f.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo não encontrado no disco local.')),
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

  void _visualizarFotoAmpliada(AppTheme theme, String caminho) {
    final resolvido = ImagemService.resolverCaminhoExistente(caminho) ?? caminho;
    final f = File(resolvido);
    if (!f.existsSync()) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        contentPadding: const EdgeInsets.all(12),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(ctx).width * 0.85,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(f, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDialogCompartilharComanda(AppTheme theme) {
    final pdv = context.read<PdvProvider>();
    List<PedidoLoja> pedidos = [];

    if (widget.modoLoja && widget.lojaId != null) {
      final loja = pdv.buscarPorId(widget.lojaId!);
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

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Selecionar Comanda',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
            ),
            child: pedidos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Nenhum pedido encontrado para compartilhar.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: pedidos.length,
                    separatorBuilder: (dialogCtx, index) => Divider(
                      height: 1,
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (dialogCtx, index) {
                      final p = pedidos[index];
                      final numStr = p.numero.toString().padLeft(4, '0');
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.buttonColor.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.receipt_rounded,
                            color: theme.buttonColor,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Pedido #$numStr',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${p.valor.toStringAsFixed(2)}',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.clienteNome.isNotEmpty
                                    ? p.clienteNome
                                    : 'Balcão',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              p.status.name.toUpperCase(),
                              style: theme.getTextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _enviarMensagem(
                            textoCustomizado:
                                'Pedido #$numStr • R\$ ${p.valor.toStringAsFixed(2)}',
                            tipo: 'comanda',
                            pedidoId: p.id,
                            dadosPedidoJson: jsonEncode(p.toJson()),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirComandaDoChat(MensagemChat msg, PedidoLoja? pedido) {
    final pdv = context.read<PdvProvider>();
    PedidoLoja? pedidoEfetivo = pedido;
    String lojaIdEfetiva = widget.lojaId ?? '';

    if (pedidoEfetivo == null && msg.dadosPedidoJson.isNotEmpty) {
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

  void _abrirMenuAnexo(AppTheme theme) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.attachment_rounded, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Anexar ao Chat',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(Icons.image_rounded, color: theme.buttonColor, size: 20),
                  ),
                  title: Text(
                    'Foto / Imagem',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Fotos de produtos, comprovantes ou galeria',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _anexarFoto();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(Icons.insert_drive_file_rounded, color: theme.buttonColor, size: 20),
                  ),
                  title: Text(
                    'Documento / Arquivo',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'PDFs, relatórios e arquivos em geral',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _anexarArquivo();
                  },
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                    child: Icon(Icons.receipt_long_rounded, color: theme.buttonColor, size: 20),
                  ),
                  title: Text(
                    'Comanda de Pedido',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Compartilhar comanda com itens e total',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirDialogCompartilharComanda(theme);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _abrirDialogCriarGrupo(AppTheme theme) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;

    final TextEditingController nomeGrupoController = TextEditingController();
    final Map<String, String> participantesDisponiveis = {};

    final todasLojas = [...pdv.lojasQueAdministro, ...pdv.lojasQueParticipo];
    for (final loja in todasLojas) {
      for (final m in loja.membros) {
        if (ChatService.normalizarCpf(m.cpf) !=
            ChatService.normalizarCpf(conta?.cpf ?? '')) {
          participantesDisponiveis[m.cpf] = m.nome;
        }
      }
    }

    final Set<String> selecionados = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.group_add_outlined, color: theme.textColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Novo Grupo',
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 450),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome do Grupo',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: TextField(
                          controller: nomeGrupoController,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: Equipe de Vendas, Cozinha...',
                            hintStyle: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selecionar Participantes (${selecionados.length})',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (participantesDisponiveis.isEmpty)
                        Text(
                          'Nenhum outro membro ou contato disponível na rede.',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        )
                      else
                        ...participantesDisponiveis.entries.map((entry) {
                          final marcado = selecionados.contains(entry.key);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: marcado,
                            title: Text(
                              entry.value,
                              style: theme.getTextStyle(
                                fontSize: 13,
                                color: theme.textColor,
                              ),
                            ),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selecionados.add(entry.key);
                                } else {
                                  selecionados.remove(entry.key);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                  ),
                  onPressed: () async {
                    final nome = nomeGrupoController.text.trim();
                    if (nome.isEmpty) return;

                    Navigator.pop(ctx);
                    final grupoCriado = await ChatService.criarGrupo(
                      nome: nome,
                      membrosCpfs: selecionados.toList(),
                      autorCpf: widget.operadorCpf ?? conta?.cpf ?? '',
                      autorNome: widget.operadorNome ?? conta?.nome ?? 'Usuário',
                      lojaOrigemId: widget.lojaId,
                    );

                    setState(() {
                      _conversaSelecionada = grupoCriado;
                    });
                  },
                  child: Text(
                    'Criar Grupo',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _abrirDialogNovaConversa(AppTheme theme) async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;
    final cpfLogado = widget.usuarioCpf ?? conta?.cpf ?? '';
    final cpfLogadoNorm = ChatService.normalizarCpf(cpfLogado);

    final List<({
      String id,
      String convId,
      String titulo,
      String subtitulo,
      String foto,
      bool ehLoja,
    })> contatosDisponiveis = [];

    if (widget.modoLoja && widget.lojaId != null) {
      final loja = pdv.buscarPorId(widget.lojaId!);
      if (loja != null) {
        final Map<String, _InfoContatoUnificado> unificados = {};
        for (final m in loja.membros) {
          final cM = ChatService.normalizarCpf(m.cpf);
          if (cM.isEmpty || cM == cpfLogadoNorm) continue;
          unificados[cM] = _InfoContatoUnificado(
            identificador: m.cpf,
            cpfNormalizado: cM,
            titulo: m.nome,
            subtitulo: 'Equipe • ${m.papel.name.toUpperCase()}',
            foto: '',
            ehMembro: true,
          );
        }
        for (final cli in loja.clientesLoja) {
          final cCli = ChatService.normalizarCpf(cli.cnpj);
          if (cCli.length == 11) {
            if (cCli == cpfLogadoNorm) continue;
            if (unificados.containsKey(cCli)) {
              final ant = unificados[cCli]!;
              unificados[cCli] = ant.copyWith(
                foto: ant.foto.isNotEmpty ? ant.foto : cli.foto,
                subtitulo: '${ant.subtitulo} | Cliente',
              );
            } else {
              unificados[cCli] = _InfoContatoUnificado(
                identificador: cli.cnpj,
                cpfNormalizado: cCli,
                titulo: cli.nome,
                subtitulo: cli.telefone.isNotEmpty ? cli.telefone : 'Cliente',
                foto: cli.foto,
                ehCliente: true,
              );
            }
          }
        }
        for (final u in unificados.values) {
          final convId = u.cpfNormalizado.isNotEmpty
              ? ChatService.conversaIdLojaUsuario(loja.id, u.cpfNormalizado)
              : 'loja_${loja.id}_cliente_${u.identificador}';
          contatosDisponiveis.add((
            id: u.identificador,
            convId: convId,
            titulo: u.titulo,
            subtitulo: u.subtitulo,
            foto: u.foto,
            ehLoja: false,
          ));
        }
      }
    } else {
      // Modo Social do Usuário
      // 1. Lojas
      final todasLojas = [
        ...pdv.lojasQueAdministro,
        ...pdv.lojasQueParticipo,
      ];
      for (final loja in todasLojas) {
        final convId = ChatService.conversaIdLojaUsuario(loja.id, cpfLogado);
        contatosDisponiveis.add((
          id: loja.id,
          convId: convId,
          titulo: loja.nome,
          subtitulo: 'Loja Nous',
          foto: loja.logo,
          ehLoja: true,
        ));
      }

      // 2. Outras pessoas / contatos
      final Map<String, ({String nome, String foto, String subtitulo})> contatosUnicos = {};
      for (final loja in todasLojas) {
        for (final m in loja.membros) {
          final cM = ChatService.normalizarCpf(m.cpf);
          if (cM.isNotEmpty && cM != cpfLogadoNorm) {
            contatosUnicos.putIfAbsent(
              cM,
              () => (
                nome: m.nome,
                foto: '',
                subtitulo: 'Membro • ${loja.nome}',
              ),
            );
          }
        }
        for (final cli in loja.clientesLoja) {
          final cCli = ChatService.normalizarCpf(cli.cnpj);
          if (cCli.length == 11 && cCli != cpfLogadoNorm) {
            if (contatosUnicos.containsKey(cCli)) {
              final ant = contatosUnicos[cCli]!;
              if (ant.foto.isEmpty && cli.foto.isNotEmpty) {
                contatosUnicos[cCli] = (
                  nome: ant.nome,
                  foto: cli.foto,
                  subtitulo: ant.subtitulo,
                );
              }
            } else {
              contatosUnicos[cCli] = (
                nome: cli.nome,
                foto: cli.foto,
                subtitulo: 'Cliente • ${loja.nome}',
              );
            }
          }
        }
      }

      for (final entry in contatosUnicos.entries) {
        final convId = ChatService.conversaIdEntreUsuarios(cpfLogado, entry.key);
        contatosDisponiveis.add((
          id: entry.key,
          convId: convId,
          titulo: entry.value.nome,
          subtitulo: entry.value.subtitulo,
          foto: entry.value.foto,
          ehLoja: false,
        ));
      }
    }

    final buscaModalController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final filtro = buscaModalController.text.trim().toLowerCase();
            final filtrados = contatosDisponiveis.where((c) {
              if (filtro.isEmpty) return true;
              return c.titulo.toLowerCase().contains(filtro) ||
                  c.subtitulo.toLowerCase().contains(filtro);
            }).toList();

            return AlertDialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.chat_outlined, color: theme.textColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Nova Conversa',
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: buscaModalController,
                      style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Buscar contato ou loja...',
                        hintStyle: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
                        prefixIcon: Icon(Icons.search, size: 18, color: theme.secondaryTextColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum contato disponível.',
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtrados.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: theme.borderColor.withValues(alpha: 0.3),
                              ),
                              itemBuilder: (context, idx) {
                                final item = filtrados[idx];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      item.ehLoja ? Icons.storefront_outlined : Icons.person_outline,
                                      size: 18,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  title: Text(
                                    item.titulo,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.subtitulo,
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await _selecionarOuIniciarConversa(
                                      convId: item.convId,
                                      titulo: item.titulo,
                                      subtitulo: item.subtitulo,
                                      identificador: item.id,
                                      foto: item.foto,
                                      ehLoja: item.ehLoja,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Fechar',
                    style: theme.getTextStyle(color: theme.secondaryTextColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selecionarOuIniciarConversa({
    required String convId,
    required String titulo,
    required String subtitulo,
    required String identificador,
    required String foto,
    required bool ehLoja,
  }) async {
    final msgs = await ChatService.carregarMensagens(
      convId,
      idVisualizador: _idVisualizador,
    );

    final conversa = ConversaChat(
      id: convId,
      titulo: titulo,
      subtitulo: subtitulo,
      foto: foto,
      identificador: identificador,
      ehLoja: ehLoja,
      ultimaMensagem: msgs.isNotEmpty ? _resumoMensagem(msgs.last) : '',
      dataHoraUltimaMensagem: msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
      naoLidasCount: 0,
      mensagens: msgs,
    );

    final index = _conversas.indexWhere((c) => c.id == convId);
    if (index != -1) {
      _conversas[index] = conversa;
    } else {
      _conversas.insert(0, conversa);
    }

    setState(() {
      _conversaSelecionada = conversa;
    });

    await _marcarConversaComoLida(conversa);
  }

  Future<void> _abrirDetalhesContato(AppTheme theme, ConversaChat conversa) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  _buildAvatar(theme, conversa, raio: 42),
                  const SizedBox(height: 12),
                  Text(
                    conversa.titulo,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversa.subtitulo,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),

                  // Mídias, Links e Docs compartilhados na conversa
                  Builder(
                    builder: (context) {
                      final midias = conversa.mensagens
                          .where((m) =>
                              m.tipo == 'imagem' &&
                              m.caminhoAnexo.trim().isNotEmpty)
                          .toList();
                      final docs = conversa.mensagens
                          .where((m) =>
                              m.tipo == 'arquivo' &&
                              m.caminhoAnexo.trim().isNotEmpty)
                          .toList();
                      final links = conversa.mensagens
                          .where((m) =>
                              m.tipo == 'texto' &&
                              (m.texto.contains('http://') ||
                                  m.texto.contains('https://') ||
                                  m.texto.contains('www.')))
                          .toList();
                      final totalItens =
                          midias.length + docs.length + links.length;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.photo_library_outlined,
                                    size: 18, color: theme.textColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Mídias, Links e Docs',
                                  style: theme.getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                                if (totalItens > 0) ...[
                                  const Spacer(),
                                  Text(
                                    '$totalItens',
                                    style: theme.getTextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (totalItens == 0)
                              Text(
                                'Nenhuma mídia ou documento compartilhado nesta conversa.',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              )
                            else ...[
                              // 1. Fotos e Imagens
                              if (midias.isNotEmpty) ...[
                                Text(
                                  'Fotos (${midias.length})',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: midias.map((m) {
                                    final resolvido =
                                        ImagemService.resolverCaminhoExistente(
                                            m.caminhoAnexo);
                                    final existe = resolvido != null &&
                                        File(resolvido).existsSync();

                                    return InkWell(
                                      onTap: existe
                                          ? () => _visualizarFotoAmpliada(
                                              theme, resolvido)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: theme.cardBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: theme.borderColor
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          child: existe
                                              ? Image.file(
                                                  File(resolvido),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 24,
                                                    color: theme
                                                        .secondaryTextColor,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.image_outlined,
                                                  size: 24,
                                                  color: theme
                                                      .secondaryTextColor,
                                                ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // 2. Documentos e Arquivos
                              if (docs.isNotEmpty) ...[
                                Text(
                                  'Documentos (${docs.length})',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  children: docs.map((d) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.borderColor
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.insert_drive_file_outlined,
                                              size: 20, color: theme.textColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d.nomeAnexo.isNotEmpty
                                                      ? d.nomeAnexo
                                                      : 'Arquivo',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme.getTextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.textColor,
                                                  ),
                                                ),
                                                if (d.tamanhoAnexo > 0)
                                                  Text(
                                                    _formatarTamanho(
                                                        d.tamanhoAnexo),
                                                    style: theme.getTextStyle(
                                                      fontSize: 10,
                                                      color: theme
                                                          .secondaryTextColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.open_in_new_rounded,
                                                size: 16,
                                                color: theme.textColor),
                                            tooltip: 'Abrir',
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () =>
                                                _abrirArquivo(d.caminhoAnexo),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // 3. Links
                              if (links.isNotEmpty) ...[
                                Text(
                                  'Links (${links.length})',
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  children: links.map((l) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.borderColor
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.link,
                                              size: 18,
                                              color: theme.buttonColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SelectableText(
                                              l.texto,
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Botão Ver Perfil Público se for pessoa
                  if (!conversa.ehLoja && !conversa.ehGrupo) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.person_outline, color: theme.buttonTextColor, size: 18),
                        label: Text(
                          'Ver Perfil Público',
                          style: theme.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.buttonTextColor,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          UsuarioNous? usuario;
                          final cpfLimpo = conversa.identificador.replaceAll(RegExp(r'\D'), '');
                          if (cpfLimpo.length == 11) {
                            usuario = await ContasNousService.buscarPorCpf(cpfLimpo);
                          }
                          usuario ??= UsuarioNous(
                            cpf: conversa.identificador,
                            nome: conversa.titulo,
                            apelido: '',
                            foto: conversa.foto,
                            dataNascimento: '',
                          );
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PerfilSocialView(
                                  usuarioAlvo: usuario,
                                  mostrarBotaoVoltar: true,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatarHora(DateTime dataHora) {
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final min = dataHora.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  Widget _buildAvatar(AppTheme theme, ConversaChat conversa, {double raio = 22}) {
    if (conversa.ehGrupo) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.buttonColor.withValues(alpha: 0.2),
        child: Icon(
          Icons.groups_outlined,
          size: raio * 1.1,
          color: theme.textColor,
        ),
      );
    }

    var providerFoto = ImagemService.obterImageProvider(conversa.foto);
    if (providerFoto == null && conversa.identificador.isNotEmpty) {
      final auth = context.read<AuthProvider>();
      final pdv = context.read<PdvProvider>();
      var fotoRecuperada = auth.buscarFotoPorCpf(conversa.identificador);
      if (fotoRecuperada.isEmpty) {
        fotoRecuperada = pdv.buscarFotoClientePorCpf(conversa.identificador) ?? '';
      }
      if (fotoRecuperada.isNotEmpty) {
        providerFoto = ImagemService.obterImageProvider(fotoRecuperada);
      }
    }

    if (providerFoto != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.3),
        backgroundImage: providerFoto,
      );
    }

    return CircleAvatar(
      radius: raio,
      backgroundColor: theme.buttonColor.withValues(alpha: 0.15),
      child: Icon(
        conversa.ehLoja ? Icons.storefront_outlined : Icons.person_outline,
        size: raio * 1.1,
        color: theme.textColor,
      ),
    );
  }

  Widget _buildListaConversas(AppTheme theme) {
    final List<ConversaChat> filtradas = [];
    if (_termoBusca.isEmpty) {
      filtradas.addAll(_conversas);
    } else {
      final idsJaAdicionados = <String>{};

      // 1. Conversas ativas com histórico que combinam com o termo
      for (final c in _conversas) {
        final match = c.titulo.toLowerCase().contains(_termoBusca) ||
            c.subtitulo.toLowerCase().contains(_termoBusca) ||
            c.identificador.toLowerCase().contains(_termoBusca) ||
            c.ultimaMensagem.toLowerCase().contains(_termoBusca);
        if (match) {
          filtradas.add(c);
          idsJaAdicionados.add(c.id);
        }
      }

      // 2. Contatos cadastrados na loja/app que combinam com o termo (mesmo sem mensagens prévias)
      for (final c in _todosContatosDisponiveis) {
        if (!idsJaAdicionados.contains(c.id)) {
          final match = c.titulo.toLowerCase().contains(_termoBusca) ||
              c.subtitulo.toLowerCase().contains(_termoBusca) ||
              c.identificador.toLowerCase().contains(_termoBusca);
          if (match) {
            filtradas.add(c);
            idsJaAdicionados.add(c.id);
          }
        }
      }
    }

    return Column(
      children: [
        // Topo com Barra de Busca e Botão + Novo Grupo
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      TextField(
                        controller: _buscaController,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: '',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: theme.secondaryTextColor,
                          ),
                          suffixIcon: _buscaController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () => _buscaController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                      if (_buscaController.text.isEmpty)
                        Positioned(
                          left: 38,
                          right: 12,
                          child: IgnorePointer(
                            child: TextoRolante(
                              texto: 'Pesquisar contatos ou lojas...',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Nova Conversa',
                child: InkWell(
                  onTap: () => _abrirDialogNovaConversa(theme),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 22,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Criar Novo Grupo',
                child: InkWell(
                  onTap: () => _abrirDialogCriarGrupo(theme),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.group_add_outlined,
                      size: 20,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista de chats
        Expanded(
          child: filtradas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _termoBusca.isEmpty
                          ? 'Nenhuma conversa iniciada.'
                          : 'Nenhum resultado encontrado.',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filtradas.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final conversa = filtradas[index];
                    final selecionada =
                        _conversaSelecionada?.id == conversa.id;

                    return _ItemConversaTile(
                      conversa: conversa,
                      selecionada: selecionada,
                      theme: theme,
                      avatar: _buildAvatar(theme, conversa),
                      horaFormatada: _formatarHora(
                        conversa.dataHoraUltimaMensagem,
                      ),
                      onTap: () {
                        setState(() {
                          _conversaSelecionada = conversa;
                        });
                        _marcarConversaComoLida(conversa);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_mensagensScrollController.hasClients) {
                            _mensagensScrollController.jumpTo(
                              _mensagensScrollController
                                  .position.maxScrollExtent,
                            );
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPainelConversaAtiva(AppTheme theme) {
    if (_conversaSelecionada == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 54,
              color: theme.secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecione uma conversa',
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escolha um contato, loja ou grupo para conversar.',
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    final conversa = _conversaSelecionada!;

    return Column(
      children: [
        // Cabeçalho da Conversa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              if (!_larguraDesktop(context))
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: theme.textColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _conversaSelecionada = null;
                    });
                  },
                ),
              Expanded(
                child: InkWell(
                  onTap: () => _abrirDetalhesContato(theme, conversa),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        _buildAvatar(theme, conversa, raio: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextoRolante(
                                texto: conversa.titulo,
                                style: theme.getTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextoRolante(
                                texto: conversa.subtitulo.isNotEmpty
                                    ? conversa.subtitulo
                                    : 'Online na rede local',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.secondaryTextColor,
                ),
                tooltip: 'Dados do contato',
                onPressed: () => _abrirDetalhesContato(theme, conversa),
              ),
            ],
          ),
        ),

        // Área das Mensagens
        Expanded(
          child: conversa.mensagens.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma mensagem ainda.\nEnvie uma mensagem abaixo para iniciar.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _mensagensScrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: conversa.mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = conversa.mensagens[
                        conversa.mensagens.length - 1 - index];
                    final enviadaPorMim = msg.enviadaPorMim;

                    return Align(
                      alignment: enviadaPorMim
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: enviadaPorMim
                              ? theme.buttonColor.withValues(alpha: 0.18)
                              : theme.cardBackgroundColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(enviadaPorMim ? 12 : 2),
                            bottomRight:
                                Radius.circular(enviadaPorMim ? 2 : 12),
                          ),
                          border: Border.all(
                            color: enviadaPorMim
                                ? theme.buttonColor.withValues(alpha: 0.4)
                                : theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: enviadaPorMim
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            // Se for grupo ou loja com atendente, exibe o autor
                            if (conversa.ehGrupo && !enviadaPorMim)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  msg.remetenteNome,
                                  style: theme.getTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              )
                            else if (msg.nomeAtendente.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${msg.remetenteNome} (${msg.nomeAtendente})',
                                  style: theme.getTextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),

                            // Renderização do conteúdo conforme o tipo
                            if (msg.tipo == 'imagem')
                              _buildCardImagem(theme, msg, enviadaPorMim)
                            else if (msg.tipo == 'arquivo')
                              _buildCardArquivo(theme, msg, enviadaPorMim)
                            else if (msg.tipo == 'comanda')
                              _buildCardComanda(theme, msg, enviadaPorMim)
                            else
                              Text(
                                msg.texto,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),

                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatarHora(msg.dataHora),
                                  style: theme.getTextStyle(
                                    fontSize: 9,
                                    color: theme.secondaryTextColor
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                if (enviadaPorMim) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 13,
                                    color: theme.secondaryTextColor
                                        .withValues(alpha: 0.8),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Barra de Envio
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(
              top: BorderSide(
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: theme.textColor,
                  size: 22,
                ),
                tooltip: 'Anexar imagem, arquivo ou comanda',
                onPressed: () => _abrirMenuAnexo(theme),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _mensagemController,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                    onSubmitted: (_) => _enviarMensagem(),
                    decoration: InputDecoration(
                      hintText: widget.modoLoja
                          ? 'Responder em nome de ${widget.nomeLoja ?? "Loja"}...'
                          : 'Digite uma mensagem...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _enviarMensagem,
                borderRadius: BorderRadius.circular(21),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.buttonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardComanda(
    AppTheme theme,
    MensagemChat msg,
    bool enviadaPorMim,
  ) {
    PedidoLoja? pedido;
    if (msg.dadosPedidoJson.isNotEmpty) {
      try {
        final mapa = jsonDecode(msg.dadosPedidoJson) as Map<String, dynamic>;
        pedido = PedidoLoja.fromJson(mapa);
      } catch (_) {}
    }

    final numero =
        pedido != null ? pedido.numero.toString().padLeft(4, '0') : msg.pedidoId;
    final totalFormatado = pedido != null
        ? 'R\$ ${pedido.valor.toStringAsFixed(2)}'
        : (msg.texto.contains('R\$') ? msg.texto : 'Comanda');
    final statusNome =
        pedido != null ? pedido.status.name.toUpperCase() : 'COMANDA';

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: theme.buttonColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'COMANDA',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.buttonColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.buttonColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  statusNome,
                  style: theme.getTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pedido #$numero',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          if (pedido != null && pedido.clienteNome.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Cliente: ${pedido.clienteNome}',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
          if (pedido != null && pedido.itens.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...pedido.itens.take(3).map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Text(
                      '${it.quantidade}x ',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        it.nomeExibicao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (pedido.itens.length > 3)
              Text(
                '+ ${pedido.itens.length - 3} outros itens...',
                style: theme.getTextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.getTextStyle(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
              Text(
                totalFormatado,
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 14),
              label: const Text(
                'Ver Comanda Completa',
                style: TextStyle(fontSize: 11),
              ),
              onPressed: () => _abrirComandaDoChat(msg, pedido),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardArquivo(
    AppTheme theme,
    MensagemChat msg,
    bool enviadaPorMim,
  ) {
    final ehPdf = msg.nomeAnexo.toLowerCase().endsWith('.pdf');
    final icone = ehPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.insert_drive_file_rounded;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.buttonColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: theme.buttonColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoRolante(
                  texto: msg.nomeAnexo.isNotEmpty
                      ? msg.nomeAnexo
                      : 'Arquivo anexo',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatarTamanho(msg.tamanhoAnexo),
                  style: theme.getTextStyle(
                    fontSize: 10,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: theme.textColor,
            ),
            tooltip: 'Abrir arquivo',
            onPressed: () => _abrirArquivo(msg.caminhoAnexo),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImagem(
    AppTheme theme,
    MensagemChat msg,
    bool enviadaPorMim,
  ) {
    final resolvido = ImagemService.resolverCaminhoExistente(msg.caminhoAnexo);
    final arquivo = resolvido != null ? File(resolvido) : null;

    if ((arquivo == null || !arquivo.existsSync()) &&
        msg.caminhoAnexo.isNotEmpty &&
        ClienteRedeLocal().conectado &&
        !_tentativasDownloadImagens.contains(msg.id)) {
      _tentativasDownloadImagens.add(msg.id);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final baixado =
              await ClienteRedeLocal().baixarImagemRemota(msg.caminhoAnexo);
          if (baixado.isNotEmpty && baixado != msg.caminhoAnexo && mounted) {
            await ChatService.salvarMensagem(
              msg.copyWith(caminhoAnexo: baixado),
              originadaDaRede: true,
            );
            if (mounted) setState(() {});
          }
        } catch (_) {}
      });
    }

    return Column(
      crossAxisAlignment:
          enviadaPorMim ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (arquivo != null && arquivo.existsSync())
          GestureDetector(
            onTap: () => _visualizarFotoAmpliada(theme, arquivo.path),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 200,
                ),
                child: Image.file(
                  arquivo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderErroImagem(theme),
                ),
              ),
            ),
          )
        else
          _buildPlaceholderErroImagem(theme),
        if (msg.texto.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            msg.texto,
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.textColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderErroImagem(AppTheme theme) {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 28,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(height: 4),
            Text(
              'Imagem',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = _larguraDesktop(context);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final titulo = widget.modoLoja
            ? 'Mensagens — ${widget.nomeLoja ?? "Loja"}'
            : 'Mensagens';
        final bool barraUniversalDesabilitadaNoDesktop =
            desktop && _conversaSelecionada != null;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: titulo,
            showBackButton: widget.mostrarBotaoVoltar ||
                barraUniversalDesabilitadaNoDesktop,
            onBackPressed: () {
              if (_conversaSelecionada != null) {
                setState(() {
                  _conversaSelecionada = null;
                });
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          body: SafeArea(
            child: desktop
                ? Row(
                    children: [
                      // Coluna Esquerda: Lista de Conversas
                      SizedBox(
                        width: 320,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: theme.borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: _buildListaConversas(theme),
                        ),
                      ),

                      // Coluna Direita: Conversa Ativa
                      Expanded(
                        child: _buildPainelConversaAtiva(theme),
                      ),
                    ],
                  )
                : (_conversaSelecionada != null
                    ? _buildPainelConversaAtiva(theme)
                    : _buildListaConversas(theme)),
          ),
          bottomNavigationBar: (!widget.modoLoja && !widget.mostrarBotaoVoltar && _conversaSelecionada == null)
              ? const FloatingBottomNavBar(
                  maxWidth: 600,
                  slotSelecionado: 1,
                  subIndiceSelecionado: 1,
                )
              : null,
        );
      },
    );
  }
}

class _InfoContatoUnificado {
  final String identificador;
  final String cpfNormalizado;
  final String titulo;
  final String subtitulo;
  final String foto;
  final bool ehMembro;
  final bool ehCliente;

  const _InfoContatoUnificado({
    required this.identificador,
    required this.cpfNormalizado,
    required this.titulo,
    required this.subtitulo,
    this.foto = '',
    this.ehMembro = false,
    this.ehCliente = false,
  });

  _InfoContatoUnificado copyWith({
    String? foto,
    String? subtitulo,
    bool? ehCliente,
  }) {
    return _InfoContatoUnificado(
      identificador: identificador,
      cpfNormalizado: cpfNormalizado,
      titulo: titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      foto: foto ?? this.foto,
      ehMembro: ehMembro,
      ehCliente: ehCliente ?? this.ehCliente,
    );
  }
}

class _ItemConversaTile extends StatefulWidget {
  final ConversaChat conversa;
  final bool selecionada;
  final AppTheme theme;
  final Widget avatar;
  final String horaFormatada;
  final VoidCallback onTap;

  const _ItemConversaTile({
    required this.conversa,
    required this.selecionada,
    required this.theme,
    required this.avatar,
    required this.horaFormatada,
    required this.onTap,
  });

  @override
  State<_ItemConversaTile> createState() => _ItemConversaTileState();
}

class _ItemConversaTileState extends State<_ItemConversaTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final selecionada = widget.selecionada;
    final conversa = widget.conversa;

    final corFundo = selecionada
        ? theme.buttonColor.withValues(alpha: _hovered ? 0.24 : 0.16)
        : (_hovered
            ? theme.cardBackgroundColor.withValues(alpha: 0.7)
            : Colors.transparent);

    final bordaEsquerda = selecionada
        ? theme.buttonColor
        : (_hovered
            ? theme.borderColor.withValues(alpha: 0.6)
            : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: corFundo,
            border: Border(
              left: BorderSide(
                color: bordaEsquerda,
                width: 3.5,
              ),
            ),
          ),
          child: Row(
            children: [
              widget.avatar,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextoRolante(
                            texto: conversa.titulo,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: selecionada
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.horaFormatada,
                          style: theme.getTextStyle(
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: TextoRolante(
                            texto: conversa.ultimaMensagem.isNotEmpty
                                ? conversa.ultimaMensagem
                                : conversa.subtitulo,
                            style: theme.getTextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                        if (conversa.naoLidasCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.dangerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversa.naoLidasCount}',
                              style: theme.getTextStyle(
                                fontSize: 9,
                                color: theme.buttonTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
