import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/views/widgets/impressora/dados_teste_impressora.dart';

class OpcoesComandaWidget extends StatelessWidget {
  final AppTheme theme;
  final List<String> camposClienteComanda;
  final bool imprimirAutomaticoAoConcluir;
  final TextEditingController rodapeController;
  final bool imprimindo;
  final ValueChanged<List<String>> onCamposClienteAlterados;
  final ValueChanged<bool> onAutomacaoAlterada;
  final VoidCallback onImprimirTeste;
  final VoidCallback onSalvar;

  const OpcoesComandaWidget({
    super.key,
    required this.theme,
    required this.camposClienteComanda,
    required this.imprimirAutomaticoAoConcluir,
    required this.rodapeController,
    required this.imprimindo,
    required this.onCamposClienteAlterados,
    required this.onAutomacaoAlterada,
    required this.onImprimirTeste,
    required this.onSalvar,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _linhaCheckbox(String chave) {
    final marcado = camposClienteComanda.contains(chave);
    final rotulo = kRotulosCamposCliente[chave] ?? chave;
    return InkWell(
      onTap: () {
        final novaLista = List<String>.from(camposClienteComanda);
        if (marcado) {
          novaLista.remove(chave);
        } else {
          novaLista.add(chave);
        }
        onCamposClienteAlterados(novaLista);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: marcado,
                activeColor: theme.buttonColor,
                checkColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) {
                  final novaLista = List<String>.from(camposClienteComanda);
                  if (v == true) {
                    if (!novaLista.contains(chave)) {
                      novaLista.add(chave);
                    }
                  } else {
                    novaLista.remove(chave);
                  }
                  onCamposClienteAlterados(novaLista);
                },
              ),
            ),
            const SizedBox(width: 4),
            Text(
              rotulo,
              style: theme.getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoDadosCliente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Dados do Cliente na Comanda'),
          Text(
            'Marque o que deve aparecer na comanda quando o cliente '
            'estiver cadastrado e o campo estiver preenchido.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: [
              for (final chave in kCamposClienteComanda)
                _linhaCheckbox(chave),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  onCamposClienteAlterados(List.of(kCamposClienteComanda));
                },
                child: Text(
                  'Marcar todos',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  onCamposClienteAlterados([]);
                },
                child: Text(
                  'Desmarcar todos',
                  style: theme.getTextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoAutomacao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _decoracaoDoBloco,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impressão automática ao concluir venda',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dispara a impressão da comanda térmica automaticamente sem precisar tocar no botão imprimir.',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          ThemedSwitch(
            theme: theme,
            value: imprimirAutomaticoAoConcluir,
            onChanged: onAutomacaoAlterada,
          ),
        ],
      ),
    );
  }

  Widget _blocoRodape() {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          _tituloDoBloco('Rodapé da Comanda'),
          TextField(
            controller: rodapeController,
            maxLines: 3,
            textAlign: TextAlign.center,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Ex: linktr.ee/nous72',
              hintStyle: theme.getTextStyle(
                  fontSize: 12, color: theme.secondaryTextColor),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: borda(theme.borderColor),
              focusedBorder: borda(theme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botoesAcao() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return theme.borderColor.withValues(alpha: 0.18);
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return theme.textColor;
            }),
            iconColor: WidgetStateProperty.resolveWith((states) {
              return theme.textColor;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: theme.textColor, width: 1.4);
              }
              return BorderSide(color: theme.borderColor, width: 1.0);
            }),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            mouseCursor: const WidgetStatePropertyAll(
              SystemMouseCursors.click,
            ),
          ),
          onPressed: imprimindo ? null : onImprimirTeste,
          icon: imprimindo
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textColor,
                  ),
                )
              : Icon(Icons.print_outlined, size: 16, color: theme.textColor),
          label: Text(
            'Imprimir Teste',
            style: theme.getTextStyle(fontSize: 12),
          ),
        ),
        OutlinedButton.icon(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return theme.borderColor.withValues(alpha: 0.18);
              }
              return theme.buttonColor;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return theme.textColor;
              }
              return theme.buttonTextColor;
            }),
            iconColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return theme.textColor;
              }
              return theme.buttonTextColor;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return BorderSide(color: theme.textColor, width: 1.4);
              }
              return BorderSide(color: theme.borderColor, width: 1.0);
            }),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            mouseCursor: const WidgetStatePropertyAll(
              SystemMouseCursors.click,
            ),
          ),
          onPressed: onSalvar,
          icon: const Icon(Icons.check, size: 16),
          label: Text(
            'Salvar Configurações',
            style: theme.getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _blocoDadosCliente(),
        const SizedBox(height: 12),
        _blocoAutomacao(),
        const SizedBox(height: 12),
        _blocoRodape(),
        const SizedBox(height: 18),
        _botoesAcao(),
      ],
    );
  }
}
