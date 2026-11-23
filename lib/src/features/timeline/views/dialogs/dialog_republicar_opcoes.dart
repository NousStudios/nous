import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';

/// Diálogo centralizado de Republicação com opção de Republicar direto
/// ou Citar com comentário (Quote).
class DialogRepublicarOpcoes extends StatefulWidget {
  final AppTheme theme;
  final PublicacaoSocial publicacao;
  final UsuarioNous usuario;

  const DialogRepublicarOpcoes({
    super.key,
    required this.theme,
    required this.publicacao,
    required this.usuario,
  });

  static Future<bool> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required PublicacaoSocial publicacao,
    required UsuarioNous usuario,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => DialogRepublicarOpcoes(
        theme: theme,
        publicacao: publicacao,
        usuario: usuario,
      ),
    );
    return res ?? false;
  }

  @override
  State<DialogRepublicarOpcoes> createState() => _DialogRepublicarOpcoesState();
}

class _DialogRepublicarOpcoesState extends State<DialogRepublicarOpcoes> {
  bool _modoCitacao = false;
  bool _enviando = false;
  final TextEditingController _citacaoCtrl = TextEditingController();

  @override
  void dispose() {
    _citacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _executar({String? citacao}) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    await TimelineService.republicar(
      original: widget.publicacao,
      meuCpf: widget.usuario.cpf,
      meuNome: widget.usuario.nomeExibicao,
      minhaFoto: widget.usuario.fotoExibicao,
      comentarioCitacao: citacao,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (citacao ?? '').trim().isNotEmpty
              ? 'Citação publicada no seu perfil!'
              : 'Publicação republicada no seu perfil!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pub = widget.publicacao;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      _modoCitacao ? 'Citar publicação' : 'Republicar',
                      style: theme.getTextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
              Divider(color: theme.borderColor.withValues(alpha: 0.35)),
              if (!_modoCitacao) ...[
                ListTile(
                  leading: Icon(Icons.repeat_rounded, color: theme.buttonColor),
                  title: Text(
                    'Republicar direto',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Compartilhar no seu perfil mantendo o formato original',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: _enviando ? null : () => _executar(),
                ),
                Divider(color: theme.borderColor.withValues(alpha: 0.2)),
                ListTile(
                  leading: Icon(
                    Icons.format_quote_rounded,
                    color: theme.buttonColor,
                  ),
                  title: Text(
                    'Citar com comentário',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Escreva sua opinião acima da publicação original',
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  onTap: () => setState(() => _modoCitacao = true),
                ),
              ] else ...[
                const SizedBox(height: 6),
                ThemedTextField(
                  theme: theme,
                  controller: _citacaoCtrl,
                  linhas: 3,
                  label: 'Escreva seu comentário sobre esta publicação...',
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pub.autorNome.isNotEmpty
                            ? pub.autorNome
                            : 'Publicação original',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      if (pub.texto.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          pub.texto,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _enviando
                      ? null
                      : () {
                          final txt = _citacaoCtrl.text.trim();
                          if (txt.isEmpty) return;
                          _executar(citacao: txt);
                        },
                  child: Text(
                    _enviando ? 'Publicando...' : 'Publicar citação',
                    style: theme.getTextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
