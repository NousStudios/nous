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
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_dados_pessoais_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_emails_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_lojas_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_registro_conta_usuario.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

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
        id: 'solic_${DateTime.now().millisecondsSinceEpoch}_${CpfValidator.onlyDigits(usuarioLogado.cpf)}',
        cpfConvidante: CpfValidator.onlyDigits(usuarioLogado.cpf),
        nomeConvidante: usuarioLogado.nome.isNotEmpty
            ? usuarioLogado.nome
            : usuarioLogado.usernameExibicao,
        cpfConvidado: CpfValidator.onlyDigits(_usuario.cpf),
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
            CpfValidator.onlyDigits(auth.contaAtual!.cpf) ==
                CpfValidator.onlyDigits(_usuario.cpf));
    final contaDoCache = auth.buscarContaPorCpf(_usuario.cpf);
    final contaAtualizada = ehProprioUsuario
        ? (auth.contaAtual ?? _usuario)
        : (contaDoCache ?? _usuario);
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
                final estaPrivado = contaAtualizada.dadoEstaPrivado('nome');
                final autorizado = contaAtualizada.dadoAutorizadoPara('nome', auth.contaAtual?.cpf ?? '');
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
          // Nome de Usuário Nous com Selo de Verificado
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              if (contaAtualizada.verificado || contaAtualizada.validadoPorCpf.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Tooltip(
                  message: 'Conta Verificada pela Comunidade Nous',
                  child: Icon(
                    Icons.verified,
                    size: 15,
                    color: Color(0xFF34B7F1),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          _borrarSeNecessario(
            Builder(
              builder: (context) {
                final cpfVisualizador = auth.contaAtual?.cpf ?? '';
                final estaPrivado = contaAtualizada.dadoEstaPrivado('cpf');

                bool censurado = false;
                bool olhoAberto = false;
                VoidCallback? aoClicarOlho;

                if (ehProprioUsuario) {
                  // O próprio usuário sempre tem o olho disponível para alternar (ex: para tirar prints com segurança)
                  final revelado = auth.dadoEstaReveladoParaDono('cpf');
                  censurado = !revelado;
                  olhoAberto = revelado;
                  aoClicarOlho = () => auth.alternarRevelacaoParaDono('cpf');
                } else if (estaPrivado) {
                  final autorizado = contaAtualizada.dadoAutorizadoPara('cpf', cpfVisualizador);
                  if (!autorizado) {
                    censurado = true;
                    olhoAberto = false;
                    aoClicarOlho = () => _solicitarAcessoAoDado('CPF', 'cpf');
                  }
                }

                Widget? widgetOlho;
                if (aoClicarOlho != null) {
                  widgetOlho = InkWell(
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
                  );
                }

                return SizedBox(
                  width: 220,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          CpfValidator.formatProtegido(
                            contaAtualizada.cpf,
                            revelado: !censurado,
                          ),
                          style: theme.getTextStyle(
                            fontSize: 13,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      if (widgetOlho != null)
                        Positioned(
                          right: 12,
                          child: widgetOlho,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Bloco Dados Pessoais
          BlocoDadosPessoaisUsuario(
            theme: theme,
            usuario: contaAtualizada,
            ehProprioUsuario: ehProprioUsuario,
            cpfVisualizador: auth.contaAtual?.cpf,
            ocultarDados: _ocultarDados,
            editandoDados: _editandoDados,
            telefone: clienteMesmoCpf?.telefone,
            endereco: clienteMesmoCpf != null && clienteMesmoCpf.endereco.isNotEmpty
                ? (clienteMesmoCpf.numero.isNotEmpty
                    ? '${clienteMesmoCpf.endereco}, ${clienteMesmoCpf.numero}'
                    : clienteMesmoCpf.endereco)
                : null,
            redesSociais: clienteMesmoCpf?.redesSociais,
            dataNascController: _dataNascController,
            nomeMaeController: _nomeMaeController,
            nomePaiController: _nomePaiController,
            localNascController: _localNascController,
            tipoSanguineoController: _tipoSanguineoController,
            estadoCivilController: _estadoCivilController,
            onIniciarEdicao: () => _iniciarEdicao(contaAtualizada),
            onCancelarEdicao: () => setState(() => _editandoDados = false),
            onSalvarEdicao: _salvarDadosPessoais,
            onSolicitarAcesso: _solicitarAcessoAoDado,
          ),

          const SizedBox(height: 12),

          // Bloco E-mails Associados
          BlocoEmailsUsuario(
            theme: theme,
            usuario: contaAtualizada,
            emailAtivo: auth.emailAtivo,
            ocultarDados: _ocultarDados,
            decoracao: _decoracaoDoBloco,
          ),

          const SizedBox(height: 12),

          // Bloco Lojas / Participações
          BlocoLojasUsuario(
            theme: theme,
            cpfUsuario: contaAtualizada.cpf,
            lojasAdmin: lojasAdmin,
            lojasParticipa: lojasParticipa,
            decoracao: _decoracaoDoBloco,
          ),

          const SizedBox(height: 12),

          // Bloco Registro Soberano & Validação de Identidade
          BlocoRegistroContaUsuario(
            theme: theme,
            usuario: contaAtualizada,
            decoracao: _decoracaoDoBloco,
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
