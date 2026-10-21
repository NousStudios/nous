import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/editar_perfil_dialog.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class PerfilSocialView extends StatefulWidget {
  final UsuarioNous? usuarioAlvo;
  final bool mostrarBotaoVoltar;

  const PerfilSocialView({
    super.key,
    this.usuarioAlvo,
    this.mostrarBotaoVoltar = false,
  });

  @override
  State<PerfilSocialView> createState() => _PerfilSocialViewState();
}

class _PerfilSocialViewState extends State<PerfilSocialView> {
  static const double _larguraMaximaConteudo = 600;
  int _abaConteudoSelecionada = 0; // 0: Grade, 1: Vídeo, 2: Documento, 3: Música

  Future<void> _abrirEdicaoPerfil(
    BuildContext context,
    AppTheme theme,
    UsuarioNous conta,
  ) async {
    final atualizou = await showDialog<bool>(
      context: context,
      builder: (_) => EditarPerfilDialog(usuario: conta),
    );
    if (atualizou == true && mounted) {
      setState(() {});
    }
  }

  void _compartilharPerfil(BuildContext context, AppTheme theme, UsuarioNous conta) {
    final link = 'nous://usuario/${conta.cpf.replaceAll(RegExp(r'\D'), '')}';
    Clipboard.setData(ClipboardData(text: link));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.share_outlined, color: theme.textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Compartilhar Perfil',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identificador copiado para a área de transferência!',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: SelectableText(
                link,
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirMensagensUsuario(BuildContext context, UsuarioNous conta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MensageriaView(
          modoLoja: false,
          usuarioCpf: conta.cpf,
          usuarioNome: conta.nome,
          usuarioFoto: conta.foto,
          usuarioApelido: conta.apelido,
        ),
      ),
    );
  }

  Widget _buildBotaoPerfil({
    required AppTheme theme,
    required String rotulo,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricaItem(AppTheme theme, String valor, String rotulo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: theme.getTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contaPropria = auth.contaAtual;
    final conta = widget.usuarioAlvo ??
        contaPropria ??
        const UsuarioNous(
          cpf: '',
          nome: 'Usuário Nous',
          apelido: 'usuario',
          dataNascimento: '',
        );

    final ehProprioUsuario = widget.usuarioAlvo == null ||
        (contaPropria != null &&
            contaPropria.cpf.replaceAll(RegExp(r'\D'), '') ==
                conta.cpf.replaceAll(RegExp(r'\D'), ''));

    final fotoResolvida = ImagemService.resolverCaminhoExistente(conta.foto);
    final temFoto = fotoResolvida != null;

    final apelidoExibicao = conta.apelido.isNotEmpty
        ? '@${conta.apelido}'
        : '@nous';

    final nomeExibicao = conta.nome.isNotEmpty
        ? conta.nome
        : 'Usuário Nous';

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: CustomAppBar(
            title: '',
            showBackButton: widget.mostrarBotaoVoltar,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _larguraMaximaConteudo),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho Social Centralizado
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage: temFoto
                              ? FileImage(File(fotoResolvida))
                              : null,
                          child: !temFoto
                              ? Icon(
                                  Icons.person,
                                  size: 52,
                                  color: theme.textColor,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          apelidoExibicao,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          nomeExibicao,
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMetricaItem(theme, '0', 'Posts'),
                          const SizedBox(width: 28),
                          _buildMetricaItem(theme, '0', 'Seguidores'),
                          const SizedBox(width: 28),
                          _buildMetricaItem(theme, '0', 'Seguindo'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Biografia Soberana
                      Center(
                        child: Text(
                          'Biografia',
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          conta.biografia.isNotEmpty
                              ? conta.biografia
                              : 'Membro soberano da rede local Nous • SuperApp de Autogestão',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botões de ação
                      Row(
                        children: [
                          if (ehProprioUsuario) ...[
                            _buildBotaoPerfil(
                              theme: theme,
                              rotulo: 'Editar Perfil',
                              onTap: () => _abrirEdicaoPerfil(context, theme, conta),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildBotaoPerfil(
                            theme: theme,
                            rotulo: 'Compartilhar',
                            onTap: () =>
                                _compartilharPerfil(context, theme, conta),
                          ),
                          const SizedBox(width: 8),
                          _buildBotaoPerfil(
                            theme: theme,
                            rotulo: 'Mensagens',
                            onTap: () => _abrirMensagensUsuario(context, conta),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Destaques / Stories (Carrossel Horizontal de Círculos)
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 8,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.cardBackgroundColor,
                                border: Border.all(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: theme.secondaryTextColor.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Divisor
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.borderColor.withValues(alpha: 0.4),
                      ),

                      // Abas de Conteúdo (Grade | Vídeo | Documento | Música)
                      Row(
                        children: [
                          _buildAbaIcone(theme, 0, Icons.grid_on_sharp),
                          _buildAbaIcone(theme, 1, Icons.play_circle_outline_rounded),
                          _buildAbaIcone(theme, 2, Icons.description_outlined),
                          _buildAbaIcone(theme, 3, Icons.music_note_outlined),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Grade de Conteúdo Social (3 colunas estilo protótipo)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.cardBackgroundColor.withValues(alpha: 0.4),
                              border: Border.all(
                                color: theme.borderColor.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 22,
                                color: theme.secondaryTextColor.withValues(alpha: 0.3),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 80), // Espaço para a barra flutuante
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: widget.mostrarBotaoVoltar
              ? null
              : const FloatingBottomNavBar(
                  maxWidth: _larguraMaximaConteudo,
                  indiceSelecionado: 1,
                ),
        );
      },
    );
  }

  Widget _buildAbaIcone(AppTheme theme, int index, IconData icone) {
    final selecionada = _abaConteudoSelecionada == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _abaConteudoSelecionada = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selecionada ? theme.textColor : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Icon(
            icone,
            size: 20,
            color: selecionada ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
