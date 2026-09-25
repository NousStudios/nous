import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

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

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class UsuariosParticipantesContainer extends StatelessWidget {
  final AppTheme theme;
  final List<MembroLoja> membros;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviarConvite;
  final ValueChanged<String> onRemover;
  final void Function(String cpf, PapelMembro papel) onAtualizarPapel;

  const UsuariosParticipantesContainer({
    super.key,
    required this.theme,
    required this.membros,
    required this.buscarConta,
    required this.onEnviarConvite,
    required this.onRemover,
    required this.onAtualizarPapel,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          mensagem,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  void _confirmarRemocao(BuildContext context, MembroLoja membro) {
    final ehUltimoDono = membro.papel == PapelMembro.dono &&
        membros.where((m) => m.papel == PapelMembro.dono).length <= 1;

    if (ehUltimoDono) {
      _avisar(context, 'A loja precisa de pelo menos um dono.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Remover membro',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            'Remover "${membro.nome}" da loja?',
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
                onRemover(membro.cpf);
              },
              child: Text(
                'Remover',
                style: theme.getTextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirConvite(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ConviteDialog(
          theme: theme,
          membrosAtuais: membros,
          buscarConta: buscarConta,
          onEnviar: (conta, papel) {
            onEnviarConvite(conta, papel);
            Navigator.of(dialogContext).pop();
            _avisar(
              context,
              'Convite enviado para ${conta.nome}.',
            );
          },
        );
      },
    );
  }

  void _abrirTrocaDePapel(BuildContext context, MembroLoja membro) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Papel de ${membro.nome}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final papel in PapelMembro.values)
                ListTile(
                  title: Text(
                    _rotuloPapel(papel),
                    style: theme.getTextStyle(
                      color: papel == membro.papel
                          ? theme.textColor
                          : theme.secondaryTextColor,
                    ),
                  ),
                  trailing: papel == membro.papel
                      ? Icon(Icons.check, color: theme.textColor, size: 18)
                      : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    onAtualizarPapel(membro.cpf, papel);
                  },
                ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _linhaDeMembro(BuildContext context, MembroLoja membro) {
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
                  '${_rotuloPapel(membro.papel)} • ${_formatarCpf(membro.cpf)}'
                  ' • desde ${_dataCurta(membro.desde)}',
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
          IconButton(
            tooltip: 'Trocar papel',
            icon: Icon(Icons.edit, size: 18, color: theme.textColor),
            onPressed: () => _abrirTrocaDePapel(context, membro),
          ),
          IconButton(
            tooltip: 'Remover',
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: () => _confirmarRemocao(context, membro),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Text(
            'Usuários Participantes',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum membro cadastrado ainda.',
            )
          else
            for (final membro in membros) _linhaDeMembro(context, membro),
          const SizedBox(height: 8),
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
              onPressed: () => _abrirConvite(context),
              child: Text(
                'Convidar usuário para loja',
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConviteDialog extends StatefulWidget {
  final AppTheme theme;
  final List<MembroLoja> membrosAtuais;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviar;

  const _ConviteDialog({
    required this.theme,
    required this.membrosAtuais,
    required this.buscarConta,
    required this.onEnviar,
  });

  @override
  State<_ConviteDialog> createState() => _ConviteDialogState();
}

class _ConviteDialogState extends State<_ConviteDialog> {
  final _cpfController = TextEditingController();
  bool _buscando = false;
  UsuarioNous? _encontrado;
  PapelMembro _papelEscolhido = PapelMembro.funcionario;
  String? _erro;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final digitos = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 11) {
      setState(() {
        _erro = 'Informe um CPF com 11 dígitos.';
        _encontrado = null;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _erro = null;
    });

    final conta = await widget.buscarConta(digitos);
    if (!mounted) return;

    if (conta == null) {
      setState(() {
        _buscando = false;
        _encontrado = null;
        _erro = 'CPF não cadastrado neste dispositivo.';
      });
      return;
    }

    final jaMembro =
        widget.membrosAtuais.any((m) => m.cpf == conta.cpf);
    setState(() {
      _buscando = false;
      _encontrado = conta;
      _erro = jaMembro ? 'Este CPF já é membro da loja.' : null;
    });
  }

  void _enviar() {
    final conta = _encontrado;
    if (conta == null) return;
    widget.onEnviar(conta, _papelEscolhido);
  }

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

  Widget _botaoDePapel(PapelMembro papel) {
    final selecionado = papel == _papelEscolhido;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selecionado ? theme.buttonColor : Colors.transparent,
          foregroundColor:
              selecionado ? theme.buttonTextColor : theme.textColor,
          side: BorderSide(color: theme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => setState(() => _papelEscolhido = papel),
        child: Text(
          _rotuloPapel(papel),
          style: theme.getTextStyle(
            fontSize: 11,
            color: selecionado ? theme.buttonTextColor : theme.textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeEnviar = _encontrado != null && _erro == null;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'Convidar usuário',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CpfInputFormatter()],
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: _decoracaoCampo('CPF do usuário'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _buscando ? null : _buscar,
                  child: Text(
                    'Buscar',
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_erro != null)
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(fontSize: 12),
              ),
            if (_encontrado != null) ...[
              Text(
                'Conta encontrada:',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                _encontrado!.nome,
                style: theme.getTextStyle(
                  fontSize: 14,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Papel na loja',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 0,
                runSpacing: 6,
                children: [
                  for (final papel in PapelMembro.values)
                    _botaoDePapel(papel),
                ],
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        TextButton(
          onPressed: podeEnviar ? _enviar : null,
          child: Text(
            'Enviar convite',
            style: theme.getTextStyle(
              color: podeEnviar
                  ? theme.textColor
                  : theme.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}