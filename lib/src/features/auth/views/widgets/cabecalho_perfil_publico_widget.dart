import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';

/// Dado de uma métrica exibida no cabeçalho público (ex.: Posts, Seguidores, Seguindo).
class MetricaPerfilPublico {
  final String valor;
  final String rotulo;
  final VoidCallback? onTap;

  const MetricaPerfilPublico({
    required this.valor,
    required this.rotulo,
    this.onTap,
  });
}

/// Cabeçalho visual unificado para Perfil Público (cidadão) e Perfil Público (loja),
/// mantendo o mesmo padrão de avatar com anel de Story, @handle, nome e 3 métricas.
class CabecalhoPerfilPublicoWidget extends StatelessWidget {
  final AppTheme theme;
  final ImageProvider? providerFoto;
  final bool temFoto;
  final bool carregandoFoto;
  final bool temStoryAtivo;
  final Color corDestaqueAnel;
  final IconData iconeFallback;
  final String tooltipFoto;
  final VoidCallback? onTapFoto;
  final VoidCallback? onLongPressFoto;
  final String handleTexto;
  final String nomeTexto;
  final Widget? seloVerificado;
  final List<MetricaPerfilPublico> metricas;
  final double raioAvatar;

  const CabecalhoPerfilPublicoWidget({
    super.key,
    required this.theme,
    required this.providerFoto,
    required this.temFoto,
    this.carregandoFoto = false,
    required this.temStoryAtivo,
    required this.corDestaqueAnel,
    this.iconeFallback = Icons.person,
    this.tooltipFoto = '',
    this.onTapFoto,
    this.onLongPressFoto,
    required this.handleTexto,
    required this.nomeTexto,
    this.seloVerificado,
    required this.metricas,
    this.raioAvatar = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Tooltip(
            message: tooltipFoto,
            child: Container(
              padding:
                  temStoryAtivo ? const EdgeInsets.all(3.5) : EdgeInsets.zero,
              decoration: temStoryAtivo
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: corDestaqueAnel,
                        width: 2.8,
                      ),
                    )
                  : null,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTapFoto,
                  onLongPress: onLongPressFoto,
                  child: CircleAvatar(
                    radius: raioAvatar,
                    backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                    backgroundImage: providerFoto,
                    child: !temFoto
                        ? (carregandoFoto
                              ? SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: theme.textColor,
                                  ),
                                )
                              : Icon(
                                  iconeFallback,
                                  size: raioAvatar,
                                  color: theme.textColor,
                                ))
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: TextoRolante(
                  texto: handleTexto,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
              if (seloVerificado != null) ...[
                const SizedBox(width: 5),
                seloVerificado!,
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextoRolante(
            texto: nomeTexto,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Row(
              children: metricas.map((m) {
                return Expanded(
                  child: Center(
                    child: InkWell(
                      onTap: m.onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            Text(
                              m.valor,
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              m.rotulo,
                              style: theme.getTextStyle(
                                fontSize: 11.5,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
