import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Janela discreta que lista as contas que foram criadas e excluídas do sistema Nous.
class ContasExcluidasDialog {
  ContasExcluidasDialog._();

  static String _formatarData(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso.isEmpty ? '—' : iso;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  static String _mascararCpf(String cpf) {
    final limpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (limpo.length < 3) return '***';
    return '${limpo.substring(0, 3)}.***.***-**';
  }

  static Future<void> mostrar({
    required BuildContext context,
    required AppTheme theme,
  }) async {
    final listaInicial = await ContasExcluidasService.carregarTodas();
    if (!context.mounted) return;

    final buscaCtrl = TextEditingController();
    String termo = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final t = termo.trim().toLowerCase();
            final filtradas = t.isEmpty
                ? listaInicial
                : listaInicial.where((c) {
                    return c.nome.toLowerCase().contains(t) ||
                        c.apelido.toLowerCase().contains(t) ||
                        c.cpf.toLowerCase().contains(t) ||
                        c.localNascimento.toLowerCase().contains(t);
                  }).toList();

            return Dialog(
              backgroundColor: theme.cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 36),
                          Expanded(
                            child: Text(
                              'Contas Excluídas do Nous',
                              textAlign: TextAlign.center,
                              style: theme.getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: theme.secondaryTextColor,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: buscaCtrl,
                        onChanged: (v) => setModalState(() => termo = v),
                        style: theme.getTextStyle(
                          fontSize: 12.5,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.backgroundColor,
                          hintText: 'Pesquisar por nome, CPF ou cidade...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: theme.secondaryTextColor,
                          ),
                          suffixIcon: termo.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: theme.secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    buscaCtrl.clear();
                                    setModalState(() => termo = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.borderColor.withValues(alpha: 0.6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.textColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filtradas.isEmpty
                            ? EstadoVazioContainer(
                                theme: theme,
                                mensagem:
                                    'Nenhuma conta excluída registrada.',
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtradas.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, idx) {
                                  final item = filtradas[idx];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.borderColor
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_off_outlined,
                                              size: 16,
                                              color: theme.dangerColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextoRolante(
                                                texto: item.nome.isNotEmpty
                                                    ? item.nome
                                                    : 'Usuário Nous',
                                                style: theme.getTextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'CPF: ${_mascararCpf(item.cpf)}'
                                          '${item.localNascimento.isNotEmpty ? ' • ${item.localNascimento}' : ''}',
                                          style: theme.getTextStyle(
                                            fontSize: 11.5,
                                            color: theme.secondaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Excluída em: ${_formatarData(item.excluidoEm)}',
                                          style: theme.getTextStyle(
                                            fontSize: 11,
                                            color: theme.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    buscaCtrl.dispose();
  }
}
