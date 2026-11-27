import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/services/guarda_acao_ui.dart';
import 'package:nous/src/core/services/preferencias_soberanas_service.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/views/em_construcao_view.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/busca/views/busca_mapa_view.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/compras/services/helpers/efeito_pacote_carrinho_helper.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/compras_usuario_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';
import 'package:nous/src/features/timeline/views/feed_descoberta_view.dart';
import 'package:nous/src/features/timeline/views/player_universal/player_universal_view.dart';

class _ItemSlotDuplo {
  final IconData icone0;
  final IconData icone1;
  final String label0;
  final String label1;

  const _ItemSlotDuplo({
    required this.icone0,
    required this.icone1,
    required this.label0,
    required this.label1,
  });
}

/// Barra de navegação flutuante universal do SuperApp Nous.
/// Cada um dos 5 botões é duplo e pode ser rolado verticalmente (arraste para cima/baixo
/// ou rodinha do mouse) para alternar entre dois modos e funcionalidades.
class FloatingBottomNavBar extends StatefulWidget {
  final double maxWidth;
  final int slotSelecionado;
  final int subIndiceSelecionado;

  // Mantido para compatibilidade com telas legadas
  final int? indiceSelecionado;
  final ValueChanged<int>? onTrocarIndice;

  const FloatingBottomNavBar({
    super.key,
    required this.maxWidth,
    this.slotSelecionado = 0,
    this.subIndiceSelecionado = 0,
    this.indiceSelecionado,
    this.onTrocarIndice,
  });

  static String _chaveUltimaAba(String cpf) {
    final norm = cpf.replaceAll(RegExp(r'\D'), '');
    return 'nav_ultima_aba_${norm.isEmpty ? 'visitante' : norm}';
  }

  static Future<void> salvarUltimaAba(
    String cpf,
    int slot,
    int subIndice,
  ) async {
    if (cpf.trim().isEmpty) return;
    await PreferenciasSoberanasService.salvarTexto(
      _chaveUltimaAba(cpf),
      '$slot:$subIndice',
    );
  }

  static Widget construirPaginaPorSlot(int slot, int subIndice) {
    if (slot == 0) {
      return subIndice == 0
          ? const ComprasUsuarioView()
          : const PerfisPdvView();
    } else if (slot == 1) {
      return subIndice == 0
          ? const PerfilSocialView(mostrarBotaoVoltar: false)
          : const MensageriaView(
              modoLoja: false,
              mostrarBotaoVoltar: true,
            );
    } else if (slot == 2) {
      return subIndice == 0
          ? const BuscaMapaView()
          : const PlayerUniversalView();
    } else if (slot == 3) {
      return subIndice == 0
          ? const FeedDescobertaView(apenasAmigos: false)
          : const FeedDescobertaView(apenasAmigos: true);
    } else {
      return subIndice == 0
          ? const EmConstrucaoView(
              titulo: 'Autogestão Social',
              subtitulo:
                  'Assembleias, deliberações e tomada de decisão coletiva',
              icone: Icons.hub_outlined,
              slotSelecionado: 4,
              subIndiceSelecionado: 0,
            )
          : const EmConstrucaoView(
              titulo: 'Governança & Gestão',
              subtitulo: 'Ferramentas de coordenação e autogestão popular',
              icone: Icons.account_tree_outlined,
              slotSelecionado: 4,
              subIndiceSelecionado: 1,
            );
    }
  }

  static Future<Widget> obterTelaInicialPorCpf(String cpf) async {
    if (cpf.trim().isEmpty) return const BuscaMapaView();
    final salvo =
        await PreferenciasSoberanasService.obterTexto(_chaveUltimaAba(cpf));
    if (salvo == null || !salvo.contains(':')) {
      return const BuscaMapaView();
    }
    final partes = salvo.split(':');
    final slot = int.tryParse(partes[0]) ?? 2;
    final subIndice = int.tryParse(partes[1]) ?? 0;
    if (slot < 0 || slot > 4 || subIndice < 0 || subIndice > 1) {
      return const BuscaMapaView();
    }
    return construirPaginaPorSlot(slot, subIndice);
  }

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  // Estado compartilhado entre instâncias para lembrar a rolagem de cada botão
  static final List<int> _memoriaSubIndices = [0, 0, 0, 0, 0];

