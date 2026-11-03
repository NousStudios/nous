import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

class CanvaColorPickerModal extends StatefulWidget {
  final AppTheme theme;
  final String title;
  final Color initialColor;
  final bool allowGradient;
  final Function(Color color, Gradient? gradient) onApply;

  const CanvaColorPickerModal({
    super.key,
    required this.theme,
    required this.title,
    required this.initialColor,
    required this.allowGradient,
    required this.onApply,
  });

  @override
  State<CanvaColorPickerModal> createState() => _CanvaColorPickerModalState();
}

class _CanvaColorPickerModalState extends State<CanvaColorPickerModal>
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    // 32 = insetPadding horizontal (16 de cada lado)
    // 32 = contentPadding horizontal (16 de cada lado)
    final rawWidth = screenWidth - 32 - 32;
    final modalWidth = rawWidth.clamp(0.0, 300.0).toDouble();

    // O seletor de cor precisa de uma folga interna para nao colar nas bordas.
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
        textAlign: TextAlign.center,
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
      actionsAlignment: MainAxisAlignment.center,
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
