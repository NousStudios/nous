import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

const List<String> kFormasDePagamento = [
  'Pix',
  'Dinheiro',
  'Débito',
  'Crédito',
  'Voucher',
  'À Prazo',
];

/// Utilitários de formatação e salvamento de arquivos PDF para relatórios do PDV.
class PdfFormatacaoUtil {
  static String valor(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  static String numero(int n) => '#${n.toString().padLeft(4, '0')}';

  static String dataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  static String situacao(StatusPedido s) {
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

  static String nomeDoItem(Loja loja, String itemId) {
    for (final i in loja.itensLoja) {
      if (i.id == itemId) {
        return i.nome.isEmpty ? 'Item' : i.nome;
      }
    }
    return 'Item removido';
  }

  static Map<String, double> comprasPorFornecedor(
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

  static List<MapEntry<String, String>> dadosDoCliente(
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
    return linhas;
  }

  /// Exibe diálogo para o usuário selecionar onde salvar e grava os bytes do PDF.
  static Future<String?> salvarArquivoPdf({
    required Uint8List bytes,
    required String nomeSugerido,
  }) async {
    const grupo = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final local = await getSaveLocation(
      suggestedName: nomeSugerido,
      acceptedTypeGroups: const [grupo],
    );

    if (local == null) return null;

    final arquivo = File(local.path);
    await arquivo.writeAsBytes(bytes);
    return local.path;
  }
}
