import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/views/dialogs/dialog_colaboradores_publicacao.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

/// Cabeçalho da publicação mostrando o avatar do autor + até 2 mini-avatares
/// dos colaboradores e os nomes de todos ao lado (com toque para abrir
/// a janela de Colaboradores ou o perfil do autor).
class CabecalhoAutorColaboradoresWidget extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final List<UsuarioNous> coautoresResolvidos;
  final Widget? trailing;

  const CabecalhoAutorColaboradoresWidget({
    super.key,
    required this.theme,
    required this.publicacao,
    this.coautoresResolvidos = const [],
    this.trailing,
  });

  @override
  State<CabecalhoAutorColaboradoresWidget> createState() =>
      _CabecalhoAutorColaboradoresWidgetState();
}

class _CabecalhoAutorColaboradoresWidgetState
    extends State<CabecalhoAutorColaboradoresWidget> {
  static final Map<String, UsuarioNous> _cacheContas = {};
  List<UsuarioNous> _coautores = const [];

  @override
  void initState() {
    super.initState();
    _sincronizarCoautores();
  }

  @override
  void didUpdateWidget(covariant CabecalhoAutorColaboradoresWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.publicacao.id != widget.publicacao.id ||
        oldWidget.coautoresResolvidos != widget.coautoresResolvidos ||
        oldWidget.publicacao.coautoresCpfs.length !=
            widget.publicacao.coautoresCpfs.length) {
      _sincronizarCoautores();
    }
  }

  Future<void> _sincronizarCoautores() async {
    if (widget.coautoresResolvidos.isNotEmpty) {
      _coautores = widget.coautoresResolvidos;
      return;
    }
    if (widget.publicacao.coautoresCpfs.isEmpty) {
      _coautores = const [];
      return;
    }

    final faltantes = <String>[];
    final resolvidos = <UsuarioNous>[];
    for (final cpf in widget.publicacao.coautoresCpfs) {
      final limpo = cpf.replaceAll(RegExp(r'\D'), '');
      if (limpo.isEmpty) continue;
      final cached = _cacheContas[limpo];
      if (cached != null) {
        resolvidos.add(cached);
      } else {
        faltantes.add(limpo);
      }
    }

    if (faltantes.isEmpty) {
      if (mounted) setState(() => _coautores = resolvidos);
      return;
    }

    final todas = await ContasNousService.carregarTodas();
    for (final u in todas) {
      final c = u.cpf.replaceAll(RegExp(r'\D'), '');
      if (c.isNotEmpty) _cacheContas[c] = u;
    }

    final listaFinal = <UsuarioNous>[];
    for (final cpf in widget.publicacao.coautoresCpfs) {
      final limpo = cpf.replaceAll(RegExp(r'\D'), '');
      if (limpo.isEmpty) continue;
      listaFinal.add(
        _cacheContas[limpo] ??
            UsuarioNous(cpf: limpo, nome: 'Colaborador', dataNascimento: ''),
      );
    }

    if (mounted) {
      setState(() => _coautores = listaFinal);
    }
  }

  String _formatarNomesParticipantes(String autorNome) {
    final nomeBase =
        autorNome.trim().isNotEmpty ? autorNome.trim() : 'Cidadão Nous';
    if (widget.publicacao.coautoresCpfs.isEmpty) return nomeBase;

    final nomesColabs = _coautores
        .map((u) => u.nomeExibicao.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (nomesColabs.isEmpty) {
      return '$nomeBase e ${widget.publicacao.coautoresCpfs.length} colaborador(es)';
    }

    final exibidos = nomesColabs.take(2).toList();
    final extras = widget.publicacao.coautoresCpfs.length - exibidos.length;
    if (extras > 0) {
      return '$nomeBase, ${exibidos.join(', ')} e +$extras';
    }
    if (exibidos.length == 1) {
      return '$nomeBase e ${exibidos.first}';
    }
    return '$nomeBase, ${exibidos[0]} e ${exibidos[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final publicacao = widget.publicacao;
    final auth = context.read<AuthProvider?>();
    final contaAutor = auth?.buscarContaPorCpf(publicacao.autorCpf);
    final fotoAutor = (contaAutor?.fotoExibicao.isNotEmpty ?? false)
        ? contaAutor!.fotoExibicao
        : publicacao.autorFoto;
    final temColabs = publicacao.coautoresCpfs.isNotEmpty;
    final colabsExibidos = _coautores.take(2).toList();
    final extrasCount = publicacao.coautoresCpfs.length - colabsExibidos.length;
    final tituloParticipantes =
        _formatarNomesParticipantes(publicacao.autorNome);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (temColabs) {
          await DialogColaboradoresPublicacao.mostrar(
            context,
            theme: theme,
            publicacao: publicacao,
          );
        } else {
          final alvo = await ContasNousService.buscarPorCpf(publicacao.autorCpf);
          if (alvo != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerfilSocialView(
                  usuarioAlvo: alvo,
                  mostrarBotaoVoltar: true,
                ),
              ),
            );
          }
        }
      },
      child: Row(
        children: [
          SizedBox(
            width: 38.0 +
                (colabsExibidos.length * 18.0) +
                (extrasCount > 0 ? 20.0 : 0.0),
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                AvatarComStoryWidget(
                  theme: theme,
                  cpf: publicacao.autorCpf,
                  nome: publicacao.autorNome,
                  foto: fotoAutor,
                  radius: 18,
                  usuario: contaAutor,
                ),
                for (int i = 0; i < colabsExibidos.length; i++)
                  Positioned(
                    left: 22.0 + (i * 16.0),
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.backgroundColor,
                      ),
                      child: Builder(
                        builder: (_) {
                          final provColab = ImagemService.obterImageProvider(
                            colabsExibidos[i].fotoExibicao,
                          );
                          return CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                theme.borderColor.withValues(alpha: 0.4),
                            backgroundImage: provColab,
                            child: provColab == null
                                ? Icon(
                                    Icons.person,
                                    size: 12,
                                    color: theme.textColor,
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                if (extrasCount > 0)
                  Positioned(
                    left: 22.0 + (colabsExibidos.length * 16.0),
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.buttonColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.backgroundColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '+$extrasCount',
                        style: theme.getTextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloParticipantes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                if (temColabs)
                  Text(
                    'Toque para ver colaboradores',
                    style: theme.getTextStyle(
                      fontSize: 10.5,
                      color: theme.buttonColor,
                    ),
                  ),
              ],
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );
  }
}
