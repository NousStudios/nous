import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';

class BackupDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _BackupConteudo(theme: theme),
          ),
        );
      },
    );
  }
}

class _BackupConteudo extends StatefulWidget {
  final AppTheme theme;

  const _BackupConteudo({required this.theme});

  @override
  State<_BackupConteudo> createState() => _BackupConteudoState();
}

class _BackupConteudoState extends State<_BackupConteudo> {
  bool _exportando = false;
  bool _importando = false;

  AppTheme get theme => widget.theme;

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          texto,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _exportar() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final caminho = await BackupService.exportar();
      if (!mounted) return;
      if (caminho == null) {
        _snack('Exportação cancelada.');
      } else {
        _snack('Backup salvo em: $caminho');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _importar() async {
    if (_importando) return;

    final substituir = await _perguntarModo();
    if (substituir == null) return;

    setState(() => _importando = true);
    try {
      final resultado = await BackupService.importar(
        substituir: substituir,
      );
      if (!mounted) return;
      if (resultado == null) {
        _snack('Importação cancelada.');
      } else {
        final auth = context.read<AuthProvider>();
        final pdv = context.read<PdvProvider>();
        final notif = context.read<NotificacoesProvider>();

        await auth.carregarCacheContas();
        await auth.recarregarConta();

        final cpf = auth.contaAtual?.cpf ?? pdv.cpfAtual;
        if (cpf != null && cpf.isNotEmpty) {
          await pdv.entrarComCpf(cpf);
          await notif.carregarParaCpf(cpf);
        }

        _snack(
          'Importado: ${resultado.contasImportadas} conta(s), '
          '${resultado.lojasImportadas} loja(s), '
          '${resultado.referenciasImportadas} referência(s), '
          '${resultado.convitesImportados} convite(s).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Falha ao importar: $e');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<bool?> _perguntarModo() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Importar backup',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Como você quer importar?\n\n'
            'Mesclar: junta o que vem do arquivo com o que já existe '
            'aqui. Nada é apagado.\n\n'
            'Substituir: apaga tudo que está aqui e deixa só o que vem '
            'do arquivo.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Substituir',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Mesclar',
                style: theme.getTextStyle(color: theme.textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _botaoAcao({
    required String rotulo,
    required IconData icone,
    required bool carregando,
    required VoidCallback aoPressionar,
    bool destaque = false,
  }) {
    final Color corFundo =
        destaque ? theme.buttonColor : Colors.transparent;
    final Color corTexto =
        destaque ? theme.buttonTextColor : theme.textColor;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: corFundo,
          foregroundColor: corTexto,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: carregando ? null : aoPressionar,
        icon: carregando
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: corTexto,
                ),
              )
            : Icon(icone, size: 18, color: corTexto),
        label: Text(
          rotulo,
          style: theme.getTextStyle(fontSize: 13, color: corTexto),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Backup dos dados',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _decoracaoDoBloco,
            child: Text(
              'O backup reúne contas de CPF, lojas, referências e '
              'convites pendentes num único arquivo .json. Guarde esse '
              'arquivo em local seguro: ele é sua cópia de segurança e '
              'também serve para migrar para outra máquina.',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _botaoAcao(
            rotulo: 'Exportar dados',
            icone: Icons.download_outlined,
            carregando: _exportando,
            aoPressionar: _exportar,
            destaque: true,
          ),
          const SizedBox(height: 10),
          _botaoAcao(
            rotulo: 'Importar dados',
            icone: Icons.upload_outlined,
            carregando: _importando,
            aoPressionar: _importar,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}