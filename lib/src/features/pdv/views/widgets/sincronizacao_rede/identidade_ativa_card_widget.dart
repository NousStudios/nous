import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

class IdentidadeAtivaCardWidget extends StatelessWidget {
  final AppTheme theme;

  const IdentidadeAtivaCardWidget({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conta = auth.contaAtual;
    final cpf = auth.cpf;
    final revelado = auth.dadoEstaReveladoParaDono('cpf');
    final cpfExibicao = CpfValidator.formatProtegido(cpf, revelado: revelado);
    final nome = conta?.nome ?? 'Usuário Nous';
    final apelidoBruto = conta?.apelido.trim() ?? '';
    final temApelido = apelidoBruto.isNotEmpty;
    final apelidoLimpo =
        apelidoBruto.replaceAll(RegExp(r'^[(@\s]+|[)\s]+$'), '');
    final apelidoFormatado =
        apelidoLimpo.isNotEmpty ? '(@$apelidoLimpo)' : '';
    final temFoto = ImagemService.existe(conta?.foto);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: temFoto
                ? ImagemService.construirImagem(
                    conta?.foto,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    fallback: Container(
                      width: 42,
                      height: 42,
                      color: theme.textColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded,
                          size: 24, color: theme.secondaryTextColor),
                    ),
                  )
                : Container(
                    width: 42,
                    height: 42,
                    color: theme.textColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person_rounded,
                        size: 24, color: theme.secondaryTextColor),
                  ),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    if (temApelido) ...[
                      const SizedBox(width: 6),
                      Text(
                        apelidoFormatado,
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'CPF: $cpfExibicao',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => auth.alternarRevelacaoParaDono('cpf'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          revelado
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Minha Identidade',
            icon: Icon(Icons.badge_outlined, size: 20, color: theme.textColor),
            onPressed: () {
              final usuario = conta ??
                  UsuarioNous(
                    cpf: cpf,
                    nome: nome,
                    apelido: apelidoBruto,
                    dataNascimento: '',
                  );
              FichaUsuarioDialog.mostrar(
                context,
                theme: theme,
                usuario: usuario,
                somenteLeitura: false,
              );
            },
          ),
        ],
      ),
    );
  }
}
