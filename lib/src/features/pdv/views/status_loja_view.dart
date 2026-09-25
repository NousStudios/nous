import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
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

  const StatusLojaView({
    super.key,
    required this.lojaId,
    required this.lojaOnlineInicial,
    required this.aoAlterarOnline,
    required this.membros,
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
        ],
      ),
    );
  }

  Widget _linhaDeMembro(AppTheme theme, MembroLoja membro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle, size: 32, color: theme.textColor),
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