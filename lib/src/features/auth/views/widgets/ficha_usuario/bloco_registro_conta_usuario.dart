import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/selo_verificado_widget.dart';

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
    final verificado = usuario.possuiValidacao;
    final totalValidacoes = usuario.totalValidacoes;
    final primeiro = usuario.validacoesOrdenadas.isNotEmpty
        ? usuario.validacoesOrdenadas.first
        : null;
    final validador = primeiro != null
        ? ((primeiro['nome'] ?? '').isNotEmpty
            ? primeiro['nome']!
            : CpfValidator.format(primeiro['cpf'] ?? ''))
        : (usuario.validadoPorNome.isNotEmpty
            ? usuario.validadoPorNome
            : (usuario.validadoPorCpf.isNotEmpty
                ? CpfValidator.format(usuario.validadoPorCpf)
                : 'Aguardando validação'));

    final dataValidacao = usuario.validadoEmFormatado;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoracao,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (verificado)
                SeloVerificadoWidget(
                  usuario: usuario,
                  theme: theme,
                  tamanho: 20,
                )
              else
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: theme.secondaryTextColor,
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
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: verificado
                    ? () => SeloVerificadoWidget.mostrarHistoricoValidadores(
                          context: context,
                          usuario: usuario,
                          theme: theme,
                        )
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: verificado
                        ? SeloVerificadoWidget.corParaQuantidade(totalValidacoes)
                            .withValues(alpha: 0.14)
                        : theme.borderColor.withValues(alpha: 0.3),
                    border: Border.all(
                      color: verificado
                          ? theme.textColor.withValues(alpha: 0.35)
                          : theme.borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    verificado
                        ? 'Verificado ($totalValidacoes)'
                        : 'Em validação',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: verificado
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _itemRegistro(
            rotulo: 'Conta criada em',
            valor: usuario.criadoEmFormatado,
            icone: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 6),
          _itemRegistro(
            rotulo: '1º Validador',
            valor: validador,
            icone: Icons.how_to_reg_outlined,
          ),
          if (verificado && dataValidacao.isNotEmpty) ...[
            const SizedBox(height: 6),
            _itemRegistro(
              rotulo: 'Data da 1ª Validação',
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
