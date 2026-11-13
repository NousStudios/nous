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
  late final TextEditingController _novoLinkController;
  late List<String> _links;
  late Map<String, String> _coresPerfil;
  String _fotoAtual = '';
  bool _salvando = false;

  static const List<String> _paletaFundo = [
    '',
    '#0E0E10',
    '#141A24',
    '#161D17',
    '#211824',
    '#F5F5F7',
    '#FFFBF2',
  ];

  static const List<String> _paletaDestaque = [
    '',
    '#34B7F1',
    '#4CAF50',
    '#FF9800',
    '#E91E63',
    '#9C27B0',
    '#FFD700',
  ];

  @override
  void initState() {
    super.initState();
    _apelidoController =
        TextEditingController(text: widget.usuario.apelidoExibicao);
    _nomeController =
        TextEditingController(text: widget.usuario.nomeExibicao);
    _biografiaController =
        TextEditingController(text: widget.usuario.biografia);
    _novoLinkController = TextEditingController();
    _links = List<String>.from(widget.usuario.links);
    _coresPerfil = Map<String, String>.from(widget.usuario.coresPerfil);
    _fotoAtual = widget.usuario.fotoExibicao;
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    _nomeController.dispose();
    _biografiaController.dispose();
    _novoLinkController.dispose();
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
      links: _links,
      coresPerfil: _coresPerfil,
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
                  // Cabeçalho centralizado
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Editar Perfil Público',
                          textAlign: TextAlign.center,
                          style: theme.getTextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
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

                  _tituloSecaoCentralizado(theme, 'Dados do Perfil'),
                  const SizedBox(height: 10),

                  // Campo: Apelido (alinhado no mesmo início do Nome de exibição)
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.textColor),
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
                  const SizedBox(height: 18),
                  _tituloSecaoCentralizado(theme, 'Links Públicos'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _novoLinkController,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'https://seusite.com ou @rede',
                            hintStyle: theme.getTextStyle(
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
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
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final link = _novoLinkController.text.trim();
                          if (link.isEmpty || _links.contains(link)) return;
                          setState(() {
                            _links.add(link);
                            _novoLinkController.clear();
                          });
                        },
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ],
                  ),
                  if (_links.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (int i = 0; i < _links.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 15,
                              color: theme.secondaryTextColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _links[i],
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 12,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _links.removeAt(i)),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 18),
                  _tituloSecaoCentralizado(theme, 'Cores do Perfil Público'),
                  const SizedBox(height: 8),
                  _seletorCorMinimalista(
                    theme: theme,
                    rotulo: 'Cor de Fundo',
                    chave: 'fundo',
                    paleta: _paletaFundo,
                  ),
                  const SizedBox(height: 10),
                  _seletorCorMinimalista(
                    theme: theme,
                    rotulo: 'Cor de Destaque',
                    chave: 'destaque',
                    paleta: _paletaDestaque,
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

  Widget _tituloSecaoCentralizado(AppTheme theme, String titulo) {
    return Column(
      children: [
        Divider(color: theme.borderColor.withValues(alpha: 0.4), height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Color? _parseHex(String hex) {
    if (hex.isEmpty) return null;
    final limpo = hex.replaceAll('#', '');
    if (limpo.length != 6) return null;
    final val = int.tryParse('FF$limpo', radix: 16);
    return val != null ? Color(val) : null;
  }

  Widget _seletorCorMinimalista({
    required AppTheme theme,
    required String rotulo,
    required String chave,
    required List<String> paleta,
  }) {
    final selecionada = _coresPerfil[chave] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rotulo,
          style: theme.getTextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final hex in paleta)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    if (hex.isEmpty) {
                      _coresPerfil.remove(chave);
                    } else {
                      _coresPerfil[chave] = hex;
                    }
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseHex(hex) ?? theme.backgroundColor,
                    border: Border.all(
                      color: selecionada == hex
                          ? theme.textColor
                          : theme.borderColor.withValues(alpha: 0.7),
                      width: selecionada == hex ? 2.2 : 1,
                    ),
                  ),
                  child: hex.isEmpty
                      ? Icon(
                          Icons.auto_awesome_outlined,
                          size: 14,
                          color: theme.secondaryTextColor,
                        )
                      : (selecionada == hex
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: (_parseHex(hex)?.computeLuminance() ?? 0) >
                                      0.5
                                  ? const Color(0xFF111111)
                                  : const Color(0xFFFFFFFF),
                            )
                          : null),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
