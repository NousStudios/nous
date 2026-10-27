import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

String _rotuloPapel(PapelMembro papel) {
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

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class UsuariosParticipantesContainer extends StatelessWidget {
  final AppTheme theme;
  final List<MembroLoja> membros;
  final List<CargoLoja> cargosPersonalizados;
  final String cpfLogado;
  final bool podeGerenciar;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviarConvite;
  final ValueChanged<String> onRemover;
  final void Function(String cpf, PapelMembro papel) onAtualizarPapel;
  final void Function(String cpf, String? cargoId)? onVincularCargoPersonalizado;
  final VoidCallback onSair;
  final bool ehLojaColetivaNous;

  const UsuariosParticipantesContainer({
    super.key,
    required this.theme,
    required this.membros,
    this.cargosPersonalizados = const [],
    required this.cpfLogado,
    required this.podeGerenciar,
    required this.buscarConta,
    required this.onEnviarConvite,
    required this.onRemover,
    required this.onAtualizarPapel,
    this.onVincularCargoPersonalizado,
    required this.onSair,
    this.ehLojaColetivaNous = false,
  });

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  void _avisar(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          mensagem,
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  Future<void> _solicitarAcessoAoDado(
    BuildContext context,
    UsuarioNous usuario,
    String rotulo,
    String chave,
  ) async {
    final auth = context.read<AuthProvider>();
    final notificacoes = context.read<NotificacoesProvider>();
    final usuarioLogado = auth.contaAtual;
    if (usuarioLogado == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        title: Text(
          'Solicitar Acesso',
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'Deseja enviar uma notificação para ${usuario.nomeExibicao} solicitando autorização para visualizar seu "$rotulo"?',
          style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Enviar Solicitação',
              style: theme.getTextStyle(color: theme.buttonTextColor),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final solicitacao = ConviteLoja(
        id: 'solic_${DateTime.now().millisecondsSinceEpoch}_${usuarioLogado.cpf}',
        cpfConvidante: usuarioLogado.cpf,
        nomeConvidante: usuarioLogado.nomeExibicao,
        cpfConvidado: usuario.cpf,
        lojaId: '',
        nomeLoja: 'Conta Pessoal',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoDadoUsuario,
        dadoSolicitado: chave,
      );
      await notificacoes.adicionarNotificacao(solicitacao);
      if (context.mounted) {
        _avisar(context, 'Solicitação enviada!');
      }
    }
  }

  void _confirmarRemocao(BuildContext context, MembroLoja membro) {
    final ehVoce = membro.cpf == cpfLogado;

    final meuMembro = membros.firstWhere(
      (m) => m.cpf == cpfLogado,
      orElse: () => MembroLoja(
        cpf: cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDono = meuMembro.papel == PapelMembro.dono;
    final ehOutroDono = !ehVoce && souDono && membro.papel == PapelMembro.dono;

    if (!ehVoce) {
      final ehUltimoDono = membro.papel == PapelMembro.dono &&
          membros.where((m) => m.papel == PapelMembro.dono).length <= 1;
      if (ehUltimoDono) {
        _avisar(context, 'A loja precisa de pelo menos um dono.');
        return;
      }
    } else {
      final souDonoOriginal = membro.papel == PapelMembro.dono;
      final quantidadeDonos =
          membros.where((m) => m.papel == PapelMembro.dono).length;
      final outros = membros.where((m) => m.cpf != cpfLogado).toList();
      if (souDonoOriginal && quantidadeDonos <= 1 && outros.isNotEmpty) {
        _avisar(
          context,
          'Você é o único dono. A posse passará para outro membro ao sair.',
        );
      } else if (souDonoOriginal && outros.isEmpty) {
        _avisar(
          context,
          'Você é o único dono e não há outros membros. A loja será excluída.',
        );
      }
    }

    final String titulo;
    final String mensagem;
    final String botaoTexto;
    final Color botaoCor;

    if (ehVoce) {
      titulo = 'Sair da loja';
      mensagem = 'Tem certeza que deseja sair da loja?';
      botaoTexto = 'Sair';
      botaoCor = theme.dangerColor;
    } else if (ehOutroDono) {
      titulo = 'Solicitar saída de dono';
      mensagem =
          'Como "${membro.nome}" também é Dono(a), a saída da loja exige o seu consentimento. Deseja enviar uma solicitação para que ele(a) concorde em sair?';
      botaoTexto = 'Enviar solicitação';
      botaoCor = theme.textColor;
    } else {
      titulo = 'Remover membro';
      mensagem =
          'Remover "${membro.nome}" da loja? Ele(a) receberá uma notificação informando sobre a remoção.';
      botaoTexto = 'Remover';
      botaoCor = theme.dangerColor;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: Text(
            mensagem,
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (ehVoce) {
                  onSair();
                } else {
                  onRemover(membro.cpf);
                }
              },
              child: Text(
                botaoTexto,
                style: theme.getTextStyle(color: botaoCor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirConvite(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ConviteDialog(
          theme: theme,
          membrosAtuais: membros,
          buscarConta: buscarConta,
          onEnviar: (conta, papel) {
            onEnviarConvite(conta, papel);
            Navigator.of(dialogContext).pop();
            _avisar(context, 'Convite enviado para ${conta.nome}.');
          },
        );
      },
    );
  }

  void _abrirTrocaDePapel(BuildContext context, MembroLoja membro) {
    final meuMembro = membros.firstWhere(
      (m) => m.cpf == cpfLogado,
      orElse: () => MembroLoja(
        cpf: cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDonoOuSocio =
        meuMembro.papel == PapelMembro.dono || meuMembro.papel == PapelMembro.socio;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Cargo e Papel de ${membro.nome}',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Papel Operacional:',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                for (final papel in PapelMembro.values)
                  ListTile(
                    dense: true,
                    title: Text(
                      _rotuloPapel(papel),
                      style: theme.getTextStyle(
                        color: papel == membro.papel
                            ? theme.textColor
                            : theme.secondaryTextColor,
                        fontWeight: papel == membro.papel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: papel == membro.papel
                        ? Icon(Icons.check, color: theme.textColor, size: 18)
                        : null,
                    onTap: () {
                      if (!souDonoOuSocio &&
                          (papel == PapelMembro.dono ||
                              papel == PapelMembro.socio)) {
                        _avisar(
                          context,
                          'Apenas Donos e Sócios podem promover membros a Dono ou Sócio.',
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      onAtualizarPapel(membro.cpf, papel);
                    },
                  ),
                if (cargosPersonalizados.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: theme.borderColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cargo Criado na Loja:',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Nenhum cargo criado',
                      style: theme.getTextStyle(
                        color: membro.cargoPersonalizadoId == null
                            ? theme.textColor
                            : theme.secondaryTextColor,
                        fontWeight: membro.cargoPersonalizadoId == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: membro.cargoPersonalizadoId == null
                        ? Icon(Icons.check, color: theme.textColor, size: 18)
                        : null,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      onVincularCargoPersonalizado?.call(membro.cpf, null);
                    },
                  ),
                  for (final cargo in cargosPersonalizados)
                    ListTile(
                      dense: true,
                      title: Text(
                        cargo.nome,
                        style: theme.getTextStyle(
                          color: membro.cargoPersonalizadoId == cargo.id
                              ? theme.textColor
                              : theme.secondaryTextColor,
                          fontWeight: membro.cargoPersonalizadoId == cargo.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: membro.cargoPersonalizadoId == cargo.id
                          ? Icon(Icons.check, color: theme.textColor, size: 18)
                          : null,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        onVincularCargoPersonalizado?.call(membro.cpf, cargo.id);
                      },
                    ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Fechar',
                style: theme.getTextStyle(color: theme.secondaryTextColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirIdentidadeDoUsuario(BuildContext context, MembroLoja membro) async {
    final conta = await buscarConta(membro.cpf);
    final usuario = conta ??
        UsuarioNous(
          cpf: membro.cpf,
          nome: membro.nome,
          apelido: membro.nome,
          dataNascimento: '',
        );
    if (!context.mounted) return;
    final ehVoce = membro.cpf.replaceAll(RegExp(r'\D'), '') ==
        cpfLogado.replaceAll(RegExp(r'\D'), '');
    FichaUsuarioDialog.mostrar(
      context,
      theme: theme,
      usuario: usuario,
      somenteLeitura: !ehVoce,
    );
  }

  Widget _linhaDeMembro(BuildContext context, MembroLoja membro) {
    final ehVoce = membro.cpf == cpfLogado;
    final podeEditarPapel = !ehLojaColetivaNous && podeGerenciar && !ehVoce;

    final meuMembro = membros.firstWhere(
      (m) => m.cpf == cpfLogado,
      orElse: () => MembroLoja(
        cpf: cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDono = meuMembro.papel == PapelMembro.dono;
    final souSocio = meuMembro.papel == PapelMembro.socio;

    bool podeExcluir = false;
    if (!ehLojaColetivaNous) {
      if (ehVoce) {
        podeExcluir = true;
      } else if (souDono) {
        podeExcluir = true;
      } else if (souSocio) {
        podeExcluir = membro.papel == PapelMembro.admin ||
            membro.papel == PapelMembro.funcionario;
      }
    }

    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();

    String foto = auth.buscarFotoPorCpf(membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
    }

    final temFoto = ImagemService.existe(foto);

    final contaMembro = auth.buscarContaPorCpf(membro.cpf);
    final nomePrivado = contaMembro?.dadoEstaPrivado('nome') ?? false;
    final cpfPrivado = contaMembro?.dadoEstaPrivado('cpf') ?? false;

    String nomeExibido = membro.nome.isEmpty ? 'Sem nome' : membro.nome;
    bool olhoNomeAberto = false;
    VoidCallback? aoClicarOlhoNome;

    if (nomePrivado && contaMembro != null) {
      if (ehVoce) {
        final revelado = auth.dadoEstaReveladoParaDono('nome');
        olhoNomeAberto = revelado;
        aoClicarOlhoNome = () => auth.alternarRevelacaoParaDono('nome');
        nomeExibido = revelado
            ? (contaMembro.nome.isNotEmpty ? contaMembro.nome : 'Sem nome')
            : (contaMembro.apelido.isNotEmpty ? contaMembro.apelido : '••••••••');
      } else {
        final autorizado = contaMembro.dadoAutorizadoPara('nome', cpfLogado);
        if (!autorizado) {
          aoClicarOlhoNome = () => _solicitarAcessoAoDado(context, contaMembro, 'Nome', 'nome');
          nomeExibido = contaMembro.apelido.isNotEmpty ? contaMembro.apelido : '••••••••';
        }
      }
    }

    String cpfExibido = _formatarCpf(membro.cpf);
    if (cpfPrivado && contaMembro != null) {
      if (ehVoce) {
        final revelado = auth.dadoEstaReveladoParaDono('cpf');
        cpfExibido = revelado ? _formatarCpf(membro.cpf) : '•••.•••.•••-••';
      } else {
        final autorizado = contaMembro.dadoAutorizadoPara('cpf', cpfLogado);
        if (!autorizado) {
          cpfExibido = '•••.•••.•••-••';
        }
      }
    }

    return _MembroLinhaComHover(
      builder: (hover) => InkWell(
        onTap: () => _abrirIdentidadeDoUsuario(context, membro),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: temFoto
                    ? ImagemService.construirImagem(
                        foto,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        fallback: Icon(
                          Icons.person,
                          size: 20,
                          color: theme.textColor,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: theme.textColor,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nomeExibido,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      if (aoClicarOlhoNome != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: aoClicarOlhoNome,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              olhoNomeAberto
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 14,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final String rotuloCargo;
                      if (membro.cargoPersonalizadoId == 'desenvolvedor') {
                        rotuloCargo = '${_rotuloPapel(membro.papel)} • Desenvolvedor';
                      } else {
                        final cargoNome = cargosPersonalizados
                            .where((c) => c.id == membro.cargoPersonalizadoId)
                            .firstOrNull
                            ?.nome;
                        rotuloCargo = cargoNome != null && cargoNome.isNotEmpty
                            ? '${_rotuloPapel(membro.papel)} ($cargoNome)'
                            : _rotuloPapel(membro.papel);
                      }
                      return Text(
                        '$rotuloCargo • $cpfExibido'
                        ' • desde ${_dataCurta(membro.desde)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (podeEditarPapel)
              IconButton(
                tooltip: 'Trocar papel',
                icon: Icon(Icons.edit, size: 18, color: theme.textColor),
                onPressed: () => _abrirTrocaDePapel(context, membro),
              ),
            if (podeExcluir)
              IconButton(
                tooltip: ehVoce
                    ? 'Sair da loja'
                    : (souDono && membro.papel == PapelMembro.dono)
                        ? 'Solicitar saída de dono'
                        : 'Remover',
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: () => _confirmarRemocao(context, membro),
              ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco,
      child: Column(
        children: [
          Text(
            'Usuários Participantes',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum membro cadastrado ainda.',
            )
          else
            for (final membro in membros) _linhaDeMembro(context, membro),
          if (!ehLojaColetivaNous && podeGerenciar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _abrirConvite(context),
                child: Text(
                  'Convidar usuário para loja',
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConviteDialog extends StatefulWidget {
  final AppTheme theme;
  final List<MembroLoja> membrosAtuais;
  final Future<UsuarioNous?> Function(String cpf) buscarConta;
  final void Function(UsuarioNous conta, PapelMembro papel) onEnviar;

  const _ConviteDialog({
    required this.theme,
    required this.membrosAtuais,
    required this.buscarConta,
    required this.onEnviar,
  });

  @override
  State<_ConviteDialog> createState() => _ConviteDialogState();
}

class _ConviteDialogState extends State<_ConviteDialog> {
  final _cpfController = TextEditingController();
  bool _buscando = false;
  UsuarioNous? _encontrado;
  PapelMembro _papelEscolhido = PapelMembro.funcionario;
  String? _erro;

  AppTheme get theme => widget.theme;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final digitos = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 11) {
      setState(() {
        _erro = 'Informe um CPF com 11 dígitos.';
        _encontrado = null;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _erro = null;
    });

    final conta = await widget.buscarConta(digitos);
    if (!mounted) return;

    if (conta == null) {
      setState(() {
        _buscando = false;
        _encontrado = null;
        _erro = 'CPF não cadastrado neste dispositivo.';
      });
      return;
    }

    final jaMembro = widget.membrosAtuais.any((m) => m.cpf == conta.cpf);
    setState(() {
      _buscando = false;
      _encontrado = conta;
      _erro = jaMembro ? 'Este CPF já é membro da loja.' : null;
    });
  }

  void _enviar() {
    final conta = _encontrado;
    if (conta == null) return;
    widget.onEnviar(conta, _papelEscolhido);
  }

  InputDecoration _decoracaoCampo(String dica) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: cor),
        );
    return InputDecoration(
      hintText: dica,
      hintStyle:
          theme.getTextStyle(fontSize: 12, color: theme.secondaryTextColor),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: borda(theme.borderColor),
      focusedBorder: borda(theme.textColor),
    );
  }

  Widget _botaoDePapel(PapelMembro papel) {
    final selecionado = papel == _papelEscolhido;
    final corAtiva = theme.buttonColor != Colors.transparent
        ? theme.buttonColor
        : theme.borderColor.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: _MembroLinhaComHover(
        builder: (hover) {
          final corFundo = selecionado
              ? (hover ? corAtiva.withValues(alpha: 0.35) : corAtiva)
              : (hover
                  ? theme.borderColor.withValues(alpha: 0.12)
                  : Colors.transparent);

          final corBorda = selecionado
              ? theme.textColor
              : (hover
                  ? theme.borderColor
                  : theme.borderColor.withValues(alpha: 0.6));

          final corTexto = selecionado
              ? (theme.buttonColor != Colors.transparent
                  ? theme.buttonTextColor
                  : theme.textColor)
              : theme.textColor;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _papelEscolhido = papel),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: corBorda,
                    width: selecionado ? 1.6 : 1.0,
                  ),
                ),
                child: Text(
                  _rotuloPapel(papel),
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight:
                        selecionado ? FontWeight.bold : FontWeight.normal,
                    color: corTexto,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeEnviar = _encontrado != null && _erro == null;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.borderColor),
      ),
      title: Text(
        'Convidar usuário',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CpfInputFormatter()],
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: _decoracaoCampo('CPF do usuário'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textColor,
                    side: BorderSide(color: theme.borderColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _buscando ? null : _buscar,
                  child: Text(
                    'Buscar',
                    style: theme.getTextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_erro != null)
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(fontSize: 12),
              ),
            if (_encontrado != null) ...[
              Text(
                'Conta encontrada:',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final temFotoEnc = ImagemService.existe(_encontrado!.foto);
                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: temFotoEnc
                            ? ImagemService.construirImagem(
                                _encontrado!.foto,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                fallback: Icon(
                                  Icons.person,
                                  size: 24,
                                  color: theme.textColor,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 24,
                                color: theme.textColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _encontrado!.nome,
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              Text(
                'Papel na loja',
                style: theme.getTextStyle(fontSize: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 0,
                runSpacing: 6,
                children: [
                  for (final papel in PapelMembro.values)
                    _botaoDePapel(papel),
                ],
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        TextButton(
          onPressed: podeEnviar ? _enviar : null,
          child: Text(
            'Enviar convite',
            style: theme.getTextStyle(
              color: podeEnviar
                  ? theme.textColor
                  : theme.secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembroLinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;

  const _MembroLinhaComHover({required this.builder});

  @override
  State<_MembroLinhaComHover> createState() => _MembroLinhaComHoverState();
}

class _MembroLinhaComHoverState extends State<_MembroLinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}