  static const List<_ItemSlotDuplo> _slots = [
    // Slot 0: Compras (Carrinho) / Perfis (Lojinha)
    _ItemSlotDuplo(
      icone0: Icons.shopping_cart_outlined,
      icone1: Icons.storefront_outlined,
      label0: 'Compras e Carteira',
      label1: 'Meus Perfis',
    ),
    // Slot 1: Perfil Social / Mensagens
    _ItemSlotDuplo(
      icone0: Icons.person_outline,
      icone1: Icons.chat_bubble_outline_rounded,
      label0: 'Perfil Social',
      label1: 'Mensagens',
    ),
    // Slot 2: Busca e Mapa / Player Universal
    _ItemSlotDuplo(
      icone0: Icons.search,
      icone1: Icons.play_circle_outline,
      label0: 'Busca e Mapa',
      label1: 'Player Universal',
    ),
    // Slot 3: Feed Descoberta / Feed Amigos
    _ItemSlotDuplo(
      icone0: Icons.explore_outlined,
      icone1: Icons.people_alt_outlined,
      label0: 'Feed de Descoberta',
      label1: 'Feed de Amigos',
    ),
    // Slot 4: Autogestão Geral / Governança
    _ItemSlotDuplo(
      icone0: Icons.hub_outlined,
      icone1: Icons.account_tree_outlined,
      label0: 'Autogestão Social',
      label1: 'Governança & Gestão',
    ),
  ];

  late int _slotAtivo;
  final GlobalKey _chaveSlotCompras = GlobalKey();

