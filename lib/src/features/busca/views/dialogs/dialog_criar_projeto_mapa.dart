import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/core/widgets/themed_switch.dart';

class DialogCriarProjetoMapa extends StatefulWidget {
  final AppTheme theme;
  final LatLng coordenada;
  final String enderecoResumo;
  final String criadorCpf;
  final String criadorNome;

  const DialogCriarProjetoMapa({
    super.key,
    required this.theme,
    required this.coordenada,
    required this.enderecoResumo,
    required this.criadorCpf,
    required this.criadorNome,
  });

  static Future<ProjetoComunitario?> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required LatLng coordenada,
    required String enderecoResumo,
    required String criadorCpf,
    required String criadorNome,
  }) {
    return showDialog<ProjetoComunitario>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardBackgroundColor,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.90,
          ),
          child: SingleChildScrollView(
            child: DialogCriarProjetoMapa(
              theme: theme,
              coordenada: coordenada,
              enderecoResumo: enderecoResumo,
              criadorCpf: criadorCpf,
              criadorNome: criadorNome,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DialogCriarProjetoMapa> createState() => _DialogCriarProjetoMapaState();
}

class _DialogCriarProjetoMapaState extends State<DialogCriarProjetoMapa> {
  final TextEditingController _tituloCtrl = TextEditingController();
  final TextEditingController _descricaoCtrl = TextEditingController();
  String _categoria = 'Buraco na rua';
  bool _euSereiResponsavel = false;
  String _caminhoFoto = '';

  static const List<String> _categorias = [
    'Buraco na rua',
    'Iluminação',
    'Limpeza urbana',
    'Acessibilidade',
    'Sinalização',
    'Outro',
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;
      final salva = await ImagemService.salvarImagemLocal(xfile.path);
      if (mounted && salva != null) {
        setState(() => _caminhoFoto = salva);
      }
    } catch (_) {}
  }

  void _salvar() {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) return;
    final agora = DateTime.now();
    final cpfLimpo = widget.criadorCpf.replaceAll(RegExp(r'\D'), '');
    final projeto = ProjetoComunitario(
      id: 'proj_${agora.millisecondsSinceEpoch}',
      titulo: titulo,
      descricao: _descricaoCtrl.text.trim(),
      categoria: _categoria,
      latitude: widget.coordenada.latitude,
      longitude: widget.coordenada.longitude,
      enderecoResumo: widget.enderecoResumo,
      criadorCpf: cpfLimpo,
      criadorNome: widget.criadorNome,
      responsavelCpf: _euSereiResponsavel ? cpfLimpo : '',
      responsavelNome: _euSereiResponsavel ? widget.criadorNome : '',
      status: _euSereiResponsavel
          ? StatusProjetoComunitario.emAndamento
          : StatusProjetoComunitario.aberto,
      caminhoFoto: _caminhoFoto,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    Navigator.of(context).pop(projeto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.handyman_outlined, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Novo Projeto Comunitário',
                  style: theme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.secondaryTextColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            widget.enderecoResumo,
            style: theme.getTextStyle(
              fontSize: 11.5,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tituloCtrl,
            style: theme.getTextStyle(fontSize: 13.5, color: theme.textColor),
            decoration: InputDecoration(
              labelText: 'O que precisa ser resolvido?',
              hintText: 'Ex.: Buraco na esquina da Rua X',
              labelStyle: theme.getTextStyle(
                fontSize: 12.5,
                color: theme.secondaryTextColor,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _categorias.map((cat) {
              final sel = _categoria == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: sel ? theme.buttonTextColor : theme.textColor,
                  ),
                ),
                selected: sel,
                selectedColor: theme.buttonColor,
                backgroundColor: theme.backgroundColor.withValues(alpha: 0.35),
                onSelected: (_) => setState(() => _categoria = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descricaoCtrl,
            maxLines: 3,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
            decoration: InputDecoration(
              labelText: 'Detalhes / materiais necessários',
              labelStyle: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eu mesmo serei o responsável',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      _euSereiResponsavel
                          ? 'Você assumirá a execução deste projeto'
                          : 'Solicitar ajuda de pessoas competentes',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              ThemedSwitch(
                theme: theme,
                value: _euSereiResponsavel,
                onChanged: (v) => setState(() => _euSereiResponsavel = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _escolherFoto,
            icon: Icon(
              _caminhoFoto.isEmpty
                  ? Icons.add_a_photo_outlined
                  : Icons.check_circle_outline,
              size: 17,
              color: theme.textColor,
            ),
            label: Text(
              _caminhoFoto.isEmpty ? 'Anexar foto do local' : 'Foto anexada',
              style: theme.getTextStyle(fontSize: 12, color: theme.textColor),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _salvar,
            child: Text(
              'Publicar Projeto no Mapa',
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
