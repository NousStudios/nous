import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
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
    final cpfFormatado = CpfValidator.format(cpf);
    final nome = conta?.nome ?? 'Usuário Nous';
    final apelido = conta?.apelido;
    final temApelido = apelido != null && apelido.trim().isNotEmpty;
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
                      child: Text(
                        nome,
                        style: theme.getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (temApelido) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(@$apelido)',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'CPF: $cpfFormatado',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
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
                    apelido: apelido ?? '',
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
