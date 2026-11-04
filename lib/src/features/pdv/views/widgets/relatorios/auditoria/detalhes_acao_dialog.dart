import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHoraCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

String _numeroCurto(int n) => '#${n.toString().padLeft(4, '0')}';

String formatarCpfAuditoria(String cpf) => CpfValidator.formatProtegido(cpf);

/// Modal que exibe os detalhes completos de uma ação registrada na auditoria.
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
                        'CPF: ${formatarCpfAuditoria(acao.cpfAutor)}',
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
