import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

// Container "simbólico": por enquanto só mostra um título, sem nenhuma
// funcionalidade por dentro. Usado para os blocos que ainda não foram
// implementados de verdade (Dados Bancários, e futuramente Usuários
// Participantes, Delivery, Galeria, etc.) — assim já fica visualmente no
// lugar certo, esperando a lógica de cada um ser construída depois.
//
// O visual (fundo semi-transparente + borda arredondada) segue o mesmo
// padrão do container "Meus Perfis Profissionais" da tela de Perfis, para
// manter a identidade visual do app.
class ContainerSimbolico extends StatelessWidget {
  final AppTheme theme;
  final String titulo;

  const ContainerSimbolico({
    super.key,
    required this.theme,
    required this.titulo,
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
      child: Center(
        // textColor porque é um cabeçalho de bloco, seguindo a mesma
        // regra usada em "Meus Perfis Profissionais".
        child: Text(
          titulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
}