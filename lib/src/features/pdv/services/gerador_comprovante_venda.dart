import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/modelos_nova_venda.dart';

class GeradorComprovanteVenda {
  static String formatarDoisDigitos(int n) => n.toString().padLeft(2, '0');

  static String formatarDataHora(DateTime d) =>
      '${formatarDoisDigitos(d.day)}/${formatarDoisDigitos(d.month)}/${d.year} '
      '${formatarDoisDigitos(d.hour)}:${formatarDoisDigitos(d.minute)}';

  static String montarComandaTexto({
    required String nomeVendedor,
    required String cnpjVendedor,
    required int numeroPedido,
    required DateTime dataHora,
    required String nomeClienteDigitado,
    required Cliente? clienteSelecionado,
    required bool Function(String campo) deveMostrarCampoCliente,
    required List<LinhaCarrinho> carrinho,
    required String Function(LinhaCarrinho) nomeExibicaoLinha,
    required double Function(LinhaCarrinho) subtotalBaseLinha,
    required ItemLoja? Function(String itemId) buscarItem,
    required double Function(String texto) precoComoNumero,
    required String Function(double valor) valorComVirgula,
    required double subtotalDosItens,
    required double frete,
    required double desconto,
    required String rotuloDesconto,
    required double acrescimo,
    required String rotuloAcrescimo,
    required double total,
    required List<LinhaPagamento> pagamentos,
    required double troco,
  }) {
    const colunas = 40;
    const duplo = '========================================';
    const simples = '----------------------------------------';

    String linhaFormatada(String esquerda, String direita) {
      final espaco = colunas - direita.length;
      if (esquerda.length >= espaco) {
        return '${esquerda.substring(0, espaco - 1)} $direita';
      }
      return '${esquerda.padRight(espaco)}$direita';
    }

    final buffer = StringBuffer();
    buffer.writeln(duplo);
    buffer.writeln(
      nomeVendedor.isEmpty ? 'Nome do vendedor' : nomeVendedor,
    );
    buffer.writeln('CNPJ: $cnpjVendedor');
    buffer.writeln(duplo);
    buffer.writeln('Pedido #${numeroPedido.toString().padLeft(4, '0')}');
    buffer.writeln('Data: ${formatarDataHora(dataHora)}');
    buffer.writeln(simples);
    buffer.writeln('Cliente: ${nomeClienteDigitado.trim()}');

    final c = clienteSelecionado;
    if (c != null) {
      if (deveMostrarCampoCliente('cnpj') && c.cnpj.trim().isNotEmpty) {
        buffer.writeln('CNPJ: ${c.cnpj.trim()}');
      }
      if (deveMostrarCampoCliente('telefone') && c.telefone.trim().isNotEmpty) {
        buffer.writeln('Telefone: ${c.telefone.trim()}');
      }
      if (deveMostrarCampoCliente('endereco')) {
        final endereco = c.endereco.trim();
        final numero = c.numero.trim();
        if (endereco.isNotEmpty) {
          final completo = numero.isEmpty ? endereco : '$endereco, $numero';
          buffer.writeln('Endereco: $completo');
        } else if (numero.isNotEmpty) {
          buffer.writeln('Numero: $numero');
        }
      }
      if (deveMostrarCampoCliente('email') && c.email.trim().isNotEmpty) {
        buffer.writeln('Email: ${c.email.trim()}');
      }
      if (deveMostrarCampoCliente('redesSociais') &&
          c.redesSociais.trim().isNotEmpty) {
        buffer.writeln('Redes sociais: ${c.redesSociais.trim()}');
      }
      if (deveMostrarCampoCliente('descricao') &&
          c.descricao.trim().isNotEmpty) {
        buffer.writeln('Descricao: ${c.descricao.trim()}');
      }
    }
    buffer.writeln(simples);
    buffer.writeln('ITENS');
    buffer.writeln('');

    for (final linhaCarrinho in carrinho) {
      final nome = nomeExibicaoLinha(linhaCarrinho);
      final subtotalBase = subtotalBaseLinha(linhaCarrinho);
      buffer.writeln(
        linhaFormatada(
          '${linhaCarrinho.quantidade}x $nome',
          valorComVirgula(subtotalBase),
        ),
      );
      linhaCarrinho.acompanhamentosPorItemId.forEach((itemId, quantidade) {
        final acompanhamento = buscarItem(itemId);
        if (acompanhamento == null || quantidade <= 0) return;
        final totalAcompanhamento = precoComoNumero(acompanhamento.preco) *
            quantidade *
            linhaCarrinho.quantidade;
        buffer.writeln(
          linhaFormatada(
            '   ${quantidade}x ${acompanhamento.nome} por unidade',
            valorComVirgula(totalAcompanhamento),
          ),
        );
      });
      final obs = linhaCarrinho.observacaoController.text.trim();
      if (obs.isNotEmpty) {
        buffer.writeln('   Obs: $obs');
      }
      buffer.writeln('');
    }

    buffer.writeln(simples);
    buffer.writeln(
      linhaFormatada('Subtotal', valorComVirgula(subtotalDosItens)),
    );
    buffer.writeln(linhaFormatada('Frete', valorComVirgula(frete)));
    if (desconto > 0) {
      buffer.writeln(
        linhaFormatada(rotuloDesconto, '-${valorComVirgula(desconto)}'),
      );
    }
    if (acrescimo > 0) {
      buffer.writeln(linhaFormatada(rotuloAcrescimo, valorComVirgula(acrescimo)));
    }
    buffer.writeln(linhaFormatada('TOTAL', valorComVirgula(total)));
    if (pagamentos.isNotEmpty) {
      buffer.writeln('Pagamentos:');
      for (final p in pagamentos) {
        final v = precoComoNumero(p.controller.text);
        buffer.writeln(
          linhaFormatada('  ${p.forma}', valorComVirgula(v)),
        );
      }
      if (troco > 0) {
        buffer.writeln(linhaFormatada('Troco', valorComVirgula(troco)));
      }
    }
    buffer.writeln(duplo);
    buffer.writeln('linktr.ee/nous72');
    buffer.write(duplo);

    return buffer.toString();
  }
}
