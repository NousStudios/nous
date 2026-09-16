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

  /// Constrói cada seção de cor dentro de um container com acabamento limpo
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
          Expanded(
            child: Text(
              title,
              style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        final currentScale = theme.fontScale;
        final canDecrease = currentScale > ThemeController.minFontScale;
        final canIncrease = currentScale < ThemeController.maxFontScale;

        // Calcula a largura do popup com base no tamanho real da tela do aparelho,
        // em vez de usar um número fixo (que estava causando overflow em telas pequenas).
        // Em telas largas, limita a 380px para não ficar exagerado; em telas estreitas,
        // usa 90% da largura disponível, sempre com uma margem de segurança.
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 440 ? screenWidth * 0.9 : 380.0;

        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: theme.borderColor, width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalizar Aparência',
                style: theme.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: theme.secondaryTextColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  // Seções de escolha de cores agrupadas
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
                    title: 'Cor do Texto',
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
                    title: 'Cor dos Botões',
                    currentColor: theme.buttonColor,
                    currentGradient: theme.buttonGradient,
                    recentColors: ThemeController.recentButtonColors,
                    allowGradient: true,
                    onSelect: (color, gradient) =>
                        ThemeController.updateButtonColor(color, gradient: gradient),
                  ),
                  const SizedBox(height: 10),
                  // NOVA SEÇÃO: cor do texto dentro dos botões (ex: "Concluído", "Aplicar")
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

                  // Configuração de Tipografia
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(currentScale * 100).round()}%',
                                style: theme.getTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove,
                                      color: canDecrease
                                          ? theme.textColor
                                          : theme.secondaryTextColor.withValues(alpha: 0.3),
                                      size: 20,
                                    ),
                                    onPressed: canDecrease
                                        ? ThemeController.decreaseFontScale
                                        : null,
                                    tooltip: 'Diminuir fonte',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      color: canIncrease
                                          ? theme.textColor
                                          : theme.secondaryTextColor.withValues(alpha: 0.3),
                                      size: 20,
                                    ),
                                    onPressed: canIncrease
                                        ? ThemeController.increaseFontScale
                                        : null,
                                    tooltip: 'Aumentar fonte',
                                  ),
                                ],
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
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor,
                  foregroundColor: theme.buttonTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Concluído',
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

    // Mesma lógica de largura responsiva aplicada aqui, já que esse modal também
    // usava um valor fixo (300) que pode estourar em telas muito estreitas.
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth < 360 ? screenWidth * 0.85 : 300.0;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        widget.title,
        style: theme.getTextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          // A largura do seletor de cores também acompanha a largura
                          // calculada do modal, em vez de um valor fixo de 240
                          colorPickerWidth: modalWidth - 40,
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
                            colorPickerWidth: modalWidth - 40,
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