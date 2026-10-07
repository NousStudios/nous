import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

const PdfPageFormat _papel58mm = PdfPageFormat(
  58 * PdfPageFormat.mm,
  200 * PdfPageFormat.mm,
  marginLeft: 5.0 * PdfPageFormat.mm,
  marginRight: 3.0 * PdfPageFormat.mm,
  marginTop: 2 * PdfPageFormat.mm,
  marginBottom: 2 * PdfPageFormat.mm,
);

const List<String> _formasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'À Prazo',
];

class ImpressaoService {
  static pw.Font? _fonteBellezaCache;

  static Future<pw.Font> _resolverFonte(String modelo) async {
    switch (modelo) {
      case 'mono':
        return pw.Font.courier();
      case 'serifada':
        return pw.Font.times();
      case 'padrao':
        return pw.Font.helvetica();
      case 'belleza':
      default:
        try {
          if (_fonteBellezaCache != null) return _fonteBellezaCache!;
          final bytes =
              await rootBundle.load('assets/fonts/Belleza-Regular.ttf');
          _fonteBellezaCache = pw.Font.ttf(bytes);
          return _fonteBellezaCache!;
        } catch (_) {
          return pw.Font.helvetica();
        }
    }
  }

  static Future<pw.Font> _resolverFonteNegrito(String modelo) async {
    switch (modelo) {
      case 'mono':
        return pw.Font.courierBold();
      case 'serifada':
        return pw.Font.timesBold();
      case 'padrao':
        return pw.Font.helveticaBold();
      case 'belleza':
      default:
        try {
          if (_fonteBellezaCache != null) return _fonteBellezaCache!;
          final bytes =
              await rootBundle.load('assets/fonts/Belleza-Regular.ttf');
          _fonteBellezaCache = pw.Font.ttf(bytes);
          return _fonteBellezaCache!;
        } catch (_) {
          return pw.Font.helveticaBold();
        }
    }
  }

  static PdfPageFormat formatoPapel(ConfiguracoesImpressora? config) {
    final margemEsquerda = (config != null && config.margemEsquerdaMm > 0
            ? config.margemEsquerdaMm
            : 5.0) *
        PdfPageFormat.mm;
    final margemDireita = (config != null && config.margemDireitaMm > 0
            ? config.margemDireitaMm
            : 3.0) *
        PdfPageFormat.mm;
    return PdfPageFormat(
      58 * PdfPageFormat.mm,
      200 * PdfPageFormat.mm,
      marginLeft: margemEsquerda,
      marginRight: margemDireita,
      marginTop: 2 * PdfPageFormat.mm,
      marginBottom: 2 * PdfPageFormat.mm,
    );
  }

