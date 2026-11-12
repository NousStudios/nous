import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/models/contrato_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/escala_trabalho_membro.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/trabalhador/aba_contrato_trabalhador_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/trabalhador/aba_escala_trabalhador_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/trabalhador/aba_financeiro_trabalhador_widget.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios/trabalhador/aba_ponto_trabalhador_widget.dart';

/// Modal completo da Central do Trabalhador.
/// Modularizado seguindo a arquitetura limpa (< 450 linhas).
class CentralContratoTrabalhadorDialog extends StatefulWidget {
  final AppTheme theme;
  final String lojaId;
  final MembroLoja membro;
  final String cpfLogado;
  final bool podeGerenciar;

  const CentralContratoTrabalhadorDialog({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.membro,
    required this.cpfLogado,
    required this.podeGerenciar,
  });

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required String lojaId,
    required MembroLoja membro,
    required String cpfLogado,
    required bool podeGerenciar,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => CentralContratoTrabalhadorDialog(
        theme: theme,
        lojaId: lojaId,
        membro: membro,
        cpfLogado: cpfLogado,
        podeGerenciar: podeGerenciar,
      ),
    );
  }

  @override
  State<CentralContratoTrabalhadorDialog> createState() =>
      _CentralContratoTrabalhadorDialogState();
}

