import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';

/// Card especializado para exibição de convites e solicitações da loja e da rede social.
class CardNotificacaoConvite extends StatelessWidget {
  final AppTheme theme;
  final ConviteLoja convite;
  final VoidCallback onAceitar;
  final VoidCallback onRecusar;

  const CardNotificacaoConvite({
    super.key,
    required this.theme,
    required this.convite,
    required this.onAceitar,
    required this.onRecusar,
  });

  static String _formatarCpf(String cpf) {
    final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 11) return cpf;
    return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
        '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
  }

  static String _rotuloPapel(PapelMembro papel) {
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

  static String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  static String _dataHoraCurta(DateTime d) =>
      '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
      '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

  @override
  Widget build(BuildContext context) {
    final c = convite;
    final String titulo;
    final String descricao;
    final bool ehAvisoInformativo;

    switch (c.tipo) {
      case TipoNotificacao.alteracaoPapel:
        titulo = 'Solicitação de ${c.nomeConvidante}';
        descricao =
            'Alteração do seu papel em "${c.nomeLoja}" para ${_rotuloPapel(c.papel)}';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.solicitacaoExclusaoDono:
        titulo = 'Solicitação de saída por ${c.nomeConvidante}';
        descricao =
            '${c.nomeConvidante} solicitou a sua saída da loja "${c.nomeLoja}". Como você é Dono(a), sua saída depende do seu consentimento.';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.remocaoLoja:
        titulo = 'Aviso de remoção';
        descricao =
            'Você foi removido(a) da loja "${c.nomeLoja}" por ${c.nomeConvidante}.';
        ehAvisoInformativo = true;
        break;
      case TipoNotificacao.conviteEntrada:
        titulo = 'Convite de ${c.nomeConvidante}';
        descricao =
            'Para entrar em "${c.nomeLoja}" como ${_rotuloPapel(c.papel)}';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.solicitacaoDadoUsuario:
        titulo = 'Acesso a dado pessoal por ${c.nomeConvidante}';
        descricao =
            '${c.nomeConvidante} solicitou permissão para visualizar seu dado "${c.dadoSolicitado.isNotEmpty ? c.dadoSolicitado : "dado privado"}" na rede.';
        ehAvisoInformativo = false;
        break;
      case TipoNotificacao.solicitacaoExclusaoConversa:
        titulo = 'Consentimento para excluir conversa';
        descricao =
            '${c.nomeConvidante} propôs excluir o histórico da conversa "${c.nomeLoja}". Você concorda?';
        ehAvisoInformativo = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: theme.getTextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatarCpf(c.cpfConvidante)} • ${_dataHoraCurta(c.dataHora)}',
            style: theme.getTextStyle(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (ehAvisoInformativo)
                TextButton(
                  onPressed: onAceitar,
                  child: Text(
                    'Entendido',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: onRecusar,
                  child: Text(
                    'Recusar',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onAceitar,
                  child: Text(
                    'Aceitar',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
