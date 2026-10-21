import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Diálogo para edição soberana do perfil público do usuário:
/// Apelido, Nome de exibição, Biografia e Foto de Perfil.
class EditarPerfilDialog extends StatefulWidget {
  final UsuarioNous usuario;

  const EditarPerfilDialog({
    super.key,
    required this.usuario,
  });

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  late final TextEditingController _apelidoController;
  late final TextEditingController _nomeController;
  late final TextEditingController _biografiaController;
  String _fotoAtual = '';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _apelidoController = TextEditingController(text: widget.usuario.apelido);
    _nomeController = TextEditingController(text: widget.usuario.nome);
    _biografiaController = TextEditingController(text: widget.usuario.biografia);
    _fotoAtual = widget.usuario.foto;
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    _nomeController.dispose();
    _biografiaController.dispose();
    super.dispose();
  }

  Future<void> _trocarFoto() async {
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null && mounted) {
      final salvo = await ImagemService.salvarImagemLocal(file.path);
      if (salvo != null && mounted) {
        setState(() {
          _fotoAtual = salvo;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);

    final auth = context.read<AuthProvider>();
    final pdv = context.read<PdvProvider>();

    var apelido = _apelidoController.text.trim();
    if (apelido.startsWith('@')) {
      apelido = apelido.substring(1).trim();
    }
    final nome = _nomeController.text.trim();
    final biografia = _biografiaController.text.trim();

    await auth.atualizarPerfilSocial(
      nome: nome,
      apelido: apelido,
      biografia: biografia,
      foto: _fotoAtual,
    );

    if (_fotoAtual.isNotEmpty) {
      pdv.sincronizarFotoUsuarioEmClientes(widget.usuario.cpf, _fotoAtual);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final fotoResolvida =
            ImagemService.resolverCaminhoExistente(_fotoAtual);
        final temFoto = fotoResolvida != null;

        return Dialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editar Perfil Público',
                        style: theme.getTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.secondaryTextColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar com botão para trocar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor:
                              theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage:
                              temFoto ? FileImage(File(fotoResolvida)) : null,
                          child: !temFoto
                              ? Icon(
                                  Icons.person,
                                  size: 42,
                                  color: theme.textColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _trocarFoto,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.buttonColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: theme.buttonTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo: Apelido
                  Text(
                    'Apelido (@)',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apelidoController,
                    style: theme.getTextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      prefixText: '@ ',
                      prefixStyle: theme.getTextStyle(color: theme.buttonColor),
                      hintText: 'seu_apelido',
                      hintStyle:
                          theme.getTextStyle(color: theme.secondaryTextColor),
                      filled: true,
                      fillColor: theme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo: Nome de exibição
                  Text(
                    'Nome de exibição',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nomeController,
                    style: theme.getTextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Como outros verão seu nome',
                      hintStyle:
                          theme.getTextStyle(color: theme.secondaryTextColor),
                      filled: true,
                      fillColor: theme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo: Biografia
                  Text(
                    'Biografia',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _biografiaController,
                    maxLines: 4,
                    maxLength: 250,
                    style: theme.getTextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Conte um pouco sobre você...',
                      hintStyle:
                          theme.getTextStyle(color: theme.secondaryTextColor),
                      filled: true,
                      fillColor: theme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botões Ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: theme.getTextStyle(
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _salvando ? null : _salvar,
                        child: _salvando
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.buttonTextColor,
                                ),
                              )
                            : Text(
                                'Salvar',
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
      },
    );
  }
}
