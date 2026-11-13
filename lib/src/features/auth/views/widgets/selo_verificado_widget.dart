import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

/// Selo de Verificado gradual e animado conforme a quantidade de validações
/// recebidas pela identidade do usuário (1 a 1000+).
class SeloVerificadoWidget extends StatefulWidget {
  final UsuarioNous usuario;
  final AppTheme theme;
  final double tamanho;

  const SeloVerificadoWidget({
    super.key,
    required this.usuario,
    required this.theme,
    this.tamanho = 18,
  });

  static Color corParaQuantidade(int total) {
    if (total >= 1000) return const Color(0xFFFFD700);
    if (total >= 900) return const Color(0xFFFFC400);
    if (total >= 800) return const Color(0xFF00BFA5);
    if (total >= 700) return const Color(0xFF9C27B0);
    if (total >= 600) return const Color(0xFFE91E63);
    if (total >= 500) return const Color(0xFFFF9800);
    if (total >= 400) return const Color(0xFFFFEB3B);
    if (total >= 300) return const Color(0xFF00BCD4);
    if (total >= 200) return const Color(0xFF4CAF50);
    if (total >= 100) return const Color(0xFF2196F3);
    return const Color(0xFFFFFFFF);
  }

  static String rotuloNivel(int total) {
    if (total >= 1000) return 'Nível Máximo • Dourado Prisma (1000+)';
    if (total >= 900) return 'Nível 10 • Dourado (900–999)';
    if (total >= 800) return 'Nível 9 • Esmeralda (800–899)';
    if (total >= 700) return 'Nível 8 • Roxo (700–799)';
    if (total >= 600) return 'Nível 7 • Rosa (600–699)';
    if (total >= 500) return 'Nível 6 • Laranja (500–599)';
    if (total >= 400) return 'Nível 5 • Amarelo (400–499)';
    if (total >= 300) return 'Nível 4 • Ciano (300–399)';
    if (total >= 200) return 'Nível 3 • Verde (200–299)';
    if (total >= 100) return 'Nível 2 • Azul (100–199)';
    return 'Nível 1 • Branco (1–99)';
  }

  static Future<void> mostrarHistoricoValidadores({
    required BuildContext context,
    required UsuarioNous usuario,
    required AppTheme theme,
  }) {
    final validacoes = usuario.validacoesOrdenadas;
    final total = validacoes.length;
    final cor = corParaQuantidade(total);

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: cor == const Color(0xFFFFFFFF)
                      ? theme.borderColor
                      : cor,
                  width: 1.8,
                ),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 28,
                color: cor == const Color(0xFFFFFFFF) &&
                        theme.backgroundColor.computeLuminance() > 0.5
                    ? theme.textColor
                    : cor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Validações de Identidade',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total ${total == 1 ? 'validação registrada' : 'validações registradas'}',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotuloNivel(total),
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
          ),
          child: validacoes.isEmpty
              ? Center(
                  child: Text(
                    'Identidade ainda sem histórico detalhado de validadores.',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: validacoes.length,
                  separatorBuilder: (_, _) => Divider(
                    color: theme.borderColor.withValues(alpha: 0.4),
                    height: 12,
                  ),
                  itemBuilder: (_, index) {
                    final v = validacoes[index];
                    final nome = (v['nome'] ?? '').isNotEmpty
                        ? v['nome']!
                        : 'Usuário Nous';
                    final cpf = v['cpf'] ?? '';
                    final cpfMask = cpf.length >= 3
                        ? '${cpf.substring(0, 3)}.***.***-**'
                        : '***';
                    final dt = DateTime.tryParse(v['dataHora'] ?? '');
                    final dataFmt = dt != null
                        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                        : '';
                    final ehPrimeiro = index == 0;

                    return Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ehPrimeiro
                                ? theme.buttonColor
                                : theme.backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            '${index + 1}º',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ehPrimeiro
                                  ? theme.buttonTextColor
                                  : theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextoRolante(
                                      texto: nome,
                                      style: theme.getTextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                  ),
                                  if (ehPrimeiro)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.backgroundColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: theme.borderColor,
                                        ),
                                      ),
                                      child: Text(
                                        '1º Validador',
                                        style: theme.getTextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                dataFmt.isNotEmpty
                                    ? 'CPF $cpfMask • $dataFmt'
                                    : 'CPF $cpfMask',
                                style: theme.getTextStyle(
                                  fontSize: 11,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<SeloVerificadoWidget> createState() => _SeloVerificadoWidgetState();
}

class _SeloVerificadoWidgetState extends State<SeloVerificadoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.usuario.possuiValidacao) return const SizedBox.shrink();

    final total = widget.usuario.totalValidacoes;
    final corBase = SeloVerificadoWidget.corParaQuantidade(total);
    final fundoClaro = widget.theme.cardBackgroundColor.computeLuminance() > 0.6;
    final ehBranco = corBase == const Color(0xFFFFFFFF);

    return Tooltip(
      message:
          'Identidade verificada ($total ${total == 1 ? 'validação' : 'validações'}). Toque para ver quem validou.',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => SeloVerificadoWidget.mostrarHistoricoValidadores(
          context: context,
          usuario: widget.usuario,
          theme: widget.theme,
        ),
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, _) {
            final t = _animCtrl.value;
            final corAnimada = total >= 1000
                ? Color.lerp(
                      const Color(0xFFFFD700),
                      const Color(0xFF00E5FF),
                      t,
                    ) ??
                    corBase
                : Color.lerp(
                      corBase,
                      corBase.withValues(alpha: 0.72),
                      t,
                    ) ??
                    corBase;

            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (ehBranco && fundoClaro
                            ? widget.theme.textColor
                            : corBase)
                        .withValues(alpha: 0.25 + (t * 0.2)),
                    blurRadius: 6 + (t * 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ehBranco && fundoClaro)
                    Icon(
                      Icons.verified_rounded,
                      size: widget.tamanho + 2,
                      color: widget.theme.textColor,
                    ),
                  Icon(
                    Icons.verified_rounded,
                    size: widget.tamanho,
                    color: ehBranco && fundoClaro
                        ? widget.theme.cardBackgroundColor
                        : corAnimada,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