  static Future<List<Printer>> listarImpressoras() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return const [];
    }
  }

  static double _tamanhoEmPontos(String tamanho) {
    switch (tamanho) {
      case 'pequena':
        return 8;
      case 'grande':
        return 12;
      case 'normal':
      default:
        return 10;
    }
  }

  static String _valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static String _numero(int n) => '#${n.toString().padLeft(4, '0')}';

  static String _dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  static String _situacao(StatusPedido s) {
    switch (s) {
      case StatusPedido.novo:
        return 'Novo';
      case StatusPedido.aceito:
        return 'Aceito';
      case StatusPedido.concluido:
        return 'Concluído';
      case StatusPedido.cancelado:
        return 'Cancelado';
    }
  }

  static String _nomeDoItem(Loja loja, String itemId) {
    for (final i in loja.itensLoja) {
      if (i.id == itemId) {
        return i.nome.isEmpty ? 'Item' : i.nome;
      }
    }
    return 'Item removido';
  }

  static Map<String, double> _comprasPorFornecedor(
    List<MovimentoEstoque> movimentos,
  ) {
    final mapa = <String, double>{};
    for (final m in movimentos) {
      if (!m.ehEntrada) continue;
      if (m.custoTotal <= 0) continue;
      final nome =
          m.fornecedorNome.trim().isEmpty ? 'Sem fornecedor' : m.fornecedorNome;
      mapa[nome] = (mapa[nome] ?? 0) + m.custoTotal;
    }
    return mapa;
  }

  static List<MapEntry<String, String>> _dadosDoCliente(
    Cliente? cliente,
    List<String> camposSelecionados,
  ) {
    if (cliente == null) return const [];
    final linhas = <MapEntry<String, String>>[];

    if (camposSelecionados.contains('cnpj') &&
        cliente.cnpj.trim().isNotEmpty) {
      linhas.add(MapEntry('CNPJ', cliente.cnpj.trim()));
    }
    if (camposSelecionados.contains('telefone') &&
        cliente.telefone.trim().isNotEmpty) {
      linhas.add(MapEntry('Telefone', cliente.telefone.trim()));
    }
    if (camposSelecionados.contains('endereco')) {
      final endereco = cliente.endereco.trim();
      final numero = cliente.numero.trim();
      if (endereco.isNotEmpty) {
        linhas.add(MapEntry(
          'Endereço',
          numero.isEmpty ? endereco : '$endereco, $numero',
        ));
      } else if (numero.isNotEmpty) {
        linhas.add(MapEntry('Número', numero));
      }
    }
    if (camposSelecionados.contains('email') &&
        cliente.email.trim().isNotEmpty) {
      linhas.add(MapEntry('Email', cliente.email.trim()));
    }
    if (camposSelecionados.contains('redesSociais') &&
        cliente.redesSociais.trim().isNotEmpty) {
      linhas.add(MapEntry('Redes sociais', cliente.redesSociais.trim()));
    }
    if (camposSelecionados.contains('descricao') &&
        cliente.descricao.trim().isNotEmpty) {
      linhas.add(MapEntry('Descrição', cliente.descricao.trim()));
    }

    return linhas;
  }

  static Future<void> imprimirTeste({
    required ConfiguracoesImpressora config,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);
    final pageFormat = formatoPapel(config);
    final fonteNormal = await _resolverFonte(config.modeloFonte);
    final fonteNegrito = await _resolverFonteNegrito(config.modeloFonte);

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
              pw.Divider(thickness: 0.5),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '[Borda Esquerda]',
                      style: estilo(negrito: true, tamanhoCustom: tamanho - 1.5),
                    ),
                    pw.Text(
                      '[Borda Direita]',
                      style: estilo(negrito: true, tamanhoCustom: tamanho - 1.5),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
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
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'TesteNous',
      format: pageFormat,
    );
  }

  static Future<void> imprimirComanda({
    required ConfiguracoesImpressora config,
    required PedidoLoja pedido,
    Cliente? cliente,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);
    final pageFormat = formatoPapel(config);
    final fonteNormal = await _resolverFonte(config.modeloFonte);
    final fonteNegrito = await _resolverFonteNegrito(config.modeloFonte);

    pw.TextStyle estilo({bool negrito = false, double? tamanhoCustom}) {
      return pw.TextStyle(
        font: negrito ? fonteNegrito : fonteNormal,
        fontSize: tamanhoCustom ?? tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget linhaDupla(
      String esquerda,
      String direita, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(esquerda, style: estilo(negrito: negrito)),
            ),
            pw.Text(direita, style: estilo(negrito: negrito)),
          ],
        ),
      );
    }

    double subtotal = 0;
    for (final item in pedido.itens) {
      subtotal += item.subtotal;
    }

    final linhasCliente = _dadosDoCliente(
      cliente,
      config.camposClienteComanda,
    );
    final pagamentos = pedido.todosPagamentos;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
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
                  'Pedido ${_numero(pedido.numero)}',
                  style: estilo(negrito: true, tamanhoCustom: tamanho + 1),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Data: ${_dataHora(pedido.dataHora)}',
                  style: estilo(tamanhoCustom: tamanho - 0.5),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              if (pedido.clienteNome.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'Cliente: ',
                          style: estilo(negrito: false),
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
              pw.Divider(thickness: 0.5),
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
                    _valor(item.subtotalBase),
                  ),
                  for (final a in item.acompanhamentos)
                    linhaDupla(
                      '   ${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                      _valor(a.precoItem *
                          a.quantidadePorUnidade *
                          item.quantidade),
                    ),
                  if (item.observacao.trim().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 1, bottom: 2, left: 4),
                      child: pw.Text(
                        'Obs: ${item.observacao.trim()}',
                        style: estilo(negrito: true),
                      ),
                    ),
                ],
              pw.SizedBox(height: 8),
              pw.Divider(),
              linhaDupla('Subtotal', _valor(subtotal)),
              linhaDupla('Frete', _valor(pedido.frete)),
              if (pedido.desconto > 0)
                linhaDupla('Desconto', '-${_valor(pedido.desconto)}'),
              if (pedido.acrescimo > 0)
                linhaDupla('Acréscimo', _valor(pedido.acrescimo)),
              linhaDupla('TOTAL', _valor(pedido.valor), negrito: true),
              pw.SizedBox(height: 4),
              if (pagamentos.isEmpty)
                linhaDupla('Pagamento', '-')
              else
                for (final p in pagamentos)
                  linhaDupla(p.forma, _valor(p.valor)),
              if (pedido.troco > 0)
                linhaDupla('Troco', _valor(pedido.troco), negrito: true),
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
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'ComandaNous-${pedido.numero}',
      format: pageFormat,
    );
  }

  static Future<void> imprimirConferenciaMesa({
    required ConfiguracoesImpressora config,
    required MesaLoja mesa,
    required String nomeLoja,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);
    final pageFormat = formatoPapel(config);
    final fonteNormal = await _resolverFonte(config.modeloFonte);
    final fonteNegrito = await _resolverFonteNegrito(config.modeloFonte);

    pw.TextStyle estilo({bool negrito = false, double? tamanhoCustom}) {
      return pw.TextStyle(
        font: negrito ? fonteNegrito : fonteNormal,
        fontSize: tamanhoCustom ?? tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget linhaDupla(
      String esquerda,
      String direita, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(esquerda, style: estilo(negrito: negrito)),
            ),
            pw.Text(direita, style: estilo(negrito: negrito)),
          ],
        ),
      );
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
                  _valor(itemMesa.item.subtotal),
                ),
                for (final acomp in itemMesa.item.acompanhamentos)
                  linhaDupla(
                    '  + ${acomp.quantidadePorUnidade}x ${acomp.nomeItem}',
                    _valor(acomp.precoItem *
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
                _valor(mesa.totalAcumulado),
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
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'ConferenciaMesa-${mesa.numero}',
      format: pageFormat,
    );
  }

  static Future<void> imprimirFinanceiro({
    required ConfiguracoesImpressora config,
    required Loja loja,
    required String periodo,
    required List<PedidoLoja> vendas,
    required List<PedidoLoja> pedidosAceitos,
    required List<PagamentoFuncionario> pagamentos,
    required List<MovimentoEstoque> movimentos,
    required double saidaEstoque,
    required bool contarEstoque,
  }) async {
    final doc = pw.Document();
    final tamanho = _tamanhoEmPontos(config.tamanhoFonte);
    final pageFormat = formatoPapel(config);
    final fonteNormal = await _resolverFonte(config.modeloFonte);
    final fonteNegrito = await _resolverFonteNegrito(config.modeloFonte);

    pw.TextStyle estilo({bool negrito = false, double? tamanhoCustom}) {
      return pw.TextStyle(
        font: negrito ? fonteNegrito : fonteNormal,
        fontSize: tamanhoCustom ?? tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
    }

    pw.Widget linhaDupla(
      String esquerda,
      String direita, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(esquerda, style: estilo(negrito: negrito)),
            ),
            pw.Text(direita, style: estilo(negrito: negrito)),
          ],
        ),
      );
    }

    double totalEntradas = 0;
    for (final p in vendas) {
      totalEntradas += p.valor;
    }
    double totalAReceber = 0;
    for (final p in pedidosAceitos) {
      totalAReceber += p.valor;
    }
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final totalSaidas =
        totalPagamentos + (contarEstoque ? saidaEstoque : 0);
    final saldo = totalEntradas - totalSaidas;

    final entradasPorForma = <String, double>{
      for (final f in _formasDePagamento) f: 0.0,
    };
    for (final p in vendas) {
      for (final pag in p.todosPagamentos) {
        entradasPorForma[pag.forma] =
            (entradasPorForma[pag.forma] ?? 0) + pag.valor;
      }
    }

    final comprasPorFornecedor = _comprasPorFornecedor(movimentos);
    final comprasOrdenadas = comprasPorFornecedor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double totalCompras = 0;
    for (final e in comprasOrdenadas) {
      totalCompras += e.value;
    }

    final vendasOrdenadas = [...vendas]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosOrdenados = [...pagamentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosOrdenados = [...movimentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (context) {
          final blocos = <pw.Widget>[];

          if (loja.nome.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Text(loja.nome, style: estilo(negrito: true)),
              ),
            );
          }
          if (loja.cnpj.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Text('CNPJ: ${loja.cnpj}', style: estilo()),
              ),
            );
          }
          blocos.add(pw.SizedBox(height: 4));
          blocos.add(
            pw.Center(
              child: pw.Text(
                'RELATÓRIO FINANCEIRO',
                style: estilo(negrito: true),
              ),
            ),
          );
          blocos.add(
            pw.Center(
              child: pw.Text('Período: $periodo', style: estilo()),
            ),
          );
          blocos.add(
            pw.Center(
              child: pw.Text(
                'Emitido: ${_dataHora(DateTime.now())}',
                style: estilo(tamanhoCustom: tamanho - 1),
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 6));
          blocos.add(pw.Divider());

          blocos.add(
            pw.Center(
              child: pw.Text('ENTRADAS', style: estilo(negrito: true)),
            ),
          );
          blocos.add(pw.SizedBox(height: 2));
          for (final forma in _formasDePagamento) {
            blocos.add(
              linhaDupla(forma, _valor(entradasPorForma[forma] ?? 0)),
            );
          }
          blocos.add(
            linhaDupla('Total', _valor(totalEntradas), negrito: true),
          );

          if (vendasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(pw.Divider());
            blocos.add(
              pw.Center(
                child: pw.Text(
                  'VENDAS DO PERÍODO',
                  style: estilo(negrito: true),
                ),
              ),
            );
            blocos.add(pw.SizedBox(height: 2));
            for (final v in vendasOrdenadas) {
              blocos.add(
                linhaDupla(
                  '${_numero(v.numero)} ${v.clienteNome}',
                  _valor(v.valor),
                ),
              );
              final formas = v.todosPagamentos
                  .map((p) => p.forma)
                  .where((f) => f.isNotEmpty)
                  .join(' + ');
              final detalhe = '${_dataHora(v.dataHora)}'
                  '${formas.isNotEmpty ? ' • $formas' : ''}';
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
                  child: pw.Text(
                    detalhe,
                    style: estilo(tamanhoCustom: tamanho - 2),
                  ),
                ),
              );
            }
          }

          blocos.add(pw.SizedBox(height: 6));
          blocos.add(pw.Divider());
          blocos.add(
            pw.Center(
              child: pw.Text('SAÍDAS', style: estilo(negrito: true)),
            ),
          );
          blocos.add(pw.SizedBox(height: 2));
          blocos.add(
            linhaDupla(
              'Pagamentos a funcionários',
              _valor(totalPagamentos),
            ),
          );
          if (contarEstoque) {
            blocos.add(
              linhaDupla('Custo de estoque', _valor(saidaEstoque)),
            );
          }
          blocos.add(
            linhaDupla('Total', _valor(totalSaidas), negrito: true),
          );

          blocos.add(pw.SizedBox(height: 6));
          blocos.add(pw.Divider());
          blocos.add(
            linhaDupla('SALDO', _valor(saldo), negrito: true),
          );
          if (pedidosAceitos.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 3));
            blocos.add(
              linhaDupla(
                'A receber (${pedidosAceitos.length})',
                _valor(totalAReceber),
              ),
            );
          }

          if (movimentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(pw.Divider());
            blocos.add(
              pw.Center(
                child: pw.Text(
                  'MOVIMENTOS DE ESTOQUE',
                  style: estilo(negrito: true),
                ),
              ),
            );
            blocos.add(pw.SizedBox(height: 2));
            for (final m in movimentosOrdenados) {
              final nome = _nomeDoItem(loja, m.itemId);
              final sinal = m.ehEntrada ? '+' : '-';
              final sufixoCusto = m.custoUnitario > 0
                  ? ' • ${_valor(m.custoUnitario)}/un'
                  : '';
              blocos.add(
                linhaDupla(
                  '$sinal${m.quantidade}x $nome$sufixoCusto',
                  _valor(m.custoTotal),
                ),
              );
              final sufixoFornecedor = m.fornecedorNome.isNotEmpty
                  ? ' • ${m.fornecedorNome}'
                  : '';
              final detalhe = '${_dataHora(m.dataHora)}'
                  '${m.nomeAutor.isNotEmpty ? ' • ${m.nomeAutor}' : ''}'
                  '$sufixoFornecedor'
                  '${m.motivo.trim().isNotEmpty ? ' • ${m.motivo.trim()}' : ''}';
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
                  child: pw.Text(
                    detalhe,
                    style: estilo(tamanhoCustom: tamanho - 2),
                  ),
                ),
              );
            }
          }

          if (comprasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(pw.Divider());
            blocos.add(
              pw.Center(
                child: pw.Text(
                  'COMPRAS POR FORNECEDOR',
                  style: estilo(negrito: true),
                ),
              ),
            );
            blocos.add(pw.SizedBox(height: 2));
            for (final e in comprasOrdenadas) {
              blocos.add(linhaDupla(e.key, _valor(e.value)));
            }
            blocos.add(
              linhaDupla('Total', _valor(totalCompras), negrito: true),
            );
          }

          if (pagamentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(pw.Divider());
            blocos.add(
              pw.Center(
                child: pw.Text(
                  'PAGAMENTOS DO PERÍODO',
                  style: estilo(negrito: true),
                ),
              ),
            );
            blocos.add(pw.SizedBox(height: 2));
            for (final p in pagamentosOrdenados) {
              blocos.add(linhaDupla(p.nome, _valor(p.valor)));
              final detalhe = '${_dataHora(p.dataHora)}'
                  '${p.nomeAutor.isNotEmpty ? ' • por ${p.nomeAutor}' : ''}'
                  '${p.descricao.trim().isNotEmpty ? ' • ${p.descricao.trim()}' : ''}';
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
                  child: pw.Text(
                    detalhe,
                    style: estilo(tamanhoCustom: tamanho - 2),
                  ),
                ),
              );
            }
          }

          if (config.rodape.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 10));
            for (final l in config.rodape.split('\n')) {
              blocos.add(pw.Center(child: pw.Text(l, style: estilo())));
            }
          }

          return blocos;
        },
      ),
    );

    final bytes = await doc.save();
    await _enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'FinanceiroNous-${DateTime.now().millisecondsSinceEpoch}',
      format: pageFormat,
    );
  }

  static Future<String?> exportarComandaPDF({
    required PedidoLoja pedido,
    required String rodape,
    Cliente? cliente,
    List<String> camposClienteComanda = kCamposClienteComandaPadrao,
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloSecao = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloCorpo = const pw.TextStyle(fontSize: 11);
    final estiloMiudo = const pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );

    double subtotalItens = 0;
    for (final item in pedido.itens) {
      subtotalItens += item.subtotal;
    }

    final linhasCliente = _dadosDoCliente(cliente, camposClienteComanda);
    final pagamentos = pedido.todosPagamentos;

    pw.Widget linhaDupla(
      String rotulo,
      String valor, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(
                rotulo,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                valor,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final blocos = <pw.Widget>[];

          blocos.add(
            pw.Center(
              child: pw.Text('Comanda', style: estiloTitulo),
            ),
          );
          if (pedido.nomeVendedor.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    pedido.nomeVendedor,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          if (pedido.cnpjVendedor.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'CNPJ: ${pedido.cnpjVendedor}',
                    style: estiloMiudo,
                  ),
                ),
              ),
            );
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Divider());
          blocos.add(pw.SizedBox(height: 8));

          blocos.add(
            pw.Text('Dados do Pedido', style: estiloSecao),
          );
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(linhaDupla('Pedido', _numero(pedido.numero)));
          blocos.add(linhaDupla('Data', _dataHora(pedido.dataHora)));
          blocos.add(linhaDupla('Cliente', pedido.clienteNome));
          for (final linha in linhasCliente) {
            blocos.add(linhaDupla(linha.key, linha.value));
          }
          blocos.add(linhaDupla('Produtos', pedido.produtoNome));
          blocos.add(linhaDupla('Situação', _situacao(pedido.status)));

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Itens', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));

          if (pedido.itens.isEmpty) {
            blocos.add(
              pw.Text(
                'Nenhum item detalhado nesta venda.',
                style: estiloMiudo,
              ),
            );
          } else {
            for (final item in pedido.itens) {
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantidade}x ${item.nomeExibicao}',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(
                            _valor(item.subtotalBase),
                            style: estiloCorpo,
                          ),
                        ],
                      ),
                      for (final a in item.acompanhamentos)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            left: 12,
                            top: 2,
                          ),
                          child: pw.Row(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  '${a.quantidadePorUnidade}x ${a.nomeItem} por unidade',
                                  style: estiloMiudo,
                                ),
                              ),
                              pw.Text(
                                _valor(a.precoItem *
                                    a.quantidadePorUnidade *
                                    item.quantidade),
                                style: estiloMiudo,
                              ),
                            ],
                          ),
                        ),
                      if (item.observacao.trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            left: 12,
                            top: 2,
                          ),
                          child: pw.Text(
                            'Obs: ${item.observacao.trim()}',
                            style: estiloMiudo,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Resumo', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(linhaDupla('Subtotal', _valor(subtotalItens)));
          if (pedido.frete > 0) {
            blocos.add(linhaDupla('Frete', _valor(pedido.frete)));
          }
          if (pedido.desconto > 0) {
            blocos.add(
              linhaDupla('Desconto', '-${_valor(pedido.desconto)}'),
            );
          }
          if (pedido.acrescimo > 0) {
            blocos.add(
              linhaDupla('Acréscimo', _valor(pedido.acrescimo)),
            );
          }
          blocos.add(
            linhaDupla('Valor total', _valor(pedido.valor), negrito: true),
          );

          if (pagamentos.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 8));
            blocos.add(pw.Text('Pagamentos', style: estiloSecao));
            blocos.add(pw.SizedBox(height: 6));
            for (final p in pagamentos) {
              blocos.add(linhaDupla(p.forma, _valor(p.valor)));
            }
            if (pedido.troco > 0) {
              blocos.add(
                linhaDupla('Troco', _valor(pedido.troco), negrito: true),
              );
            }
          }

          if (pedido.formaPagamento == 'À Prazo' ||
              pedido.todosPagamentos.any((p) => p.forma == 'À Prazo')) {
            blocos.add(pw.SizedBox(height: 8));
            blocos.add(
              linhaDupla(
                'Pagamento à prazo',
                pedido.quitado ? 'Quitado' : 'Em aberto',
              ),
            );
            blocos.add(
              linhaDupla(
                'Já pago',
                _valor(pedido.quitado ? pedido.valor : pedido.valorPago),
              ),
            );
            blocos.add(
              linhaDupla(
                'Restante',
                _valor(pedido.quitado ? 0 : pedido.valorRestante),
              ),
            );
          }

          if (pedido.comentario.trim().isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(pw.Text('Comentário', style: estiloSecao));
            blocos.add(pw.SizedBox(height: 6));
            blocos.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      pedido.comentario.trim(),
                      style: estiloCorpo,
                    ),
                    if (pedido.comentarioAutorNome.isNotEmpty ||
                        pedido.comentarioAutorCpf.isNotEmpty ||
                        pedido.comentarioAutorEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Por: ${[
                          if (pedido.comentarioAutorNome.isNotEmpty)
                            pedido.comentarioAutorNome,
                          if (pedido.comentarioAutorCpf.isNotEmpty)
                            pedido.comentarioAutorCpf,
                          if (pedido.comentarioAutorEmail.isNotEmpty)
                            pedido.comentarioAutorEmail,
                        ].join(' • ')}',
                        style: estiloMiudo,
                      ),
                    ],
                    if (pedido.comentarioDataHora != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Em: ${_dataHora(pedido.comentarioDataHora!)}',
                        style: estiloMiudo,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (rodape.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 20));
            for (final l in rodape.split('\n')) {
              blocos.add(
                pw.Center(
                  child: pw.Text(l, style: estiloMiudo),
                ),
              );
            }
          }

          return blocos;
        },
      ),
    );

    final bytes = await doc.save();

    const grupo = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final local = await getSaveLocation(
      suggestedName:
          'comanda_${pedido.numero.toString().padLeft(4, '0')}.pdf',
      acceptedTypeGroups: const [grupo],
    );

    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsBytes(bytes);
    return local.path;
  }

  static Future<String?> exportarFinanceiroPDF({
    required Loja loja,
    required String periodo,
    required String rodape,
    required List<PedidoLoja> vendas,
    required List<PedidoLoja> pedidosAceitos,
    required List<PagamentoFuncionario> pagamentos,
    required List<MovimentoEstoque> movimentos,
    required double saidaEstoque,
    required bool contarEstoque,
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloSecao = pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloCorpo = const pw.TextStyle(fontSize: 11);
    final estiloMiudo = const pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );

    double totalEntradas = 0;
    for (final p in vendas) {
      totalEntradas += p.valor;
    }
    double totalAReceber = 0;
    for (final p in pedidosAceitos) {
      totalAReceber += p.valor;
    }
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final totalSaidas =
        totalPagamentos + (contarEstoque ? saidaEstoque : 0);
    final saldo = totalEntradas - totalSaidas;

    final entradasPorForma = <String, double>{
      for (final f in _formasDePagamento) f: 0.0,
    };
    for (final p in vendas) {
      for (final pag in p.todosPagamentos) {
        entradasPorForma[pag.forma] =
            (entradasPorForma[pag.forma] ?? 0) + pag.valor;
      }
    }

    final comprasPorFornecedor = _comprasPorFornecedor(movimentos);
    final comprasOrdenadas = comprasPorFornecedor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double totalCompras = 0;
    for (final e in comprasOrdenadas) {
      totalCompras += e.value;
    }

    final vendasOrdenadas = [...vendas]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final pagamentosOrdenados = [...pagamentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final movimentosOrdenados = [...movimentos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    pw.Widget linhaDupla(
      String rotulo,
      String valor, {
      bool negrito = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 220,
              child: pw.Text(
                rotulo,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                valor,
                style: negrito
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : estiloCorpo,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final blocos = <pw.Widget>[];

          blocos.add(
            pw.Center(
              child: pw.Text('Relatório Financeiro', style: estiloTitulo),
            ),
          );
          if (loja.nome.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    loja.nome,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          if (loja.cnpj.isNotEmpty) {
            blocos.add(
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'CNPJ: ${loja.cnpj}',
                    style: estiloMiudo,
                  ),
                ),
              ),
            );
          }
          blocos.add(
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  'Período: $periodo • Emitido em ${_dataHora(DateTime.now())}',
                  style: estiloMiudo,
                ),
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Divider());
          blocos.add(pw.SizedBox(height: 8));

          blocos.add(
            pw.Text('Entradas por forma de pagamento', style: estiloSecao),
          );
          blocos.add(pw.SizedBox(height: 6));
          for (final forma in _formasDePagamento) {
            blocos.add(
              linhaDupla(forma, _valor(entradasPorForma[forma] ?? 0)),
            );
          }
          blocos.add(
            linhaDupla('Total de entradas', _valor(totalEntradas),
                negrito: true),
          );

          if (vendasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Vendas do período', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final v in vendasOrdenadas) {
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${_numero(v.numero)} • ${v.clienteNome}',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(_valor(v.valor), style: estiloCorpo),
                        ],
                      ),
                      pw.Text(
                        '${_dataHora(v.dataHora)}'
                        '${v.todosPagamentos.isNotEmpty ? ' • ${v.todosPagamentos.map((p) => p.forma).where((f) => f.isNotEmpty).join(' + ')}' : ''}',
                        style: estiloMiudo,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Saídas', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(
            linhaDupla(
              'Pagamentos a funcionários',
              _valor(totalPagamentos),
            ),
          );
          if (contarEstoque) {
            blocos.add(
              linhaDupla('Custo de estoque', _valor(saidaEstoque)),
            );
          }
          blocos.add(
            linhaDupla('Total de saídas', _valor(totalSaidas),
                negrito: true),
          );

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Balança orçamentária', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 6));
          blocos.add(
            linhaDupla('Saldo', _valor(saldo), negrito: true),
          );
          if (pedidosAceitos.isNotEmpty) {
            blocos.add(
              linhaDupla(
                'A receber (${pedidosAceitos.length})',
                _valor(totalAReceber),
              ),
            );
          }

          if (movimentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Movimentos de estoque', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final m in movimentosOrdenados) {
              final nome = _nomeDoItem(loja, m.itemId);
              final sinal = m.ehEntrada ? '+' : '-';
              final sufixoCusto = m.custoUnitario > 0
                  ? ' • ${_valor(m.custoUnitario)}/un'
                  : '';
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '$sinal${m.quantidade}x $nome$sufixoCusto',
                              style: estiloCorpo,
                            ),
                          ),
                          pw.Text(
                            _valor(m.custoTotal),
                            style: estiloCorpo,
                          ),
                        ],
                      ),
                      pw.Text(
                        '${_dataHora(m.dataHora)}'
                        '${m.nomeAutor.isNotEmpty ? ' • por ${m.nomeAutor}' : ''}'
                        '${m.fornecedorNome.isNotEmpty ? ' • ${m.fornecedorNome}' : ''}'
                        '${m.motivo.trim().isNotEmpty ? ' • ${m.motivo.trim()}' : ''}',
                        style: estiloMiudo,
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (comprasOrdenadas.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Compras por fornecedor', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final e in comprasOrdenadas) {
              blocos.add(linhaDupla(e.key, _valor(e.value)));
            }
            blocos.add(
              linhaDupla('Total de compras', _valor(totalCompras),
                  negrito: true),
            );
          }

          if (pagamentosOrdenados.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 16));
            blocos.add(
              pw.Text('Pagamentos a funcionários', style: estiloSecao),
            );
            blocos.add(pw.SizedBox(height: 6));
            for (final p in pagamentosOrdenados) {
              blocos.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(p.nome, style: estiloCorpo),
                          ),
                          pw.Text(_valor(p.valor), style: estiloCorpo),
                        ],
                      ),
                      pw.Text(
                        '${_dataHora(p.dataHora)}'
                        '${p.nomeAutor.isNotEmpty ? ' • por ${p.nomeAutor}' : ''}',
                        style: estiloMiudo,
                      ),
                      if (p.descricao.trim().isNotEmpty)
                        pw.Text(
                          p.descricao.trim(),
                          style: estiloMiudo,
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          if (rodape.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 20));
            for (final l in rodape.split('\n')) {
              blocos.add(
                pw.Center(
                  child: pw.Text(l, style: estiloMiudo),
                ),
              );
            }
          }

          return blocos;
        },
      ),
    );

    final bytes = await doc.save();

    final agora = DateTime.now();
    final sufixo =
        '${agora.year}${agora.month.toString().padLeft(2, '0')}'
        '${agora.day.toString().padLeft(2, '0')}_'
        '${agora.hour.toString().padLeft(2, '0')}'
        '${agora.minute.toString().padLeft(2, '0')}';

    const grupo = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final local = await getSaveLocation(
      suggestedName: 'financeiro_$sufixo.pdf',
      acceptedTypeGroups: const [grupo],
    );

    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsBytes(bytes);
    return local.path;
  }

  static Future<String?> exportarExtratoClientePDF({
    required Loja loja,
    required Cliente cliente,
    required List<PedidoLoja> pedidos,
  }) async {
    final doc = pw.Document();

    final estiloTitulo = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloSecao = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloCorpo = const pw.TextStyle(fontSize: 10);
    final estiloNegrito = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final estiloMiudo = const pw.TextStyle(
      fontSize: 8,
      color: PdfColors.grey700,
    );

    double totalComprado = 0;
    double dividaEmAberto = 0;
    for (final p in pedidos) {
      if (p.status != StatusPedido.cancelado) {
        totalComprado += p.valor;
      }
      if (p.aPrazoEmAberto) {
        dividaEmAberto += p.valorRestante;
      }
    }

    final pedidosOrdenados = [...pedidos]
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final blocos = <pw.Widget>[];

          // Cabeçalho da Loja
          blocos.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        loja.nome.isNotEmpty ? loja.nome : 'Comércio',
                        style: estiloTitulo,
                      ),
                      if (loja.cnpj.isNotEmpty)
                        pw.Text('CNPJ: ${loja.cnpj}', style: estiloCorpo),
                      if (loja.telefone.isNotEmpty)
                        pw.Text('Telefone: ${loja.telefone}', style: estiloCorpo),
                      if (loja.endereco.isNotEmpty)
                        pw.Text(
                          '${loja.endereco}, ${loja.numero}',
                          style: estiloCorpo,
                        ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('EXTRATO DE COMPRAS', style: estiloSecao),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Emissão: ${_dataHora(DateTime.now())}',
                      style: estiloMiudo,
                    ),
                    pw.Text('Software Nous', style: estiloMiudo),
                  ],
                ),
              ],
            ),
          );

          blocos.add(pw.SizedBox(height: 12));
          blocos.add(pw.Divider(thickness: 1, color: PdfColors.grey400));
          blocos.add(pw.SizedBox(height: 8));

          // Dados do Cliente & Resumo Financeiro
          blocos.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DADOS DO CLIENTE', style: estiloSecao),
                        pw.SizedBox(height: 4),
                        pw.Text('Nome: ${cliente.nome}', style: estiloNegrito),
                        if (cliente.cnpj.isNotEmpty)
                          pw.Text('Documento: ${cliente.cnpj}', style: estiloCorpo),
                        if (cliente.telefone.isNotEmpty)
                          pw.Text('Telefone: ${cliente.telefone}', style: estiloCorpo),
                        if (cliente.endereco.isNotEmpty)
                          pw.Text(
                            'Endereço: ${cliente.endereco}, ${cliente.numero}',
                            style: estiloCorpo,
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('RESUMO FINANCEIRO', style: estiloSecao),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Total de Compras: ${pedidosOrdenados.length}',
                          style: estiloCorpo,
                        ),
                        pw.Text(
                          'Total Comprado: ${_valor(totalComprado)}',
                          style: estiloCorpo,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Saldo em Aberto (A Prazo): ${_valor(dividaEmAberto)}',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: dividaEmAberto > 0
                                ? PdfColors.red700
                                : PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

          blocos.add(pw.SizedBox(height: 16));
          blocos.add(pw.Text('Histórico de Compras', style: estiloSecao));
          blocos.add(pw.SizedBox(height: 8));

          if (pedidosOrdenados.isEmpty) {
            blocos.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Center(
                  child: pw.Text(
                    'Nenhum pedido registrado para este cliente.',
                    style: estiloCorpo,
                  ),
                ),
              ),
            );
          } else {
            blocos.add(
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'Nº',
                  'Data/Hora',
                  'Itens Consumidos',
                  'Pagamento',
                  'Status',
                  'Valor',
                ],
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FixedColumnWidth(85),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(65),
                },
                data: pedidosOrdenados.map((p) {
                  final itensTexto = p.itens.map((it) {
                    final extras = it.acompanhamentos.isNotEmpty
                        ? ' (+${it.acompanhamentos.map((a) => a.nomeItem).join(', ')})'
                        : '';
                    return '${it.quantidade}x ${it.nomeItem}$extras';
                  }).join('\n');

                  final pagamentosTexto = p.todosPagamentos.isNotEmpty
                      ? p.todosPagamentos
                          .map((pag) => '${pag.forma}: ${_valor(pag.valor)}')
                          .join('\n')
                      : (p.formaPagamento.isNotEmpty
                          ? p.formaPagamento
                          : 'Não inf.');

                  return [
                    _numero(p.numero),
                    _dataHora(p.dataHora),
                    itensTexto.isNotEmpty ? itensTexto : p.produtoNome,
                    pagamentosTexto,
                    _situacao(p.status),
                    _valor(p.valor),
                  ];
                }).toList(),
              ),
            );
          }

          blocos.add(pw.SizedBox(height: 20));
          blocos.add(pw.Divider(thickness: 0.5, color: PdfColors.grey400));
          blocos.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Documento não fiscal para conferência e controle.',
                  style: estiloMiudo,
                ),
                pw.Text(
                  'Nous — Software Universal de Autogestão',
                  style: estiloMiudo,
                ),
              ],
            ),
          );

          return blocos;
        },
      ),
    );

    final bytes = await doc.save();

    final agora = DateTime.now();
    final sufixo =
        '${agora.year}${agora.month.toString().padLeft(2, '0')}'
        '${agora.day.toString().padLeft(2, '0')}_'
        '${agora.hour.toString().padLeft(2, '0')}'
        '${agora.minute.toString().padLeft(2, '0')}';

    final nomeSanitizado = cliente.nome
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    const grupo = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final local = await getSaveLocation(
      suggestedName: 'extrato_${nomeSanitizado}_$sufixo.pdf',
      acceptedTypeGroups: const [grupo],
    );

    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsBytes(bytes);
    return local.path;
  }

  static Future<void> _enviarParaImpressora({
    required Uint8List bytes,
    required String nomeImpressora,
    required String jobName,
    PdfPageFormat? format,
  }) async {
    final formatoFinal = format ?? _papel58mm;
    if (nomeImpressora.isEmpty) {
      await Printing.layoutPdf(
        onLayout: (f) async => bytes,
        name: jobName,
        format: formatoFinal,
      );
      return;
    }

    final printer = Printer(url: nomeImpressora, name: nomeImpressora);
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (f) async => bytes,
      name: jobName,
      format: formatoFinal,
      dynamicLayout: false,
    );
  }
}