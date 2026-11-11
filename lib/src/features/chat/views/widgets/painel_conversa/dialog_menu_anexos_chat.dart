import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';

/// Modal para anexos ao chat em grade de ícones seguindo o Design System Nous.
class DialogMenuAnexosChat {
  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
    required VoidCallback onAnexarFoto,
    required VoidCallback onAnexarArquivo,
    required VoidCallback onCompartilharContato,
    VoidCallback? onCompartilharComanda,
    VoidCallback? onFazerPedido,
  }) async {
    void mostrarEmConstrucao(String nome) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            '$nome: Funcionalidade em construção',
            style: theme.getTextStyle(color: theme.textColor),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final itens = [
      if (onFazerPedido != null)
        _ItemMenuAnexo(
          rotulo: 'Fazer Pedido',
          icone: Icons.restaurant_menu_rounded,
          onTap: () {
            Navigator.pop(context);
            onFazerPedido();
          },
        ),
      _ItemMenuAnexo(
        rotulo: 'Galeria',
        icone: Icons.photo_library_rounded,
        onTap: () {
          Navigator.pop(context);
          onAnexarFoto();
        },
      ),
      _ItemMenuAnexo(
        rotulo: 'Documento',
        icone: Icons.insert_drive_file_rounded,
        onTap: () {
          Navigator.pop(context);
          onAnexarArquivo();
        },
      ),
      _ItemMenuAnexo(
        rotulo: 'Contato',
        icone: Icons.person_rounded,
        onTap: () {
          Navigator.pop(context);
          onCompartilharContato();
        },
      ),
      _ItemMenuAnexo(
        rotulo: 'Localização',
        icone: Icons.location_on_rounded,
        onTap: () => mostrarEmConstrucao('Localização'),
      ),
      _ItemMenuAnexo(
        rotulo: 'Enquete',
        icone: Icons.poll_rounded,
        onTap: () => mostrarEmConstrucao('Enquete'),
      ),
      _ItemMenuAnexo(
        rotulo: 'PIX',
        icone: Icons.currency_exchange_rounded,
        onTap: () => mostrarEmConstrucao('PIX'),
      ),
      _ItemMenuAnexo(
        rotulo: 'Evento',
        icone: Icons.event_rounded,
        onTap: () => mostrarEmConstrucao('Evento'),
      ),
      if (onCompartilharComanda != null)
        _ItemMenuAnexo(
          rotulo: 'Comanda',
          icone: Icons.receipt_long_rounded,
          onTap: () {
            Navigator.pop(context);
            onCompartilharComanda();
          },
        ),
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.borderColor),
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final item = itens[index];
                return InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          item.icone,
                          color: theme.textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ItemMenuAnexo {
  final String rotulo;
  final IconData icone;
  final VoidCallback onTap;

  const _ItemMenuAnexo({
    required this.rotulo,
    required this.icone,
    required this.onTap,
  });
}
