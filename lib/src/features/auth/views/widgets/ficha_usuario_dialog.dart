import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/notificacoes/models/convite_loja.dart';
import 'package:nous/src/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
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
    bool? somenteLeitura,
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
              somenteLeitura: somenteLeitura,
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
  final bool? somenteLeitura;

  const _FichaUsuarioConteudo({
    required this.theme,
    required this.usuarioInicial,
    this.somenteLeitura,
  });

  @override
  State<_FichaUsuarioConteudo> createState() => _FichaUsuarioConteudoState();
}

class _FichaUsuarioConteudoState extends State<_FichaUsuarioConteudo> {
  late UsuarioNous _usuario;
  bool _editandoDados = false;
  bool _ocultarDados = true;

  late final TextEditingController _nomeController;
  late final TextEditingController _apelidoController;
  late final TextEditingController _dataNascController;
  late final TextEditingController _nomeMaeController;
  late final TextEditingController _nomePaiController;
  late final TextEditingController _localNascController;
  late final TextEditingController _tipoSanguineoController;
  late final TextEditingController _estadoCivilController;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuarioInicial;
    _nomeController =
        TextEditingController(text: widget.usuarioInicial.nome);
    _apelidoController =
        TextEditingController(text: widget.usuarioInicial.apelido);
    _dataNascController =
        TextEditingController(text: widget.usuarioInicial.dataNascimento);
    _nomeMaeController =
        TextEditingController(text: widget.usuarioInicial.nomeMae);
    _nomePaiController =
        TextEditingController(text: widget.usuarioInicial.nomePai);
    _localNascController =
        TextEditingController(text: widget.usuarioInicial.localNascimento);
    _tipoSanguineoController =
        TextEditingController(text: widget.usuarioInicial.tipoSanguineo);
    _estadoCivilController =
        TextEditingController(text: widget.usuarioInicial.estadoCivil);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _apelidoController.dispose();
    _dataNascController.dispose();
    _nomeMaeController.dispose();
    _nomePaiController.dispose();
    _localNascController.dispose();
    _tipoSanguineoController.dispose();
    _estadoCivilController.dispose();
    super.dispose();
  }

  Future<void> _salvarNome(String novoNome) async {
    final auth = context.read<AuthProvider>();
    await auth.atualizarNome(novoNome);
    setState(() {
      _usuario = _usuario.copyWith(nome: novoNome.trim());
    });
  }

  Future<void> _salvarApelido(String novoApelido) async {
    final auth = context.read<AuthProvider>();
    await auth.atualizarApelido(novoApelido);
    setState(() {
      _usuario = _usuario.copyWith(apelido: novoApelido.trim());
    });
  }

  void _iniciarEdicao(UsuarioNous atual) {
    _dataNascController.text = atual.dataNascimento;
    _nomeMaeController.text = atual.nomeMae;
    _nomePaiController.text = atual.nomePai;
    _localNascController.text = atual.localNascimento;
    _tipoSanguineoController.text = atual.tipoSanguineo;
    _estadoCivilController.text = atual.estadoCivil;
    setState(() => _editandoDados = true);
  }

  Future<void> _salvarDadosPessoais() async {
    final auth = context.read<AuthProvider>();
    final dataNasc = _dataNascController.text.trim();
    final mae = _nomeMaeController.text.trim();
    final pai = _nomePaiController.text.trim();
    final local = _localNascController.text.trim();
    final sangue = _tipoSanguineoController.text.trim();
    final estadoCiv = _estadoCivilController.text.trim();

    await auth.atualizarDadosPessoais(
      dataNascimento: dataNasc,
      nomeMae: mae,
      nomePai: pai,
      localNascimento: local,
      tipoSanguineo: sangue,
      estadoCivil: estadoCiv,
    );

    if (!mounted) return;
    setState(() {
      _usuario = _usuario.copyWith(
        dataNascimento: dataNasc,
        nomeMae: mae,
        nomePai: pai,
        localNascimento: local,
        tipoSanguineo: sangue,
        estadoCivil: estadoCiv,
      );
      _editandoDados = false;
    });
  }

  Widget _campoEdicao(String rotulo, TextEditingController controller,
      {String dica = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            cursorColor: theme.textColor,
            style: theme.getTextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: dica,
              hintStyle: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Future<void> _solicitarAcessoAoDado(String rotulo, String chave) async {
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
          'Deseja enviar uma notificação para ${_usuario.nome.isNotEmpty ? _usuario.nome : "o usuário"} solicitando autorização para visualizar: "$rotulo"?',
          style: theme.getTextStyle(
            fontSize: 13,
            color: theme.textColor,
          ),
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

    if (confirmar == true && mounted) {
      final solicitacao = ConviteLoja(
        id: 'solic_${DateTime.now().millisecondsSinceEpoch}_${usuarioLogado.cpf}',
        cpfConvidante: usuarioLogado.cpf,
        nomeConvidante: usuarioLogado.nome.isNotEmpty
            ? usuarioLogado.nome
            : usuarioLogado.usernameExibicao,
        cpfConvidado: _usuario.cpf,
        lojaId: '',
        nomeLoja: 'Conta Pessoal',
        papel: PapelMembro.funcionario,
        dataHora: DateTime.now(),
        tipo: TipoNotificacao.solicitacaoDadoUsuario,
        dadoSolicitado: chave,
      );
      await notificacoes.adicionarNotificacao(solicitacao);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'Solicitação enviada para ${_usuario.nome.isNotEmpty ? _usuario.nome : "o usuário"}!',
              style: theme.getTextStyle(color: theme.textColor),
            ),
          ),
        );
      }
    }
  }

  Widget _linhaInfo(
    String rotulo,
    String valor, {
    bool destaque = false,
    String? chavePrivacidade,
    bool ehProprioUsuario = true,
    String? cpfVisualizador,
  }) {
    final auth = context.watch<AuthProvider>();
    final temChave = chavePrivacidade != null;
    final estaPrivado = temChave && _usuario.dadoEstaPrivado(chavePrivacidade);

    bool censurado = false;
    bool olhoAberto = false;
    VoidCallback? aoClicarOlho;

    if (estaPrivado) {
      if (ehProprioUsuario) {
        final revelado = auth.dadoEstaReveladoParaDono(chavePrivacidade);
        censurado = !revelado;
        olhoAberto = revelado;
        aoClicarOlho = () => auth.alternarRevelacaoParaDono(chavePrivacidade);
      } else {
        final autorizado = _usuario.dadoAutorizadoPara(chavePrivacidade, cpfVisualizador ?? '');
        if (!autorizado) {
          censurado = true;
          olhoAberto = false;
          aoClicarOlho = () => _solicitarAcessoAoDado(rotulo, chavePrivacidade);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              censurado ? '••••••••' : (valor.isEmpty ? '—' : valor),
              textAlign: TextAlign.right,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
                color: destaque ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ),
          if (estaPrivado && aoClicarOlho != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: aoClicarOlho,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  olhoAberto ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 15,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _aoClicarFoto() async {
    final temFoto = _usuario.foto.isNotEmpty && ImagemService.existe(_usuario.foto);

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
    final ehProprioUsuario = (widget.somenteLeitura == false) ||
        (widget.somenteLeitura == null &&
            auth.contaAtual != null &&
            auth.contaAtual!.cpf.replaceAll(RegExp(r'\D'), '') ==
                _usuario.cpf.replaceAll(RegExp(r'\D'), ''));
    final contaAtualizada =
        ehProprioUsuario ? (auth.contaAtual ?? _usuario) : _usuario;
    final fotoResolvida =
        ImagemService.resolverCaminhoExistente(contaAtualizada.foto);
    final temFoto = fotoResolvida != null;

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
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _ocultarDados
                    ? 'Mostrar dados sensíveis'
                    : 'Ocultar dados sensíveis',
                icon: Icon(
                  _ocultarDados
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.secondaryTextColor,
                ),
                onPressed: () {
                  setState(() {
                    _ocultarDados = !_ocultarDados;
                  });
                },
              ),
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

          // Avatar Clicável (apenas se for o próprio usuário)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: ehProprioUsuario ? _aoClicarFoto : null,
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
                        File(fotoResolvida),
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

          // Apelido (acima do nome real, na mesma grafia do CPF)
          if (ehProprioUsuario)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 260,
                child: TextField(
                  controller: _apelidoController,
                  textAlign: TextAlign.center,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                  cursorColor: theme.textColor,
                  decoration: InputDecoration(
                    labelText: 'Apelido',
                    labelStyle: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                    hintText: 'Digite seu apelido',
                    hintStyle: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: theme.textColor),
                    ),
                  ),
                  onChanged: (novo) => _salvarApelido(novo),
                ),
              ),
            )
          else if (contaAtualizada.apelido.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                contaAtualizada.apelido,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),

          if (ehProprioUsuario)
            Builder(
              builder: (context) {
                final estaPrivado = _usuario.dadoEstaPrivado('nome');
                final revelado = auth.dadoEstaReveladoParaDono('nome');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Center(
                    child: SizedBox(
                      width: 260,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          TextField(
                            controller: _nomeController,
                            textAlign: TextAlign.center,
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                            cursorColor: theme.textColor,
                            decoration: InputDecoration(
                              labelText: 'Nome Próprio',
                              labelStyle: theme.getTextStyle(
                                fontSize: 12,
                                color: theme.secondaryTextColor,
                              ),
                              hintText: 'Digite seu nome completo',
                              hintStyle: theme.getTextStyle(
                                fontSize: 13,
                                color: theme.secondaryTextColor.withValues(alpha: 0.6),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: estaPrivado ? 28 : 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: theme.borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: theme.textColor),
                              ),
                            ),
                            onChanged: (novo) => _salvarNome(novo),
                          ),
                          if (estaPrivado)
                            Positioned(
                              right: 6,
                              child: InkWell(
                                onTap: () => auth.alternarRevelacaoParaDono('nome'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    revelado
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 16,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Builder(
              builder: (context) {
                final estaPrivado = _usuario.dadoEstaPrivado('nome');
                final autorizado = _usuario.dadoAutorizadoPara('nome', auth.contaAtual?.cpf ?? '');
                final nomeTexto = estaPrivado && !autorizado
                    ? (contaAtualizada.apelido.isNotEmpty ? contaAtualizada.apelido : '••••••••')
                    : (contaAtualizada.nome.isEmpty ? 'Nome do Usuário' : contaAtualizada.nome);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nomeTexto,
                      textAlign: TextAlign.center,
                      style: theme.getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (estaPrivado && !autorizado) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _solicitarAcessoAoDado('Nome', 'nome'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.visibility_off_outlined,
                            size: 15,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 6),
          // Nome de Usuário Nous (imutável, com a mesma identidade visual do CPF)
          Text(
            contaAtualizada.usernameExibicao.isNotEmpty
                ? contaAtualizada.usernameExibicao
                : '@usuario',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          _borrarSeNecessario(
            Builder(
              builder: (context) {
                final cpfVisualizador = auth.contaAtual?.cpf ?? '';
                final estaPrivado = _usuario.dadoEstaPrivado('cpf');

                bool censurado = false;
                bool olhoAberto = false;
                VoidCallback? aoClicarOlho;

                if (estaPrivado) {
                  if (ehProprioUsuario) {
                    final revelado = auth.dadoEstaReveladoParaDono('cpf');
                    censurado = !revelado;
                    olhoAberto = revelado;
                    aoClicarOlho = () => auth.alternarRevelacaoParaDono('cpf');
                  } else {
                    final autorizado = _usuario.dadoAutorizadoPara('cpf', cpfVisualizador);
                    if (!autorizado) {
                      censurado = true;
                      olhoAberto = false;
                      aoClicarOlho = () => _solicitarAcessoAoDado('CPF', 'cpf');
                    }
                  }
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      censurado
                          ? '•••.•••.•••-••'
                          : _formatarCpf(contaAtualizada.cpf),
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    if (estaPrivado && aoClicarOlho != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: aoClicarOlho,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            olhoAberto
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 15,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Bloco Dados Pessoais
          _borrarSeNecessario(
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
                if (_editandoDados) ...[
                  _campoEdicao('Data de nascimento', _dataNascController,
                      dica: 'DD/MM/AAAA'),
                  _campoEdicao('Nome da Mãe', _nomeMaeController,
                      dica: 'Nome completo da mãe'),
                  _campoEdicao('Nome do Pai', _nomePaiController,
                      dica: 'Nome completo do pai'),
                  _campoEdicao('Local de Nascimento', _localNascController,
                      dica: 'Cidade - UF'),
                  _campoEdicao('Tipo Sanguíneo', _tipoSanguineoController,
                      dica: 'Ex: O+, A-, AB+'),
                  _campoEdicao('Estado Civil', _estadoCivilController,
                      dica: 'Ex: Solteiro(a), Casado(a)'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _editandoDados = false),
                        child: Text(
                          'Cancelar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.buttonColor,
                          foregroundColor: theme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _salvarDadosPessoais,
                        child: Text(
                          'Salvar',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.buttonTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _linhaInfo(
                    'Data de nascimento',
                    contaAtualizada.dataNascimento,
                    chavePrivacidade: 'dataNascimento',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  _linhaInfo(
                    'Nome da mãe',
                    contaAtualizada.nomeMae,
                    chavePrivacidade: 'nomeMae',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  _linhaInfo(
                    'Nome do pai',
                    contaAtualizada.nomePai,
                    chavePrivacidade: 'nomePai',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  _linhaInfo(
                    'Local de nascimento',
                    contaAtualizada.localNascimento,
                    chavePrivacidade: 'localNascimento',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  _linhaInfo(
                    'Tipo sanguíneo',
                    contaAtualizada.tipoSanguineo,
                    chavePrivacidade: 'tipoSanguineo',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  _linhaInfo(
                    'Estado civil',
                    contaAtualizada.estadoCivil,
                    chavePrivacidade: 'estadoCivil',
                    ehProprioUsuario: ehProprioUsuario,
                    cpfVisualizador: auth.contaAtual?.cpf,
                  ),
                  if (clienteMesmoCpf != null) ...[
                    if (clienteMesmoCpf.telefone.isNotEmpty)
                      _linhaInfo(
                        'Telefone',
                        clienteMesmoCpf.telefone,
                        chavePrivacidade: 'telefone',
                        ehProprioUsuario: ehProprioUsuario,
                        cpfVisualizador: auth.contaAtual?.cpf,
                      ),
                    if (clienteMesmoCpf.endereco.isNotEmpty)
                      _linhaInfo(
                        'Endereço',
                        clienteMesmoCpf.numero.isNotEmpty
                            ? '${clienteMesmoCpf.endereco}, ${clienteMesmoCpf.numero}'
                            : clienteMesmoCpf.endereco,
                        chavePrivacidade: 'endereco',
                        ehProprioUsuario: ehProprioUsuario,
                        cpfVisualizador: auth.contaAtual?.cpf,
                      ),
                    if (clienteMesmoCpf.redesSociais.isNotEmpty)
                      _linhaInfo('Redes sociais', clienteMesmoCpf.redesSociais),
                  ],
                  if (ehProprioUsuario) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(color: theme.borderColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _iniciarEdicao(contaAtualizada),
                        icon: Icon(Icons.edit_outlined,
                            size: 16, color: theme.textColor),
                        label: Text(
                          'Editar dados pessoais',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ],
            ),
          ),
          ),

          const SizedBox(height: 12),

          // Bloco E-mails Associados
          _borrarSeNecessario(
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
                      _linhaInfo(l.nome, _obterCargoUsuarioNaLoja(l, contaAtualizada.cpf)),
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
                      _linhaInfo(l.nome, _obterCargoUsuarioNaLoja(l, contaAtualizada.cpf)),
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

  String _obterCargoUsuarioNaLoja(Loja loja, String cpfUsuario) {
    final cpfDigitos = cpfUsuario.replaceAll(RegExp(r'\D'), '');
    for (final m in loja.membros) {
      if (m.cpf.replaceAll(RegExp(r'\D'), '') == cpfDigitos) {
        if (m.cargoPersonalizadoId != null &&
            m.cargoPersonalizadoId!.trim().isNotEmpty) {
          final cargoPers = loja.cargosPersonalizados
              .where((c) => c.id == m.cargoPersonalizadoId)
              .firstOrNull;
          if (cargoPers != null && cargoPers.nome.trim().isNotEmpty) {
            return cargoPers.nome.trim();
          }
        }
        switch (m.papel) {
          case PapelMembro.dono:
            return 'Dono';
          case PapelMembro.socio:
            return 'Sócio';
          case PapelMembro.admin:
            return 'Administrador';
          case PapelMembro.funcionario:
            return 'Funcionário';
        }
      }
    }
    if (loja.cpfDonoOriginal.replaceAll(RegExp(r'\D'), '') == cpfDigitos) {
      return 'Dono';
    }
    return 'Membro';
  }

  Widget _borrarSeNecessario(Widget child) {
    if (!_ocultarDados) return child;
    return IgnorePointer(
      ignoring: true,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
        child: child,
      ),
    );
  }
}
