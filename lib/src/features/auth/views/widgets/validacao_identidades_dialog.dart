import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/validacao_identidade_dialog.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Janela "Validação de Identidades" dentro do perfil coletivo do Nous.
/// Lista todos os usuários que ainda não tiveram sua identidade validada por outro usuário.
class ValidacaoIdentidadesDialog {
  ValidacaoIdentidadesDialog._();

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
  }) async {
    final auth = context.read<AuthProvider>();
    await auth.carregarCacheContas();
    if (!context.mounted) return;

    final buscaCtrl = TextEditingController();
    String termo = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final authWatch = context.watch<AuthProvider>();
            final meuCpf = CpfValidator.onlyDigits(
              authWatch.contaAtual?.cpf ?? authWatch.cpf,
            );
            final t = termo.trim().toLowerCase();

            final pendentes = authWatch.contasCache.where((u) {
              if (u.possuiValidacao) return false;
              if (t.isEmpty) return true;
              return u.nome.toLowerCase().contains(t) ||
                  u.apelido.toLowerCase().contains(t) ||
                  u.cpf.toLowerCase().contains(t) ||
                  u.localNascimento.toLowerCase().contains(t);
            }).toList();

            return Dialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 36),
                          Expanded(
                            child: Text(
                              'Validação de Identidades',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: theme.secondaryTextColor,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Usuários aguardando atestado comunitário de outro cidadão Nous.',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: buscaCtrl,
                        onChanged: (v) => setModalState(() => termo = v),
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.backgroundColor,
                          hintText: 'Pesquisar por nome, CPF ou cidade...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: theme.secondaryTextColor,
                          ),
                          suffixIcon: termo.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    buscaCtrl.clear();
                                    setModalState(() => termo = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.borderColor),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: pendentes.isEmpty
                            ? EstadoVazioContainer(
                                theme: theme,
                                mensagem:
                                    'Todos os usuários cadastrados já possuem identidade validada.',
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: pendentes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, idx) {
                                  final u = pendentes[idx];
                                  return _buildCardPendente(
                                    context: context,
                                    usuario: u,
                                    meuCpf: meuCpf,
                                    theme: theme,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    buscaCtrl.dispose();
  }

  static Widget _buildCardPendente({
    required BuildContext context,
    required UsuarioNous usuario,
    required String meuCpf,
    required AppTheme theme,
  }) {
    final cpfLimpo = CpfValidator.onlyDigits(usuario.cpf);
    final ehProprio = cpfLimpo == meuCpf;
    final cpfParcial = cpfLimpo.length >= 3
        ? '${cpfLimpo.substring(0, 3)}.***.***-**'
        : '***';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: ImagemService.construirImagem(
                usuario.foto,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                fallback: Container(
                  color: theme.cardBackgroundColor,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoRolante(
                  texto: usuario.nome.isNotEmpty
                      ? usuario.nome
                      : usuario.nomeExibicao,
                  style: theme.getTextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  'CPF: $cpfParcial • Criado em ${usuario.criadoEmFormatado}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                if (usuario.localNascimento.isNotEmpty)
                  Text(
                    usuario.localNascimento,
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!ehProprio)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final atualizado = await ValidacaoIdentidadeDialog.mostrar(
                  context: context,
                  alvo: usuario,
                  theme: theme,
                );
                if (atualizado != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: theme.cardBackgroundColor,
                      content: Text(
                        'Identidade de ${atualizado.nomeExibicao} validada com sucesso!',
                        style: theme.getTextStyle(color: theme.textColor),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Validar',
                style: theme.getTextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            )
          else
            Text(
              'Sua conta',
              style: theme.getTextStyle(
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
        ],
      ),
    );
  }
}
