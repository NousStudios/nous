import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

// Agrupa os controllers de texto usados no formulário de Delivery, no
// mesmo espírito do ControllersDadosLoja que já existe no projeto. A tela
// de Dados do Perfil cria um conjunto desses, passa para este widget, e é
// responsável por chamar dispose() quando a tela for fechada.
class ControllersDelivery {
  final endereco = TextEditingController();
  final freteGratisAte = TextEditingController();
  final valorPorKm = TextEditingController();

  void dispose() {
    endereco.dispose();
    freteGratisAte.dispose();
    valorPorKm.dispose();
  }
}

// Container completo de "Delivery": título centralizado no topo (não
// existia no protótipo original — foi adicionado para seguir o mesmo
// padrão visual dos outros blocos da tela), seguido do toggle "A Loja
// possui serviço de delivery", do campo de endereço, e dos campos "Frete
// Grátis até" + "R$ por Km" lado a lado — tudo dentro da mesma moldura
// (fundo semi-transparente + borda) usada nos outros blocos da tela de
// Dados do Perfil.
//
// É um StatefulWidget porque precisa lembrar se o toggle está ligado ou
// desligado — e só um StatelessWidget não consegue guardar isso.
class DeliveryContainer extends StatefulWidget {
  final AppTheme theme;
  final ControllersDelivery controllers;

  const DeliveryContainer({
    super.key,
    required this.theme,
    required this.controllers,
  });

  @override
  State<DeliveryContainer> createState() => _DeliveryContainerState();
}

class _DeliveryContainerState extends State<DeliveryContainer> {
  // Começa desligado por padrão: o delivery só passa a valer se o dono da
  // loja ligar isso de propósito.
  bool _possuiDelivery = false;

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
          // nos outros containers já implementados, para todos os blocos
          // da tela ficarem visualmente idênticos. É o título que você
          // pediu para adicionar, já que o protótipo original não tinha
          // nenhum aqui.
          Text(
            'Delivery',
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
                  'A Loja possui serviço de delivery',
                  style: theme.getTextStyle(fontSize: 13),
                ),
              ),
              Switch(
                value: _possuiDelivery,
                // activeColor foi renomeado para activeThumbColor pelo
                // Flutter (o antigo nome era ambíguo — dava a entender
                // que pintava o Switch inteiro, quando na verdade só
                // pinta a "bolinha"/thumb). Mesmo efeito visual de antes.
                activeThumbColor: theme.buttonColor,
                onChanged: (novoValor) {
                  setState(() => _possuiDelivery = novoValor);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          ThemedTextField(
            theme: theme,
            controller: controllers.endereco,
            label: 'Digite o endereço da Loja',
          ),
          const SizedBox(height: 12),

          // "Frete Grátis até" e "R$ por Km" lado a lado, seguindo o
          // protótipo. Usamos o estilo "com borda" normal (mesmo padrão
          // do resto do app), já que no print os dois aparecem como
          // caixas de campo, não sublinhados.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: controllers.freteGratisAte,
                  label: 'Frete Grátis até',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: controllers.valorPorKm,
                  label: 'R\$ por Km',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}