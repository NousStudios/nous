import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/configuracoes_impressora.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/estoque_baixa_service.dart';
import 'package:nous/src/features/pdv/services/impressao_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/comanda_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/criar_mesa_dialog.dart';
import 'package:nous/src/features/pdv/views/widgets/mesas/fechar_conta_mesa_dialog.dart';

/// Controlador desacoplado responsável pela gestão de mesas, comandas,
/// transferências e fechamento de contas do salão no PDV.
class GerenciadorMesasLoja {
  final BuildContext Function() obterContext;
  final String lojaId;
  final List<MesaLoja> Function() obterMesas;
  final List<CategoriaLoja> Function() obterCategorias;
  final List<ItemLoja> Function() obterItens;
  final List<GrupoComponentesLoja> Function() obterGrupos;
  final List<Cliente> Function() obterClientes;
  final List<PedidoLoja> Function() obterPedidos;
  final List<MovimentoEstoque> Function() obterMovimentos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final void Function(void Function()) setState;
  final void Function() aoPersistir;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final void Function(Cliente novoCliente) salvarCliente;
  final bool Function() estaMontado;
  final Future<bool> Function({required String titulo, required String mensagem}) confirmarExclusao;
  final String Function(int numero) formatarNumeroPedido;
  final String Function(double valor) formatarValor;
  final String Function(double qtd) formatarQuantidade;

  GerenciadorMesasLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterMesas,
    required this.obterCategorias,
    required this.obterItens,
    required this.obterGrupos,
    required this.obterClientes,
    required this.obterPedidos,
    required this.obterMovimentos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.setState,
    required this.aoPersistir,
    required this.registrarAcao,
    required this.salvarCliente,
    required this.confirmarExclusao,
    required this.formatarNumeroPedido,
    required this.formatarValor,
    required this.formatarQuantidade,
  });

  void abrirComandaMesa(MesaLoja mesa) {
    final context = obterContext();
    final mesas = obterMesas();
    final indice = mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1) return;

    final categorias = obterCategorias();
    final itens = obterItens();
    final grupos = obterGrupos();
    final cpfLogado = obterCpfLogado();
    final nomeLogado = obterNomeLogado();

    ComandaMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesa: mesas[indice],
      categoriasDisponiveis: categorias,
      itensDisponiveis: itens,
      gruposDisponiveis: grupos,
      todasMesas: mesas,
      autorCpf: cpfLogado,
      autorNome: nomeLogado,
      aoAtualizarMesa: (mesaAtualizada) {
        final statusMudou = mesas[indice].status != mesaAtualizada.status;
        final novosItens =
            mesaAtualizada.itens.length > mesas[indice].itens.length;
        final itensRemovidos =
            mesaAtualizada.itens.length < mesas[indice].itens.length;
        final itensAnteriores = mesas[indice].itens;

        setState(() => mesas[indice] = mesaAtualizada);
        aoPersistir();
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarMesa(mesaAtualizada);
        }

        if (statusMudou && mesaAtualizada.status == StatusMesa.ocupada) {
          registrarAcao(
            TipoAcao.mesaAberta,
            'Mesa "${mesaAtualizada.numero}" aberta por $nomeLogado'
            '${mesaAtualizada.clienteNome.isNotEmpty ? " (Cliente: ${mesaAtualizada.clienteNome})" : ""}',
          );
        } else if (statusMudou && mesaAtualizada.status == StatusMesa.livre) {
          registrarAcao(
            TipoAcao.mesaLiberada,
            'Mesa "${mesaAtualizada.numero}" liberada por $nomeLogado',
          );
        } else if (novosItens) {
          final ultimoItem = mesaAtualizada.itens.last;
          registrarAcao(
            TipoAcao.itemAdicionadoMesa,
            'Adicionado ${ultimoItem.item.quantidade}x "${ultimoItem.item.nomeItem}" na Mesa "${mesaAtualizada.numero}" por ${ultimoItem.autorNome}',
          );
        } else if (itensRemovidos) {
          final atuaisIds = mesaAtualizada.itens.map((i) => i.id).toSet();
          final removidos =
              itensAnteriores.where((i) => !atuaisIds.contains(i.id)).toList();
          final itemRemovido = removidos.isNotEmpty ? removidos.first : null;
          final descricao = itemRemovido != null
              ? '${itemRemovido.item.quantidade}x "${itemRemovido.item.nomeItem}"'
              : 'item';
          registrarAcao(
            TipoAcao.itemRemovidoMesa,
            'Removido $descricao da Mesa "${mesaAtualizada.numero}" por $nomeLogado',
          );
        }
      },
      aoFecharConta: (mesaParaFechar) {
        fecharContaMesa(mesaParaFechar);
      },
      aoImprimirConferencia: (mesaConferencia) {
        final lojaAtual =
            context.read<PdvProvider>().buscarPorId(lojaId);
        ImpressaoService.imprimirConferenciaMesa(
          config: lojaAtual?.configuracoesImpressora ??
              const ConfiguracoesImpressora(),
          mesa: mesaConferencia,
          nomeLoja: lojaAtual?.nome ?? 'Restaurante',
        );
      },
      aoTransferirMesa: (mesaOrigem, mesaDestino) {
        transferirMesa(mesaOrigem, mesaDestino);
      },
      aoEditarMesa: () {
        editarMesa(mesa);
      },
    );
  }

  void transferirMesa(MesaLoja origem, MesaLoja destino) {
    final context = obterContext();
    final mesas = obterMesas();
    final idxOrigem = mesas.indexWhere((m) => m.id == origem.id);
    final idxDestino = mesas.indexWhere((m) => m.id == destino.id);
    if (idxOrigem == -1 || idxDestino == -1) return;

    final mesaOrigem = mesas[idxOrigem];
    final mesaDestino = mesas[idxDestino];
    final nomeLogado = obterNomeLogado();

    if (mesaDestino.status == StatusMesa.livre) {
      final destinoAtualizada = mesaDestino.copyWith(
        status: StatusMesa.ocupada,
        clienteNome: mesaOrigem.clienteNome,
        atendenteCpf: mesaOrigem.atendenteCpf,
        atendenteNome: mesaOrigem.atendenteNome,
        dataHoraAbertura: mesaOrigem.dataHoraAbertura ?? DateTime.now(),
        itens: List.of(mesaOrigem.itens),
      );
      final origemLiberada = mesaOrigem.copyWith(
        status: StatusMesa.livre,
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
        itens: const [],
      );

      setState(() {
        mesas[idxDestino] = destinoAtualizada;
        mesas[idxOrigem] = origemLiberada;
      });
      aoPersistir();

      registrarAcao(
        TipoAcao.mesaTransferida,
        'Comanda da Mesa "${origem.numero}" transferida para a Mesa "${destino.numero}" por $nomeLogado',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comanda da Mesa ${origem.numero} transferida com sucesso para a Mesa ${destino.numero}!',
          ),
        ),
      );
    } else {
      final clienteFinal = mesaDestino.clienteNome.isNotEmpty
          ? mesaDestino.clienteNome
          : mesaOrigem.clienteNome;
      final destinoAtualizada = mesaDestino.copyWith(
        clienteNome: clienteFinal,
        itens: [...mesaDestino.itens, ...mesaOrigem.itens],
      );
      final origemLiberada = mesaOrigem.copyWith(
        status: StatusMesa.livre,
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
        itens: const [],
      );

      setState(() {
        mesas[idxDestino] = destinoAtualizada;
        mesas[idxOrigem] = origemLiberada;
      });
      aoPersistir();
      if (ClienteRedeLocal().conectado) {
        ClienteRedeLocal().enviarMesa(destinoAtualizada);
        ClienteRedeLocal().enviarMesa(origemLiberada);
      }

      registrarAcao(
        TipoAcao.mesaTransferida,
        'Comanda da Mesa "${origem.numero}" unificada à Mesa "${destino.numero}" por $nomeLogado',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comanda da Mesa ${origem.numero} unificada à Mesa ${destino.numero}!',
          ),
        ),
      );
    }
  }

  void editarMesa(MesaLoja mesa) {
    final context = obterContext();
    final mesas = obterMesas();
    final indice = mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1) return;

    CriarMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesaExistente: mesas[indice],
      aoSalvar: (mesaEditada) {
        setState(() => mesas[indice] = mesaEditada);
        aoPersistir();
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarMesa(mesaEditada);
        }
      },
      aoExcluir: mesas[indice].status == StatusMesa.livre
          ? () => confirmarExclusaoMesa(mesa)
          : null,
    );
  }

  Future<void> confirmarExclusaoMesa(MesaLoja mesa) async {
    final confirmou = await confirmarExclusao(
      titulo: 'Excluir Mesa',
      mensagem:
          'Tem certeza que deseja excluir a Mesa "${mesa.numero}"? Essa ação não pode ser desfeita.',
    );
    if (!confirmou) return;

    final mesas = obterMesas();
    setState(() => mesas.removeWhere((m) => m.id == mesa.id));
    aoPersistir();
    registrarAcao(
      TipoAcao.mesaExcluida,
      'Mesa "${mesa.numero}" removida do restaurante',
    );
  }

  Future<void> fecharContaMesa(MesaLoja mesa) async {
    final context = obterContext();
    final mesas = obterMesas();
    final indice = mesas.indexWhere((m) => m.id == mesa.id);
    if (indice == -1 || mesa.itens.isEmpty) return;

    final clientes = obterClientes();
    final resultado = await FecharContaMesaDialog.mostrar(
      context,
      theme: ThemeController.currentTheme.value,
      mesa: mesa,
      clientes: clientes,
      onSalvarCliente: (novoCliente) async {
        salvarCliente(novoCliente);
      },
    );

    if (resultado == null || !context.mounted || !estaMontado()) return;

    final lojaAtual = context.read<PdvProvider>().buscarPorId(lojaId);
    final pedidos = obterPedidos();
    final proximoNumero = pedidos.fold<int>(
          0,
          (maior, p) => p.numero > maior ? p.numero : maior,
        ) +
        1;

    final itensVendidos = mesa.itens.map((i) => i.item).toList();
    final totalValor = mesa.totalAcumulado;
    final nomesItens = itensVendidos
        .map((i) => '${i.quantidade}x ${i.nomeItem}')
        .join(', ');

    Cliente? clienteMesa;
    final nomeParaBuscar = (resultado.clienteNome != null &&
            resultado.clienteNome!.trim().isNotEmpty)
        ? resultado.clienteNome!.trim()
        : mesa.clienteNome.trim();
    if (nomeParaBuscar.isNotEmpty) {
      final nomeLimpo = nomeParaBuscar.toLowerCase();
      clienteMesa = clientes.where((c) {
        return c.nome.trim().toLowerCase() == nomeLimpo;
      }).firstOrNull;
    }

    final temPrazoMesa = resultado.pagamentos.any((p) {
      final f = p.forma.trim().toLowerCase();
      return f == 'à prazo' || f == 'a prazo';
    });
    final valorPagoMesa = resultado.pagamentos
        .where((p) {
          final f = p.forma.trim().toLowerCase();
          return f != 'à prazo' && f != 'a prazo';
        })
        .fold<double>(0.0, (s, p) => s + p.valor);
    final valorEntradaMesa = valorPagoMesa > resultado.valorFinal
        ? resultado.valorFinal
        : valorPagoMesa;

    final clienteIdFinal = (resultado.clienteId != null &&
            resultado.clienteId!.isNotEmpty)
        ? resultado.clienteId!
        : (clienteMesa?.id ?? '');
    final clienteNomeFinal = (resultado.clienteNome != null &&
            resultado.clienteNome!.trim().isNotEmpty)
        ? resultado.clienteNome!
        : (mesa.clienteNome.isNotEmpty
            ? mesa.clienteNome
            : 'Mesa ${mesa.numero}');

    final pedido = PedidoLoja(
      id: gerarIdUnico(),
      numero: proximoNumero,
      clienteId: clienteIdFinal,
      clienteNome: clienteNomeFinal,
      produtoNome: nomesItens.isNotEmpty
          ? nomesItens
          : 'Consumo Mesa ${mesa.numero}',
      itens: itensVendidos,
      formaPagamento: resultado.formaPagamento,
      pagamentosExtras: resultado.pagamentos.length > 1
          ? resultado.pagamentos
          : const [],
      desconto: resultado.desconto,
      acrescimo: resultado.acrescimo,
      valor: resultado.valorFinal,
      quitado: !temPrazoMesa || valorEntradaMesa >= resultado.valorFinal,
      valorPago: !temPrazoMesa ? resultado.valorFinal : valorEntradaMesa,
      dataHora: DateTime.now(),
      status: StatusPedido.concluido,
      nomeVendedor: lojaAtual?.nome ?? '',
      cnpjVendedor: lojaAtual?.cnpj ?? '',
      lojaId: lojaId,
      comentario: 'Mesa ${mesa.numero} atendida por ${mesa.atendenteNome}',
    );

    final cpfLogado = obterCpfLogado();
    final nomeLogado = obterNomeLogado();
    final itens = obterItens();
    final novosMovimentos = <MovimentoEstoque>[];

    if (resultado.baixarEstoque) {
      novosMovimentos.addAll(
        EstoqueBaixaService.calcularMovimentosBaixa(
          itensVendidos: itensVendidos,
          itensCadastrados: itens,
          motivo:
              'Consumo Mesa ${mesa.numero} - Pedido #${formatarNumeroPedido(proximoNumero)}',
          cpfAutor: cpfLogado,
          nomeAutor: nomeLogado,
        ),
      );
    }

    final movimentosEstoque = obterMovimentos();

    setState(() {
      pedidos.add(pedido);
      movimentosEstoque.addAll(novosMovimentos);
      mesas[indice] = mesa.copyWith(
        status: StatusMesa.livre,
        itens: const [],
        clienteNome: '',
        atendenteCpf: '',
        atendenteNome: '',
        dataHoraAbertura: null,
      );
    });

    aoPersistir();

    // Sincronização em Rede Wi-Fi
    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarMesa(mesas[indice]);
      ClienteRedeLocal().enviarPedido(pedido);
      for (final m in novosMovimentos) {
        ClienteRedeLocal().enviarMovimentoEstoque(m);
      }
    }
    if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'mesa_atualizada',
        'mesa': mesas[indice].toJson(),
      });
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_adicionado',
        'pedido': pedido.toJson(),
      });
      for (final m in novosMovimentos) {
        ServidorRedeLocal().notificarTodos({
          'tipo': 'estoque_atualizado',
          'movimento': m.toJson(),
        });
      }
    }

    registrarAcao(
      TipoAcao.mesaFechada,
      'Mesa "${mesa.numero}" fechada (${formatarValor(totalValor)} via ${resultado.formaPagamento}) por $nomeLogado',
    );
    registrarAcao(
      TipoAcao.novaVenda,
      'Nova venda #${formatarNumeroPedido(proximoNumero)} da Mesa "${mesa.numero}" (${formatarValor(totalValor)})',
    );
    registrarAcao(
      TipoAcao.pedidoConcluido,
      'Pedido #${formatarNumeroPedido(proximoNumero)} concluído (${formatarValor(totalValor)})',
    );

    for (final mov in novosMovimentos) {
      registrarAcao(
        TipoAcao.movimentoEstoqueRegistrado,
        'Baixa de estoque: ${formatarQuantidade(mov.quantidade)} pelo fechamento da Mesa "${mesa.numero}"',
      );
    }

    if (!context.mounted || !estaMontado()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            ThemeController.currentTheme.value.cardBackgroundColor,
        content: Text(
          'Conta da Mesa ${mesa.numero} fechada com sucesso!',
          style: ThemeController.currentTheme.value.getTextStyle(
            color: ThemeController.currentTheme.value.textColor,
          ),
        ),
      ),
    );
  }
}
