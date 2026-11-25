import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/timeline/views/widgets/avatar_com_story_widget.dart';

class FeedDescobertaFiltrosBar extends StatelessWidget {
  final AppTheme theme;
  final TextEditingController buscaController;
  final ValueChanged<String> onBuscaChanged;
  final List<UsuarioNous> perfisEncontrados;
  final bool modoApenasAmigos;
  final String? tagFiltroAtiva;
  final VoidCallback onLimparTagFiltro;
  final List<Map<String, dynamic>> abas;
  final int abaSelecionada;
  final ValueChanged<int> onSelecionarAba;
  final ValueChanged<int> onRemoverAba;
  final VoidCallback onAdicionarAba;

  const FeedDescobertaFiltrosBar({
    super.key,
    required this.theme,
    required this.buscaController,
    required this.onBuscaChanged,
    required this.perfisEncontrados,
    required this.modoApenasAmigos,
    required this.tagFiltroAtiva,
    required this.onLimparTagFiltro,
    required this.abas,
    required this.abaSelecionada,
    required this.onSelecionarAba,
    required this.onRemoverAba,
    required this.onAdicionarAba,
  });

  static Future<({String titulo, List<String> tags})?> mostrarDialogNovaTimeline(
    BuildContext context,
    AppTheme theme,
  ) async {
    final tituloCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nova Timeline por #Tag',
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 14),
                ThemedTextField(
                  theme: theme,
                  controller: tituloCtrl,
                  label: 'Nome da timeline (ex.: Receitas)',
                ),
                const SizedBox(height: 10),
                ThemedTextField(
                  theme: theme,
                  controller: tagsCtrl,
                  label: 'Tags separadas por vírgula (ex.: receita, bolo)',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Adicionar Timeline'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    ({String titulo, List<String> tags})? resultado;
    if (ok == true) {
      final titulo = tituloCtrl.text.trim();
      final tags = tagsCtrl.text
          .split(',')
          .map((e) => e.trim().toLowerCase().replaceAll('#', ''))
          .where((e) => e.isNotEmpty)
          .toList();
      if (titulo.isNotEmpty && tags.isNotEmpty) {
        resultado = (titulo: titulo, tags: tags);
      }
    }

    tituloCtrl.dispose();
    tagsCtrl.dispose();
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: ThemedTextField(
            theme: theme,
            controller: buscaController,
            label: 'Buscar por #tag, assunto ou @pessoa...',
            onChanged: onBuscaChanged,
          ),
        ),
        if (perfisEncontrados.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: perfisEncontrados.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                final conta = perfisEncontrados[idx];
                return ActionChip(
                  backgroundColor: theme.cardBackgroundColor,
                  side: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.45),
                  ),
                  avatar: AvatarComStoryWidget(
                    theme: theme,
                    cpf: conta.cpf,
                    nome: conta.nomeExibicao,
                    foto: conta.fotoExibicao,
                    radius: 11,
                    usuario: conta,
                  ),
                  label: Text(
                    conta.usernameExibicao.isNotEmpty
                        ? '${conta.nomeExibicao} (${conta.usernameExibicao})'
                        : conta.nomeExibicao,
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.textColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PerfilSocialView(
                          usuarioAlvo: conta,
                          mostrarBotaoVoltar: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        if (!modoApenasAmigos)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (tagFiltroAtiva != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text('#$tagFiltroAtiva'),
                      selected: true,
                      onDeleted: onLimparTagFiltro,
                    ),
                  ),
                for (int i = 0; i < abas.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onLongPress: (abas[i]['ehPadrao'] == true)
                          ? null
                          : () => onRemoverAba(i),
                      child: ChoiceChip(
                        label: Text(
                          abas[i]['titulo'] as String? ?? 'Feed',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color:
                                (tagFiltroAtiva == null && abaSelecionada == i)
                                    ? theme.buttonTextColor
                                    : theme.textColor,
                          ),
                        ),
                        selected:
                            tagFiltroAtiva == null && abaSelecionada == i,
                        selectedColor: theme.buttonColor,
                        backgroundColor: theme.cardBackgroundColor,
                        onSelected: (_) => onSelecionarAba(i),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Adicionar timeline de #tag',
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: theme.textColor,
                  ),
                  onPressed: onAdicionarAba,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
