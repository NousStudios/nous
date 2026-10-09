import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _rotuloPapel(PapelMembro papel) {
  switch (papel) {
    case PapelMembro.dono:
      return 'Dono';
    case PapelMembro.socio:
      return 'Sócio';
    case PapelMembro.admin:
      return 'Admin';
    case PapelMembro.funcionario:
      return 'Funcionário';
  }
}

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

class StatusLojaView extends StatefulWidget {
  final String lojaId;
  final bool lojaOnlineInicial;
  final ValueChanged<bool> aoAlterarOnline;
  final List<MembroLoja> membros;
  final String cpfLogado;
  final bool podeSair;
  final VoidCallback onSair;

  const StatusLojaView({
    super.key,
    required this.lojaId,
    required this.lojaOnlineInicial,
    required this.aoAlterarOnline,
    required this.membros,
    required this.cpfLogado,
    required this.podeSair,
    required this.onSair,
  });

  @override
  State<StatusLojaView> createState() => _StatusLojaViewState();
}

class _StatusLojaViewState extends State<StatusLojaView> {
  late bool _online;

  @override
  void initState() {
    super.initState();
    _online = widget.lojaOnlineInicial;
  }

  void _alternarOnline(bool valor) {
    setState(() => _online = valor);
    widget.aoAlterarOnline(valor);
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(AppTheme theme, String texto) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: theme.getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  void _confirmarSaida() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = ThemeController.currentTheme.value;
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Sair da loja',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Tem certeza que deseja sair desta loja?',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onSair();
              },
              child: Text(
                'Sair',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _itemMetrica({
    required AppTheme theme,
    required IconData icone,
    required String rotulo,
    required String valor,
    bool destaque = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destaque
              ? theme.textColor.withValues(alpha: 0.35)
              : theme.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 14, color: theme.secondaryTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoResumoDoDia(AppTheme theme) {
    final pdv = context.watch<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);
    if (loja == null) return const SizedBox.shrink();

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final pedidosHoje = loja.pedidosLoja.where((p) {
      if (p.status == StatusPedido.cancelado) return false;
      final dataPedido =
          DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day);
      return dataPedido == hoje;
    }).toList();

    final totalVendasHoje = pedidosHoje.length;
    final faturamentoHoje = pedidosHoje.fold<double>(
      0.0,
      (soma, p) => soma + p.valor,
    );
    final ticketMedio =
        totalVendasHoje == 0 ? 0.0 : faturamentoHoje / totalVendasHoje;

    // Situação do caixa e saldo em dinheiro
    final turnoAberto = loja.turnosCaixa.where((t) => t.aberto).firstOrNull;
    final caixaAberto = turnoAberto != null;

    double saldoEmDinheiro = 0.0;
    if (turnoAberto != null) {
      double vendasDinheiroTurno = 0.0;
      for (final p in loja.pedidosLoja) {
        if (p.status == StatusPedido.cancelado) continue;
        if (p.dataHora.isAfter(turnoAberto.dataAbertura) ||
            p.dataHora.isAtSameMomentAs(turnoAberto.dataAbertura)) {
          for (final pag in p.todosPagamentos) {
            if (pag.forma.toLowerCase() == 'dinheiro') {
              vendasDinheiroTurno += pag.valor;
            }
          }
          vendasDinheiroTurno -= p.troco;
        }
      }
      saldoEmDinheiro = turnoAberto.saldoInicial +
          turnoAberto.totalSuprimentos -
          turnoAberto.totalSangrias +
          vendasDinheiroTurno;
      if (saldoEmDinheiro < 0) saldoEmDinheiro = 0.0;
    } else {
      final ultimoTurno =
          loja.turnosCaixa.isNotEmpty ? loja.turnosCaixa.last : null;
      if (ultimoTurno != null && ultimoTurno.saldoFinalInformado != null) {
        saldoEmDinheiro = ultimoTurno.saldoFinalInformado!;
      }
    }

    String moeda(double v) =>
        'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_outlined, size: 20, color: theme.textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumo Operacional do Dia',
                  style: theme.getTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: caixaAberto
                      ? theme.borderColor.withValues(alpha: 0.25)
                      : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: caixaAberto ? theme.borderColor : Colors.redAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      caixaAberto ? Icons.lock_open : Icons.lock_outline,
                      size: 13,
                      color: caixaAberto ? theme.textColor : Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      caixaAberto ? 'Caixa Aberto' : 'Caixa Fechado',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: caixaAberto ? theme.textColor : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.attach_money,
                  rotulo: 'Faturamento',
                  valor: moeda(faturamentoHoje),
                  destaque: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.receipt_long_outlined,
                  rotulo: 'Vendas Hoje',
                  valor: '$totalVendasHoje',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.trending_up,
                  rotulo: 'Ticket Médio',
                  valor: moeda(ticketMedio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _itemMetrica(
                  theme: theme,
                  icone: Icons.point_of_sale_outlined,
                  rotulo: 'Saldo Caixa (Dinheiro)',
                  valor: moeda(saldoEmDinheiro),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoStatus(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Status da Loja'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(left: 20, right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _online ? 'Online' : 'Offline',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _online,
                  onChanged: _alternarOnline,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: theme.textColor,
                  activeTrackColor:
                      theme.borderColor.withValues(alpha: 0.4),
                  inactiveThumbColor: theme.secondaryTextColor,
                  inactiveTrackColor: Colors.transparent,
                  trackOutlineColor:
                      WidgetStatePropertyAll(theme.borderColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.membros.length} '
            '${widget.membros.length == 1 ? 'membro' : 'membros'}',
            style: theme.getTextStyle(fontSize: 13),
          ),
          if (widget.podeSair) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _confirmarSaida,
                child: Text(
                  'Sair da loja',
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaDeMembro(AppTheme theme, MembroLoja membro) {
    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();

    String foto = auth.buscarFotoPorCpf(membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
    }

    final temFoto = foto.isNotEmpty && File(foto).existsSync();

    return _MembroLinhaComHover(
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: temFoto
                    ? Image.file(
                        File(foto),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 20,
                          color: theme.textColor,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: theme.textColor,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membro.nome.isEmpty ? 'Sem nome' : membro.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_rotuloPapel(membro.papel)} • ${_formatarCpf(membro.cpf)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoTrabalhadores(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Lista de Trabalhadores'),
          const SizedBox(height: 12),
          if (widget.membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum trabalhador cadastrado ainda.',
            )
          else
            for (final membro in widget.membros) _linhaDeMembro(theme, membro),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(title: 'Status da Loja'),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _blocoResumoDoDia(theme),
                      const SizedBox(height: 16),
                      _blocoStatus(theme),
                      const SizedBox(height: 16),
                      _blocoTrabalhadores(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MembroLinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;

  const _MembroLinhaComHover({required this.builder});

  @override
  State<_MembroLinhaComHover> createState() => _MembroLinhaComHoverState();
}

class _MembroLinhaComHoverState extends State<_MembroLinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}