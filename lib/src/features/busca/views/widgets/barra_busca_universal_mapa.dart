import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/services/voz_busca_service.dart';
import 'package:nous/src/features/busca/views/dialogs/dialog_escuta_voz_mapa.dart';

class BarraBuscaUniversalMapa extends StatefulWidget {
  final BuscaMapaController controller;
  final TextEditingController textController;
  final AppTheme theme;

  const BarraBuscaUniversalMapa({
    super.key,
    required this.controller,
    required this.textController,
    required this.theme,
  });

  @override
  State<BarraBuscaUniversalMapa> createState() =>
      _BarraBuscaUniversalMapaState();
}

class _BarraBuscaUniversalMapaState extends State<BarraBuscaUniversalMapa> {
  bool _mostrarFiltros = false;
  bool _ouvindoVoz = false;

  @override
  void dispose() {
    if (_ouvindoVoz) {
      VozBuscaService.cancelarEscutaAtiva();
    }
    super.dispose();
  }

  Future<void> _iniciarBuscaPorVoz() async {
    if (_ouvindoVoz) return;

    if (!Platform.isWindows) {
      setState(() => _ouvindoVoz = true);
      final resultado = await VozBuscaService.ouvirAndroid();
      if (!mounted) return;
      setState(() => _ouvindoVoz = false);
      _aplicarResultadoVoz(resultado);
      return;
    }

    final pronto = await VozBuscaService.motorWindowsPronto();
    if (!mounted) return;
    if (!pronto) {
      final preparou = await _mostrarDialogoPrepararMotorVoz();
      if (!preparou || !mounted) return;
    }

    final resultado = await DialogEscutaVozMapa.mostrar(
      context,
      theme: widget.theme,
    );
    if (!mounted || resultado == null || resultado.cancelado) return;
    _aplicarResultadoVoz(resultado);
  }

  void _aplicarResultadoVoz(ResultadoVozBusca resultado) {
    final limpo = (resultado.texto ?? '').trim();
    if (limpo.isNotEmpty) {
      widget.textController.text = limpo;
      widget.textController.selection = TextSelection.collapsed(
        offset: limpo.length,
      );
      widget.controller.definirPainelBusca(true);
      widget.controller.atualizarBusca(limpo);
    } else {
      _mostrarAvisoVoz(
        resultado.mensagemErro ??
            'Não foi possível captar a voz. Verifique o microfone ou digite para buscar.',
      );
    }
  }

