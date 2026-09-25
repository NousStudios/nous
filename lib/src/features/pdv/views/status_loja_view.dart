import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

class StatusLojaView extends StatefulWidget {
  final String lojaId;
  final bool lojaOnlineInicial;
  final ValueChanged<bool> aoAlterarOnline;

  const StatusLojaView({
    super.key,
    required this.lojaId,
    required this.lojaOnlineInicial,
    required this.aoAlterarOnline,
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
            '1/1 Online',
            style: theme.getTextStyle(fontSize: 13),
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
          EstadoVazioContainer(
            theme: theme,
            mensagem: 'Nenhum trabalhador cadastrado ainda.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                side: BorderSide(color: theme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Convidar usuários: em construção'),
                  ),
                );
              },
              child: Text(
                'Convidar usuários para a loja',
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
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