import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

class GerenciadorClientesFornecedoresLoja {
  final BuildContext Function() obterContext;
  final bool Function() estaMontado;
  final String lojaId;
  final List<Cliente> Function() obterClientes;
  final List<Fornecedor> Function() obterFornecedores;
  final List<PedidoLoja> Function() obterPedidos;
  final String Function() obterCpfLogado;
  final String Function() obterNomeLogado;
  final bool Function() podeEditarAbaLoja;
  final VoidCallback avisarSemPermissao;
  final void Function(void Function()) setState;
  final VoidCallback persistirListasLoja;
  final void Function(TipoAcao tipo, String descricao) registrarAcao;
  final String Function(double valor) formatarValor;

  const GerenciadorClientesFornecedoresLoja({
    required this.obterContext,
    required this.estaMontado,
    required this.lojaId,
    required this.obterClientes,
    required this.obterFornecedores,
    required this.obterPedidos,
    required this.obterCpfLogado,
    required this.obterNomeLogado,
    required this.podeEditarAbaLoja,
    required this.avisarSemPermissao,
    required this.setState,
    required this.persistirListasLoja,
    required this.registrarAcao,
    required this.formatarValor,
  });

  void salvarCliente(Cliente cliente) {
    final clientes = obterClientes();
    final existia = clientes.any((c) => c.id == cliente.id);

    setState(() {
      final indice = clientes.indexWhere((c) => c.id == cliente.id);
      if (indice == -1) {
        clientes.add(cliente);
      } else {
        clientes[indice] = cliente;
      }
    });
    persistirListasLoja();

    final context = obterContext();
    final cpfDigitos = obterCpfLogado().replaceAll(RegExp(r'[^0-9]'), '');
    final clienteDigitos = cliente.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpfDigitos.isNotEmpty &&
        cpfDigitos == clienteDigitos &&
        cliente.foto.isNotEmpty) {
      context.read<AuthProvider>().atualizarFoto(cliente.foto);
    }

    registrarAcao(
      existia ? TipoAcao.clienteAtualizado : TipoAcao.clienteCriado,
      existia
          ? 'Cliente "${cliente.nome}" atualizado'
          : 'Cliente "${cliente.nome}" cadastrado',
    );
  }

  void pagarCliente(String clienteId, double valor, String formaPagamento) {
    final clientes = obterClientes();
    final pedidos = obterPedidos();
    final indiceCliente = clientes.indexWhere((c) => c.id == clienteId);
    final nomeCliente =
        indiceCliente == -1 ? '' : clientes[indiceCliente].nome;

    final anterioresPorId = <String, PedidoLoja>{
      for (final p in pedidos) p.id: p,
    };

    final atualizados = aplicarPagamentoAPrazo(
      pedidos,
      clienteId,
      valor,
      clienteNome: nomeCliente.isNotEmpty ? nomeCliente : null,
    );
    setState(() {
      pedidos
        ..clear()
        ..addAll(atualizados);
    });

    final context = obterContext();
    if (formaPagamento.trim().toLowerCase() == 'dinheiro') {
      context.read<PdvProvider>().registrarMovimentoCaixa(
            lojaId,
            tipo: TipoMovimentoCaixa.suprimento,
            valor: valor,
            motivo: 'Recebimento de fiado - $nomeCliente',
            cpf: obterCpfLogado(),
            nome: obterNomeLogado(),
          );
    }

    persistirListasLoja();

    for (final p in atualizados) {
      final anterior = anterioresPorId[p.id];
      if (anterior != null &&
          (anterior.quitado != p.quitado ||
              (anterior.valorPago - p.valorPago).abs() > 0.001)) {
        if (ClienteRedeLocal().conectado) {
          ClienteRedeLocal().enviarPedido(p);
        }
        if (ServidorRedeLocal().ativo) {
          ServidorRedeLocal().notificarTodos({
            'tipo': 'pedido_atualizado',
            'lojaId': lojaId,
            'pedido': p.toJson(),
          });
        }
      }
    }

    registrarAcao(
      TipoAcao.pagamentoPrazoRecebido,
      'Pagamento à prazo recebido ($formaPagamento) de "$nomeCliente" '
          '(${formatarValor(valor)})',
    );
  }

  void excluirCliente(String clienteId) {
    final clientes = obterClientes();
    final indice = clientes.indexWhere((c) => c.id == clienteId);
    final nome = indice == -1 ? '' : clientes[indice].nome;

    setState(() => clientes.removeWhere((c) => c.id == clienteId));
    persistirListasLoja();

    registrarAcao(
      TipoAcao.clienteExcluido,
      'Cliente "$nome" excluído',
    );
  }

  void salvarFornecedor(Fornecedor fornecedor) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final fornecedores = obterFornecedores();
    final existia = fornecedores.any((f) => f.id == fornecedor.id);

    setState(() {
      final indice =
          fornecedores.indexWhere((f) => f.id == fornecedor.id);
      if (indice == -1) {
        fornecedores.add(fornecedor);
      } else {
        fornecedores[indice] = fornecedor;
      }
    });
    persistirListasLoja();

    registrarAcao(
      TipoAcao.dadosLojaAtualizados,
      existia
          ? 'Fornecedor "${fornecedor.nome}" atualizado'
          : 'Fornecedor "${fornecedor.nome}" cadastrado',
    );
  }

  void excluirFornecedor(String fornecedorId) {
    if (!podeEditarAbaLoja()) {
      avisarSemPermissao();
      return;
    }

    final fornecedores = obterFornecedores();
    final indice = fornecedores.indexWhere((f) => f.id == fornecedorId);
    final nome = indice == -1 ? '' : fornecedores[indice].nome;

    setState(() => fornecedores.removeWhere((f) => f.id == fornecedorId));
    persistirListasLoja();

    registrarAcao(
      TipoAcao.dadosLojaAtualizados,
      'Fornecedor "$nome" excluído',
    );
  }
}
