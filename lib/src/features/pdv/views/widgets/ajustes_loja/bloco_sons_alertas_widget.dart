import 'package:flutter/material.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Bloco encapsulado de configuração dos sons e alertas sonoros do sistema.
class BlocoSonsAlertasWidget extends StatelessWidget {
  final AppTheme theme;
  final BoxDecoration decoracaoBloco;
  final bool podeEditar;
  final Map<String, String> sonsAlertas;
  final List<String> arquivosAudio;
  final Map<String, String> descricoesAnexos;
  final void Function(String chave, String valor) onSalvarSomAlerta;

  const BlocoSonsAlertasWidget({
    super.key,
    required this.theme,
    required this.decoracaoBloco,
    required this.podeEditar,
    required this.sonsAlertas,
    required this.arquivosAudio,
    required this.descricoesAnexos,
    required this.onSalvarSomAlerta,
  });

  String _extrairNomeArquivo(String caminho) {
    final desc = descricoesAnexos[caminho]?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final partes = caminho.split(RegExp(r'[\\/]'));
    return partes.isNotEmpty ? partes.last : caminho;
  }

  @override
  Widget build(BuildContext context) {
    final eventos = [
      (
        chave: SomService.eventoNovoPedido,
        titulo: 'Novo Pedido Recebido',
        descricao: 'Tocado quando um novo pedido entra no sistema.',
      ),
      (
        chave: SomService.eventoConclusaoPedido,
        titulo: 'Tempo Limite / Alerta de Pedido',
        descricao: 'Tocado quando um pedido atinge o tempo limite estipulado.',
      ),
      (
        chave: SomService.eventoBipVenda,
        titulo: 'Bip de Leitura na Venda (Código de Barras / Item)',
        descricao:
            'Tocado ao adicionar um item ou ler com leitor de código de barras.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_outlined,
                  color: theme.buttonColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sons e Alertas do Sistema',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Personalize os efeitos sonoros para as principais operações. Você pode manter o bip padrão nativo do sistema, silenciar ou selecionar qualquer arquivo de áudio anexado na aba Dados.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...eventos.map((ev) {
            final valorAtual = sonsAlertas[ev.chave] ?? SomService.opcaoPadrao;
            final ehSomNativo =
                SomService.sonsNativos.any((s) => s.id == valorAtual);
            final existeArquivo = valorAtual == SomService.opcaoPadrao ||
                valorAtual == SomService.opcaoSilencioso ||
                ehSomNativo ||
                arquivosAudio.contains(valorAtual);
            final valorSelecionado =
                existeArquivo ? valorAtual : SomService.opcaoPadrao;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev.titulo,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ev.descricao,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: valorSelecionado,
                              isExpanded: true,
                              dropdownColor: theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                size: 18,
                                color: podeEditar
                                    ? theme.textColor
                                    : theme.secondaryTextColor
                                        .withValues(alpha: 0.5),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: SomService.opcaoPadrao,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        size: 16,
                                        color: theme.buttonColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Padrão do Sistema (Alerta 1)',
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...SomService.sonsNativos
                                    .where((s) => s.id != SomService.opcaoPadrao)
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.music_note_outlined,
                                              size: 16,
                                              color: theme.secondaryTextColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              s.nome,
                                              style: theme.getTextStyle(
                                                fontSize: 12,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                DropdownMenuItem(
                                  value: SomService.opcaoSilencioso,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.volume_off,
                                        size: 16,
                                        color: theme.secondaryTextColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Silencioso (Sem som)',
                                        style: theme.getTextStyle(
                                          fontSize: 12,
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (arquivosAudio.isNotEmpty) ...[
                                  ...arquivosAudio.map(
                                    (caminho) => DropdownMenuItem(
                                      value: caminho,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.audiotrack,
                                            size: 16,
                                            color: theme.buttonColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _extrairNomeArquivo(caminho),
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.getTextStyle(
                                                fontSize: 12,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              onChanged: podeEditar
                                  ? (novo) {
                                      if (novo != null) {
                                        onSalvarSomAlerta(ev.chave, novo);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Testar som',
                        icon: Icon(
                          Icons.play_circle_outline_rounded,
                          color: theme.buttonColor,
                          size: 26,
                        ),
                        onPressed: () {
                          if (valorSelecionado == SomService.opcaoSilencioso) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: theme.cardBackgroundColor,
                                duration: const Duration(seconds: 1),
                                content: Text(
                                  'Este evento está configurado como silencioso.',
                                  style: theme.getTextStyle(
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          SomService.tocarConfiguracao(valorSelecionado);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