  @override
  void initState() {
    super.initState();
    _slotAtivo = widget.indiceSelecionado ?? widget.slotSelecionado;
    // Sincroniza a memória com a tela atual caso ela declare um sub-índice explícito
    if (_slotAtivo >= 0 && _slotAtivo < _memoriaSubIndices.length) {
      _memoriaSubIndices[_slotAtivo] = widget.subIndiceSelecionado;
    }
    EfeitoPacoteCarrinhoHelper.chaveSlotCompras = _chaveSlotCompras;
    CarrinhoComprasService.ultimoItemAdicionado
        .addListener(_aoDetectarItemNoCarrinho);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final pdv = context.read<PdvProvider>();
        unawaited(CarrinhoComprasService.sincronizarContagemTotal(pdv));
      } catch (_) {}
    });
  }

  void _aoDetectarItemNoCarrinho() {
    if (!mounted) return;
    // Se o slot 0 estava exibindo "Meus Perfis", gira suavemente para "Compras e Carteira"
    if (_memoriaSubIndices[0] == 1) {
      setState(() {
        _memoriaSubIndices[0] = 0;
      });
    }
  }

  @override
  void dispose() {
    if (EfeitoPacoteCarrinhoHelper.chaveSlotCompras == _chaveSlotCompras) {
      EfeitoPacoteCarrinhoHelper.chaveSlotCompras = null;
    }
    CarrinhoComprasService.ultimoItemAdicionado
        .removeListener(_aoDetectarItemNoCarrinho);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final novoSlot = widget.indiceSelecionado ?? widget.slotSelecionado;
    if (_slotAtivo != novoSlot) {
      _slotAtivo = novoSlot;
    }
    if (_slotAtivo >= 0 && _slotAtivo < _memoriaSubIndices.length) {
      _memoriaSubIndices[_slotAtivo] = widget.subIndiceSelecionado;
    }
  }

  void _rolarSlot(int slot, bool paraCima) {
    final subAtual = _memoriaSubIndices[slot];
    final novoSub = paraCima ? 0 : 1;
    if (subAtual == novoSub) {
      // Se já estava no limite, alterna para o outro
      final alternado = subAtual == 0 ? 1 : 0;
      _memoriaSubIndices[slot] = alternado;
      _navegarPara(slot, alternado, paraCima: paraCima);
    } else {
      _memoriaSubIndices[slot] = novoSub;
      _navegarPara(slot, novoSub, paraCima: paraCima);
    }
  }

  void _aoTocarSlot(int slot) {
    if (widget.onTrocarIndice != null) {
      widget.onTrocarIndice!(slot);
      return;
    }

    final subIndice = _memoriaSubIndices[slot];
    // Se clicou no mesmo slot e sub-índice que já está aberto, não precisa reabrir
    if (slot == _slotAtivo && subIndice == widget.subIndiceSelecionado) {
      return;
    }

    _navegarPara(slot, subIndice);
  }

  void _navegarPara(int slot, int subIndice, {bool? paraCima}) {
    if (slot == widget.slotSelecionado &&
        subIndice == widget.subIndiceSelecionado &&
        paraCima == null) {
      return;
    }
    GuardaAcaoUi.executarSincrono('nav_universal', () {
      _executarNavegacao(slot, subIndice, paraCima: paraCima);
    });
  }

  void _executarNavegacao(int slot, int subIndice, {bool? paraCima}) {
    final cpf = context.read<AuthProvider>().cpf;
    final ehMensageria = slot == 1 && subIndice == 1;
    if (!ehMensageria) {
      unawaited(FloatingBottomNavBar.salvarUltimaAba(cpf, slot, subIndice));
    }
    final pagina = FloatingBottomNavBar.construirPaginaPorSlot(slot, subIndice);

    // Transição suave vertical simulando o arrasto de descida/subida da tela
    final offsetInicio = paraCima == null
        ? const Offset(0.0, 0.05)
        : (paraCima ? const Offset(0.0, -0.06) : const Offset(0.0, 0.06));

    final rota = PageRouteBuilder<void>(
      pageBuilder: (context, anim, secAnim) => pagina,
      transitionDuration: const Duration(milliseconds: 230),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvo = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvo,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: offsetInicio,
              end: Offset.zero,
            ).animate(curvo),
            child: child,
          ),
        );
      },
    );

    if (ehMensageria) {
      Navigator.of(context).push(rota).then((_) {
        _memoriaSubIndices[1] = 0;
      });
    } else {
      Navigator.of(context).pushAndRemoveUntil(rota, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraDaTela = MediaQuery.sizeOf(context).width;
    final sobra = larguraDaTela - widget.maxWidth;
    final margemLateral = (sobra / 2).clamp(0.0, larguraDaTela / 2);

    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            margemLateral + 20,
            0,
            margemLateral + 20,
            16,
          ),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_slots.length, (slot) {
                final item = _slots[slot];
                final subIndice = _memoriaSubIndices[slot];
                final selecionado = slot == _slotAtivo &&
                    subIndice == widget.subIndiceSelecionado;

                final iconeAtual = subIndice == 0 ? item.icone0 : item.icone1;
                final rotuloAtual = subIndice == 0 ? item.label0 : item.label1;

                return Expanded(
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        if (pointerSignal.scrollDelta.dy > 0) {
                          _rolarSlot(slot, false);
                        } else if (pointerSignal.scrollDelta.dy < 0) {
                          _rolarSlot(slot, true);
                        }
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (details) {
                        final vy = details.primaryVelocity ?? 0;
                        if (vy < -80) {
                          _rolarSlot(slot, true);
                        } else if (vy > 80) {
                          _rolarSlot(slot, false);
                        }
                      },
                      onTap: () => _aoTocarSlot(slot),
                      child: Tooltip(
                        message: '$rotuloAtual (Deslize para alternar)',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Micro-indicador de modo superior/inferior
                            Container(
                              width: 14,
                              height: 3,
                              decoration: BoxDecoration(
                                color: subIndice == 0
                                    ? (selecionado
                                        ? theme.buttonColor
                                        : theme.secondaryTextColor
                                            .withValues(alpha: 0.5))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Stack(
                              key: slot == 0 ? _chaveSlotCompras : null,
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 340),
                                  transitionBuilder: (child, animation) {
                                    final giro = Tween<double>(
                                      begin: 0.5,
                                      end: 1.0,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutBack,
                                      ),
                                    );
                                    final escala = Tween<double>(
                                      begin: 0.72,
                                      end: 1.0,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );
                                    return RotationTransition(
                                      turns: giro,
                                      child: ScaleTransition(
                                        scale: escala,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    iconeAtual,
                                    key: ValueKey('$slot-$subIndice'),
                                    size: 24,
                                    color: selecionado
                                        ? theme.textColor
                                        : theme.secondaryTextColor,
                                  ),
                                ),
                                if (slot == 0 && subIndice == 0)
                                  Positioned(
                                    right: -6,
                                    top: -4,
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: CarrinhoComprasService
                                          .totalItensNoCarrinho,
                                      builder: (context, total, _) {
                                        if (total <= 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: theme.dangerColor,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            total > 99 ? '99+' : '$total',
                                            textAlign: TextAlign.center,
                                            style: theme.getTextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: theme.buttonTextColor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 14,
                              height: 3,
                              decoration: BoxDecoration(
                                color: subIndice == 1
                                    ? (selecionado
                                        ? theme.buttonColor
                                        : theme.secondaryTextColor
                                            .withValues(alpha: 0.5))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}