import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/core/services/gerador_id.dart';
import 'package:nous/src/core/services/relogio_rede_service.dart';
import 'package:nous/src/core/services/som_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/chat/controllers/mensageria_controller.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/lojas_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';

/// Serviço desacoplado responsável pela orquestração do Autoatendimento no Chat:
/// catálogo, pedidos diretos para o balcão da loja e gestão de ficha do cliente.
class ChatAutoatendimentoService {
  ChatAutoatendimentoService._();

  /// Resolve a Loja alvo do autoatendimento localizando no PdvProvider,
  /// na loja sincronizada da rede local, no SQLite local ou via HTTP no Balcão.
  static Future<Loja?> obterLojaCatalogo({
    required String lojaIdBruto,
    required PdvProvider pdv,
  }) async {
    final idLimpo = PdvProvider.normalizarIdLoja(lojaIdBruto);
    Loja? loja = pdv.buscarPorId(idLimpo);

    final clienteRede = ClienteRedeLocal();
    if (loja == null &&
        clienteRede.lojaSincronizada != null &&
        PdvProvider.normalizarIdLoja(clienteRede.lojaSincronizada!.id) == idLimpo) {
      loja = clienteRede.lojaSincronizada;
    }

    loja ??= await LojasService.carregarLojaPorId(idLimpo);

    // Se conectado na rede local (ou com IP conhecido do balcão), busca versão fresca do catálogo se necessário
    if (loja == null || (loja.itensLoja.isEmpty && loja.categoriasLoja.isEmpty)) {
      String? ip = clienteRede.ipServidor;
      int porta = clienteRede.portaServidor ?? ServidorRedeLocal.portaPadraoHttp;
      if (ip == null && clienteRede.lojasEncontradas.value.isNotEmpty) {
        final daLoja = clienteRede.lojasEncontradas.value
            .where((d) => PdvProvider.normalizarIdLoja(d.lojaId) == idLimpo)
            .firstOrNull;
        final alvo = daLoja ?? clienteRede.lojasEncontradas.value.first;
        ip = alvo.ip;
        porta = alvo.porta;
      }
      if (ip == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          ip = prefs.getString('nous_ultimo_ip_balcao');
          porta = prefs.getInt('nous_ultima_porta_balcao') ??
              ServidorRedeLocal.portaPadraoHttp;
        } catch (_) {}
      }
      if (ip != null && ip.isNotEmpty) {
        try {
          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 4);
          final uri = Uri.http('$ip:$porta', '/api/loja', {'lojaId': idLimpo});
          final req = await client.getUrl(uri);
          final resp = await req.close();
          if (resp.statusCode == HttpStatus.ok) {
            final body = await utf8.decodeStream(resp);
            final dados = jsonDecode(body) as Map<String, dynamic>;
            if (dados['loja'] is Map<String, dynamic>) {
              final lojaRemota = Loja.fromJson(
                dados['loja'] as Map<String, dynamic>,
              );
              await LojasService.salvarLojaIndividual(lojaRemota);
              await pdv.adicionarOuAtualizarLoja(lojaRemota);
              loja = lojaRemota;
            }
          }
        } catch (e) {
          debugPrint('[ChatAutoatendimento] Falha ao buscar catálogo remoto: $e');
        }
      }
    }

    if (loja == null && pdv.lojas.isNotEmpty) {
      loja = pdv.lojas
          .where((l) => l.id != PdvProvider.idLojaColetivaNous)
          .firstOrNull;
    }
    return loja;
  }

  /// Localiza ou cria a ficha de cliente na loja de forma inteligente sem duplicação
  static Future<Cliente> resolverOuCriarFichaCliente({
    required Loja loja,
    required UsuarioNous usuario,
    required PdvProvider pdv,
  }) async {
    final meuCpf = ChatService.normalizarCpf(usuario.cpf);
    final meuNome = usuario.nomeExibicao.trim().isNotEmpty
        ? usuario.nomeExibicao.trim()
        : (usuario.nome.trim().isNotEmpty ? usuario.nome.trim() : 'Cliente Nous');

    // 1. Busca por CPF normalizado
    if (meuCpf.isNotEmpty && meuCpf.length == 11) {
      final porCpf = loja.clientesLoja.where((c) {
        final cCpf = ChatService.normalizarCpf(c.cnpj);
        return cCpf.isNotEmpty && cCpf == meuCpf;
      }).firstOrNull;

      if (porCpf != null) {
        return porCpf;
      }
    }

    // 2. Busca por Nome idêntico (insensível a maiúsculas)
    final porNome = loja.clientesLoja.where((c) {
      return c.nome.trim().toLowerCase() == meuNome.toLowerCase();
    }).firstOrNull;

    if (porNome != null) {
      return porNome;
    }

    // 3. Se não existe, cria ficha nova automaticamente vinculada aos dados do cidadão
    final novoCliente = Cliente(
      id: gerarIdUnico(),
      nome: meuNome,
      cnpj: usuario.cpf,
      telefone: '',
      endereco: '',
      numero: '',
      email: usuario.emails.isNotEmpty ? usuario.emails.first : '',
      foto: usuario.fotoExibicao,
      descricao: 'Cliente cadastrado via Autoatendimento no Chat',
    );

    final clientesAtualizados = List<Cliente>.from(loja.clientesLoja)
      ..add(novoCliente);
    final lojaAtualizada = loja.copyWith(clientesLoja: clientesAtualizados);
    await pdv.adicionarOuAtualizarLoja(lojaAtualizada);

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarEventoWs({
        'tipo': 'cliente_atualizado',
        'lojaId': loja.id,
        'cliente': novoCliente.toJson(),
      });
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'cliente_atualizado',
        'lojaId': loja.id,
        'cliente': novoCliente.toJson(),
      });
    }

    return novoCliente;
  }

  /// Atualiza os dados cadastrais da ficha de cliente na loja (sem alterar dados financeiros)
  static Future<void> atualizarFichaCliente({
    required String lojaId,
    required Cliente clienteAtualizado,
    required PdvProvider pdv,
  }) async {
    final loja = await obterLojaCatalogo(lojaIdBruto: lojaId, pdv: pdv);
    if (loja == null) return;

    final clientes = List<Cliente>.from(loja.clientesLoja);
    final idx = clientes.indexWhere((c) => c.id == clienteAtualizado.id);
    final Cliente consolidado;
    if (idx != -1) {
      final antigo = clientes[idx];
      consolidado = clienteAtualizado.copyWith(
        fretePadrao: antigo.fretePadrao,
      );
      clientes[idx] = consolidado;
    } else {
      consolidado = clienteAtualizado;
      clientes.add(consolidado);
    }

    final lojaSalva = loja.copyWith(clientesLoja: clientes);
    await pdv.adicionarOuAtualizarLoja(lojaSalva);

    if (ClienteRedeLocal().conectado) {
      ClienteRedeLocal().enviarEventoWs({
        'tipo': 'cliente_atualizado',
        'lojaId': loja.id,
        'cliente': consolidado.toJson(),
      });
    } else if (ServidorRedeLocal().ativo) {
      ServidorRedeLocal().notificarTodos({
        'tipo': 'cliente_atualizado',
        'lojaId': loja.id,
        'cliente': consolidado.toJson(),
      });
    }
  }

  /// Envia um novo pedido de autoatendimento direto para a aba 'Novos' da loja e para o chat
  static Future<PedidoLoja> enviarPedidoAutoatendimento({
    required BuildContext context,
    required String lojaId,
    required List<ItemVendido> carrinho,
    required String observacaoGeral,
    required String formaPagamento,
    required MensageriaController controller,
  }) async {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final loja = await obterLojaCatalogo(lojaIdBruto: lojaId, pdv: pdv);

    if (loja == null) {
      throw Exception('Loja não encontrada para envio do pedido.');
    }

    final usuario = auth.contaAtual ??
        UsuarioNous(
          cpf: auth.cpf,
          nome: auth.contaAtual?.nome ?? 'Cliente',
          dataNascimento: '',
        );

    // 1. Resolve ou cria ficha do cliente sem duplicações
    final cliente = await resolverOuCriarFichaCliente(
      loja: loja,
      usuario: usuario,
      pdv: pdv,
    );

    // 2. Calcula total e monta comanda
    final agora = RelogioRedeService.agora();
    double total = 0.0;
    final bufferComanda = StringBuffer();
    bufferComanda.writeln('📋 *PEDIDO DE AUTOATENDIMENTO (CHAT)*');
    bufferComanda.writeln(
      '⏰ Data/Hora: ${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}',
    );
    bufferComanda.writeln('👤 Cliente: ${cliente.nome}');
    if (cliente.telefone.isNotEmpty) {
      bufferComanda.writeln('📞 Tel: ${cliente.telefone}');
    }
    if (cliente.endereco.isNotEmpty) {
      bufferComanda.writeln(
        '📍 Entrega: ${cliente.endereco}${cliente.numero.isNotEmpty ? ', Nº ${cliente.numero}' : ''}',
      );
    }
    bufferComanda.writeln('--------------------------------');

    for (final item in carrinho) {
      final subtotal = item.subtotal;
      total += subtotal;
      bufferComanda.writeln(
        '${item.quantidade}x ${item.nomeExibicao} - R\$ ${subtotal.toStringAsFixed(2)}',
      );
      for (final comp in item.acompanhamentos) {
        final qtdStr = comp.quantidadePorUnidade > 1
            ? '${comp.quantidadePorUnidade}x '
            : '';
        bufferComanda.writeln(
          '   + $qtdStr${comp.nomeItem}${comp.precoItem > 0 ? ' (R\$ ${(comp.precoItem * comp.quantidadePorUnidade).toStringAsFixed(2)})' : ''}',
        );
      }
      if (item.observacao.trim().isNotEmpty) {
        bufferComanda.writeln('   Obs: ${item.observacao.trim()}');
      }
    }

    bufferComanda.writeln('--------------------------------');
    bufferComanda.writeln('💰 TOTAL: R\$ ${total.toStringAsFixed(2)}');
    bufferComanda.writeln(
      '💳 Pagamento: ${formaPagamento.trim().isNotEmpty ? formaPagamento.trim() : 'A combinar no chat'}',
    );
    if (observacaoGeral.trim().isNotEmpty) {
      bufferComanda.writeln('📝 Observações: ${observacaoGeral.trim()}');
    }

    final resumoItens = carrinho
        .map((i) => '${i.quantidade}x ${i.nomeExibicao}')
        .join(', ');
    final proximoNumero = (loja.pedidosLoja.isNotEmpty
            ? loja.pedidosLoja
                .map((p) => p.numero)
                .reduce((a, b) => a > b ? a : b)
            : 0) +
        1;

    // 3. Monta entidade soberana do pedido com status "novo" (cai na aba "Novos")
    final pedido = PedidoLoja(
      id: agora.millisecondsSinceEpoch.toString(),
      numero: proximoNumero,
      clienteId: cliente.id,
      clienteNome: cliente.nome,
      produtoNome: resumoItens,
      dataHora: agora,
      valor: total,
      status: StatusPedido.novo,
      comanda: bufferComanda.toString(),
      formaPagamento: formaPagamento.trim().isNotEmpty
          ? formaPagamento.trim()
          : 'Autoatendimento no Chat',
      pagamentosExtras: const [],
      valorRecebido: 0.0,
      troco: 0.0,
      quitado: false,
      valorPago: 0.0,
      itens: List.of(carrinho),
      nomeVendedor: loja.nome,
      cnpjVendedor: loja.cnpj,
      lojaId: loja.id,
    );

    // 4. Persiste localmente e despacha na rede local (WebSocket + REST) para cair em "Novos"
    final lojaAtual = pdv.buscarPorId(loja.id) ?? loja;
    final pedidosAtualizados = List<PedidoLoja>.from(lojaAtual.pedidosLoja)
      ..insert(0, pedido);
    await pdv.adicionarOuAtualizarLoja(
      lojaAtual.copyWith(pedidosLoja: pedidosAtualizados),
    );

    if (ServidorRedeLocal().ativo) {
      SomService.tocarEvento(SomService.eventoNovoPedido, loja: lojaAtual);
      ServidorRedeLocal().notificarTodos({
        'tipo': 'pedido_adicionado',
        'lojaId': loja.id,
        'pedido': pedido.toJson(),
      });
    } else {
      final clienteRede = ClienteRedeLocal();
      if (clienteRede.conectado) {
        clienteRede.enviarEventoWs({
          'tipo': 'pedido_adicionado',
          'lojaId': loja.id,
          'pedido': pedido.toJson(),
        });
      }
      await clienteRede.enviarPedido(pedido);
    }

    // 5. Envia comanda estruturada no Chat para reflexo instantâneo no histórico
    final payloadPedidoJson = jsonEncode(pedido.toJson());
    await controller.enviarMensagem(
      texto:
          'Novo pedido de autoatendimento #${pedido.numero.toString().padLeft(4, '0')} • R\$ ${pedido.valor.toStringAsFixed(2)}',
      tipo: 'comanda',
      caminhoAnexo: '',
      nomeAnexo: 'Pedido #${pedido.numero.toString().padLeft(4, '0')}',
      tamanhoAnexo: 0,
      pedidoId: pedido.id,
      dadosPedidoJson: payloadPedidoJson,
      auth: auth,
    );

    return pedido;
  }
}
