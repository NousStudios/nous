import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

/// Bloco que apresenta o Registro Soberano da Conta Nous e o Atestado de Verificação
class BlocoRegistroContaUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final BoxDecoration decoracao;

  const BlocoRegistroContaUsuario({
    super.key,
    required this.theme,
    required this.usuario,
    required this.decoracao,
  });

  @override
  Widget build(BuildContext context) {
    final verificado = usuario.verificado || usuario.validadoPorCpf.isNotEmpty;
    final validador = usuario.validadoPorNome.isNotEmpty
        ? usuario.validadoPorNome
        : (usuario.validadoPorCpf.isNotEmpty
            ? CpfValidator.format(usuario.validadoPorCpf)
            : 'Rede Soberana Nous • Gênese');

    final dataValidacao = usuario.validadoEmFormatado.isNotEmpty
        ? usuario.validadoEmFormatado
        : usuario.criadoEmFormatado;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verificado ? Icons.verified : Icons.verified_user_outlined,
                size: 18,
                color: verificado ? const Color(0xFF34B7F1) : theme.secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextoRolante(
                  texto: 'Registro Soberano da Conta',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: verificado
                      ? const Color(0xFF34B7F1).withValues(alpha: 0.15)
                      : theme.borderColor.withValues(alpha: 0.3),
                  border: Border.all(
                    color: verificado
                        ? const Color(0xFF34B7F1).withValues(alpha: 0.5)
                        : theme.borderColor,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (verificado) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF34B7F1),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      verificado ? 'Verificado' : 'Em validação',
                      style: theme.getTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: verificado
                            ? const Color(0xFF34B7F1)
                            : theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _itemRegistro(
            rotulo: 'Membro desde',
            valor: usuario.criadoEmFormatado,
            icone: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 6),
          _itemRegistro(
            rotulo: 'Validado por',
            valor: validador,
            icone: Icons.how_to_reg_outlined,
          ),
          if (dataValidacao.isNotEmpty) ...[
            const SizedBox(height: 6),
            _itemRegistro(
              rotulo: 'Data de Validação',
              valor: dataValidacao,
              icone: Icons.verified_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRegistro({
    required String rotulo,
    required String valor,
    required IconData icone,
  }) {
    return Row(
      children: [
        Icon(icone, size: 14, color: theme.secondaryTextColor),
        const SizedBox(width: 6),
        Text(
          '$rotulo: ',
          style: theme.getTextStyle(
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
        Expanded(
          child: TextoRolante(
            texto: valor,
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
