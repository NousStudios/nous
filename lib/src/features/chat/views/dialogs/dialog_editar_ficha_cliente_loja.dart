import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/chat/services/chat_autoatendimento_service.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Modal soberano para que o próprio cliente visualize e edite seus dados de entrega e contato
/// na ficha de cliente da loja, sem ter acesso ou permissão sobre dados financeiros restritos.
class DialogEditarFichaClienteLoja extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final Cliente cliente;
  final VoidCallback? onSalvo;

  const DialogEditarFichaClienteLoja({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.cliente,
    this.onSalvo,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required String lojaId,
    required Cliente cliente,
    VoidCallback? onSalvo,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DialogEditarFichaClienteLoja(
        theme: theme,
        lojaId: lojaId,
        cliente: cliente,
        onSalvo: onSalvo,
      ),
    );
  }

  @override
  State<DialogEditarFichaClienteLoja> createState() =>
      _DialogEditarFichaClienteLojaState();
}

class _DialogEditarFichaClienteLojaState
    extends State<DialogEditarFichaClienteLoja> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _numeroController;
  late final TextEditingController _emailController;
  late final TextEditingController _redesSociaisController;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente.nome);
    _telefoneController = TextEditingController(text: widget.cliente.telefone);
    _enderecoController = TextEditingController(text: widget.cliente.endereco);
    _numeroController = TextEditingController(text: widget.cliente.numero);
    _emailController = TextEditingController(text: widget.cliente.email);
    _redesSociaisController =
        TextEditingController(text: widget.cliente.redesSociais);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _emailController.dispose();
    _redesSociaisController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.dangerColor,
          content: Text(
            'O nome não pode ficar vazio.',
            style: widget.theme.getTextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizado = widget.cliente.copyWith(
        nome: nome,
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        numero: _numeroController.text.trim(),
        email: _emailController.text.trim(),
        redesSociais: _redesSociaisController.text.trim(),
      );

      final pdv = context.read<PdvProvider>();
      await ChatAutoatendimentoService.atualizarFichaCliente(
        lojaId: widget.lojaId,
        clienteAtualizado: atualizado,
        pdv: pdv,
      );

      if (mounted) {
        widget.onSalvo?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: widget.theme.cardBackgroundColor,
            content: Text(
              'Seus dados nesta loja foram atualizados com sucesso!',
              style: widget.theme.getTextStyle(color: widget.theme.textColor),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: widget.theme.dangerColor,
            content: Text(
              'Erro ao salvar dados: $e',
              style: widget.theme.getTextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = widget.theme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
        prefixIcon: Icon(icone, size: 18, color: theme.secondaryTextColor),
        filled: true,
        fillColor: theme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.buttonColor, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tamanho = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: tamanho.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.buttonColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      color: theme.buttonColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Dados na Loja',
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          'Atualize seu endereço e contato para entregas',
                          style: theme.getTextStyle(
                            fontSize: 11,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: theme.borderColor.withValues(alpha: 0.3)),
              const SizedBox(height: 10),

              // Formulário rolável
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCampoTexto(
                        controller: _nomeController,
                        label: 'Nome Completo / Exibição',
                        icone: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildCampoTexto(
                        controller: _telefoneController,
                        label: 'Telefone / WhatsApp',
                        icone: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildCampoTexto(
                        controller: _enderecoController,
                        label: 'Endereço (Rua, Avenida, Bairro)',
                        icone: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildCampoTexto(
                        controller: _numeroController,
                        label: 'Número e Complemento (Apto, Bloco)',
                        icone: Icons.home_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildCampoTexto(
                        controller: _emailController,
                        label: 'E-mail',
                        icone: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildCampoTexto(
                        controller: _redesSociaisController,
                        label: 'Rede Social / Ponto de Referência',
                        icone: Icons.tag_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: theme.borderColor.withValues(alpha: 0.3)),
              const SizedBox(height: 10),

              // Botões inferiores
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: theme.getTextStyle(color: theme.secondaryTextColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Salvar Dados',
                            style: theme.getTextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.buttonTextColor,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
