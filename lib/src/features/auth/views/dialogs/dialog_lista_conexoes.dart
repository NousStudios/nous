import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Diálogo estilo Instagram para exibir a lista de Seguidores ou Seguindo
class DialogListaConexoes extends StatefulWidget {
  final String titulo;
  final List<String> cpfs;
  final AppTheme theme;
  final UsuarioNous? usuarioDonoLista;

  const DialogListaConexoes({
    super.key,
    required this.titulo,
    required this.cpfs,
    required this.theme,
    this.usuarioDonoLista,
  });

  static Future<void> exibir({
    required BuildContext context,
    required String titulo,
    required List<String> cpfs,
    required AppTheme theme,
    UsuarioNous? usuarioDonoLista,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DialogListaConexoes(
        titulo: titulo,
        cpfs: cpfs,
        theme: theme,
        usuarioDonoLista: usuarioDonoLista,
      ),
    );
  }

  @override
  State<DialogListaConexoes> createState() => _DialogListaConexoesState();
}

class _DialogListaConexoesState extends State<DialogListaConexoes> {
  final TextEditingController _buscaController = TextEditingController();
  final Map<String, UsuarioNous?> _contasCarregadas = {};
  bool _carregando = true;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarContas() async {
    for (final cpfBruto in widget.cpfs) {
      final cpfNorm = ChatService.normalizarCpf(cpfBruto);
      if (cpfNorm.isEmpty) continue;
      try {
        final conta = await ContasNousService.buscarPorCpf(cpfNorm);
        _contasCarregadas[cpfNorm] = conta;
      } catch (_) {
        _contasCarregadas[cpfNorm] = null;
      }
    }
    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }

  List<String> get _cpfsFiltrados {
    final todos = widget.cpfs
        .map((c) => ChatService.normalizarCpf(c))
        .where((c) => c.isNotEmpty)
        .toList();

    if (_filtro.trim().isEmpty) return todos;

    final query = _filtro.trim().toLowerCase();
    return todos.where((cpf) {
      final conta = _contasCarregadas[cpf];
      if (conta == null) {
        return cpf.contains(query);
      }
      return conta.nome.toLowerCase().contains(query) ||
          conta.apelido.toLowerCase().contains(query) ||
          conta.usernameExibicao.toLowerCase().contains(query) ||
          cpf.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final auth = context.watch<AuthProvider>();
    final contaLogada = auth.contaAtual;
    final meuCpfNorm = ChatService.normalizarCpf(contaLogada?.cpf ?? auth.cpf);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho do modal
              Row(
                children: [
                  Expanded(
                    child: TextoRolante(
                      texto: '${widget.titulo} (${widget.cpfs.length})',
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Campo de busca rápida
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: theme.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        onChanged: (v) => setState(() => _filtro = v),
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar usuário...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_filtro.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _buscaController.clear();
                          setState(() => _filtro = '');
                        },
                        child: Icon(
                          Icons.clear,
                          size: 16,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista de Conexões
              Flexible(
                child: _carregando
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.textColor,
                          ),
                        ),
                      )
                    : _cpfsFiltrados.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 40,
                                    color: theme.secondaryTextColor.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _filtro.isNotEmpty
                                        ? 'Nenhum usuário encontrado'
                                        : 'Nenhum usuário na lista',
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _cpfsFiltrados.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: theme.borderColor.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (ctx, index) {
                              final cpf = _cpfsFiltrados[index];
                              final conta = _contasCarregadas[cpf];
                              final ehEu = cpf == meuCpfNorm;
                              final jaSeguindo = contaLogada?.estaSeguindo(cpf) ?? false;

                              final nome = conta?.nomeExibicao.isNotEmpty == true
                                  ? conta!.nomeExibicao
                                  : 'Usuário Nous';
                              final username = conta?.usernameExibicao.isNotEmpty == true
                                  ? conta!.usernameExibicao
                                  : '@usuario';

                              final fotoResolvida = conta?.fotoExibicao.isNotEmpty == true
                                  ? ImagemService.resolverCaminhoExistente(conta!.fotoExibicao)
                                  : null;
                              final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();

                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PerfilSocialView(
                                        usuarioAlvo: conta ??
                                            UsuarioNous(
                                              cpf: cpf,
                                              nome: nome,
                                              apelido: username.replaceAll('@', ''),
                                              dataNascimento: '',
                                            ),
                                        mostrarBotaoVoltar: true,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                                        backgroundImage: temFoto
                                            ? ImagemService.obterImageProvider(fotoResolvida)
                                            : null,
                                        child: !temFoto
                                            ? Icon(
                                                Icons.person,
                                                size: 22,
                                                color: theme.textColor,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),

                                      // Nome e @username
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: TextoRolante(
                                                    texto: nome,
                                                    style: theme.getTextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.textColor,
                                                    ),
                                                  ),
                                                ),
                                                if (conta?.verificado == true) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.verified,
                                                    size: 14,
                                                    color: Color(0xFF34B7F1),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            TextoRolante(
                                              texto: username,
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                color: theme.secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Botão de Ação (Seguir / Seguindo / Você)
                                      if (ehEu)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: theme.borderColor.withValues(alpha: 0.2),
                                          ),
                                          child: Text(
                                            'Você',
                                            style: theme.getTextStyle(
                                              fontSize: 11,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        )
                                      else if (contaLogada != null)
                                        SizedBox(
                                          height: 30,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              await auth.alternarSeguir(cpf);
                                              if (mounted) setState(() {});
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              side: BorderSide(
                                                color: jaSeguindo
                                                    ? theme.borderColor.withValues(alpha: 0.6)
                                                    : theme.textColor,
                                              ),
                                              backgroundColor: jaSeguindo
                                                  ? Colors.transparent
                                                  : theme.textColor.withValues(alpha: 0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: Text(
                                              jaSeguindo ? 'Seguindo' : 'Seguir',
                                              style: theme.getTextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
