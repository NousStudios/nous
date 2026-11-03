import 'package:pdf/widgets.dart' as pw;
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';

class GeradorBobinaMesa {
  static Future<void> imprimirConferenciaMesa({
    required ConfiguracoesImpressora config,
    required MesaLoja mesa,
    required String nomeLoja,
  }) async {
    final doc = pw.Document();
    final tamanho = ImpressaoUtils.tamanhoEmPontos(config.tamanhoFonte);
    final pageFormat = ImpressaoUtils.formatoPapel(config);
    final fonteNormal = await ImpressaoUtils.resolverFonte(config.modeloFonte);
    final fonteNegrito =
        await ImpressaoUtils.resolverFonteNegrito(config.modeloFonte);

    pw.TextStyle estilo({bool negrito = false, double? tamanhoCustom}) {
      return pw.TextStyle(
        font: negrito ? fonteNegrito : fonteNormal,
        fontSize: tamanhoCustom ?? tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget linhaDupla(String esquerda, String direita,
        {bool negrito = false}) {
      return ImpressaoUtils.linhaDupla(esquerda, direita,
          estilo: estilo, negrito: negrito);
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          final agora = DateTime.now();
          final dataHoraStr =
              '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')} ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  nomeLoja.isNotEmpty ? nomeLoja : 'Restaurante',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 1),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'CONFERÊNCIA DE MESA',
                  style: estilo(negrito: true),
                ),
              ),
              pw.Divider(thickness: 0.5),
              linhaDupla('Mesa:', mesa.numero, negrito: true),
              if (mesa.descricao.isNotEmpty)
                linhaDupla('Local:', mesa.descricao),
              if (mesa.clienteNome.isNotEmpty)
                linhaDupla('Cliente:', mesa.clienteNome, negrito: true),
              if (mesa.atendenteNome.isNotEmpty)
                linhaDupla('Atendente:', mesa.atendenteNome),
              linhaDupla('Emissão:', dataHoraStr),
              pw.Divider(thickness: 0.5),
              pw.Text('ITENS CONSUMIDOS', style: estilo(negrito: true)),
              pw.SizedBox(height: 2),
              for (final itemMesa in mesa.itens) ...[
                linhaDupla(
                  '${itemMesa.item.quantidade}x ${itemMesa.item.nomeExibicao}',
                  ImpressaoUtils.valor(itemMesa.item.subtotal),
                ),
                for (final acomp in itemMesa.item.acompanhamentos)
                  linhaDupla(
                    '  + ${acomp.quantidadePorUnidade}x ${acomp.nomeItem}',
                    ImpressaoUtils.valor(acomp.precoItem *
                        acomp.quantidadePorUnidade *
                        itemMesa.item.quantidade),
                  ),
                if (itemMesa.item.observacao.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                    child: pw.Text(
                      'Obs: ${itemMesa.item.observacao}',
                      style: estilo(negrito: true),
                    ),
                  ),
              ],
              pw.Divider(thickness: 0.5),
              linhaDupla(
                'TOTAL:',
                ImpressaoUtils.valor(mesa.totalAcumulado),
                negrito: true,
              ),
              pw.Divider(thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  '* Conferência não fiscal *',
                  style: estilo(tamanhoCustom: tamanho - 2),
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await ImpressaoUtils.enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'ConferenciaMesa-${mesa.numero}',
      format: pageFormat,
    );
  }
}
