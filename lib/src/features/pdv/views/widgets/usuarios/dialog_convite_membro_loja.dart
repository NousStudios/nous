import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

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

/// Diálogo para busca de usuário por CPF e envio de convite para a loja.
class DialogConviteMembroLoja extends StatefulWidget {
  final AppTheme theme;
  final List<MembroLoja> membrosAtuais;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviar;

  const DialogConviteMembroLoja({
    super.key,
    required this.theme,
    required this.membrosAtuais,
    required this.buscarConta,
    required this.onEnviar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<MembroLoja> membrosAtuais,
    required Future<UsuarioNous?> Function(String cpf) buscarConta,
    required void Function(UsuarioNous conta, PapelMembro papel) onEnviar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => DialogConviteMembroLoja(
        theme: theme,
        membrosAtuais: membrosAtuais,
        buscarConta: buscarConta,
        onEnviar: onEnviar,
      ),
    );
  }

  @override
  State<DialogConviteMembroLoja> createState() => _DialogConviteMembroLojaState();
}

class _DialogConviteMembroLojaState extends State<DialogConviteMembroLoja> {
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

    final jaMembro = widget.membrosAtuais.any((m) => m.cpf == conta.cpf);
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
    final corAtiva = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _papelEscolhido = papel),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selecionado ? corAtiva : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selecionado
                    ? theme.textColor
                    : theme.borderColor.withValues(alpha: 0.6),
                width: selecionado ? 1.6 : 1.0,
              ),
            ),
            child: Text(
              _rotuloPapel(papel),
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                color: selecionado
                    ? (theme.buttonColor != Colors.transparent
                        ? theme.buttonTextColor
                        : theme.textColor)
                    : theme.textColor,
              ),
            ),
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
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final temFotoEnc = ImagemService.existe(_encontrado!.foto);
                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: temFotoEnc
                            ? ImagemService.construirImagem(
                                _encontrado!.foto,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                fallback: Icon(
                                  Icons.person,
                                  size: 24,
                                  color: theme.textColor,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 24,
                                color: theme.textColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _encontrado!.nome,
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                );
              }),
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
