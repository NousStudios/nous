import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/services/mapa_geo_service.dart';

class PainelRotasMapa extends StatefulWidget {
  final BuscaMapaController controller;
  final AppTheme theme;

  const PainelRotasMapa({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  State<PainelRotasMapa> createState() => _PainelRotasMapaState();
}

class _PainelRotasMapaState extends State<PainelRotasMapa> {
  final TextEditingController _destinoCtrl = TextEditingController();
  List<EnderecoGeocodificado> _sugestoesDestino = [];
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _destinoCtrl.text = widget.controller.destinoRotaLabel;
  }

  @override
  void didUpdateWidget(covariant PainelRotasMapa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.destinoRotaLabel.isNotEmpty &&
        _destinoCtrl.text != widget.controller.destinoRotaLabel) {
      _destinoCtrl.text = widget.controller.destinoRotaLabel;
    }
  }

  @override
  void dispose() {
    _destinoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pesquisarDestino(String texto) async {
    if (texto.trim().length < 3) {
      setState(() => _sugestoesDestino = []);
      return;
    }
    setState(() => _buscando = true);
    final res = await MapaGeoService.buscarEnderecos(
      texto.trim(),
      limite: 6,
      referencia: widget.controller.centroReferencia,
      cidadeReferencia: MapaGeoService.extrairCidadeDeResumo(
        widget.controller.enderecoUsuarioResumo,
      ),
    );
    if (mounted) {
      setState(() {
        _sugestoesDestino = res;
        _buscando = false;
      });
    }
  }

  void _avisarModuloMotoristas(String modalidade) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.cardBackgroundColor,
          duration: const Duration(seconds: 3),
          content: Text(
            '$modalidade: o módulo de motoristas e fretes será integrado na próxima etapa.',
            style: widget.theme.getTextStyle(
              fontSize: 12,
              color: widget.theme.textColor,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ctrl = widget.controller;
    final rota = ctrl.rotaAtual;

    final lojasComCoord = ctrl.lojas
        .where((l) => ctrl.coordenadasLojas.containsKey(l.id))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
                tooltip: 'Fechar rotas',
                onPressed: ctrl.fecharModoRota,
              ),
              Expanded(
                child: Column(
                  children: [
                    _campoRota(
                      theme: theme,
                      icone: Icons.my_location_rounded,
                      texto: ctrl.origemRotaLabel,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _destinoCtrl,
                              onChanged: _pesquisarDestino,
                              onSubmitted: (texto) async {
                                final q = texto.trim();
                                if (q.length < 3) return;
                                final coord =
                                    await MapaGeoService.geocodificarEndereco(q);
                                if (coord != null && mounted) {
                                  setState(() => _sugestoesDestino = []);
                                  await widget.controller.tracarRotaPara(
                                    destino: coord,
                                    destinoLabel: q,
                                  );
                                }
                              },
                              style: theme.getTextStyle(
                                fontSize: 12.5,
                                color: theme.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Destino',
                                hintStyle: theme.getTextStyle(
                                  fontSize: 12.5,
                                  color: theme.secondaryTextColor,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_vert_rounded, color: theme.textColor),
                tooltip: 'Inverter origem e destino',
                onPressed: ctrl.inverterOrigemDestino,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Botões de modalidade (print 2)
          Row(
            children: [
              _chipModalidade(
                theme,
                'Solicitar carro',
                () => _avisarModuloMotoristas('Solicitar carro'),
              ),
              const SizedBox(width: 6),
              _chipModalidade(
                theme,
                'Solicitar moto',
                () => _avisarModuloMotoristas('Solicitar moto'),
              ),
              const SizedBox(width: 6),
              _chipModalidade(
                theme,
                'Solicitar delivery',
                () => _avisarModuloMotoristas('Solicitar delivery'),
              ),
            ],
          ),
          if (ctrl.calculandoRota) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              color: theme.buttonColor,
              backgroundColor: theme.borderColor.withValues(alpha: 0.3),
              minHeight: 3,
            ),
          ],
          if (_buscando) ...[
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textColor,
                ),
              ),
            ),
          ] else if (_sugestoesDestino.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _sugestoesDestino.length,
                itemBuilder: (_, i) {
                  final end = _sugestoesDestino[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: theme.textColor,
                    ),
                    title: Text(
                      end.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: end.subtitulo.isNotEmpty
                        ? Text(
                            end.subtitulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 10.5,
                              color: theme.secondaryTextColor,
                            ),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _sugestoesDestino = [];
                        _destinoCtrl.text = end.titulo;
                      });
                      ctrl.tracarRotaPara(
                        destino: end.coordenada,
                        destinoLabel: end.titulo,
                      );
                    },
                  );
                },
              ),
            ),
          ] else if (rota == null && lojasComCoord.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Próximos',
              style: theme.getTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            ...lojasComCoord.take(3).map((loja) {
              final coord = ctrl.coordenadasLojas[loja.id]!;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: theme.textColor,
                ),
                title: Text(
                  loja.nome,
                  style: theme.getTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  [loja.endereco, loja.numero]
                      .where((e) => e.trim().isNotEmpty)
                      .join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 10.5,
                    color: theme.secondaryTextColor,
                  ),
                ),
                onTap: () {
                  _destinoCtrl.text = loja.nome;
                  ctrl.tracarRotaPara(
                    destino: coord,
                    destinoLabel: loja.nome,
                  );
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _campoRota({
    required AppTheme theme,
    required IconData icone,
    required String texto,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icone, size: 15, color: theme.secondaryTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(
                fontSize: 12.5,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipModalidade(
    AppTheme theme,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.7),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.getTextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
