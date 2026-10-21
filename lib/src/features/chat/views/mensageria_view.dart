import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

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
  });

  @override
  State<MensageriaView> createState() => _MensageriaViewState();
}

class _MensageriaViewState extends State<MensageriaView> {
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController();
  final ScrollController _mensagensScrollController = ScrollController();

  List<ConversaChat> _conversas = [];
  ConversaChat? _conversaSelecionada;
  String _termoBusca = '';
  bool _inicializado = false;

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

    if (widget.modoLoja && widget.lojaId != null) {
      // MODO LOJA
      final loja = pdv.buscarPorId(widget.lojaId!);
      if (loja != null) {
        final Map<String, _InfoContatoUnificado> contatosUnificados = {};
        final cpfLogadoNorm = ChatService.normalizarCpf(
          widget.operadorCpf ?? contaLogada?.cpf ?? '',
        );

        // 1. Membros da equipe da loja (identidade soberana por CPF)
        for (final membro in loja.membros) {
          final cpfMembro = ChatService.normalizarCpf(membro.cpf);
          if (cpfMembro.isEmpty) continue;

          final ehProprioOperador = cpfMembro == cpfLogadoNorm;

          contatosUnificados[cpfMembro] = _InfoContatoUnificado(
            identificador: membro.cpf,
            cpfNormalizado: cpfMembro,
            titulo: ehProprioOperador ? '${membro.nome} (Você)' : membro.nome,
            subtitulo: 'Equipe • ${membro.papel.name.toUpperCase()}',
            foto: '',
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
              final fotoResolvida = existente.foto.isNotEmpty
                  ? existente.foto
                  : cliente.foto;
              contatosUnificados[cpfCliente] = existente.copyWith(
                foto: fotoResolvida,
                subtitulo: '${existente.subtitulo} | Cliente',
                ehCliente: true,
              );
            } else {
              // Cliente novo com CPF
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
                foto: cliente.foto,
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
              ? msgs.last.texto
              : (c.ehMembro
                  ? 'Canal direto da equipe com a loja.'
                  : 'Comandas e mensagens da loja.');

          final dataHoraUltima =
              msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now();

          // Só exibe se já houver mensagens trocadas ou se for a conversa atualmente aberta
          if (msgs.isNotEmpty ||
              (_conversaSelecionada != null &&
                  _conversaSelecionada!.id == convId)) {
            lista.add(
              ConversaChat(
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
              ),
            );
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

        if (msgs.isNotEmpty ||
            (_conversaSelecionada != null &&
                _conversaSelecionada!.id == convId)) {
          lista.add(
            ConversaChat(
              id: convId,
              titulo: loja.nome,
              subtitulo: 'Loja Nous',
              foto: loja.logo,
              identificador: loja.id,
              ehLoja: true,
              ultimaMensagem: msgs.isNotEmpty
                  ? msgs.last.texto
                  : 'Canal de atendimento da loja.',
              dataHoraUltimaMensagem:
                  msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
              naoLidasCount: naoLidas,
              mensagens: msgs,
            ),
          );
        }
      }

      // Conversas com outros membros e clientes conhecidos (desduplicados por CPF)
      final Map<String, ({String nome, String foto})> contatosUnicos = {};
      final cLogadoNorm = ChatService.normalizarCpf(cpfLogado);

      for (final loja in todasLojas) {
        for (final m in loja.membros) {
          final cMembro = ChatService.normalizarCpf(m.cpf);
          if (cMembro.isNotEmpty && cMembro != cLogadoNorm) {
            contatosUnicos.putIfAbsent(cMembro, () => (nome: m.nome, foto: ''));
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
              contatosUnicos[cCli] = (nome: c.nome, foto: c.foto);
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

        if (msgs.isNotEmpty ||
            (_conversaSelecionada != null &&
                _conversaSelecionada!.id == convId)) {
          lista.add(
            ConversaChat(
              id: convId,
              titulo: entry.value.nome,
              subtitulo: 'Contato Nous',
              foto: entry.value.foto,
              identificador: entry.key,
              ehLoja: false,
              ultimaMensagem:
                  msgs.isNotEmpty ? msgs.last.texto : 'Toque para conversar.',
              dataHoraUltimaMensagem:
                  msgs.isNotEmpty ? msgs.last.dataHora : DateTime.now(),
              naoLidasCount: naoLidas,
              mensagens: msgs,
            ),
          );
        }
      }
    }

    // Carregar Grupos
    final grupos = await ChatService.carregarGrupos(
      cpfParticipante: widget.modoLoja ? null : contaLogada?.cpf,
    );
    lista.addAll(grupos);

    // Ordenar conversas pela mais recente
    lista.sort(
      (a, b) => b.dataHoraUltimaMensagem.compareTo(a.dataHoraUltimaMensagem),
    );

    if (!mounted) return;

    setState(() {
      _conversas = lista;
      if (manterSelecionada && _conversaSelecionada != null) {
        final index =
            _conversas.indexWhere((c) => c.id == _conversaSelecionada!.id);
        if (index != -1) {
          _conversaSelecionada = _conversas[index];
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

  Future<void> _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _conversaSelecionada == null) return;

    final agora = DateTime.now();
    final auth = context.read<AuthProvider>();
    final conta = auth.contaAtual;

    final remetenteId = widget.modoLoja
        ? (widget.lojaId ?? 'loja')
        : (widget.usuarioCpf ?? conta?.cpf ?? 'usuario');

    final remetenteNome = widget.modoLoja
        ? (widget.nomeLoja ?? 'Loja')
        : (widget.usuarioNome ?? conta?.nome ?? 'Usuário');

    final atendenteNome = widget.modoLoja
        ? (widget.operadorNome ?? conta?.nome ?? 'Atendente')
        : '';

    final destinatarioId = _conversaSelecionada!.identificador;

    final novaMensagem = MensagemChat(
      id: 'msg_${agora.millisecondsSinceEpoch}',
      conversaId: _conversaSelecionada!.id,
      remetenteId: remetenteId,
      remetenteNome: remetenteNome,
      destinatarioId: destinatarioId,
      texto: texto,
      dataHora: agora,
      enviadaPorMim: true,
      nomeAtendente: atendenteNome,
      cpfAtendente: widget.operadorCpf ?? conta?.cpf ?? '',
      lida: false,
    );

    _mensagemController.clear();
    await ChatService.salvarMensagem(novaMensagem);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mensagensScrollController.hasClients) {
        _mensagensScrollController.animateTo(
          _mensagensScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
      ultimaMensagem: msgs.isNotEmpty ? msgs.last.texto : '',
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

                  // Mídias trocadas
                  Container(
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
                            Icon(Icons.photo_library_outlined, size: 18, color: theme.textColor),
                            const SizedBox(width: 8),
                            Text(
                              'Mídias, Links e Docs',
                              style: theme.getTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma mídia ou documento compartilhado nesta conversa.',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
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

    final caminhoFoto = ImagemService.resolverCaminhoExistente(conversa.foto);
    final temFoto = caminhoFoto != null;

    if (temFoto) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.3),
        backgroundImage: FileImage(File(caminhoFoto)),
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
    final filtradas = _conversas.where((c) {
      if (_termoBusca.isEmpty) return true;
      return c.titulo.toLowerCase().contains(_termoBusca) ||
          c.subtitulo.toLowerCase().contains(_termoBusca) ||
          c.ultimaMensagem.toLowerCase().contains(_termoBusca);
    }).toList();

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
                  child: TextField(
                    controller: _buscaController,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar contatos ou lojas...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
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
                              Text(
                                conversa.subtitulo.isNotEmpty
                                    ? conversa.subtitulo
                                    : 'Online na rede local',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: conversa.mensagens.length,
                  itemBuilder: (context, index) {
                    final msg = conversa.mensagens[index];
                    final enviadaPorMim = msg.enviadaPorMim;

                    return Align(
                      alignment: enviadaPorMim
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.70,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    final desktop = _larguraDesktop(context);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final titulo = widget.modoLoja
            ? 'Mensagens — ${widget.nomeLoja ?? "Loja"}'
            : 'Mensagens Nous';

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: titulo,
            showBackButton: true,
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
                          child: Text(
                            conversa.ultimaMensagem.isNotEmpty
                                ? conversa.ultimaMensagem
                                : conversa.subtitulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                color: Colors.white,
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
