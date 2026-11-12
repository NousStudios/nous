import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

/// Resultado do onboarding para salvar a nova conta
class ResultadoOnboardingIdentidade {
  final String nome;
  final String apelido;
  final String foto;
  final String biografia;
  final List<String> dadosPrivados;

  const ResultadoOnboardingIdentidade({
    required this.nome,
    required this.apelido,
    required this.foto,
    required this.biografia,
    required this.dadosPrivados,
  });
}

/// Diálogo completo de Onboarding para configurar a Identidade e as Regras de Transparência
class DialogOnboardingIdentidadeNous extends StatefulWidget {
  final String cpf;
  final String username;
  final AppTheme theme;

  const DialogOnboardingIdentidadeNous({
    super.key,
    required this.cpf,
    required this.username,
    required this.theme,
  });

  static Future<ResultadoOnboardingIdentidade?> mostrar(
    BuildContext context, {
    required String cpf,
    required String username,
    required AppTheme theme,
  }) {
    return showDialog<ResultadoOnboardingIdentidade>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DialogOnboardingIdentidadeNous(
        cpf: cpf,
        username: username,
        theme: theme,
      ),
    );
  }

  @override
  State<DialogOnboardingIdentidadeNous> createState() =>
      _DialogOnboardingIdentidadeNousState();
}

class _DialogOnboardingIdentidadeNousState
    extends State<DialogOnboardingIdentidadeNous> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _apelidoController;
  late final TextEditingController _biografiaController;

  String _fotoCaminho = '';
  String? _erro;

  // Regras de Transparência (quais dados são privados)
  bool _nomePublico = true;
  bool _fotoPublica = true;
  bool _emailsPublicos = false;
  bool _dataNascimentoPublica = false;
  bool _filiacaoPublica = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _apelidoController = TextEditingController(text: widget.username.replaceAll('@', ''));
    _biografiaController = TextEditingController();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _biografiaController.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    const typeGroup = XTypeGroup(
      label: 'Imagens',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null && mounted) {
      final salvo = await ImagemService.salvarImagemLocal(file.path);
      if (salvo != null && mounted) {
        setState(() {
          _fotoCaminho = salvo;
        });
      }
    }
  }

  void _concluir() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Informe seu nome completo para a sua identidade.');
      return;
    }

    final dadosPrivados = <String>['cpf']; // CPF sempre protegido
    if (!_nomePublico) dadosPrivados.add('nome');
    if (!_fotoPublica) dadosPrivados.add('foto');
    if (!_emailsPublicos) dadosPrivados.add('emails');
    if (!_dataNascimentoPublica) dadosPrivados.add('dataNascimento');
    if (!_filiacaoPublica) dadosPrivados.add('filiacao');

    Navigator.of(context).pop(
      ResultadoOnboardingIdentidade(
        nome: nome,
        apelido: _apelidoController.text.trim().isNotEmpty
            ? _apelidoController.text.trim()
            : widget.username.replaceAll('@', ''),
        foto: _fotoCaminho,
        biografia: _biografiaController.text.trim(),
        dadosPrivados: dadosPrivados,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cpfFormatado = CpfValidator.format(widget.cpf);
    final usernameFormatado = widget.username.startsWith('@')
        ? widget.username
        : '@${widget.username}';

    final fotoResolvida = _fotoCaminho.isNotEmpty
        ? ImagemService.resolverCaminhoExistente(_fotoCaminho)
        : null;
    final temFoto = fotoResolvida != null && File(fotoResolvida).existsSync();

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho de Boas-vindas
                Center(
                  child: Text(
                    'Identidade Soberana Nous',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Configure seu perfil e as regras de transparência da sua conta',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Foto de Perfil com Avatar Clicável
                Center(
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: _escolherFoto,
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                          backgroundImage: temFoto
                              ? ImagemService.obterImageProvider(fotoResolvida)
                              : null,
                          child: !temFoto
                              ? Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 42,
                                  color: theme.textColor,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: theme.textColor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _escolherFoto,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: theme.backgroundColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tags de Identificação (@username e CPF)
                Center(
                  child: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.borderColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              usernameFormatado,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 13,
                              color: Color(0xFF34B7F1),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.borderColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'CPF: $cpfFormatado',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Nome Completo
                ThemedTextField(
                  theme: theme,
                  controller: _nomeController,
                  label: 'Nome Completo',
                  obrigatorio: true,
                  onChanged: (_) {
                    if (_erro != null) setState(() => _erro = null);
                  },
                ),
                const SizedBox(height: 10),

                // Campo Apelido / Nome Social
                ThemedTextField(
                  theme: theme,
                  controller: _apelidoController,
                  label: 'Apelido ou Nome Social',
                ),
                const SizedBox(height: 10),

                // Campo Biografia
                ThemedTextField(
                  theme: theme,
                  controller: _biografiaController,
                  label: 'Biografia Inicial',
                  linhas: 2,
                ),
                const SizedBox(height: 16),

                // Seção: Regras de Transparência
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: theme.textColor),
                          const SizedBox(width: 6),
                          Text(
                            'Regras de Transparência da Conta',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Defina quais dados os outros membros poderão visualizar na Validação de Identidades e na rede:',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _itemInterruptor(
                        rotulo: 'Nome Completo público',
                        descricao: 'Se desativado, exibe apenas seu Apelido ou @username',
                        valor: _nomePublico,
                        onChanged: (v) => setState(() => _nomePublico = v),
                      ),
                      const Divider(height: 12),
                      _itemInterruptor(
                        rotulo: 'Foto de Perfil pública',
                        descricao: 'Permite que outros membros vejam sua foto',
                        valor: _fotoPublica,
                        onChanged: (v) => setState(() => _fotoPublica = v),
                      ),
                      const Divider(height: 12),
                      _itemInterruptor(
                        rotulo: 'E-mails vinculados visíveis',
                        descricao: 'Compartilha seus e-mails na validação de identidade',
                        valor: _emailsPublicos,
                        onChanged: (v) => setState(() => _emailsPublicos = v),
                      ),
                      const Divider(height: 12),
                      _itemInterruptor(
                        rotulo: 'Data de Nascimento visível',
                        descricao: 'Mostra sua data de nascimento',
                        valor: _dataNascimentoPublica,
                        onChanged: (v) => setState(() => _dataNascimentoPublica = v),
                      ),
                      const Divider(height: 12),
                      _itemInterruptor(
                        rotulo: 'Filiação (Nome dos pais) visível',
                        descricao: 'Exibe o nome de pai e mãe cadastrados',
                        valor: _filiacaoPublica,
                        onChanged: (v) => setState(() => _filiacaoPublica = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Registro da Conta (Soberania Comunitária)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34B7F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF34B7F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 20,
                        color: Color(0xFF34B7F1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conta com Selo de Verificação Comunitária',
                              style: theme.getTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            Text(
                              'Validada pela Rede Soberana Nous desde o registro inicial.',
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.dangerColor,
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Botão de Criar Conta
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _concluir,
                  child: Text(
                    'Concluir Criação da Conta',
                    style: theme.getTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemInterruptor({
    required String rotulo,
    required String descricao,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = widget.theme;
    return InkWell(
      onTap: () => onChanged(!valor),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    descricao,
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: valor,
              onChanged: onChanged,
              activeTrackColor: theme.textColor,
              activeThumbColor: theme.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}
