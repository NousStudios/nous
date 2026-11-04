import 'package:pdf/widgets.dart' as pw;
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';

class GeradorBobinaComanda {
  static Future<void> imprimirTeste({
    required ConfiguracoesImpressora config,
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

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Teste de Impressão Nous',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 1.5),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'E: ${config.margemEsquerdaMm.toStringAsFixed(1)}mm | D: ${config.margemDireitaMm.toStringAsFixed(1)}mm | ${config.modeloFonte}',
                  style: estilo(negrito: true, tamanhoCustom: tamanho - 1),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(height: 6, thickness: 0.5),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '[Borda Esquerda]',
                      style:
                          estilo(negrito: true, tamanhoCustom: tamanho - 1.5),
                    ),
                    pw.Text(
                      '[Borda Direita]',
                      style:
                          estilo(negrito: true, tamanhoCustom: tamanho - 1.5),
                    ),
                  ],
                ),
              ),
              pw.Divider(height: 6, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Trabalhar todos, trabalhar menos, produzir o necessário, redistribuir tudo!',
                  style: estilo(),
                ),
              ),
              pw.SizedBox(height: 8),
              if (config.rodape.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    config.rodape,
                    style: estilo(tamanhoCustom: tamanho - 1),
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
      jobName: 'TesteNous',
      format: ImpressaoUtils.formatoResolvidoDoDocumento(doc, pageFormat),
    );
  }

  static Future<void> imprimirExemploComanda({
    required ConfiguracoesImpressora config,
    required String cliente,
    String? cnpj,
    String? telefone,
    String? endereco,
    String? email,
    String? redesSociais,
    String? descricao,
    required List<MapEntry<String, double>> itens,
    required String pagamento,
    String? rodape,
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

    pw.Widget linhaDado(String rotulo, String valor) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$rotulo: ', style: estilo(negrito: true)),
            pw.Expanded(
              child: pw.Text(
                valor,
                textAlign: pw.TextAlign.right,
                style: estilo(negrito: false),
              ),
            ),
          ],
        ),
      );
    }

    double total = 0;
    for (final item in itens) {
      total += item.value;
    }

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Comanda #0042',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 2),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  ImpressaoUtils.dataHora(DateTime.now()),
                  style: estilo(tamanhoCustom: tamanho - 2),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(height: 6, thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'CLIENTE',
                  style: estilo(negrito: true, tamanhoCustom: tamanho - 1),
                ),
              ),
              pw.SizedBox(height: 2),
              linhaDado('Nome', cliente),
              if (cnpj != null && cnpj.isNotEmpty) linhaDado('CNPJ', cnpj),
              if (telefone != null && telefone.isNotEmpty)
                linhaDado('Telefone', telefone),
              if (endereco != null && endereco.isNotEmpty)
                linhaDado('Endereço', endereco),
              if (email != null && email.isNotEmpty) linhaDado('Email', email),
              if (redesSociais != null && redesSociais.isNotEmpty)
                linhaDado('Redes', redesSociais),
              if (descricao != null && descricao.isNotEmpty)
                linhaDado('Descrição', descricao),
              pw.Divider(height: 6, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'ITENS',
                  style: estilo(negrito: true, tamanhoCustom: tamanho - 1),
                ),
              ),
              pw.SizedBox(height: 2),
              for (final item in itens)
                linhaDupla(item.key, ImpressaoUtils.valor(item.value)),
              pw.Divider(height: 6, thickness: 0.5),
              pw.SizedBox(height: 2),
              linhaDupla('TOTAL', ImpressaoUtils.valor(total), negrito: true),
              pw.SizedBox(height: 2),
              linhaDupla('Pagamento', pagamento),
              if (rodape != null && rodape.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    rodape,
                    style: estilo(tamanhoCustom: tamanho - 2),
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
      jobName: 'ExemploComandaNous',
      format: ImpressaoUtils.formatoResolvidoDoDocumento(doc, pageFormat),
    );
  }

  static Future<void> imprimirComandaPedido({
    required ConfiguracoesImpressora config,
    required PedidoLoja pedido,
    Cliente? cliente,
    List<String> camposClienteComanda = kCamposClienteComandaPadrao,
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

    final linhasCliente =
        ImpressaoUtils.dadosDoCliente(cliente, camposClienteComanda);
    final subtotal = pedido.itens.fold<double>(0.0, (s, i) => s + i.subtotal);
    final pagamentos = pedido.todosPagamentos;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (pedido.nomeVendedor.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    pedido.nomeVendedor,
                    style: estilo(negrito: true, tamanhoCustom: tamanho + 1.5),
                  ),
                ),
              if (pedido.cnpjVendedor.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'CNPJ: ${pedido.cnpjVendedor}',
                    style: estilo(tamanhoCustom: tamanho - 1),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Comanda ${ImpressaoUtils.numero(pedido.numero)}',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 2),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  ImpressaoUtils.dataHora(pedido.dataHora),
                  style: estilo(tamanhoCustom: tamanho - 2),
                ),
              ),
              pw.Divider(height: 6, thickness: 0.5),
              pw.SizedBox(height: 2),
              if (pedido.clienteNome.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Cliente: ',
                          style: estilo(negrito: true),
                        ),
                        pw.TextSpan(
                          text: pedido.clienteNome,
                          style: estilo(
                            negrito: true,
                            tamanhoCustom: tamanho + 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final linha in linhasCliente)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${linha.key}: ',
                          style: estilo(negrito: true),
                        ),
                        pw.TextSpan(
                          text: linha.value,
                          style: estilo(negrito: false),
                        ),
                      ],
                    ),
                  ),
                ),
              if (pedido.comentario.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
                  child: pw.Text(
                    'Obs Pedido: ${pedido.comentario.trim()}',
                    style: estilo(negrito: true),
                  ),
                ),
              pw.Divider(height: 6, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('ITENS', style: estilo(negrito: true)),
              ),
              pw.SizedBox(height: 4),
              if (pedido.itens.isEmpty)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(
                      'Nenhum item registrado.',
                      style: estilo(),
                    ),
                  ),
                )
              else
                for (final item in pedido.itens) ...[
                  pw.SizedBox(height: 4),
                  linhaDupla(
                    '${item.quantidade}x ${item.nomeExibicao}',
                    ImpressaoUtils.valor(item.subtotalBase),
                  ),
                  for (final a in item.acompanhamentos)
                    linhaDupla(
                      '   ${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                      ImpressaoUtils.valor(a.precoItem *
                          a.quantidadePorUnidade *
                          item.quantidade),
                    ),
                  if (item.observacao.trim().isNotEmpty)
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.only(top: 1, bottom: 2, left: 4),
                      child: pw.Text(
                        'Obs: ${item.observacao.trim()}',
                        style: estilo(negrito: true),
                      ),
                    ),
                ],
              pw.SizedBox(height: 8),
              pw.Divider(height: 6, thickness: 0.5),
              linhaDupla('Subtotal', ImpressaoUtils.valor(subtotal)),
              linhaDupla('Frete', ImpressaoUtils.valor(pedido.frete)),
              if (pedido.desconto > 0)
                linhaDupla(
                    'Desconto', '-${ImpressaoUtils.valor(pedido.desconto)}'),
              if (pedido.acrescimo > 0)
                linhaDupla(
                    'Acréscimo', ImpressaoUtils.valor(pedido.acrescimo)),
              linhaDupla('TOTAL', ImpressaoUtils.valor(pedido.valor),
                  negrito: true),
              pw.SizedBox(height: 4),
              if (pagamentos.isEmpty)
                linhaDupla('Pagamento', '-')
              else
                for (final p in pagamentos)
                  linhaDupla(p.forma, ImpressaoUtils.valor(p.valor)),
              if (pedido.troco > 0)
                linhaDupla('Troco', ImpressaoUtils.valor(pedido.troco),
                    negrito: true),
              if (config.rodape.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                for (final l in config.rodape.split('\n'))
                  pw.Center(child: pw.Text(l, style: estilo())),
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
      jobName: 'ComandaNous-${pedido.numero}',
      format: ImpressaoUtils.formatoResolvidoDoDocumento(doc, pageFormat),
    );
  }
}
