import 'package:pdf/widgets.dart' as pw;
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/services/impressao/impressao_utils.dart';

class GeradorBobinaFinanceiro {
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

    final entradasPorForma = <String, double>{
      for (final f in kFormasDePagamentoImpressao) f: 0.0,
    };
    for (final p in vendas) {
      for (final pag in p.todosPagamentos) {
        final ehPrazo = pag.forma.trim().toLowerCase() == 'à prazo' ||
            pag.forma.trim().toLowerCase() == 'a prazo' ||
            pag.forma.toLowerCase().contains('prazo');
        final chave = ehPrazo ? 'À Prazo' : pag.forma;
        entradasPorForma[chave] =
            (entradasPorForma[chave] ?? 0) + pag.valor;
      }
    }

    double totalEntradas = 0;
    for (final v in entradasPorForma.values) {
      totalEntradas += v;
    }
    double totalAReceber = 0;
    for (final p in pedidosAceitos) {
      totalAReceber += p.valor;
    }
    for (final p in vendas) {
      if (p.aPrazoEmAberto) {
        totalAReceber += p.valorRestante;
      }
    }
    double totalPagamentos = 0;
    for (final p in pagamentos) {
      totalPagamentos += p.valor;
    }
    final totalSaidas =
        totalPagamentos + (contarEstoque ? saidaEstoque : 0);
    final saldo = totalEntradas - totalSaidas;

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
      pw.Page(
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
                'Emitido: ${ImpressaoUtils.dataHora(DateTime.now())}',
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
          for (final forma in kFormasDePagamentoImpressao) {
            blocos.add(
              linhaDupla(
                  forma, ImpressaoUtils.valor(entradasPorForma[forma] ?? 0)),
            );
          }
          blocos.add(
            linhaDupla(
                'Total', ImpressaoUtils.valor(totalEntradas), negrito: true),
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
                  '${ImpressaoUtils.numero(v.numero)} ${v.clienteNome}',
                  ImpressaoUtils.valor(v.valor),
                ),
              );
              final formas = v.todosPagamentos
                  .map((p) => p.forma)
                  .where((f) => f.isNotEmpty)
                  .join(' + ');
              final detalhe = '${ImpressaoUtils.dataHora(v.dataHora)}'
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
              ImpressaoUtils.valor(totalPagamentos),
            ),
          );
          if (contarEstoque) {
            blocos.add(
              linhaDupla('Custo de estoque',
                  ImpressaoUtils.valor(saidaEstoque)),
            );
          }
          blocos.add(
            linhaDupla('Total', ImpressaoUtils.valor(totalSaidas),
                negrito: true),
          );

          blocos.add(pw.SizedBox(height: 6));
          blocos.add(pw.Divider());
          blocos.add(
            linhaDupla('SALDO', ImpressaoUtils.valor(saldo), negrito: true),
          );
          if (pedidosAceitos.isNotEmpty) {
            blocos.add(pw.SizedBox(height: 3));
            blocos.add(
              linhaDupla(
                'A receber (${pedidosAceitos.length})',
                ImpressaoUtils.valor(totalAReceber),
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
                  ? ' • ${ImpressaoUtils.valor(m.custoUnitario)}/un'
                  : '';
              blocos.add(
                linhaDupla(
                  '$sinal${m.quantidade}x $nome$sufixoCusto',
                  ImpressaoUtils.valor(m.custoTotal),
                ),
              );
              final sufixoFornecedor = m.fornecedorNome.isNotEmpty
                  ? ' • ${m.fornecedorNome}'
                  : '';
              final detalhe = '${ImpressaoUtils.dataHora(m.dataHora)}'
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
              blocos.add(
                  linhaDupla(e.key, ImpressaoUtils.valor(e.value)));
            }
            blocos.add(
              linhaDupla('Total', ImpressaoUtils.valor(totalCompras),
                  negrito: true),
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
              blocos.add(
                  linhaDupla(p.nome, ImpressaoUtils.valor(p.valor)));
              final detalhe = '${ImpressaoUtils.dataHora(p.dataHora)}'
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

          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: blocos,
          );
        },
      ),
    );

    final bytes = await doc.save();
    await ImpressaoUtils.enviarParaImpressora(
      bytes: bytes,
      nomeImpressora: config.nomeImpressora,
      jobName: 'FinanceiroNous-${DateTime.now().millisecondsSinceEpoch}',
      format: ImpressaoUtils.formatoResolvidoDoDocumento(doc, pageFormat),
    );
  }
}
