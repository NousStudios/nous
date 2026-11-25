import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';

/// Seção de seleção e exibição de colaboradores (coautores) no diálogo de
/// edição de publicação.
class SecaoColaboradoresEditarPubWidget extends StatelessWidget {
  final AppTheme theme;
  final String autorCpf;
  final List<String> coautoresCpfs;
  final List<UsuarioNous> todasContas;
  final ValueChanged<List<String>> onAlterarCoautores;

  const SecaoColaboradoresEditarPubWidget({
    super.key,
    required this.theme,
    required this.autorCpf,
    required this.coautoresCpfs,
    required this.todasContas,
    required this.onAlterarCoautores,
  });

  String _nomeColaborador(String cpf) {
    final limpo = cpf.replaceAll(RegExp(r'\D'), '');
    for (final c in todasContas) {
      if (c.cpf.replaceAll(RegExp(r'\D'), '') == limpo) {
        return c.nomeExibicao.isNotEmpty ? c.nomeExibicao : cpf;
      }
    }
    return cpf;
  }

  Future<void> _abrirSeletorColaborador(BuildContext context) async {
    final autorLimpo = autorCpf.replaceAll(RegExp(r'\D'), '');
    final selecionados =
        coautoresCpfs.map((c) => c.replaceAll(RegExp(r'\D'), '')).toSet();
    final buscaCtrl = TextEditingController();
    String termo = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setModalState) {
          final candidatos = todasContas.where((u) {
            final uCpf = u.cpf.replaceAll(RegExp(r'\D'), '');
            if (uCpf.isEmpty || uCpf == autorLimpo) return false;
            if (termo.trim().isEmpty) return true;
            final t = termo.trim().toLowerCase();
            return u.nomeExibicao.toLowerCase().contains(t) ||
                u.usernameExibicao.toLowerCase().contains(t);
          }).toList();

          return Dialog(
            backgroundColor: theme.cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.borderColor),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 380,
                maxHeight: MediaQuery.sizeOf(dCtx).height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Marcar Colaboradores',
                      style: theme.getTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: buscaCtrl,
                      onChanged: (v) => setModalState(() => termo = v),
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou @usuario...',
                        hintStyle: theme.getTextStyle(
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: theme.secondaryTextColor,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: candidatos.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'Nenhum usuário encontrado.',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: candidatos.length,
                              itemBuilder: (_, i) {
                                final u = candidatos[i];
                                final uCpf =
                                    u.cpf.replaceAll(RegExp(r'\D'), '');
                                final marcado = selecionados.contains(uCpf);
                                return CheckboxListTile(
                                  dense: true,
                                  value: marcado,
                                  activeColor: theme.buttonColor,
                                  checkColor: theme.buttonTextColor,
                                  title: Text(
                                    u.nomeExibicao,
                                    style: theme.getTextStyle(
                                      fontSize: 13,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  subtitle: u.usernameExibicao.isNotEmpty
                                      ? Text(
                                          u.usernameExibicao,
                                          style: theme.getTextStyle(
                                            fontSize: 11,
                                            color: theme.secondaryTextColor,
                                          ),
                                        )
                                      : null,
                                  onChanged: (v) {
                                    setModalState(() {
                                      if (v == true) {
                                        selecionados.add(uCpf);
                                      } else {
                                        selecionados.remove(uCpf);
                                      }
                                    });
                                    onAlterarCoautores(selecionados.toList());
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Concluir',
                          style: theme.getTextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.buttonColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    buscaCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Colaboradores',
              style: theme.getTextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            TextButton.icon(
              onPressed: () => _abrirSeletorColaborador(context),
              icon: Icon(
                Icons.person_add_alt_1_outlined,
                size: 16,
                color: theme.textColor,
              ),
              label: Text(
                'Marcar',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
        if (coautoresCpfs.isEmpty)
          Text(
            'Nenhum colaborador marcado.',
            style: theme.getTextStyle(
              fontSize: 11.5,
              color: theme.secondaryTextColor,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cpf in coautoresCpfs)
                Chip(
                  backgroundColor: theme.backgroundColor.withValues(alpha: 0.6),
                  side: BorderSide(
                    color: theme.borderColor.withValues(alpha: 0.5),
                  ),
                  label: Text(
                    _nomeColaborador(cpf),
                    style: theme.getTextStyle(
                      fontSize: 11.5,
                      color: theme.textColor,
                    ),
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.secondaryTextColor,
                  ),
                  onDeleted: () {
                    final atualizados = List<String>.from(coautoresCpfs)
                      ..remove(cpf);
                    onAlterarCoautores(atualizados);
                  },
                ),
            ],
          ),
      ],
    );
  }
}
