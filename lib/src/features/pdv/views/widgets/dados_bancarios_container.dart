import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';

// As três opções de tipo de conta do formulário. Um enum, em vez de um
// texto solto, evita erros de digitação e deixa claro quais são as únicas
// opções possíveis.
enum TipoConta { poupanca, corrente, juridica }

// Agrupa os controllers de texto usados no formulário de Dados Bancários,
// no mesmo espírito do ControllersDadosLoja que já existe no projeto. A
// tela de Dados do Perfil cria um conjunto desses, passa para este
// widget, e é responsável por chamar dispose() quando a tela for fechada.
class ControllersDadosBancarios {
  final nomeTitular = TextEditingController();
  final instituicaoFinanceira = TextEditingController();
  final agencia = TextEditingController();
  final conta = TextEditingController();
  final digito = TextEditingController();

  void dispose() {
    nomeTitular.dispose();
    instituicaoFinanceira.dispose();
    agencia.dispose();
    conta.dispose();
    digito.dispose();
  }
}

// Container completo de "Dados Bancários": título centralizado no topo,
// seguido do formulário e do botão "Cadastrar", tudo dentro da mesma
// moldura (fundo semi-transparente + borda) usada nos outros blocos da
// tela de Dados do Perfil.
//
// É um StatefulWidget porque precisa lembrar qual "Tipo de Conta" (Poupança
// / Corrente / Jurídica) está selecionado no momento — e só um
// StatelessWidget não consegue guardar isso.
class DadosBancariosContainer extends StatefulWidget {
  final AppTheme theme;
  final ControllersDadosBancarios controllers;

  const DadosBancariosContainer({
    super.key,
    required this.theme,
    required this.controllers,
  });

  @override
  State<DadosBancariosContainer> createState() =>
      _DadosBancariosContainerState();
}

class _DadosBancariosContainerState extends State<DadosBancariosContainer> {
  // null = nenhum tipo de conta escolhido ainda.
  TipoConta? _tipoSelecionado;

  // Monta um par "bolinha de rádio + texto" reutilizável, um para cada
  // tipo de conta. Ficou numa função à parte para não repetir o mesmo
  // bloco de código três vezes lá embaixo.
  //
  // Antes, cada Radio recebia "groupValue" e "onChanged" diretamente —
  // essa forma foi descontinuada pelo Flutter (é o aviso "deprecated" que
  // você viu). Agora o Radio só precisa saber o próprio "value"; quem
  // controla qual está selecionado é o RadioGroup, lá no método build().
  Widget _opcaoTipoConta(AppTheme theme, TipoConta tipo, String rotulo) {
    return InkWell(
      onTap: () => setState(() => _tipoSelecionado = tipo),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<TipoConta>(
              value: tipo,
              activeColor: theme.textColor,
            ),
            Text(rotulo, style: theme.getTextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

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
          // Título do bloco — mesmo estilo usado em ContainerSimbolico,
          // para os blocos "de verdade" e os ainda simbólicos ficarem
          // visualmente idênticos.
          Text(
            'Dados Bancários',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 20),

          ThemedTextField(
            theme: theme,
            controller: controllers.nomeTitular,
            label: 'Nome do Titular da Conta',
            sublinhado: true,
          ),
          const SizedBox(height: 16),

          ThemedTextField(
            theme: theme,
            controller: controllers.instituicaoFinanceira,
            label: 'Nome da instituição financeira',
          ),
          const SizedBox(height: 12),

          // RadioGroup<TipoConta>: é o novo "dono" da seleção. Ele guarda
          // qual TipoConta está marcado (groupValue) e o que fazer quando
          // o usuário troca a seleção (onChanged) — os três Radio's lá
          // dentro (dentro do Wrap) só precisam dizer qual valor cada um
          // representa.
          RadioGroup<TipoConta>(
            groupValue: _tipoSelecionado,
            onChanged: (novoTipo) =>
                setState(() => _tipoSelecionado = novoTipo),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                _opcaoTipoConta(theme, TipoConta.poupanca, 'Conta Poupança'),
                _opcaoTipoConta(theme, TipoConta.corrente, 'Conta Corrente'),
                _opcaoTipoConta(theme, TipoConta.juridica, 'Conta Jurídica'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Agência, Conta e Dígito lado a lado, no estilo "sublinhado",
          // igual ao protótipo.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: controllers.agencia,
                  label: 'Agência',
                  tipoDeTeclado: TextInputType.number,
                  sublinhado: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: controllers.conta,
                  label: 'Conta',
                  tipoDeTeclado: TextInputType.number,
                  sublinhado: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: controllers.digito,
                  label: 'Dígito',
                  tipoDeTeclado: TextInputType.number,
                  sublinhado: true,
                ),
              ),
            ],
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
                // todo: conectar a um provider de dados bancários quando
                // ele existir. Por enquanto o botão só existe
                // visualmente, como os outros containers ainda não
                // implementados de verdade.
              },
              child: Text(
                'Cadastrar',
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