  void _mostrarAvisoVoz(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: widget.theme.cardBackgroundColor,
          duration: const Duration(seconds: 3),
          content: Text(
            mensagem,
            style: widget.theme.getTextStyle(
              fontSize: 12,
              color: widget.theme.textColor,
            ),
          ),
        ),
      );
  }

  Future<bool> _mostrarDialogoPrepararMotorVoz() async {
    final theme = widget.theme;
    final progressoNotifier = ValueNotifier<double>(0.0);
    final etapaNotifier = ValueNotifier<String>('Preparando motor de voz...');
    var iniciado = false;
    var sucesso = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        if (!iniciado) {
          iniciado = true;
          unawaited(
            VozBuscaService.prepararMotorWindows(
              onProgresso: (p, etapa) {
                progressoNotifier.value = p;
                etapaNotifier.value = etapa;
              },
            ).then((erro) {
              if (!ctx.mounted) return;
              if (erro == null) {
                sucesso = true;
                Navigator.of(ctx).pop();
              } else {
                Navigator.of(ctx).pop();
                if (mounted) _mostrarAvisoVoz(erro);
              }
            }),
          );
        }

        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Preparando Pesquisa por Voz Offline',
            style: theme.getTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: ValueListenableBuilder<double>(
            valueListenable: progressoNotifier,
            builder: (_, progresso, _) {
              return ValueListenableBuilder<String>(
                valueListenable: etapaNotifier,
                builder: (_, etapa, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Baixando uma única vez o motor offline rápido em Português (~66 MB). Depois funcionará sem internet.',
                        style: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: progresso > 0 ? progresso : null,
                        color: theme.buttonColor,
                        backgroundColor: theme.borderColor.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        etapa,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );

    progressoNotifier.dispose();
    etapaNotifier.dispose();
    return sucesso;
  }

  String _rotuloFiltro(FiltroBuscaMapa f) {
    switch (f) {
      case FiltroBuscaMapa.todos:
        return 'Todos';
      case FiltroBuscaMapa.produtos:
        return 'Produtos';
      case FiltroBuscaMapa.servicos:
        return 'Serviços';
      case FiltroBuscaMapa.perfis:
        return 'Perfis';
      case FiltroBuscaMapa.lojas:
        return 'Lojas';
      case FiltroBuscaMapa.enderecos:
        return 'Endereços';
      case FiltroBuscaMapa.projetos:
        return 'Projetos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ctrl = widget.controller;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.borderColor.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, size: 22, color: theme.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.textController,
                  onTap: () {
                    if (!ctrl.ehFiltroCatalogoComercial) {
                      ctrl.definirPainelBusca(true);
                    }
                  },
                  onChanged: ctrl.atualizarBusca,
                  onSubmitted: (_) => ctrl.confirmarBuscaComercial(),
                  textInputAction: TextInputAction.search,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: _ouvindoVoz
                        ? 'Ouvindo...'
                        : (ctrl.filtroAtivo == FiltroBuscaMapa.produtos
                            ? 'Pesquisar produtos...'
                            : (ctrl.filtroAtivo == FiltroBuscaMapa.servicos
                                ? 'Pesquisar serviços...'
                                : 'Pesquisar')),
                    hintStyle: theme.getTextStyle(
                      fontSize: 14,
                      color: _ouvindoVoz
                          ? theme.dangerColor
                          : theme.secondaryTextColor,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.textController.text.isNotEmpty ||
                  ctrl.painelBuscaExpandido ||
                  ctrl.exibirCatalogoComercial ||
                  ctrl.filtroAtivo != FiltroBuscaMapa.todos)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: theme.secondaryTextColor,
                  ),
                  tooltip: 'Fechar pesquisa',
                  onPressed: () {
                    widget.textController.clear();
                    ctrl.atualizarBusca('');
                    ctrl.definirFiltro(FiltroBuscaMapa.todos);
                    ctrl.definirPainelBusca(false);
                    FocusScope.of(context).unfocus();
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.filter_alt_outlined,
                  size: 20,
                  color: _mostrarFiltros ||
                          ctrl.filtroAtivo != FiltroBuscaMapa.todos
                      ? theme.textColor
                      : theme.secondaryTextColor,
                ),
                tooltip: 'Filtrar pesquisa',
                onPressed: () =>
                    setState(() => _mostrarFiltros = !_mostrarFiltros),
              ),
              IconButton(
                icon: Icon(
                  _ouvindoVoz ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  size: 20,
                  color: _ouvindoVoz ? theme.dangerColor : theme.textColor,
                ),
                tooltip: 'Pesquisa por voz',
                onPressed: _iniciarBuscaPorVoz,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        if (ctrl.exibirLocalUsuario) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextoRolante(
              texto: ctrl.enderecoUsuarioResumo,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ),
        ],
        if (_mostrarFiltros) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: ctrl.alternarCompartilhamentoLocalizacao,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ctrl.compartilharLocalizacaoTempoReal
                            ? theme.buttonColor
                            : theme.cardBackgroundColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ctrl.compartilharLocalizacaoTempoReal
                              ? theme.buttonColor
                              : theme.borderColor.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ctrl.compartilharLocalizacaoTempoReal
                                ? Icons.location_on_rounded
                                : Icons.location_off_outlined,
                            size: 13,
                            color: ctrl.compartilharLocalizacaoTempoReal
                                ? theme.buttonTextColor
                                : theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ctrl.compartilharLocalizacaoTempoReal
                                ? 'Ao vivo: Ativo'
                                : 'Ao vivo: Oculto',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ctrl.compartilharLocalizacaoTempoReal
                                  ? theme.buttonTextColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: ctrl.alternarExibirLocalUsuario,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ctrl.exibirLocalUsuario
                            ? theme.buttonColor
                            : theme.cardBackgroundColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ctrl.exibirLocalUsuario
                              ? theme.buttonColor
                              : theme.borderColor.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ctrl.exibirLocalUsuario
                                ? Icons.place_outlined
                                : Icons.visibility_off_outlined,
                            size: 13,
                            color: ctrl.exibirLocalUsuario
                                ? theme.buttonTextColor
                                : theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ctrl.exibirLocalUsuario
                                ? 'Local: Visível'
                                : 'Local: Oculto',
                            style: theme.getTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ctrl.exibirLocalUsuario
                                  ? theme.buttonTextColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...FiltroBuscaMapa.values.map((filtro) {
                final ativo = ctrl.filtroAtivo == filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ctrl.definirFiltro(filtro),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ativo
                            ? theme.buttonColor
                            : theme.cardBackgroundColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ativo
                              ? theme.buttonColor
                              : theme.borderColor.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        _rotuloFiltro(filtro),
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              ativo ? FontWeight.bold : FontWeight.w500,
                          color: ativo
                              ? theme.buttonTextColor
                              : theme.textColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
