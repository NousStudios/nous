import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_utils.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/venda_registrada_dialog.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _numeroCurto(int n) => '#${n.toString().padLeft(4, '0')}';

String _formatarCpf(String cpf) {
  if (cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
      '${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
}

class AuditoriaRelatorioWidget extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final List<RegistroAcao> acoesOrigem;
  final List<PedidoLoja> pedidos;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<String>? onExcluirPedido;
  final void Function(String pedidoId, DadosComentario dados)?
      onSalvarComentario;
  final void Function(String clienteId)? aoAbrirClientes;

  const AuditoriaRelatorioWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.acoesOrigem,
    required this.pedidos,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onExcluirPedido,
    this.onSalvarComentario,
    this.aoAbrirClientes,
  });

  @override
  State<AuditoriaRelatorioWidget> createState() =>
      _AuditoriaRelatorioWidgetState();
}

class _AuditoriaRelatorioWidgetState extends State<AuditoriaRelatorioWidget> {
  final _buscaAcoesController = TextEditingController();
  final _acoesScrollController = ScrollController();

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _buscaAcoesController.dispose();
    _acoesScrollController.dispose();
    super.dispose();
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  List<RegistroAcao> _acoesFiltradas(List<RegistroAcao> origem) {
    final termo = _buscaAcoesController.text.trim();
    final lista = termo.isEmpty
        ? List.of(origem)
        : origem.where((a) {
            if (TextoUtils.contemIgnorandoAcentos(a.descricao, termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(a.nomeAutor, termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(a.emailAutor, termo)) return true;
            if (a.cpfAutor.contains(termo)) return true;
            if (TextoUtils.contemIgnorandoAcentos(_formatarCpf(a.cpfAutor), termo)) {
              return true;
            }
            if (TextoUtils.contemIgnorandoAcentos(_dataHoraCurta(a.dataHora), termo)) {
              return true;
            }
            return false;
          }).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  void _abrirDetalhesAcao(RegistroAcao acao) {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    final clientes = loja?.clientesLoja ?? const <Cliente>[];

    Cliente? clienteEncontrado;
    final matchAspas = RegExp(r'"([^"]+)"').firstMatch(acao.descricao);
    if (matchAspas != null) {
      final nome = matchAspas.group(1)?.trim().toLowerCase() ?? '';
      clienteEncontrado = clientes
          .where((c) => c.nome.trim().toLowerCase() == nome)
          .firstOrNull;
    }

    PedidoLoja? pedidoEncontrado;
    final matchPedido = RegExp(r'#(\d+)').firstMatch(acao.descricao);
    if (matchPedido != null) {
      final numPed = int.tryParse(matchPedido.group(1)!);
      if (numPed != null) {
        pedidoEncontrado =
            widget.pedidos.where((p) => p.numero == numPed).firstOrNull;
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => DetalhesAcaoDialog(
        theme: theme,
        acao: acao,
        clienteVinculado: clienteEncontrado,
        pedidoVinculado: pedidoEncontrado,
        onAbrirPerfilCliente:
            clienteEncontrado != null && widget.aoAbrirClientes != null
                ? () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    widget.aoAbrirClientes!(clienteEncontrado!.id);
                  }
                : null,
        onAbrirPedido: pedidoEncontrado != null
            ? () {
                Navigator.of(ctx).pop();
                VendaRegistradaDialog.mostrar(
                  context,
                  theme: theme,
                  lojaId: widget.lojaId,
                  pedido: pedidoEncontrado!,
                  autorCpf: widget.autorCpf,
                  autorNome: widget.autorNome,
                  autorEmail: widget.autorEmail,
                  onSalvarComentario: widget.onSalvarComentario != null
                      ? (dados) => widget.onSalvarComentario!(
                            pedidoEncontrado!.id,
                            dados,
                          )
                      : null,
                  onExcluir: widget.onExcluirPedido != null
                      ? () => widget.onExcluirPedido!(pedidoEncontrado!.id)
                      : null,
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acoes = _acoesFiltradas(widget.acoesOrigem);
    final nadaRegistrado = widget.acoesOrigem.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Ações',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          TextField(
            controller: _buscaAcoesController,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: _decoracaoCampo('Pesquisar ações (texto ou data)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (nadaRegistrado)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação registrada ainda.',
            )
          else if (acoes.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhuma ação encontrada.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                controller: _acoesScrollController,
                shrinkWrap: true,
                itemCount: acoes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) => BarraAcaoWidget(
                  theme: theme,
                  acao: acoes[index],
                  onTap: () => _abrirDetalhesAcao(acoes[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BarraAcaoWidget extends StatefulWidget {
  final AppTheme theme;
  final RegistroAcao acao;
  final VoidCallback onTap;

  const BarraAcaoWidget({
    super.key,
    required this.theme,
    required this.acao,
    required this.onTap,
  });

  @override
  State<BarraAcaoWidget> createState() => _BarraAcaoWidgetState();
}

class _BarraAcaoWidgetState extends State<BarraAcaoWidget> {
  bool _hover = false;

  AppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final acao = widget.acao;
    final autorPartes = <String>[
      if (acao.nomeAutor.isNotEmpty) acao.nomeAutor,
      if (acao.cpfAutor.isNotEmpty) _formatarCpf(acao.cpfAutor),
      if (acao.emailAutor.isNotEmpty) acao.emailAutor,
    ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: acao.descricao,
                      textAlign: TextAlign.start,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dataHoraCurta(acao.dataHora),
                      style: theme.getTextStyle(
                        fontSize: 10,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    if (autorPartes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextoRolante(
                        texto: 'por ${autorPartes.join(' • ')}',
                        textAlign: TextAlign.start,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _hover ? theme.textColor : theme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetalhesAcaoDialog extends StatelessWidget {
  final AppTheme theme;
  final RegistroAcao acao;
  final Cliente? clienteVinculado;
  final PedidoLoja? pedidoVinculado;
  final VoidCallback? onAbrirPerfilCliente;
  final VoidCallback? onAbrirPedido;

  const DetalhesAcaoDialog({
    super.key,
    required this.theme,
    required this.acao,
    this.clienteVinculado,
    this.pedidoVinculado,
    this.onAbrirPerfilCliente,
    this.onAbrirPedido,
  });

  String _rotuloTipo(TipoAcao tipo) {
    return switch (tipo) {
      TipoAcao.dadosLojaAtualizados => 'Dados da Loja Atualizados',
      TipoAcao.novaVenda => 'Nova Venda Registrada',
      TipoAcao.pedidoAceito => 'Pedido Aceito',
      TipoAcao.pedidoRecusado => 'Pedido Recusado',
      TipoAcao.pedidoConcluido => 'Pedido Concluído',
      TipoAcao.pedidoCancelado => 'Pedido Cancelado',
      TipoAcao.pedidoExcluido => 'Pedido Excluído',
      TipoAcao.comentarioSalvo => 'Comentário em Pedido',
      TipoAcao.clienteCriado => 'Cliente Cadastrado',
      TipoAcao.clienteAtualizado => 'Cliente Atualizado',
      TipoAcao.clienteExcluido => 'Cliente Excluído',
      TipoAcao.itemCriado => 'Item Criado',
      TipoAcao.itemAtualizado => 'Item Atualizado',
      TipoAcao.itemExcluido => 'Item Excluído',
      TipoAcao.categoriaCriada => 'Categoria Criada',
      TipoAcao.categoriaAtualizada => 'Categoria Atualizada',
      TipoAcao.categoriaExcluida => 'Categoria Excluída',
      TipoAcao.grupoCriado => 'Grupo de Componentes Criado',
      TipoAcao.grupoAtualizado => 'Grupo Atualizado',
      TipoAcao.grupoExcluido => 'Grupo Excluído',
      TipoAcao.lojaExcluida => 'Perfil / Loja Excluída',
      TipoAcao.membroAdicionado => 'Membro Adicionado',
      TipoAcao.membroRemovido => 'Membro Removido',
      TipoAcao.papelAlterado => 'Papel de Membro Alterado',
      TipoAcao.conviteEnviado => 'Convite Enviado',
      TipoAcao.pagamentoPrazoRecebido => 'Pagamento de Fiado Recebido',
      TipoAcao.itemVinculadoCategoria => 'Item Vinculado à Categoria',
      TipoAcao.itemDesvinculadoCategoria => 'Item Desvinculado',
      TipoAcao.itemVinculadoGrupo => 'Item Vinculado ao Grupo',
      TipoAcao.itemDesvinculadoGrupo => 'Item Desvinculado',
      TipoAcao.movimentoEstoqueRegistrado => 'Movimento de Estoque',
      TipoAcao.movimentoEstoqueRemovido => 'Estorno de Estoque',
      TipoAcao.pagamentoFuncionarioRegistrado => 'Pagamento Registrado',
      TipoAcao.pagamentoFuncionarioRemovido => 'Pagamento Removido',
      TipoAcao.mesaCriada => 'Mesa Criada',
      TipoAcao.mesaExcluida => 'Mesa Excluída',
      TipoAcao.mesaAberta => 'Mesa Aberta',
      TipoAcao.itemAdicionadoMesa => 'Item Adicionado à Mesa',
      TipoAcao.itemRemovidoMesa => 'Item Removido da Mesa',
      TipoAcao.mesaFechada => 'Mesa Fechada',
      TipoAcao.mesaLiberada => 'Mesa Liberada',
      TipoAcao.mesaTransferida => 'Mesa Transferida',
      TipoAcao.caixaAberto => 'Abertura de Caixa',
      TipoAcao.caixaFechado => 'Fechamento de Caixa',
      TipoAcao.sangriaRegistrada => 'Sangria de Caixa',
      TipoAcao.suprimentoRegistrado => 'Suprimento de Caixa',
      TipoAcao.turnoCaixaExcluido => 'Turno de Caixa Excluído',
      TipoAcao.transacoesResetadas => 'Transações da Loja Resetadas',
    };
  }

  IconData _iconeTipo(TipoAcao tipo) {
    return switch (tipo) {
      TipoAcao.clienteCriado ||
      TipoAcao.clienteAtualizado ||
      TipoAcao.clienteExcluido ||
      TipoAcao.pagamentoPrazoRecebido =>
        Icons.person_outline,
      TipoAcao.novaVenda ||
      TipoAcao.pedidoAceito ||
      TipoAcao.pedidoConcluido ||
      TipoAcao.pedidoCancelado ||
      TipoAcao.pedidoExcluido ||
      TipoAcao.pedidoRecusado ||
      TipoAcao.comentarioSalvo =>
        Icons.receipt_long_outlined,
      TipoAcao.caixaAberto ||
      TipoAcao.caixaFechado ||
      TipoAcao.sangriaRegistrada ||
      TipoAcao.suprimentoRegistrado ||
      TipoAcao.turnoCaixaExcluido =>
        Icons.point_of_sale_outlined,
      TipoAcao.itemCriado ||
      TipoAcao.itemAtualizado ||
      TipoAcao.itemExcluido ||
      TipoAcao.movimentoEstoqueRegistrado ||
      TipoAcao.movimentoEstoqueRemovido =>
        Icons.inventory_2_outlined,
      TipoAcao.mesaCriada ||
      TipoAcao.mesaAberta ||
      TipoAcao.itemAdicionadoMesa ||
      TipoAcao.itemRemovidoMesa ||
      TipoAcao.mesaFechada ||
      TipoAcao.mesaLiberada ||
      TipoAcao.mesaTransferida ||
      TipoAcao.mesaExcluida =>
        Icons.table_restaurant_outlined,
      _ => Icons.history_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconeTipo(acao.tipo), color: theme.textColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Detalhes da Ação',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            _rotuloTipo(acao.tipo),
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _dataHoraCurta(acao.dataHora),
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Descrição:',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acao.descricao,
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: theme.borderColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'Autor do Registro:',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      acao.nomeAutor.isNotEmpty
                          ? acao.nomeAutor
                          : 'Usuário do Sistema',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (acao.cpfAutor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'CPF: ${_formatarCpf(acao.cpfAutor)}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                    if (acao.emailAutor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'E-mail: ${acao.emailAutor}',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (onAbrirPerfilCliente != null && clienteVinculado != null) ...[
                OutlinedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.borderColor.withValues(alpha: 0.18);
                      }
                      return theme.buttonColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    iconColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: theme.textColor, width: 1.4);
                      }
                      return BorderSide(color: theme.borderColor, width: 1.0);
                    }),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    mouseCursor: const WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                  ),
                  onPressed: onAbrirPerfilCliente,
                  icon: const Icon(Icons.person, size: 16),
                  label: Text(
                    'Ver Perfil de "${clienteVinculado!.nome}"',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (onAbrirPedido != null && pedidoVinculado != null) ...[
                OutlinedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.borderColor.withValues(alpha: 0.18);
                      }
                      return theme.buttonColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    iconColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return theme.textColor;
                      }
                      return theme.buttonTextColor;
                    }),
                    side: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return BorderSide(color: theme.textColor, width: 1.4);
                      }
                      return BorderSide(color: theme.borderColor, width: 1.0);
                    }),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    mouseCursor: const WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                  ),
                  onPressed: onAbrirPedido,
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: Text(
                    'Ver Comanda do Pedido #${_numeroCurto(pedidoVinculado!.numero)}',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (acao.tipo == TipoAcao.pedidoExcluido ||
                  acao.tipo == TipoAcao.clienteExcluido ||
                  acao.tipo == TipoAcao.itemExcluido) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.borderColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registro original arquivado no log histórico da autogestão.',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return theme.borderColor.withValues(alpha: 0.18);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return theme.textColor;
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return BorderSide(color: theme.textColor, width: 1.4);
                    }
                    return BorderSide(color: theme.borderColor, width: 1.0);
                  }),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 11),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  mouseCursor: const WidgetStatePropertyAll(
                    SystemMouseCursors.click,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fechar', style: theme.getTextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
