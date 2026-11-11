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
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/registro_ponto_membro.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

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

  // Controllers Contrato
  late final TextEditingController _tipoContratoController;
  late final TextEditingController _valorPadraoController;
  late final TextEditingController _observacoesContratoController;
  String _formaPagamentoContrato = 'Dinheiro';
  List<String> _arquivosContrato = [];

  // Controllers Escala
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
      text: contratoExistente?.tipoContrato ?? 'Diarista',
    );
    _valorPadraoController = TextEditingController(
      text: contratoExistente != null && contratoExistente.valorPadrao > 0
          ? contratoExistente.valorPadrao.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _observacoesContratoController = TextEditingController(
      text: contratoExistente?.observacoes ?? '',
    );
    _formaPagamentoContrato = contratoExistente?.formaPagamentoPadrao ?? 'Dinheiro';
    _arquivosContrato = List<String>.from(contratoExistente?.caminhosArquivos ?? const []);

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
      _diasEscala = List<int>.from(escalaExistente.diasSemana);
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

  String _formatarDataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }

  String _formatarMoeda(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _anexarArquivo() async {
    try {
      final arquivos = await openFiles();
      if (arquivos.isNotEmpty) {
        setState(() {
          for (final a in arquivos) {
            if (!_arquivosContrato.contains(a.path)) {
              _arquivosContrato.add(a.path);
            }
          }
        });
      }
    } catch (_) {}
  }

  void _salvarContrato() {
    final valor = double.tryParse(_valorPadraoController.text.replaceAll(',', '.')) ?? 0.0;
    final contrato = ContratoTrabalhoMembro(
      id: widget.membro.cpf,
      cpf: widget.membro.cpf,
      tipoContrato: _tipoContratoController.text.trim(),
      valorPadrao: valor,
      formaPagamentoPadrao: _formaPagamentoContrato,
      caminhosArquivos: _arquivosContrato,
      dataInicio: DateTime.now(),
      observacoes: _observacoesContratoController.text.trim(),
    );
    context.read<PdvProvider>().salvarContratoTrabalho(widget.lojaId, contrato);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text('Contrato de trabalho salvo com sucesso!', style: theme.getTextStyle(color: theme.textColor)),
      ),
    );
  }

  void _salvarEscala() {
    final escala = EscalaTrabalhoMembro(
      id: widget.membro.cpf,
      cpf: widget.membro.cpf,
      diasSemana: _diasEscala,
      horarioEntrada: _horarioEntradaController.text.trim(),
      horarioSaida: _horarioSaidaController.text.trim(),
      ativo: true,
    );
    context.read<PdvProvider>().salvarEscalaTrabalho(widget.lojaId, escala);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text('Escala semanal salva com sucesso!', style: theme.getTextStyle(color: theme.textColor)),
      ),
    );
  }

  void _baterPonto(Loja loja) {
    final pdv = context.read<PdvProvider>();
    final auth = context.read<AuthProvider>();
    final pontosAbertos = loja.registrosPonto
        .where((p) => p.cpf == widget.membro.cpf && p.estaEmAberto)
        .toList();

    if (pontosAbertos.isNotEmpty) {
      // Finaliza o ponto em aberto
      final ultimo = pontosAbertos.first;
      pdv.finalizarPonto(widget.lojaId, ultimo.id, DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text('Ponto finalizado com sucesso!', style: theme.getTextStyle(color: theme.textColor)),
        ),
      );
    } else {
      // Inicia novo ponto
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
            // Abas de navegação
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
                      return _painelHistoricoFinanceiro(pagamentos, totalRecebido, totalDevido);
                    case 1:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('contratoTrabalho') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('contratoTrabalho', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Contrato de Trabalho');
                      return _painelContratoTrabalho();
                    case 2:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('registroPonto') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('registroPonto', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Registro de Ponto');
                      return _painelPontoEletronico(loja, pontos, temPontoAberto);
                    case 3:
                      final privado = !ehVoce &&
                          (contaMembro?.dadoEstaPrivado('escalaTrabalho') ?? false) &&
                          !(contaMembro?.dadoAutorizadoPara('escalaTrabalho', widget.cpfLogado) ?? false);
                      if (privado) return _blocoDadoPrivado('Escala de Trabalho');
                      return _painelEscalaTrabalho(escala);
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

  Widget _painelHistoricoFinanceiro(List<PagamentoFuncionario> pagamentos, double recebido, double devido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(texto: 'Total Recebido', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                    const SizedBox(height: 2),
                    TextoRolante(texto: _formatarMoeda(recebido), style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(texto: 'Pendente (A Prazo)', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                    const SizedBox(height: 2),
                    TextoRolante(texto: _formatarMoeda(devido), style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: devido > 0 ? theme.dangerColor : theme.textColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextoRolante(texto: 'Extrato de Diárias e Pagamentos (${pagamentos.length}):', style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor)),
        const SizedBox(height: 6),
        if (pagamentos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum pagamento registrado para este trabalhador ainda.', textAlign: TextAlign.center, style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pagamentos.length,
            separatorBuilder: (_, _) => Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
            itemBuilder: (context, idx) {
              final p = pagamentos[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(_formatarDataHora(p.dataHora), style: theme.getTextStyle(fontSize: 10.5, color: theme.secondaryTextColor)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextoRolante(
                        texto: '${p.descricao.isNotEmpty ? p.descricao : "Diária/Salário"} (${p.formaPagamento}${!p.pago ? " • A Prazo" : ""})',
                        style: theme.getTextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatarMoeda(p.valor),
                      style: theme.getTextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: !p.pago ? theme.dangerColor : theme.textColor),
                    ),
                    if (!p.pago && widget.podeGerenciar) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                        onPressed: () => context.read<PdvProvider>().quitarPagamentoFuncionario(widget.lojaId, p.id),
                        child: Text('Quitar', style: theme.getTextStyle(fontSize: 10, color: theme.textColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _painelContratoTrabalho() {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de Contrato', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _tipoContratoController,
                    enabled: widget.podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'CLT, PJ, Diarista, Temporário',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: borda(theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valor Padrão da Diária', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _valorPadraoController,
                    enabled: widget.podeGerenciar,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: borda(theme.borderColor.withValues(alpha: 0.5)),
                      focusedBorder: borda(theme.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Observações do Contrato', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
        const SizedBox(height: 4),
        TextField(
          controller: _observacoesContratoController,
          enabled: widget.podeGerenciar,
          maxLines: 2,
          style: theme.getTextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Acordos, condições de pagamento, benefícios...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: borda(theme.borderColor.withValues(alpha: 0.5)),
            focusedBorder: borda(theme.textColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextoRolante(
                texto: 'Arquivos & Documentos Anexados (${_arquivosContrato.length}):',
                style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor),
              ),
            ),
            if (widget.podeGerenciar) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                onPressed: _anexarArquivo,
                icon: Icon(Icons.attach_file, size: 14, color: theme.textColor),
                label: Text('Anexar', style: theme.getTextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (_arquivosContrato.isEmpty)
          Text('Nenhum documento anexado ainda.', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _arquivosContrato.map((caminho) {
              final nomeArquivo = caminho.split(RegExp(r'[\\/]')).last;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 13, color: theme.textColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: TextoRolante(
                          texto: nomeArquivo,
                          style: theme.getTextStyle(fontSize: 10.5),
                        ),
                      ),
                      if (widget.podeGerenciar) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() => _arquivosContrato.remove(caminho)),
                          child: Icon(Icons.close, size: 12, color: theme.dangerColor),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        if (widget.podeGerenciar) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
                foregroundColor: theme.textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _salvarContrato,
              child: Text('Salvar Contrato', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _painelPontoEletronico(Loja? loja, List<RegistroPontoMembro> pontos, bool temPontoAberto) {
    if (loja == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: temPontoAberto ? theme.textColor.withValues(alpha: 0.08) : theme.backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: temPontoAberto ? theme.textColor : theme.borderColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: temPontoAberto ? 'Ponto Ativo (Trabalhando)' : 'Ponto Fechado (Fora do Turno)',
                      style: theme.getTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textColor),
                    ),
                    TextoRolante(
                      texto: temPontoAberto ? 'Entrada registrada. Clique para registrar saída.' : 'Clique para registrar início de jornada.',
                      style: theme.getTextStyle(fontSize: 10.5, color: theme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: temPontoAberto ? theme.dangerColor.withValues(alpha: 0.85) : theme.buttonColor,
                  foregroundColor: temPontoAberto ? theme.textColor : theme.buttonTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _baterPonto(loja),
                icon: Icon(temPontoAberto ? Icons.logout : Icons.login, size: 16),
                label: Text(temPontoAberto ? 'Bater Saída' : 'Bater Entrada', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: temPontoAberto ? theme.textColor : theme.buttonTextColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextoRolante(texto: 'Histórico de Ponto (${pontos.length}):', style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor)),
        const SizedBox(height: 6),
        if (pontos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum registro de ponto registrado.', textAlign: TextAlign.center, style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pontos.length,
            separatorBuilder: (_, _) => Divider(height: 6, color: theme.borderColor.withValues(alpha: 0.2)),
            itemBuilder: (context, idx) {
              final p = pontos[idx];
              final duracao = p.duracaoTrabalhada;
              final horas = duracao.inHours;
              final minutos = duracao.inMinutes % 60;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(p.estaEmAberto ? Icons.timelapse : Icons.check_circle_outline, size: 14, color: p.estaEmAberto ? theme.secondaryTextColor : theme.textColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextoRolante(
                            texto: 'Entrada: ${_formatarDataHora(p.dataHoraEntrada)}',
                            style: theme.getTextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          TextoRolante(
                            texto: p.dataHoraSaida != null
                                ? 'Saída: ${_formatarDataHora(p.dataHoraSaida!)} • Duração: ${horas}h ${minutos}min'
                                : 'Em andamento...',
                            style: theme.getTextStyle(fontSize: 10, color: theme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _painelEscalaTrabalho(EscalaTrabalhoMembro? escala) {
    const nomesDias = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Dias de Trabalho da Semana:', style: theme.getTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.secondaryTextColor)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (idx) {
            final dia = idx + 1;
            final selecionado = _diasEscala.contains(dia);
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.podeGerenciar
                  ? () {
                      setState(() {
                        if (selecionado) {
                          if (_diasEscala.length > 1) _diasEscala.remove(dia);
                        } else {
                          _diasEscala.add(dia);
                        }
                      });
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selecionado
                      ? (theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.35))
                      : theme.backgroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selecionado ? theme.textColor : theme.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  nomesDias[dia]!,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                    color: theme.textColor,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horário de Entrada', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _horarioEntradaController,
                    enabled: widget.podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '08:00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.textColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horário de Saída', style: theme.getTextStyle(fontSize: 11, color: theme.secondaryTextColor)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _horarioSaidaController,
                    enabled: widget.podeGerenciar,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: '17:00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.textColor)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.podeGerenciar) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor != Colors.transparent ? theme.buttonColor : theme.borderColor.withValues(alpha: 0.25),
                foregroundColor: theme.textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _salvarEscala,
              child: Text('Salvar Escala Semanal', style: theme.getTextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ],
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
