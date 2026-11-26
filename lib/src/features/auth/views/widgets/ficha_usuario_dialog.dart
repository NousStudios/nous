import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/services/cep_service.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/auth/views/widgets/ficha/cabecalho_ficha_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha/solicitar_acesso_dado_dialog.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_dados_pessoais_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_emails_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_lojas_usuario.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario/bloco_registro_conta_usuario.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class FichaUsuarioDialog {
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required UsuarioNous usuario,
    bool? somenteLeitura,
  }) {
    return GuardaAcaoUi.executarUnico<void>(
      'dialog_ficha_${usuario.cpf}',
      () => showDialog<void>(
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
      ),
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
  late final TextEditingController _cepResidencialController;
  late final TextEditingController _enderecoResidencialController;
  late final TextEditingController _numeroResidencialController;
  bool _buscandoCep = false;
  String _ultimoCepConsultado = '';

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
    _cepResidencialController =
        TextEditingController(text: widget.usuarioInicial.cepResidencial);
    _enderecoResidencialController =
        TextEditingController(text: widget.usuarioInicial.enderecoResidencial);
    _numeroResidencialController =
        TextEditingController(text: widget.usuarioInicial.numeroResidencial);
    _ultimoCepConsultado =
        CepService.normalizarDigitos(widget.usuarioInicial.cepResidencial);
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
    _cepResidencialController.dispose();
    _enderecoResidencialController.dispose();
    _numeroResidencialController.dispose();
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
    _cepResidencialController.text = atual.cepResidencial;
    _enderecoResidencialController.text = atual.enderecoResidencial;
    _numeroResidencialController.text = atual.numeroResidencial;
    _ultimoCepConsultado = CepService.normalizarDigitos(atual.cepResidencial);
    setState(() => _editandoDados = true);
  }

  Future<void> _aoAlterarCep(String valor) async {
    final digitos = CepService.normalizarDigitos(valor);
    if (digitos.length != 8 || digitos == _ultimoCepConsultado) {
      return;
    }
    _ultimoCepConsultado = digitos;
    if (mounted) setState(() => _buscandoCep = true);

    final resultado = await CepService.buscar(digitos);
    if (!mounted) return;
    setState(() => _buscandoCep = false);

    if (resultado == null) return;
    final partes = <String>[
      if (resultado.logradouro.isNotEmpty) resultado.logradouro,
      if (resultado.bairro.isNotEmpty) resultado.bairro,
      if (resultado.cidade.isNotEmpty)
        resultado.uf.isNotEmpty
            ? '${resultado.cidade} - ${resultado.uf}'
            : resultado.cidade,
    ];
    if (partes.isNotEmpty) {
      _enderecoResidencialController.text = partes.join(', ');
    }
  }

  Future<void> _salvarDadosPessoais() async {
    final auth = context.read<AuthProvider>();
    final dataNasc = _dataNascController.text.trim();
    final mae = _nomeMaeController.text.trim();
    final pai = _nomePaiController.text.trim();
    final local = _localNascController.text.trim();
    final sangue = _tipoSanguineoController.text.trim();
    final estadoCiv = _estadoCivilController.text.trim();
    final cepRes = _cepResidencialController.text.trim();
    final enderecoRes = _enderecoResidencialController.text.trim();
    final numeroRes = _numeroResidencialController.text.trim();

    await auth.atualizarDadosPessoais(
      dataNascimento: dataNasc,
      nomeMae: mae,
      nomePai: pai,
      localNascimento: local,
      tipoSanguineo: sangue,
      estadoCivil: estadoCiv,
      cepResidencial: cepRes,
      enderecoResidencial: enderecoRes,
      numeroResidencial: numeroRes,
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
        cepResidencial: cepRes,
        enderecoResidencial: enderecoRes,
        numeroResidencial: numeroRes,
      );
      _editandoDados = false;
    });
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Future<void> _solicitarAcessoAoDado(String rotulo, String chave) {
    return SolicitarAcessoDadoDialog.mostrar(
      context,
      theme: theme,
      usuarioAlvo: _usuario,
      rotulo: rotulo,
      chave: chave,
    );
  }

  Future<void> _aoClicarFoto() async {
    final temFoto =
        _usuario.foto.isNotEmpty && ImagemService.existe(_usuario.foto);

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

    final clienteMesmoCpf = pdv.buscarClientePorCpf(contaAtualizada.cpf);
    final lojasAdmin = pdv.lojasQueAdministro;
    final lojasParticipa = pdv.lojasQueParticipo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CabecalhoFichaUsuario(
            theme: theme,
            usuario: contaAtualizada,
            ehProprioUsuario: ehProprioUsuario,
            cpfVisualizador: auth.contaAtual?.cpf ?? '',
            ocultarDados: _ocultarDados,
            fotoResolvida: fotoResolvida,
            apelidoController: _apelidoController,
            nomeController: _nomeController,
            nomePrivadoDono: _usuario.dadoEstaPrivado('nome'),
            nomeReveladoDono: auth.dadoEstaReveladoParaDono('nome'),
            cpfReveladoDono: auth.dadoEstaReveladoParaDono('cpf'),
            onAlternarOcultarDados: () =>
                setState(() => _ocultarDados = !_ocultarDados),
            onAoClicarFoto: _aoClicarFoto,
            onSalvarApelido: _salvarApelido,
            onSalvarNome: _salvarNome,
            onAlternarRevelacaoNome: () =>
                auth.alternarRevelacaoParaDono('nome'),
            onAlternarRevelacaoCpf: () =>
                auth.alternarRevelacaoParaDono('cpf'),
            onSolicitarAcesso: _solicitarAcessoAoDado,
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
            endereco:
                clienteMesmoCpf != null && clienteMesmoCpf.endereco.isNotEmpty
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
            cepResidencialController: _cepResidencialController,
            enderecoResidencialController: _enderecoResidencialController,
            numeroResidencialController: _numeroResidencialController,
            buscandoCep: _buscandoCep,
            onAlterarCep: _aoAlterarCep,
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
}
