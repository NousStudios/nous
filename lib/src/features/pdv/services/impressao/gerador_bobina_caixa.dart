import 'package:pdf/widgets.dart' as pw;
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';

class GeradorBobinaCaixa {
  static Future<void> imprimirFechamentoCaixa({
    required ConfiguracoesImpressora config,
    required String lojaNome,
    required String lojaCnpj,
    required TurnoCaixa turno,
    required double vendasDinheiro,
    required double vendasOutros,
    double vendasAPrazo = 0.0,
    required double saldoEsperado,
    required double saldoInformado,
    String observacao = '',
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
          estilo: estilo, negrito: negrito, espacamentoVertical: 1.5);
    }

    final diferenca = saldoInformado - saldoEsperado;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (lojaNome.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    lojaNome,
                    style: estilo(negrito: true, tamanhoCustom: tamanho + 1.5),
                  ),
                ),
              if (lojaCnpj.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'CNPJ: $lojaCnpj',
                    style: estilo(tamanhoCustom: tamanho - 1),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'FECHAMENTO DE CAIXA',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 1),
                ),
              ),
              pw.Divider(thickness: 0.5),
              linhaDupla(
                  'Abertura', ImpressaoUtils.dataHora(turno.dataAbertura)),
              if (turno.dataFechamento != null)
                linhaDupla('Fechamento',
                    ImpressaoUtils.dataHora(turno.dataFechamento!)),
              if (turno.abertoPorNome.isNotEmpty)
                linhaDupla('Operador', turno.abertoPorNome),
              pw.Divider(thickness: 0.5),
              linhaDupla(
                  'Fundo Inicial', ImpressaoUtils.valor(turno.saldoInicial)),
              linhaDupla('Vendas Dinheiro (+)',
                  ImpressaoUtils.valor(vendasDinheiro)),
              linhaDupla('Vendas Pix / Cartão (+)',
                  ImpressaoUtils.valor(vendasOutros)),
              if (vendasAPrazo > 0)
                linhaDupla('Vendas à Prazo / Fiado',
                    ImpressaoUtils.valor(vendasAPrazo)),
              if (turno.totalSuprimentos > 0)
                linhaDupla('Suprimentos (+)',
                    ImpressaoUtils.valor(turno.totalSuprimentos)),
              if (turno.totalSangrias > 0)
                linhaDupla('Sangrias (-)',
                    '-${ImpressaoUtils.valor(turno.totalSangrias)}'),
              pw.Divider(thickness: 0.5),
              linhaDupla('Dinheiro Esperado',
                  ImpressaoUtils.valor(saldoEsperado),
                  negrito: true),
              linhaDupla('Dinheiro Contado',
                  ImpressaoUtils.valor(saldoInformado),
                  negrito: true),
              linhaDupla(
                diferenca.abs() < 0.01
                    ? 'Diferença'
                    : (diferenca > 0 ? 'Sobra de Caixa' : 'Quebra de Caixa'),
                diferenca.abs() < 0.01
                    ? 'R\$ 0,00'
                    : ImpressaoUtils.valor(diferenca.abs()),
                negrito: true,
              ),
              if (observacao.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Obs: $observacao',
                    style: estilo(tamanhoCustom: tamanho - 1)),
              ],
              pw.SizedBox(height: 12),
              pw.Center(
                  child: pw.Text('___________________________________',
                      style: estilo())),
              pw.Center(
                  child: pw.Text('Assinatura do Responsável',
                      style: estilo(tamanhoCustom: tamanho - 1.5))),
              pw.SizedBox(height: 8),
              if (config.rodape.isNotEmpty)
                pw.Center(
                    child: pw.Text(config.rodape,
                        style: estilo(tamanhoCustom: tamanho - 1.5))),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await ImpressaoUtils.enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'FechamentoCaixa-${turno.id}',
      format: pageFormat,
    );
  }

  static Future<void> imprimirMovimentoCaixa({
    required ConfiguracoesImpressora config,
    required String lojaNome,
    required String lojaCnpj,
    required TipoMovimentoCaixa tipo,
    required double valor,
    required String motivo,
    required DateTime dataHora,
    String operadorNome = '',
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
          estilo: estilo, negrito: negrito, espacamentoVertical: 1.5);
    }

    final dataHoraStr =
        '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year} '
        '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';

    final ehSangria = tipo == TipoMovimentoCaixa.sangria;
    final titulo =
        ehSangria ? 'COMPROVANTE DE SANGRIA' : 'COMPROVANTE DE SUPRIMENTO';
    final descricaoTipo =
        ehSangria ? 'Retirada de Caixa' : 'Aporte no Caixa';

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (lojaNome.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    lojaNome,
                    style: estilo(negrito: true, tamanhoCustom: tamanho + 1),
                  ),
                ),
              if (lojaCnpj.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'CNPJ: $lojaCnpj',
                    style: estilo(tamanhoCustom: tamanho - 2),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  titulo,
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 0.5),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  descricaoTipo,
                  style: estilo(tamanhoCustom: tamanho - 2),
                ),
              ),
              pw.Divider(thickness: 0.5),
              linhaDupla('Data/Hora:', dataHoraStr),
              if (operadorNome.isNotEmpty)
                linhaDupla('Operador:', operadorNome),
              linhaDupla('Valor:', ImpressaoUtils.valor(valor), negrito: true),
              if (motivo.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text('Motivo / Justificativa:',
                    style: estilo(negrito: true)),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, top: 1),
                  child: pw.Text(motivo, style: estilo()),
                ),
              ],
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Container(
                  width: 140,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(width: 0.5),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Assinatura do Responsável',
                  style: estilo(tamanhoCustom: tamanho - 2),
                ),
              ),
              if (config.rodape.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    config.rodape,
                    style: estilo(tamanhoCustom: tamanho - 3),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await ImpressaoUtils.enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'Caixa-$titulo',
      format: pageFormat,
    );
  }
}
