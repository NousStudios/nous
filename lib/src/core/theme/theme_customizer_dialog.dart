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
    final displayOptions = recentColors.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...displayOptions.map((option) {
              final isSelected = option.gradient == currentGradient &&
                  (option.gradient != null || currentColor.toARGB32() == option.color.toARGB32());

              return GestureDetector(
                onTap: () => onSelect(option.color, option.gradient),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: option.gradient == null ? option.color : null,
                    gradient: option.gradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : theme.borderColor,
                      width: isSelected ? 3 : 1,
                    ),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.borderColor, width: 1.5),
                ),
                child: Icon(Icons.add, color: theme.textColor, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, child) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Personalizar Aparência',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildColorSection(
                  context: context,
                  theme: theme,
                  title: 'Cor de Fundo',
                  currentColor: theme.backgroundColor,
                  currentGradient: theme.backgroundGradient,
                  recentColors: ThemeController.recentBackgroundColors,
                  allowGradient: true,
                  onSelect: (color, gradient) => ThemeController.updateBackgroundColor(color, gradient: gradient),
                ),
                const SizedBox(height: 16),
                _buildColorSection(
                  context: context,
                  theme: theme,
                  title: 'Cor das Janelas',
                  currentColor: theme.cardBackgroundColor,
                  currentGradient: theme.cardGradient,
                  recentColors: ThemeController.recentCardColors,
                  allowGradient: true,
                  onSelect: (color, gradient) => ThemeController.updateCardColor(color, gradient: gradient),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                _buildColorSection(
                  context: context,
                  theme: theme,
                  title: 'Cor dos Botões',
                  currentColor: theme.buttonColor,
                  currentGradient: theme.buttonGradient,
                  recentColors: ThemeController.recentButtonColors,
                  allowGradient: true,
                  onSelect: (color, gradient) => ThemeController.updateButtonColor(color, gradient: gradient),
                ),
                const SizedBox(height: 16),
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
                Text(
                  'Fonte do Texto',
                  style: theme.getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: theme.fontName,
                      dropdownColor: theme.cardBackgroundColor,
                      isExpanded: true,
                      items: fonts.map((font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(
                            font,
                            style: theme.getTextStyle(color: theme.textColor),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Concluído',
                style: theme.getTextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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

class _CanvaColorPickerModalState extends State<_CanvaColorPickerModal> with SingleTickerProviderStateMixin {
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

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
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
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowGradient) ...[
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: theme.secondaryTextColor,
                indicatorColor: Colors.blue,
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
                          colorPickerWidth: 240,
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
                            pickerColor: _activeGradientIndex == 0 ? _gradientStart : _gradientEnd,
                            onColorChanged: (c) {
                              setState(() {
                                if (_activeGradientIndex == 0) {
                                  _gradientStart = c;
                                } else {
                                  _gradientEnd = c;
                                }
                              });
                            },
                            colorPickerWidth: 240,
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
          child: Text('Cancelar', style: theme.getTextStyle(color: theme.secondaryTextColor)),
        ),
        TextButton(
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
          child: Text('Aplicar', style: theme.getTextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}