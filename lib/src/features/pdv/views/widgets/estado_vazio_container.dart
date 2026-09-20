import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Barra horizontal usada quando uma seção da aba Loja ainda não tem
// nada criado (ex: "Nenhuma categoria criada ainda").
//
// Ela usa o MESMO molde visual dos containers que aparecem depois que
// o usuário cria o elemento (ex: CategoriaLojaContainer): borda
// arredondada com a borderColor em 60% e largura total. Assim, o
// espaço "reservado" já mostra onde a barra vai aparecer, e a tela
// não dá um "salto" visual quando o primeiro elemento é criado.
//
// A altura mínima (50) acompanha a altura de uma barra de categoria
// fechada (quadrado de 32 + padding vertical de 8 em cima e embaixo
// + borda). O texto fica centralizado e usa FittedBox, então nunca
// quebra linha nem causa overflow no celular: se faltar espaço, ele
// só encolhe.
class EstadoVazioContainer extends StatelessWidget {
  final AppTheme theme;
  final String mensagem;

  const EstadoVazioContainer({
    super.key,
    required this.theme,
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          mensagem,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}