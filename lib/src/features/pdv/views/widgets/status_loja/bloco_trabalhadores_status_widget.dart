import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_excluidas_service.dart';
import 'package:nous/src/features/auth/views/widgets/contas_excluidas_dialog.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/features/pdv/views/widgets/status_loja/widgets/linha_trabalhador_status_widget.dart';

/// Card que exibe a lista de trabalhadores e status dos seus dispositivos na rede local.
class BlocoTrabalhadoresStatusWidget extends StatefulWidget {
  final String lojaId;
  final List<MembroLoja> membrosFallback;
  final String cpfLogado;
  final AppTheme theme;

  const BlocoTrabalhadoresStatusWidget({
    super.key,
    required this.lojaId,
    required this.membrosFallback,
    required this.cpfLogado,
    required this.theme,
  });

  @override
  State<BlocoTrabalhadoresStatusWidget> createState() =>
      _BlocoTrabalhadoresStatusWidgetState();
}

class _BlocoTrabalhadoresStatusWidgetState
    extends State<BlocoTrabalhadoresStatusWidget> {
  final TextEditingController _buscaCtrl = TextEditingController();
  String _termoBusca = '';
  Set<String> _cpfsExcluidos = {};

  bool get _ehLojaColetivaNous =>
      widget.lojaId == PdvProvider.idLojaColetivaNous ||
      widget.lojaId == ChatService.idLojaColetivaNous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().carregarCacheContas();
      _carregarExcluidos();
    });
  }

  Future<void> _carregarExcluidos() async {
    final lista = await ContasExcluidasService.carregarTodas();
    if (!mounted) return;
    setState(() {
      _cpfsExcluidos = lista
          .map((e) => e.cpf.replaceAll(RegExp(r'\D'), ''))
          .where((e) => e.isNotEmpty)
          .toSet();
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  BoxDecoration _decoracaoDoBloco(AppTheme theme) {
    return BoxDecoration(
      color: theme.cardBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.borderColor),
    );
  }

  Widget _tituloDoBloco(AppTheme theme, String titulo) {
    return Text(
      titulo,
      style: theme.getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  bool _correspondeBusca(MembroLoja m, AuthProvider auth, String termo) {
    if (termo.isEmpty) return true;
    final t = termo.toLowerCase();
    final tDigitos = termo.replaceAll(RegExp(r'\D'), '');
    if (m.nome.toLowerCase().contains(t)) return true;
    if (m.cpf.toLowerCase().contains(t)) return true;
    if (tDigitos.isNotEmpty &&
        m.cpf.replaceAll(RegExp(r'\D'), '').contains(tDigitos)) {
      return true;
    }

    final u = auth.buscarContaPorCpf(m.cpf);
    if (u == null) return false;
    final campos = [
      u.nome,
      u.apelido,
      u.nomeDeUsuario,
      u.nomePublico,
      u.apelidoPublico,
      u.localNascimento,
      u.dataNascimento,
      u.estadoCivil,
      u.tipoSanguineo,
      u.nomePai,
      u.nomeMae,
      u.biografia,
      ...u.emails,
    ];
    return campos.any((c) => c.toLowerCase().contains(t));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final loja = context.watch<PdvProvider>().buscarPorId(widget.lojaId);
    final auth = context.watch<AuthProvider>();
    final ehLojaColetivaNous = _ehLojaColetivaNous;

    final cpfsAtivos = auth.contasCache
        .map((c) => c.cpf.replaceAll(RegExp(r'\D'), ''))
        .toSet();
    final membros = (loja?.membros ?? widget.membrosFallback).where((m) {
      final cpfNorm = m.cpf.replaceAll(RegExp(r'\D'), '');
      if (ehLojaColetivaNous) {
        if (_cpfsExcluidos.contains(cpfNorm)) return false;
        if (cpfsAtivos.isNotEmpty && !cpfsAtivos.contains(cpfNorm)) {
          return false;
        }
        if (!_correspondeBusca(m, auth, _termoBusca)) return false;
      }
      return true;
    }).toList();
    final titulo =
        ehLojaColetivaNous ? 'Lista de Usuários' : 'Lista de Trabalhadores';
    final msgVazia = ehLojaColetivaNous
        ? (_termoBusca.isNotEmpty
            ? 'Nenhum usuário encontrado para "$_termoBusca".'
            : 'Nenhum usuário cadastrado ainda.')
        : 'Nenhum trabalhador cadastrado ainda.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          Row(
            children: [
              if (ehLojaColetivaNous) const SizedBox(width: 32),
              Expanded(
                child: Center(child: _tituloDoBloco(theme, titulo)),
              ),
              if (ehLojaColetivaNous)
                Tooltip(
                  message: 'Contas excluídas do Nous',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      await ContasExcluidasDialog.mostrar(
                        context: context,
                        theme: theme,
                      );
                      _carregarExcluidos();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.history_toggle_off_rounded,
                        size: 18,
                        color: theme.secondaryTextColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (ehLojaColetivaNous) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _buscaCtrl,
              onChanged: (v) => setState(() => _termoBusca = v.trim()),
              style: theme.getTextStyle(fontSize: 12.5, color: theme.textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.backgroundColor,
                hintText: 'Pesquisar por nome, CPF, cidade ou identidade...',
                hintStyle: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 16,
                          color: theme.secondaryTextColor,
                        ),
                        onPressed: () {
                          _buscaCtrl.clear();
                          setState(() => _termoBusca = '');
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
          ],
          const SizedBox(height: 12),
          if (auth.modoVisitante)
            EstadoVazioContainer(
              theme: theme,
              mensagem:
                  'A identidade dos integrantes desta loja fica oculta no Modo Visitante.',
            )
          else if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: msgVazia,
            )
          else
            for (final membro in membros)
              LinhaTrabalhadorStatusWidget(
                lojaId: widget.lojaId,
                membro: membro,
                cpfLogado: widget.cpfLogado,
                theme: theme,
              ),
        ],
      ),
    );
  }
}
