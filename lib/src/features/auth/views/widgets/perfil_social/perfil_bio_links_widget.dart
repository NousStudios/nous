import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Seção de biografia e links externos do perfil social, incluindo o diálogo
/// com a lista completa de links quando há mais de um cadastrado.
class PerfilBioLinksWidget extends StatelessWidget {
  final AppTheme theme;
  final String biografia;
  final List<String> links;
  final Color textoSobreFundo;
  final Color textoSecSobreFundo;
  final Color corBordaPerfil;
  final Color? corDestaqueCustom;

  const PerfilBioLinksWidget({
    super.key,
    required this.theme,
    required this.biografia,
    required this.links,
    required this.textoSobreFundo,
    required this.textoSecSobreFundo,
    required this.corBordaPerfil,
    this.corDestaqueCustom,
  });

  Future<void> _abrirOuCopiarLink(BuildContext context, String link) async {
    final linkLimpo = link.trim();
    final uri = Uri.tryParse(
      linkLimpo.startsWith('http://') || linkLimpo.startsWith('https://')
          ? linkLimpo
          : 'https://$linkLimpo',
    );
    if (uri != null) {
      try {
        final abriu = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (abriu) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          'Link copiado: $link',
          style: theme.getTextStyle(color: theme.textColor),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _abrirJanelaTodosLinks(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.70,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        'Links',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.secondaryTextColor),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.borderColor.withValues(alpha: 0.4),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: links.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final link = links[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _abrirOuCopiarLink(context, link),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: corBordaPerfil.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 16,
                              color: theme.textColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                link,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar link',
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: theme.secondaryTextColor,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: link));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: theme.cardBackgroundColor,
                                    content: Text(
                                      'Link copiado: $link',
                                      style: theme.getTextStyle(
                                        color: theme.textColor,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Biografia',
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textoSobreFundo,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            biografia.isNotEmpty
                ? biografia
                : 'Membro soberano da rede local Nous • SuperApp de Autogestão',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: textoSecSobreFundo,
            ),
          ),
        ),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 10),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (links.length == 1) {
                  _abrirOuCopiarLink(context, links.first);
                } else {
                  _abrirJanelaTodosLinks(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: corBordaPerfil.withValues(alpha: 0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: corDestaqueCustom ?? textoSobreFundo,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        links.length == 1
                            ? links.first
                            : '${links.first}  •  +${links.length - 1} link(s)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textoSobreFundo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
