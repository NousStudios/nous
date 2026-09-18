import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Container reutilizável no "estilo Galeria": título centralizado, com um
// ícone de "mais opções" (⋯) no canto superior direito, e uma fileira de
// quadrados vazios abaixo (por enquanto só visual, sem nenhum arquivo de
// verdade dentro).
//
// Esse é o mesmo padrão visual usado nos quatro containers "Galeria",
// "Arquivos", "Músicas" e "Vídeos" — só o título muda de um para o outro
// — por isso um único widget genérico serve para os quatro, em vez de
// quatro arquivos quase idênticos.
class GaleriaEstiloContainer extends StatelessWidget {
  final AppTheme theme;
  final String titulo;

  // Quantos quadrados vazios mostrar na fileira. 3 é o valor usado no
  // protótipo original da Galeria, mas deixamos como parâmetro caso
  // algum dos outros três (Arquivos, Músicas, Vídeos) precise de uma
  // quantidade diferente no futuro.
  final int quantidadeItens;

  const GaleriaEstiloContainer({
    super.key,
    required this.theme,
    required this.titulo,
    this.quantidadeItens = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          // Stack sobrepõe widgets um em cima do outro. Aqui usamos para
          // colocar o ícone "⋯" no canto direito, sem empurrar o título
          // para fora do centro — se fosse um Row comum (título +
          // ícone), o título ficaria deslocado para a esquerda em vez de
          // centralizado de verdade na tela.
          Stack(
            alignment: Alignment.center,
            children: [
              // Título do bloco — mesmo estilo usado em ContainerSimbolico
              // e nos outros containers já implementados.
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              // Positioned coloca o ícone fixo no canto direito do Stack,
              // por cima do título (que continua centralizado por trás
              // dele).
              Positioned(
                right: 0,
                child: Icon(
                  Icons.more_horiz,
                  color: theme.secondaryTextColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fileira de quadrados vazios — por enquanto só o "molde"
          // visual de onde os arquivos/fotos/músicas/vídeos vão
          // aparecer, quando existir um provider de verdade guardando
          // esses itens.
          Row(
            children: List.generate(quantidadeItens, (indice) {
              // Não coloca espaço ANTES do primeiro quadrado, só ENTRE
              // eles — é o que o "if (indice > 0)" garante aqui.
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: indice > 0 ? 8 : 0),
                  child: AspectRatio(
                    // 1:1 = quadrado perfeito, do mesmo jeito que os
                    // quadrados do protótipo.
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.borderColor),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}