class _CentralContratoTrabalhadorDialogState
    extends State<CentralContratoTrabalhadorDialog> {
  int _abaSelecionada = 0;

  late final TextEditingController _tipoContratoController;
  late final TextEditingController _valorPadraoController;
  late final TextEditingController _observacoesContratoController;
  final String _formaPagamentoContrato = 'Dinheiro';
  List<String> _arquivosContrato = [];

  late final TextEditingController _horarioEntradaController;
  late final TextEditingController _horarioSaidaController;
  List<int> _diasEscala = [1, 2, 3, 4, 5];

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    final pdv = context.read<PdvProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);

    final contratoExistente = loja?.contratosTrabalho
        .where((c) => c.cpf == widget.membro.cpf)
        .firstOrNull;

    _tipoContratoController = TextEditingController(
      text: contratoExistente?.tipoContrato ?? '',
    );
    _valorPadraoController = TextEditingController(
      text: (contratoExistente?.valorPadrao ?? 0.0) > 0
          ? contratoExistente!.valorPadrao.toStringAsFixed(2)
          : '',
    );
    _observacoesContratoController = TextEditingController(
      text: contratoExistente?.observacoes ?? '',
    );
    _arquivosContrato = List.from(contratoExistente?.caminhosArquivos ?? []);

    final escalaExistente = loja?.escalasTrabalho
        .where((e) => e.cpf == widget.membro.cpf)
        .firstOrNull;

    _horarioEntradaController = TextEditingController(
      text: escalaExistente?.horarioEntrada ?? '08:00',
    );
    _horarioSaidaController = TextEditingController(
      text: escalaExistente?.horarioSaida ?? '17:00',
    );
    if (escalaExistente != null && escalaExistente.diasSemana.isNotEmpty) {
      _diasEscala = List.from(escalaExistente.diasSemana);
    }
  }

  @override
  void dispose() {
    _tipoContratoController.dispose();
    _valorPadraoController.dispose();
    _observacoesContratoController.dispose();
    _horarioEntradaController.dispose();
    _horarioSaidaController.dispose();
    super.dispose();
  }

  Future<void> _anexarArquivo() async {
    final typeGroup = const XTypeGroup(
      label: 'Documentos',
      extensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'txt'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        if (!_arquivosContrato.contains(file.path)) {
          _arquivosContrato.add(file.path);
        }
      });
    }
  }

  void _salvarContrato() {
    final pdv = context.read<PdvProvider>();
    final valor = double.tryParse(_valorPadraoController.text.replaceAll(',', '.')) ?? 0.0;
    final loja = pdv.lojas.where((l) => l.id == widget.lojaId).firstOrNull;
    final contratoExistente = loja?.contratosTrabalho
        .where((c) => c.cpf == widget.membro.cpf)
        .firstOrNull;

    final contrato = contratoExistente != null
        ? contratoExistente.copyWith(
            tipoContrato: _tipoContratoController.text.trim(),
            valorPadrao: valor,
            formaPagamentoPadrao: _formaPagamentoContrato,
            observacoes: _observacoesContratoController.text.trim(),
            caminhosArquivos: _arquivosContrato,
          )
        : ContratoTrabalhoMembro.novo(
            cpf: widget.membro.cpf,
            tipoContrato: _tipoContratoController.text.trim(),
            valorPadrao: valor,
            formaPagamentoPadrao: _formaPagamentoContrato,
            observacoes: _observacoesContratoController.text.trim(),
            caminhosArquivos: _arquivosContrato,
          );

    pdv.salvarContratoTrabalho(widget.lojaId, contrato);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text('Contrato de trabalho salvo com sucesso!', style: theme.getTextStyle(color: theme.textColor)),
      ),
    );
  }

  void _salvarEscala() {
    final pdv = context.read<PdvProvider>();
    final loja = pdv.lojas.where((l) => l.id == widget.lojaId).firstOrNull;
    final escalaExistente = loja?.escalasTrabalho
        .where((e) => e.cpf == widget.membro.cpf)
        .firstOrNull;

    final escala = escalaExistente != null
        ? escalaExistente.copyWith(
            diasSemana: _diasEscala,
            horarioEntrada: _horarioEntradaController.text.trim(),
            horarioSaida: _horarioSaidaController.text.trim(),
          )
        : EscalaTrabalhoMembro.novo(
            cpf: widget.membro.cpf,
            diasSemana: _diasEscala,
            horarioEntrada: _horarioEntradaController.text.trim(),
            horarioSaida: _horarioSaidaController.text.trim(),
          );

    pdv.salvarEscalaTrabalho(widget.lojaId, escala);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text('Escala semanal de trabalho atualizada!', style: theme.getTextStyle(color: theme.textColor)),
      ),
    );
  }

  void _baterPonto(Loja loja) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();

    final pontoAberto = loja.registrosPonto
        .where((p) => p.cpf == widget.membro.cpf && p.estaEmAberto)
        .firstOrNull;

    if (pontoAberto != null) {
      pdv.finalizarPonto(widget.lojaId, pontoAberto.id, DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text('Ponto finalizado com sucesso!', style: theme.getTextStyle(color: theme.textColor)),
        ),
      );
    } else {
      final novo = RegistroPontoMembro.novo(
        cpf: widget.membro.cpf,
        dataHoraEntrada: DateTime.now(),
        cpfAutor: auth.contaAtual?.cpf ?? widget.cpfLogado,
      );
      pdv.registrarPonto(widget.lojaId, novo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text('Entrada de ponto registrada!', style: theme.getTextStyle(color: theme.textColor)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.watch<PdvProvider>();
    final auth = context.watch<AuthProvider>();
    final loja = pdv.buscarPorId(widget.lojaId);

    final contaMembro = auth.buscarContaPorCpf(widget.membro.cpf);
    final nomeSoberano = contaMembro?.nomeExibicaoPara(
          cpfVisualizador: widget.cpfLogado,
          reveladoParaDono: widget.membro.cpf == widget.cpfLogado,
        ) ??
        widget.membro.nome;

    final pagamentos = loja?.pagamentosFuncionarios
            .where((p) => p.cpf == widget.membro.cpf)
            .toList() ??
        const [];
    final totalRecebido = pagamentos.where((p) => p.pago).fold<double>(0.0, (s, p) => s + p.valor);
    final totalDevido = pagamentos.where((p) => !p.pago).fold<double>(0.0, (s, p) => s + p.valor);

    final pontos = loja?.registrosPonto
            .where((p) => p.cpf == widget.membro.cpf)
            .toList() ??
        const [];
    final temPontoAberto = pontos.any((p) => p.estaEmAberto);

    final escala = loja?.escalasTrabalho
        .where((e) => e.cpf == widget.membro.cpf)
        .firstOrNull;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(Icons.badge_outlined, size: 22, color: theme.textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoRolante(
                  texto: nomeSoberano,
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                TextoRolante(
                  texto: 'Gestão Soberana do Trabalhador • ${widget.membro.papel.name}',
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.textColor, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _botaoAba(0, 'Histórico Financeiro', Icons.monetization_on_outlined),
                  const SizedBox(width: 6),
                  _botaoAba(1, 'Contrato & Arquivos', Icons.description_outlined),
                  const SizedBox(width: 6),
                  _botaoAba(2, 'Ponto Eletrônico', Icons.access_time_rounded),
                  const SizedBox(width: 6),
                  _botaoAba(3, 'Escala de Trabalho', Icons.calendar_month_outlined),
                  const SizedBox(width: 6),
                  _botaoAba(4, 'Identidade Nous', Icons.person_outline),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Builder(builder: (context) {
                  final ehVoce = widget.membro.cpf == widget.cpfLogado;
                  switch (_abaSelecionada) {
                    case 0:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('pagamentosTrabalhador') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('pagamentosTrabalhador', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Diárias e Pagamentos');
                      return AbaFinanceiroTrabalhadorWidget(
                        theme: theme,
                        lojaId: widget.lojaId,
                        pagamentos: pagamentos,
                        totalRecebido: totalRecebido,
                        totalDevido: totalDevido,
                        podeGerenciar: widget.podeGerenciar,
                      );
                    case 1:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('contratoTrabalho') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('contratoTrabalho', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Contrato de Trabalho');
                      return AbaContratoTrabalhadorWidget(
                        theme: theme,
                        podeGerenciar: widget.podeGerenciar,
                        tipoContratoController: _tipoContratoController,
                        valorPadraoController: _valorPadraoController,
                        observacoesContratoController: _observacoesContratoController,
                        arquivosContrato: _arquivosContrato,
                        onAnexarArquivo: _anexarArquivo,
                        onRemoverArquivo: (c) => setState(() => _arquivosContrato.remove(c)),
                        onSalvarContrato: _salvarContrato,
                      );
                    case 2:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('registroPonto') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('registroPonto', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Registro de Ponto');
                      return AbaPontoTrabalhadorWidget(
                        theme: theme,
                        loja: loja,
                        pontos: pontos,
                        temPontoAberto: temPontoAberto,
                        onBaterPonto: () => _baterPonto(loja!),
                      );
                    case 3:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('escalaTrabalho') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('escalaTrabalho', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Escala de Trabalho');
                      return AbaEscalaTrabalhadorWidget(
                        theme: theme,
                        podeGerenciar: widget.podeGerenciar,
                        escala: escala,
                        diasEscala: _diasEscala,
                        horarioEntradaController: _horarioEntradaController,
                        horarioSaidaController: _horarioSaidaController,
                        onAlternarDia: (dia) {
                          setState(() {
                            if (_diasEscala.contains(dia)) {
                              if (_diasEscala.length > 1) _diasEscala.remove(dia);
                            } else {
                              _diasEscala.add(dia);
                            }
                          });
                        },
                        onSalvarEscala: _salvarEscala,
                      );
                    case 4:
                      return _painelIdentidadeSoberana(contaMembro);
                    default:
                      return const SizedBox.shrink();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoAba(int indice, String rotulo, IconData icone) {
    final ativa = _abaSelecionada == indice;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _abaSelecionada = indice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ativa
              ? theme.borderColor.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ativa ? theme.textColor : theme.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 14, color: ativa ? theme.textColor : theme.secondaryTextColor),
            const SizedBox(width: 5),
            Text(
              rotulo,
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
                color: ativa ? theme.textColor : theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoDadoPrivado(String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 36, color: theme.secondaryTextColor),
          const SizedBox(height: 10),
          Text(
            '$rotulo Privado',
            style: theme.getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O trabalhador optou por manter suas informações de $rotulo privadas em sua Conta Nous.',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelIdentidadeSoberana(dynamic contaMembro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ficha Soberana do Cidadão',
          style: theme.getTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Acesse ou consulte a ficha de identidade completa registrada na Conta Nous respeitando os níveis de privacidade e consentimento.',
          style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
            foregroundColor: theme.textColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.badge, size: 18),
          label: Text('Abrir Identidade do Usuário', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          onPressed: () {
            if (contaMembro != null) {
              FichaUsuarioDialog.mostrar(context, theme: theme, usuario: contaMembro);
            }
          },
        ),
      ],
    );
  }
}
