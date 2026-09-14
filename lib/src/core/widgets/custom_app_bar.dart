import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onSettingsPressed;

  const CustomAppBar({
    super.key,
    this.title,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      centerTitle: true,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            tooltip: 'Configurações',
            icon: Image.asset(
              'assets/icons/settings_icon.png', // Altere para o nome exato do seu PNG
              width: 24,
              height: 24,
            ),
            onPressed: onSettingsPressed ??
                () {
                  // Ação padrão ao clicar nas primeiras versões
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configurações em desenvolvimento'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}