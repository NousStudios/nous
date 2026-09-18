import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

// Agrupa os controllers de texto usados no formulário de Usuários
// Participantes, no mesmo espírito do ControllersDadosLoja que já existe
// no projeto. A tela de Dados do Perfil cria um conjunto desses, passa
// para este widget, e é responsável por chamar dispose() quando a tela
// for fechada.
class ControllersUsuariosParticipantes {
  final dono = TextEditingController();
  final socio = TextEditingController();
  final admin = TextEditingController();
  final funcionario = TextEditingController();

  void dispose() {
    dono.dispose();
    socio.dispose();
    admin.dispose();
    funcionario.dispose();
  }
}

// Container completo de "Usuários Participantes": título centralizado no
// topo, seguido do toggle "Permitir que a página seja administrada por
// terceiros", dos campos de cada função, e do botão "Convidar usuário
// para loja" — tudo dentro da mesma moldura (fundo semi-transparente +
// borda) usada nos outros blocos da tela de Dados do Perfil.
//
// No protótipo original, o toggle vinha ACIMA do título — aqui invertemos
// a ordem (título primeiro, centralizado, depois o toggle) para seguir o
// mesmo padrão visual dos outros containers da tela, que sempre começam
// com o título.
//
// É um StatefulWidget porque precisa lembrar se o toggle está ligado ou
// desligado — e só um StatelessWidget não consegue guardar isso.
class UsuariosParticipantesContainer extends StatefulWidget {
  final AppTheme theme;
  final ControllersUsuariosParticipantes controllers;

  const UsuariosParticipantesContainer({
    super.key,
    required this.theme,
    required this.controllers,
  });

  @override
  State<UsuariosParticipantesContainer> createState() =>
      _UsuariosParticipantesContainerState();
}

class _UsuariosParticipantesContainerState
    extends State<UsuariosParticipantesContainer> {
  // Começa desligado por padrão: por segurança, uma página só deveria
  // passar a ser administrada por terceiros se o dono ligar isso de
  // propósito.
  bool _administradaPorTerceiros = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final controllers = widget.controllers;

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
          // Título do bloco — mesmo estilo usado em ContainerSimbolico e
          // em DadosBancariosContainer, para todos os blocos da tela
          // ficarem visualmente idênticos.
          Text(
            'Usuários Participantes',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Row com o texto do toggle e o próprio Switch. Expanded no
          // texto garante que, se o texto for longo demais para a
          // largura da tela, ele quebra linha em vez de empurrar o
          // Switch para fora da tela.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Permitir que a página seja administrada por terceiros',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: _administradaPorTerceiros,
                // activeColor foi renomeado para activeThumbColor pelo
                // Flutter (o antigo nome era ambíguo — dava a entender
                // que pintava o Switch inteiro, quando na verdade só
                // pinta a "bolinha"/thumb). Mesmo efeito visual de antes.
                activeThumbColor: theme.buttonColor,
                onChanged: (novoValor) {
                  setState(() => _administradaPorTerceiros = novoValor);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          ThemedTextField(
            theme: theme,
            controller: controllers.dono,
            label: 'Dono',
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: controllers.socio,
            label: 'Sócio',
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: controllers.admin,
            label: 'Admin',
          ),
          const SizedBox(height: 12),

          ThemedTextField(
            theme: theme,
            controller: controllers.funcionario,
            label: 'Funcionário',
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // todo: conectar a um provider de usuários participantes
                // quando ele existir. Por enquanto o botão só existe
                // visualmente, como os outros containers ainda não
                // implementados de verdade.
              },
              child: Text(
                'Convidar usuário para loja',
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}