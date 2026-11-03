import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataHora(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year} '
    '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// Bloco para registro, auditoria e edição de comentários anexados à venda.
class BlocoComentarioVendaWidget extends StatefulWidget {
  final AppTheme theme;
  final PedidoLoja pedido;
  final double larguraBloco;
  final String autorCpf;
  final String autorNome;
  final String autorEmail;
  final ValueChanged<DadosComentario>? onSalvarComentario;

  const BlocoComentarioVendaWidget({
    super.key,
    required this.theme,
    required this.pedido,
    required this.larguraBloco,
    required this.autorCpf,
    required this.autorNome,
    required this.autorEmail,
    this.onSalvarComentario,
  });

  @override
  State<BlocoComentarioVendaWidget> createState() =>
      _BlocoComentarioVendaWidgetState();
}

class _BlocoComentarioVendaWidgetState extends State<BlocoComentarioVendaWidget> {
  late final TextEditingController _comentarioController;
  late String _comentarioSalvo;
  late DateTime? _comentarioDataHoraSalvo;
  late String _comentarioAutorNomeSalvo;
  late String _comentarioAutorCpfSalvo;
  late String _comentarioAutorEmailSalvo;

  AppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _comentarioSalvo = widget.pedido.comentario;
    _comentarioDataHoraSalvo = widget.pedido.comentarioDataHora;
    _comentarioAutorNomeSalvo = widget.pedido.comentarioAutorNome;
    _comentarioAutorCpfSalvo = widget.pedido.comentarioAutorCpf;
    _comentarioAutorEmailSalvo = widget.pedido.comentarioAutorEmail;
    _comentarioController = TextEditingController(text: _comentarioSalvo);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  BoxDecoration get _decoracaoDoBloco => BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      );

  Widget _tituloDoBloco(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  void _salvarComentario() {
    final texto = _comentarioController.text.trim();
    final agora = DateTime.now();

    final dados = DadosComentario(
      texto: texto,
      cpfAutor: widget.autorCpf,
      nomeAutor: widget.autorNome,
      emailAutor: widget.autorEmail,
      dataHora: agora,
    );

    widget.onSalvarComentario?.call(dados);
    setState(() {
      _comentarioSalvo = texto;
      _comentarioDataHoraSalvo = agora;
      _comentarioAutorNomeSalvo = widget.autorNome;
      _comentarioAutorCpfSalvo = widget.autorCpf;
      _comentarioAutorEmailSalvo = widget.autorEmail;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardBackgroundColor,
        content: Text(
          widget.onSalvarComentario != null
              ? 'Comentário salvo.'
              : 'Comentário salvo (apenas nesta sessão).',
          style: theme.getTextStyle(color: theme.textColor),
        ),
      ),
    );
  }

  String _autorDoComentarioExibido() {
    final partes = <String>[
      if (_comentarioAutorNomeSalvo.isNotEmpty) _comentarioAutorNomeSalvo,
      if (_comentarioAutorCpfSalvo.isNotEmpty) _comentarioAutorCpfSalvo,
      if (_comentarioAutorEmailSalvo.isNotEmpty) _comentarioAutorEmailSalvo,
    ];
    return partes.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final autorAntigo = _autorDoComentarioExibido();
    final dataAntiga = _comentarioDataHoraSalvo;

    return Center(
      child: Container(
        width: widget.larguraBloco,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _decoracaoDoBloco,
        child: Column(
          children: [
            _tituloDoBloco('Comentário'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _comentarioController,
                    maxLines: 4,
                    cursorColor: theme.textColor,
                    style: theme.getTextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário sobre esta venda...',
                      hintStyle: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
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
                  if (_comentarioSalvo.trim().isNotEmpty &&
                      autorAntigo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Por: $autorAntigo',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  if (_comentarioSalvo.trim().isNotEmpty &&
                      dataAntiga != null) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Em: ${_dataHora(dataAntiga)}',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.buttonTextColor,
                        side: BorderSide(color: theme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvarComentario,
                      child: Text(
                        'Salvar Comentário',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.buttonTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
