import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class ThemeCustomizerDialog extends StatelessWidget {
  const ThemeCustomizerDialog({super.key});

  static const List<String> fonts = ['Belleza', 'Inter', 'Roboto', 'Poppins', 'Lato'];

  void _openCanvaStyleColorPicker({
    required BuildContext context,
    required AppTheme theme,
    required String title,
    required Color currentColor,
    required bool allowGradient,
    required Function(Color color, Gradient? gradient) onApply,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _CanvaColorPickerModal(
          theme: theme,
          title: title,
          initialColor: currentColor,
          allowGradient: allowGradient,
          onApply: (color, gradient) {
            onApply(color, gradient);
            Navigator.of(dialogCtx).pop();
          },
        );
      },
    );
  }

  void _showSaveThemeDialog(BuildContext context, AppTheme theme) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Salvar Tema',
            style: theme.getTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: theme.getTextStyle(),
            decoration: InputDecoration(
              hintText: 'Nome do tema (ex: Meu Tema Roxo)',
              hintStyle: theme.getTextStyle(color: theme.secondaryTextColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.textColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                ThemeController.saveCurrentThemeAs(name);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Salvar',
                style: theme.getTextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorSection({
    required BuildContext context,
    required AppTheme theme,
    required String title,
    required Color currentColor,
    required Gradient? currentGradient,
    required List<ColorOption> recentColors,
    required bool allowGradient,
    required Function(Color color, Gradient? gradient) onSelect,
  }) {
    final displayOptions = recentColors.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded: o texto ocupa todo o espaco que sobrar depois das bolinhas.
          // Com maxLines + ellipsis ele nunca "empurra" a linha para fora da tela,
          // mesmo com a fonte no tamanho maximo (1.6x).
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          // Este Row tem tamanho FIXO e previsivel: cada bolinha mede 34 de largura.
          // mainAxisSize.min faz ele ocupar so o necessario, nunca mais.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...displayOptions.map((option) {
                final isSelected = option.gradient == currentGradient &&
                    (option.gradient != null || currentColor.toARGB32() == option.color.toARGB32());

                return GestureDetector(
                  onTap: () => onSelect(option.color, option.gradient),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: option.gradient == null ? option.color : null,
                      gradient: option.gradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.buttonColor : theme.borderColor,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.buttonColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _openCanvaStyleColorPicker(
                  context: context,
                  theme: theme,
                  title: 'Personalizar $title',
                  currentColor: currentColor,
                  allowGradient: allowGradient,
                  onApply: onSelect,
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.borderColor, width: 1.5),
                  ),
                  child: Icon(Icons.add, color: theme.textColor, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Botao de "+" e "-" feito a mao, com tamanho FIXO de 32x32.
  //
  // Por que nao usar IconButton aqui? Porque o IconButton tem regras internas
  // de "area minima de toque" (48x48 por padrao no Material) que entram em
  // conflito quando a gente tenta reduzi-lo. O tamanho final dele fica
  // imprevisivel, e era justamente isso que estourava a linha quando a fonte
  // aumentava. Com um Container de tamanho fixo, a conta e sempre a mesma.
  Widget _buildFontScaleButton({
    required AppTheme theme,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        // Se "enabled" for falso, passamos null e o botao fica inativo.
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? theme.textColor
                : theme.secondaryTextColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final currentScale = theme.fontScale;
        final canDecrease = currentScale > ThemeController.minFontScale;
        final canIncrease = currentScale < ThemeController.maxFontScale;

        // ============ CALCULO DA LARGURA (SEM LayoutBuilder) ============
        // IMPORTANTE: nao usar LayoutBuilder dentro do "content" de um
        // AlertDialog. O AlertDialog precisa MEDIR o conteudo antes de
        // desenha-lo (ele usa IntrinsicWidth por dentro), e o LayoutBuilder
        // so sabe se construir DEPOIS de saber o espaco disponivel.
        // Os dois juntos criam um impasse: era isso que travava o app.
        //
        // Aqui usamos MediaQuery.sizeOf(context), que da a largura da tela
        // de forma segura, e descontamos as margens que NOS MESMOS definimos
        // logo abaixo (insetPadding e contentPadding) - ou seja, nao e chute,
        // sao numeros que estao escritos neste proprio arquivo.
        final screenWidth = MediaQuery.sizeOf(context).width;

        // 32 = insetPadding horizontal (16 de cada lado)
        // 40 = contentPadding horizontal (20 de cada lado)
        final rawWidth = screenWidth - 32 - 40;

        // clamp(0.0, 380.0) = "prenda esse numero entre 0 e 380".
        // Isso protege contra dois desastres: largura negativa (que quebra o
        // Flutter em telas muito estreitas) e largura exagerada em desktop.
        final contentWidth = rawWidth.clamp(0.0, 380.0).toDouble();
        // ================================================================

        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: theme.borderColor, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Personalizar Aparência',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor de Fundo',
                    currentColor: theme.backgroundColor,
                    currentGradient: theme.backgroundGradient,
                    recentColors: ThemeController.recentBackgroundColors,
                    allowGradient: true,
                    onSelect: (color, gradient) =>
                        ThemeController.updateBackgroundColor(color, gradient: gradient),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor das Janelas',
                    currentColor: theme.cardBackgroundColor,
                    currentGradient: theme.cardGradient,
                    recentColors: ThemeController.recentCardColors,
                    allowGradient: true,
                    onSelect: (color, gradient) =>
                        ThemeController.updateCardColor(color, gradient: gradient),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor dos Títulos',
                    currentColor: theme.textColor,
                    currentGradient: null,
                    recentColors: ThemeController.recentTextColors,
                    allowGradient: false,
                    onSelect: (color, _) => ThemeController.updateTextColor(color),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor do Texto Normal',
                    currentColor: theme.secondaryTextColor,
                    currentGradient: null,
                    recentColors: ThemeController.recentSecondaryTextColors,
                    allowGradient: false,
                    onSelect: (color, _) => ThemeController.updateSecondaryTextColor(color),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor dos Botões',
                    currentColor: theme.buttonColor,
                    currentGradient: theme.buttonGradient,
                    recentColors: ThemeController.recentButtonColors,
                    allowGradient: true,
                    onSelect: (color, gradient) =>
                        ThemeController.updateButtonColor(color, gradient: gradient),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor do Texto dos Botões',
                    currentColor: theme.buttonTextColor,
                    currentGradient: null,
                    recentColors: ThemeController.recentButtonTextColors,
                    allowGradient: false,
                    onSelect: (color, _) => ThemeController.updateButtonTextColor(color),
                  ),
                  const SizedBox(height: 10),
                  _buildColorSection(
                    context: context,
                    theme: theme,
                    title: 'Cor das Arestas',
                    currentColor: theme.borderColor,
                    currentGradient: null,
                    recentColors: ThemeController.recentBorderColors,
                    allowGradient: false,
                    onSelect: (color, _) => ThemeController.updateBorderColor(color),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: theme.borderColor.withValues(alpha: 0.5), height: 1),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fonte do Texto',
                          style: theme.getTextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: theme.fontName,
                              dropdownColor: theme.cardBackgroundColor,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down, color: theme.textColor),
                              items: fonts.map((font) {
                                return DropdownMenuItem<String>(
                                  value: font,
                                  child: Text(
                                    font,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.getTextStyle(
                                      color: theme.textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newFont) {
                                if (newFont != null) {
                                  ThemeController.updateFont(newFont);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tamanho da Fonte',
                          style: theme.getTextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),

                        // ========== SECAO QUE ESTOURAVA (RECONSTRUIDA) ==========
                        // A linha agora e 100% previsivel:
                        //  - Expanded (texto da porcentagem) = pega o que sobrar
                        //  - SizedBox de 8 = espaco fixo
                        //  - Row de dois botoes de 32x32 + 4 de espaco = 68 fixos
                        // Como o texto e o unico elemento "elastico", ele encolhe
                        // sozinho quando a fonte cresce. Nao ha como estourar.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${(currentScale * 100).round()}%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.getTextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFontScaleButton(
                                    theme: theme,
                                    icon: Icons.remove,
                                    enabled: canDecrease,
                                    onPressed: ThemeController.decreaseFontScale,
                                    tooltip: 'Diminuir fonte',
                                  ),
                                  const SizedBox(width: 4),
                                  _buildFontScaleButton(
                                    theme: theme,
                                    icon: Icons.add,
                                    enabled: canIncrease,
                                    onPressed: ThemeController.increaseFontScale,
                                    tooltip: 'Aumentar fonte',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ========================================================
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showSaveThemeDialog(context, theme),
                      icon: Icon(Icons.save_outlined, color: theme.textColor, size: 20),
                      label: Text(
                        'Salvar Tema Atual...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(fontSize: 14, color: theme.textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  side: BorderSide(color: theme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Concluído',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.buttonTextColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CanvaColorPickerModal extends StatefulWidget {
  final AppTheme theme;
  final String title;
  final Color initialColor;
  final bool allowGradient;
  final Function(Color color, Gradient? gradient) onApply;

  const _CanvaColorPickerModal({
    required this.theme,
    required this.title,
    required this.initialColor,
    required this.allowGradient,
    required this.onApply,
  });

  @override
  State<_CanvaColorPickerModal> createState() => _CanvaColorPickerModalState();
}

class _CanvaColorPickerModalState extends State<_CanvaColorPickerModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _solidColor;
  late Color _gradientStart;
  late Color _gradientEnd;
  int _activeGradientIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.allowGradient ? 2 : 1, vsync: this);
    _solidColor = widget.initialColor;
    _gradientStart = widget.initialColor;
    _gradientEnd = Colors.blue;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Mesmo raciocinio do popup principal: NADA de LayoutBuilder dentro do
    // content de um AlertDialog. Este modal tambem estava com o problema,
    // entao ele travaria assim que voce clicasse no botao "+" de qualquer cor.
    final screenWidth = MediaQuery.sizeOf(context).width;

    // 32 = insetPadding horizontal (16 de cada lado)
    // 32 = contentPadding horizontal (16 de cada lado)
    final rawWidth = screenWidth - 32 - 32;
    final modalWidth = rawWidth.clamp(0.0, 300.0).toDouble();

    // O seletor de cor precisa de uma folga interna para nao colar nas bordas.
    // O clamp garante que esse valor nunca fique negativo em telas minusculas.
    final pickerWidth = (modalWidth - 24).clamp(0.0, 300.0).toDouble();

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        widget.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.getTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: modalWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowGradient) ...[
              TabBar(
                controller: _tabController,
                labelColor: theme.buttonColor,
                unselectedLabelColor: theme.secondaryTextColor,
                indicatorColor: theme.buttonColor,
                tabs: const [
                  Tab(text: 'Sólida'),
                  Tab(text: 'Gradiente'),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ColorPicker(
                          pickerColor: _solidColor,
                          onColorChanged: (c) => setState(() => _solidColor = c),
                          colorPickerWidth: pickerWidth,
                          pickerAreaHeightPercent: 0.5,
                          enableAlpha: true,
                          displayThumbColor: true,
                          portraitOnly: true,
                          hexInputBar: true,
                        ),
                      ],
                    ),
                  ),
                  if (widget.allowGradient)
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [_gradientStart, _gradientEnd],
                              ),
                              border: Border.all(color: theme.borderColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: Text('Cor 1', style: theme.getTextStyle(fontSize: 12)),
                                selected: _activeGradientIndex == 0,
                                onSelected: (_) => setState(() => _activeGradientIndex = 0),
                                avatar: CircleAvatar(backgroundColor: _gradientStart),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Cor 2', style: theme.getTextStyle(fontSize: 12)),
                                selected: _activeGradientIndex == 1,
                                onSelected: (_) => setState(() => _activeGradientIndex = 1),
                                avatar: CircleAvatar(backgroundColor: _gradientEnd),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ColorPicker(
                            pickerColor:
                                _activeGradientIndex == 0 ? _gradientStart : _gradientEnd,
                            onColorChanged: (c) {
                              setState(() {
                                if (_activeGradientIndex == 0) {
                                  _gradientStart = c;
                                } else {
                                  _gradientEnd = c;
                                }
                              });
                            },
                            colorPickerWidth: pickerWidth,
                            pickerAreaHeightPercent: 0.4,
                            enableAlpha: false,
                            portraitOnly: true,
                            hexInputBar: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
              style: theme.getTextStyle(color: theme.secondaryTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.buttonColor,
            foregroundColor: theme.buttonTextColor,
            side: BorderSide(color: theme.borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_tabController.index == 0 || !widget.allowGradient) {
              widget.onApply(_solidColor, null);
            } else {
              final gradient = LinearGradient(
                colors: [_gradientStart, _gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
              widget.onApply(_gradientStart, gradient);
            }
          },
          child: Text(
            'Aplicar',
            style: theme.getTextStyle(
              color: theme.buttonTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}