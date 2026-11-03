import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

/// Linha de exibição de campo da ficha de usuário com controle de privacidade e censura seletiva.
class LinhaInfoUsuario extends StatelessWidget {
  final AppTheme theme;
  final String rotulo;
  final String valor;
  final bool destaque;
  final String? chavePrivacidade;
  final bool ehProprioUsuario;
  final String? cpfVisualizador;
  final UsuarioNous usuario;
  final void Function(String rotulo, String chave) onSolicitarAcesso;

  const LinhaInfoUsuario({
    super.key,
    required this.theme,
    required this.rotulo,
    required this.valor,
    this.destaque = false,
    this.chavePrivacidade,
    this.ehProprioUsuario = true,
    this.cpfVisualizador,
    required this.usuario,
    required this.onSolicitarAcesso,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final temChave = chavePrivacidade != null;
    final estaPrivado = temChave && usuario.dadoEstaPrivado(chavePrivacidade!);

    bool censurado = false;
    bool olhoAberto = false;
    VoidCallback? aoClicarOlho;

    if (estaPrivado) {
      if (ehProprioUsuario) {
        final revelado = auth.dadoEstaReveladoParaDono(chavePrivacidade!);
        censurado = !revelado;
        olhoAberto = revelado;
        aoClicarOlho = () => auth.alternarRevelacaoParaDono(chavePrivacidade!);
      } else {
        final autorizado = usuario.dadoAutorizadoPara(
          chavePrivacidade!,
          cpfVisualizador ?? '',
        );
        if (!autorizado) {
          censurado = true;
          olhoAberto = false;
          aoClicarOlho = () => onSolicitarAcesso(rotulo, chavePrivacidade!);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              censurado ? '••••••••' : (valor.isEmpty ? '—' : valor),
              textAlign: TextAlign.right,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            height: 20,
            child: (estaPrivado && aoClicarOlho != null)
                ? InkWell(
                    onTap: aoClicarOlho,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Icon(
                        olhoAberto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 15,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
