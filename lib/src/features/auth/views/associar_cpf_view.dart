import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/contas_usuario_view.dart';

class _DataNascimentoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class AssociarCpfView extends StatefulWidget {
  const AssociarCpfView({super.key});

  @override
  State<AssociarCpfView> createState() => _AssociarCpfViewState();
}

class _AssociarCpfViewState extends State<AssociarCpfView> {
  final _nomeController = TextEditingController();
  final _dataController = TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  bool get _dataValida {
    final texto = _dataController.text;
    if (texto.length != 10) return false;
    final partes = texto.split('/');
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return false;
    final data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return false;
    return ano <= DateTime.now().year;
  }

  List<String> _problemas(String cpf) {
    final problemas = <String>[];
    if (!CpfValidator.isValid(cpf)) problemas.add('CPF inválido');
    if (_nomeController.text.trim().isEmpty) problemas.add('Informe seu nome');
    if (!_dataValida) problemas.add('Informe uma data de nascimento válida');
    return problemas;
  }

  Future<void> _associar(String cpf) async {
    setState(() => _salvando = true);

    await context.read<AuthProvider>().associarConta(
          nome: _nomeController.text,
          dataNascimento: _dataController.text,
        );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ContasUsuarioView()),
      (route) => false,
    );
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  InputDecoration _decoracaoCampo(AppTheme theme, String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 14, color: theme.secondaryTextColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  Widget _linhaStatus(AppTheme theme, bool ok, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.lock_outline,
            size: 18,
            color: theme.textColor,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cpf = context.watch<AuthProvider>().cpf;

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final problemas = _problemas(cpf);
        final tudoCerto = problemas.isEmpty;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.textColor),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              'Associar ao Nous',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: _decoracaoDoBloco(theme),
                        child: Center(
                          child: tudoCerto
                              ? _linhaStatus(theme, true, 'Tudo certo!')
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final problema in problemas)
                                      _linhaStatus(theme, false, problema),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: _decoracaoDoBloco(theme),
                        child: Text(
                          CpfValidator.applyMask(cpf),
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 16,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nomeController,
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 14),
                        decoration: _decoracaoCampo(theme, 'Nome completo'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dataController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_DataNascimentoFormatter()],
                        cursorColor: theme.textColor,
                        style: theme.getTextStyle(fontSize: 14),
                        decoration:
                            _decoracaoCampo(theme, 'Data de Nascimento'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.buttonColor,
                            foregroundColor: theme.buttonTextColor,
                            disabledBackgroundColor:
                                theme.buttonColor.withValues(alpha: 0.3),
                            elevation: 0,
                            minimumSize: const Size.fromHeight(55),
                            side: BorderSide(color: theme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed:
                              tudoCerto && !_salvando ? () => _associar(cpf) : null,
                          child: _salvando
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.buttonTextColor,
                                  ),
                                )
                              : Text(
                                  'Associar ao Nous',
                                  style: theme.getTextStyle(
                                    fontSize: 16,
                                    color: theme.buttonTextColor,
                                  ),
                                ),
                        ),
                      ),
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