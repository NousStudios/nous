import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/views/em_construcao_view.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/chat/views/mensageria_view.dart';
import 'package:nous/src/features/pdv/views/compras_usuario_view.dart';
import 'package:nous/src/features/pdv/views/perfis_pdv_view.dart';

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
      label0: 'Compras & Carteira',
      label1: 'Meus Perfis',
    ),
    // Slot 1: Perfil Social / Mensagens
    _ItemSlotDuplo(
      icone0: Icons.person_outline,
      icone1: Icons.chat_bubble_outline_rounded,
      label0: 'Perfil Social',
      label1: 'Mensagens',
    ),
    // Slot 2: Busca & Mapa / Player Universal
    _ItemSlotDuplo(
      icone0: Icons.search,
      icone1: Icons.play_circle_outline,
      label0: 'Busca & Mapa',
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

  @override
  void initState() {
    super.initState();
    _slotAtivo = widget.indiceSelecionado ?? widget.slotSelecionado;
    // Sincroniza a memória com a tela atual caso ela declare um sub-índice explícito
    if (_slotAtivo >= 0 && _slotAtivo < _memoriaSubIndices.length) {
      _memoriaSubIndices[_slotAtivo] = widget.subIndiceSelecionado;
    }
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
      _navegarPara(slot, alternado);
    } else {
      _memoriaSubIndices[slot] = novoSub;
      _navegarPara(slot, novoSub);
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

  void _navegarPara(int slot, int subIndice) {
    Widget pagina;

    if (slot == 0) {
      if (subIndice == 0) {
        pagina = const ComprasUsuarioView();
      } else {
        pagina = const PerfisPdvView();
      }
    } else if (slot == 1) {
      if (subIndice == 0) {
        pagina = const PerfilSocialView(mostrarBotaoVoltar: false);
      } else {
        pagina = const MensageriaView(
          modoLoja: false,
          mostrarBotaoVoltar: false,
        );
      }
    } else if (slot == 2) {
      if (subIndice == 0) {
        pagina = const EmConstrucaoView(
          titulo: 'Busca & Mapa',
          subtitulo: 'Localize lojas, produtos e produtores soberanos no mapa',
          icone: Icons.search,
          slotSelecionado: 2,
          subIndiceSelecionado: 0,
        );
      } else {
        pagina = const EmConstrucaoView(
          titulo: 'Player Universal',
          subtitulo: 'Vídeos, músicas e leitor de PDFs integrados na rede',
          icone: Icons.play_circle_outline,
          slotSelecionado: 2,
          subIndiceSelecionado: 1,
        );
      }
    } else if (slot == 3) {
      if (subIndice == 0) {
        pagina = const EmConstrucaoView(
          titulo: 'Feed de Descoberta',
          subtitulo: 'Memes, novidades e publicações de toda a rede local',
          icone: Icons.explore_outlined,
          slotSelecionado: 3,
          subIndiceSelecionado: 0,
        );
      } else {
        pagina = const EmConstrucaoView(
          titulo: 'Feed de Amigos',
          subtitulo: 'Publicações da sua rede de confiança e conexões',
          icone: Icons.people_alt_outlined,
          slotSelecionado: 3,
          subIndiceSelecionado: 1,
        );
      }
    } else {
      if (subIndice == 0) {
        pagina = const EmConstrucaoView(
          titulo: 'Autogestão Social',
          subtitulo: 'Assembleias, deliberações e tomada de decisão coletiva',
          icone: Icons.hub_outlined,
          slotSelecionado: 4,
          subIndiceSelecionado: 0,
        );
      } else {
        pagina = const EmConstrucaoView(
          titulo: 'Governança & Gestão',
          subtitulo: 'Ferramentas de coordenação e autogestão popular',
          icone: Icons.account_tree_outlined,
          slotSelecionado: 4,
          subIndiceSelecionado: 1,
        );
      }
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => pagina),
      (route) => route.isFirst,
    );
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
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.85,
                                      end: 1.0,
                                    ).animate(animation),
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