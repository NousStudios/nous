import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/services/criptografia_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Diálogo soberano para Exportação e Restauração de Chaves Criptográficas com Proteção por Senha Mestre.
class DialogChavesCriptograficas extends StatefulWidget {
  final AppTheme theme;
  final String cpf;

  const DialogChavesCriptograficas({
    super.key,
    required this.theme,
    required this.cpf,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required String cpf,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DialogChavesCriptograficas(
        theme: theme,
        cpf: cpf,
      ),
    );
  }

  @override
  State<DialogChavesCriptograficas> createState() =>
      _DialogChavesCriptograficasState();
}

class _DialogChavesCriptograficasState
    extends State<DialogChavesCriptograficas> {
  int _abaAtiva = 0; // 0: Exportar, 1: Importar

  // Controladores de Exportação
  final _senhaExportarCtrl = TextEditingController();
  bool _mostrarSenhaExportar = false;
  String? _resultadoExportacao;
  bool _exportando = false;
  String? _erroExportar;

  // Controladores de Importação
  final _payloadImportarCtrl = TextEditingController();
  final _senhaImportarCtrl = TextEditingController();
  bool _mostrarSenhaImportar = false;
  bool _importando = false;
  String? _mensagemImportar;
  bool _sucessoImportar = false;

  @override
  void dispose() {
    _senhaExportarCtrl.dispose();
    _payloadImportarCtrl.dispose();
    _senhaImportarCtrl.dispose();
    super.dispose();
  }

  Future<void> _executarExportacao() async {
    final senha = _senhaExportarCtrl.text.trim();
    if (senha.length < 6) {
      setState(() {
        _erroExportar = 'A senha mestre deve conter no mínimo 6 caracteres.';
      });
      return;
    }

    setState(() {
      _exportando = true;
      _erroExportar = null;
      _resultadoExportacao = null;
    });

    try {
      final envelope = await CriptografiaService.exportarCofreChavesComSenha(
        cpf: widget.cpf,
        senhaMestre: senha,
      );
      setState(() {
        _resultadoExportacao = envelope;
        _exportando = false;
      });
    } catch (e) {
      setState(() {
        _erroExportar = 'Erro ao exportar cofre: $e';
        _exportando = false;
      });
    }
  }

  Future<void> _executarImportacao() async {
    final payload = _payloadImportarCtrl.text.trim();
    final senha = _senhaImportarCtrl.text.trim();

    if (payload.isEmpty) {
      setState(() {
        _mensagemImportar = 'Cole o pacote de chaves (.nouskey ou JSON) exportado.';
        _sucessoImportar = false;
      });
      return;
    }
    if (senha.isEmpty) {
      setState(() {
        _mensagemImportar = 'Digite a senha mestre usada na exportação.';
        _sucessoImportar = false;
      });
      return;
    }

    setState(() {
      _importando = true;
      _mensagemImportar = null;
    });

    try {
      final sucesso = await CriptografiaService.importarCofreChavesComSenha(
        payloadCifrado: payload,
        senhaMestre: senha,
      );

      setState(() {
        _importando = false;
        _sucessoImportar = sucesso;
        _mensagemImportar = sucesso
            ? 'Cofre de chaves e identidade E2EE restaurados com sucesso!'
            : 'Senha mestre incorreta ou pacote corrompido.';
      });
    } catch (e) {
      setState(() {
        _importando = false;
        _sucessoImportar = false;
        _mensagemImportar = 'Falha ao importar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    size: 20,
                    color: theme.textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cofre Criptográfico & Chaves E2EE',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Suas chaves assimétricas Ed25519 (assinatura de atestados/mensagens) e X25519 (cifragem ponta a ponta) ficam no cofre deste dispositivo. Use esta função para migrar sua identidade com senha de segurança.',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),

              // Abas
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _abaAtiva = 0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _abaAtiva == 0
                              ? theme.backgroundColor.withValues(alpha: 0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _abaAtiva == 0
                                ? theme.borderColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Exportar com Senha',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: _abaAtiva == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _abaAtiva == 0
                                  ? theme.textColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _abaAtiva = 1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _abaAtiva == 1
                              ? theme.backgroundColor.withValues(alpha: 0.8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _abaAtiva == 1
                                ? theme.borderColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Importar & Restaurar',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: _abaAtiva == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _abaAtiva == 1
                                  ? theme.textColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conteúdo da Aba 0: Exportar
              if (_abaAtiva == 0) ...[
                Text(
                  'Defina uma senha mestre para blindar o arquivo com AES-GCM (256-bit):',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _senhaExportarCtrl,
                  obscureText: !_mostrarSenhaExportar,
                  style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Senha mestre (mínimo 6 dígitos)',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarSenhaExportar
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarSenhaExportar = !_mostrarSenhaExportar;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                  ),
                ),
                if (_erroExportar != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _erroExportar!,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _exportando ? null : _executarExportacao,
                  icon: _exportando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline, size: 16),
                  label: Text(
                    _exportando ? 'Cifrando Chaves...' : 'Gerar Chaves Protegidas',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
                if (_resultadoExportacao != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pacote Cifrado Gerado com Sucesso:',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _resultadoExportacao!,
                          maxLines: 3,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _resultadoExportacao!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pacote copiado para a área de transferência!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copiar Pacote Cifrado'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Conteúdo da Aba 1: Importar
              if (_abaAtiva == 1) ...[
                Text(
                  'Cole o pacote de chaves (.nouskey ou JSON) a restaurar:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _payloadImportarCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Cole aqui o texto {"tipo":"nous_cofre_chaves_v1", ...}',
                    hintStyle: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Digite a senha mestre para decifrar:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _senhaImportarCtrl,
                  obscureText: !_mostrarSenhaImportar,
                  style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Senha mestre original',
                    hintStyle: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarSenhaImportar
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: theme.secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarSenhaImportar = !_mostrarSenhaImportar;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    filled: true,
                    fillColor: theme.backgroundColor.withValues(alpha: 0.4),
                  ),
                ),
                if (_mensagemImportar != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _mensagemImportar!,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _sucessoImportar
                          ? Colors.greenAccent
                          : theme.dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _importando ? null : _executarImportacao,
                  icon: _importando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.key_rounded, size: 16),
                  label: Text(
                    _importando ? 'Decifrando e Restaurando...' : 'Restaurar Chaves no Aparelho',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
