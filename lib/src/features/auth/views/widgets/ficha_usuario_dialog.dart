import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

class FichaUsuarioDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous usuario,
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
            child: _FichaUsuarioConteudo(
              theme: theme,
              usuarioInicial: usuario,
            ),
          ),
        );
      },
    );
  }
}

class _FichaUsuarioConteudo extends StatefulWidget {
  final AppTheme theme;
  final UsuarioNous usuarioInicial;

  const _FichaUsuarioConteudo({
    required this.theme,
    required this.usuarioInicial,
  });

  @override
  State<_FichaUsuarioConteudo> createState() => _FichaUsuarioConteudoState();
}

class _FichaUsuarioConteudoState extends State<_FichaUsuarioConteudo> {
  late UsuarioNous _usuario;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioInicial;
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _linhaInfo(String rotulo, String valor, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valor.isEmpty ? '—' : valor,
              textAlign: TextAlign.right,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _aoClicarFoto() async {
    final temFoto = _usuario.foto.isNotEmpty && File(_usuario.foto).existsSync();

    if (temFoto) {
      await OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto de Perfil',
        onEscolherNova: () => _selecionarNovaFoto(),
        onRemover: () => _salvarFoto(''),
      );
    } else {
      await _selecionarNovaFoto();
    }
  }

  Future<void> _selecionarNovaFoto() async {
    const typeGroup = XTypeGroup(
      label: 'Imagens',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null && mounted) {
      final salvo = await ImagemService.salvarImagemLocal(file.path);
      if (salvo != null && mounted) {
        await _salvarFoto(salvo);
      }
    }
  }

  Future<void> _salvarFoto(String novaFoto) async {
    final auth = context.read<AuthProvider>();
    await auth.atualizarFoto(novaFoto);
    if (!mounted) return;
    context
        .read<PdvProvider>()
        .sincronizarFotoUsuarioEmClientes(_usuario.cpf, novaFoto);

    setState(() {
      _usuario = _usuario.copyWith(foto: novaFoto);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final auth = context.watch<AuthProvider>();
    final contaAtualizada = auth.contaAtual ?? _usuario;
    final temFoto = contaAtualizada.foto.isNotEmpty &&
        File(contaAtualizada.foto).existsSync();

    final clienteMesmoCpf = pdv.buscarClientePorCpf(contaAtualizada.cpf);
    final lojasAdmin = pdv.lojasQueAdministro;
    final lojasParticipa = pdv.lojasQueParticipo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'Identidade do Usuário',
                style: theme.getTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, color: theme.secondaryTextColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar Clicável
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _aoClicarFoto,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: temFoto
                    ? Image.file(
                        File(contaAtualizada.foto),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 48,
                          color: theme.textColor,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 48,
                        color: theme.textColor,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            contaAtualizada.nome.isEmpty
                ? 'Nome do Usuário'
                : contaAtualizada.nome,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatarCpf(contaAtualizada.cpf),
            style: theme.getTextStyle(
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),

          const SizedBox(height: 16),

          // Bloco Dados Pessoais
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _decoracaoDoBloco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Dados Pessoais',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                _linhaInfo('CPF', _formatarCpf(contaAtualizada.cpf)),
                _linhaInfo('Data de nascimento', contaAtualizada.dataNascimento),
                if (clienteMesmoCpf != null) ...[
                  if (clienteMesmoCpf.telefone.isNotEmpty)
                    _linhaInfo('Telefone', clienteMesmoCpf.telefone),
                  if (clienteMesmoCpf.endereco.isNotEmpty)
                    _linhaInfo(
                      'Endereço',
                      clienteMesmoCpf.numero.isNotEmpty
                          ? '${clienteMesmoCpf.endereco}, ${clienteMesmoCpf.numero}'
                          : clienteMesmoCpf.endereco,
                    ),
                  if (clienteMesmoCpf.redesSociais.isNotEmpty)
                    _linhaInfo('Redes sociais', clienteMesmoCpf.redesSociais),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bloco E-mails Associados
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _decoracaoDoBloco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'E-mails Associados ao CPF',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                if (contaAtualizada.emails.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Nenhum e-mail cadastrado.',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                else
                  for (final email in contaAtualizada.emails)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            auth.emailAtivo == email
                                ? Icons.check_circle_outline
                                : Icons.mail_outline,
                            size: 16,
                            color: auth.emailAtivo == email
                                ? theme.buttonColor
                                : theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style: theme.getTextStyle(
                                fontSize: 12,
                                color: auth.emailAtivo == email
                                    ? theme.textColor
                                    : theme.secondaryTextColor,
                                fontWeight: auth.emailAtivo == email
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (auth.emailAtivo == email)
                            Text(
                              'Ativo',
                              style: theme.getTextStyle(
                                fontSize: 10,
                                color: theme.buttonColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bloco Lojas / Participações
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _decoracaoDoBloco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Lojas e Coletivos',
                    textAlign: TextAlign.center,
                    style: theme.getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                if (lojasAdmin.isEmpty && lojasParticipa.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Nenhuma loja associada neste dispositivo.',
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  )
                else ...[
                  if (lojasAdmin.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      child: Text(
                        'Administra:',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    for (final l in lojasAdmin)
                      _linhaInfo(l.nome, 'Dono / Sócio'),
                  ],
                  if (lojasParticipa.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      child: Text(
                        'Participa:',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    for (final l in lojasParticipa)
                      _linhaInfo(l.nome, 'Membro'),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fechar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
