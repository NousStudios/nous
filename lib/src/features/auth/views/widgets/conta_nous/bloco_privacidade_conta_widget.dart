import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

/// Bloco de configuração de Privacidade e Transparência de dados pessoais soberanos.
class BlocoPrivacidadeContaWidget extends StatelessWidget {
  final UsuarioNous? conta;
  final AppTheme theme;

  const BlocoPrivacidadeContaWidget({
    super.key,
    required this.conta,
    required this.theme,
  });

  Widget _itemPrivacidade({
    required BuildContext context,
    required AppTheme theme,
    required String titulo,
    required String subtitulo,
    required bool privado,
    required List<String> chaves,
    required UsuarioNous? conta,
    required VoidCallback onAlternar,
  }) {
    final auth = context.read<AuthProvider>();
    final cpfsAutorizados = <String>{};
    if (conta != null) {
      for (final chave in chaves) {
        cpfsAutorizados.addAll(conta.obterCpfsAutorizadosPara(chave));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titulo,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        if (privado) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      privado
                          ? 'Privado (exige aprovação prévia para visualização)'
                          : subtitulo,
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ThemedSwitch(
                theme: theme,
                value: !privado,
                onChanged: (_) => onAlternar(),
              ),
            ],
          ),
          if (cpfsAutorizados.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: theme.secondaryTextColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Usuários com acesso concedido (${cpfsAutorizados.length}):',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cpfsAutorizados.map((cpfAlvo) {
                      final usuarioAlvo = auth.buscarContaPorCpf(cpfAlvo);
                      final nomeAlvo = usuarioAlvo?.nomeExibicao.isNotEmpty == true
                          ? usuarioAlvo!.nomeExibicao
                          : _formatarCpf(cpfAlvo);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nomeAlvo,
                              style: theme.getTextStyle(
                                fontSize: 11,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () async {
                                for (final chave in chaves) {
                                  await auth.revogarAcessoDado(chave, cpfAlvo);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: theme.dangerColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacidade e Transparência',
                style: theme.getTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Defina quais dados você permite que fiquem visíveis para outros usuários nas lojas e no mapa. Se um dado for mantido privado, outros membros verão um ícone de cadeado e precisarão solicitar sua aprovação por notificação.',
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 16,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mensagens Diretas',
                            style: theme.getTextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (conta?.quemPodeEnviarMensagens == 'apenas_seguidos')
                            ? 'Apenas pessoas que você segue podem iniciar chat'
                            : 'Qualquer usuário da rede pode iniciar uma conversa direta',
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ThemedSwitch(
                  theme: theme,
                  value: conta?.quemPodeEnviarMensagens != 'apenas_seguidos',
                  onChanged: (permitirTodos) {
                    auth.atualizarQuemPodeEnviarMensagens(
                      permitirTodos ? 'todos' : 'apenas_seguidos',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Nome Próprio / Nome Civil',
            subtitulo: 'Exibir seu nome civil completo (se privado, exibe apenas seu apelido)',
            privado: conta?.dadoEstaPrivado('nome') ?? false,
            chaves: const ['nome'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('nome'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'CPF do Cidadão',
            subtitulo: 'Exibir seu CPF publicamente em lojas',
            privado: conta?.dadoEstaPrivado('cpf') ?? false,
            chaves: const ['cpf'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('cpf'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Data de Nascimento',
            subtitulo: 'Exibir sua data de nascimento',
            privado: conta?.dadoEstaPrivado('dataNascimento') ?? false,
            chaves: const ['dataNascimento'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('dataNascimento'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Filiação (Mãe e Pai)',
            subtitulo: 'Exibir nomes dos pais na identidade',
            privado: (conta?.dadoEstaPrivado('nomeMae') ?? false) ||
                (conta?.dadoEstaPrivado('nomePai') ?? false),
            chaves: const ['nomeMae', 'nomePai'],
            conta: conta,
            onAlternar: () {
              auth.alternarPrivacidadeDado('nomeMae');
              auth.alternarPrivacidadeDado('nomePai');
            },
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Local de Nascimento',
            subtitulo: 'Exibir cidade e estado de origem',
            privado: conta?.dadoEstaPrivado('localNascimento') ?? false,
            chaves: const ['localNascimento'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('localNascimento'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Tipo Sanguíneo',
            subtitulo: 'Exibir seu tipo sanguíneo',
            privado: conta?.dadoEstaPrivado('tipoSanguineo') ?? false,
            chaves: const ['tipoSanguineo'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('tipoSanguineo'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Estado Civil',
            subtitulo: 'Exibir estado civil',
            privado: conta?.dadoEstaPrivado('estadoCivil') ?? false,
            chaves: const ['estadoCivil'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('estadoCivil'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Telefone e Endereço',
            subtitulo: 'Exibir contato telefônico e localização',
            privado: (conta?.dadoEstaPrivado('telefone') ?? false) ||
                (conta?.dadoEstaPrivado('endereco') ?? false),
            chaves: const ['telefone', 'endereco'],
            conta: conta,
            onAlternar: () {
              auth.alternarPrivacidadeDado('telefone');
              auth.alternarPrivacidadeDado('endereco');
            },
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Biografia e Apresentação',
            subtitulo: 'Exibir seu resumo biográfico na identidade',
            privado: conta?.dadoEstaPrivado('biografia') ?? false,
            chaves: const ['biografia'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('biografia'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'E-mails de Contato',
            subtitulo: 'Exibir seus e-mails cadastrados',
            privado: conta?.dadoEstaPrivado('emails') ?? false,
            chaves: const ['emails'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('emails'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Diárias e Pagamentos (Autogestão)',
            subtitulo: 'Permitir que outros membros vejam suas diárias e valores recebidos na loja',
            privado: conta?.dadoEstaPrivado('pagamentosTrabalhador') ?? false,
            chaves: const ['pagamentosTrabalhador'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('pagamentosTrabalhador'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Escala de Trabalho',
            subtitulo: 'Permitir que outros colaboradores vejam seus dias e horários de escala',
            privado: conta?.dadoEstaPrivado('escalaTrabalho') ?? false,
            chaves: const ['escalaTrabalho'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('escalaTrabalho'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Registro de Ponto',
            subtitulo: 'Permitir que outros colaboradores vejam seus horários de entrada e saída',
            privado: conta?.dadoEstaPrivado('registroPonto') ?? false,
            chaves: const ['registroPonto'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('registroPonto'),
          ),
          _itemPrivacidade(
            context: context,
            theme: theme,
            titulo: 'Contrato de Trabalho',
            subtitulo: 'Permitir visualização dos termos e anexos de contrato de trabalho',
            privado: conta?.dadoEstaPrivado('contratoTrabalho') ?? false,
            chaves: const ['contratoTrabalho'],
            conta: conta,
            onAlternar: () => auth.alternarPrivacidadeDado('contratoTrabalho'),
          ),
        ],
      ),
    );
  }
}
