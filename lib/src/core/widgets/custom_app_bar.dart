import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  // Função para exibir o pop-up de configurações
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite fechar clicando fora do pop-up
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Fundo escuro minimalista
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          
          // Ajusta o espaçamento do título para manter o alinhamento perfeito
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
          
          // Título centralizado
          title: const Text(
            'Configurações',
            textAlign: TextAlign.center, // <--- CENTRALIZA O TEXTO DO TÍTULO
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ajusta a altura ao conteúdo
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: Colors.white70),
                title: const Text('Tema', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Ação para trocar tema
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white70),
                title: const Text('Idioma', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Ação para trocar idioma
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text('Sobre o App', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Ação sobre
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha a janela
              child: const Text(
                'Fechar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black, // Padrão minimalista
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: [
        IconButton(
          tooltip: 'Configurações',
          icon: Image.asset(
            'assets/icons/settings_icon.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => _showSettingsDialog(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}