import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/solicitacao_validacao_identidade.dart';
import 'package:nous/src/features/auth/services/validacao_identidade_service.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Modal ou painel para visualização e deliberação de validações de identidade no Perfil Nous
class DialogFilaValidacaoIdentidades extends StatefulWidget {
  final AppTheme theme;
  final String cpfValidador;
  final String nomeValidador;

  const DialogFilaValidacaoIdentidades({
    super.key,
    required this.theme,
    required this.cpfValidador,
    required this.nomeValidador,
  });

  @override
  State<DialogFilaValidacaoIdentidades> createState() => _DialogFilaValidacaoIdentidadesState();
}

class _DialogFilaValidacaoIdentidadesState extends State<DialogFilaValidacaoIdentidades> {
  List<SolicitacaoValidacaoIdentidade> _solicitacoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  Future<void> _carregarSolicitacoes() async {
    final lista = await ValidacaoIdentidadeService.listarSolicitacoes();
    if (!mounted) return;
    setState(() {
      _solicitacoes = lista;
      _carregando = false;
    });
  }

  Future<void> _aprovar(SolicitacaoValidacaoIdentidade sol) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.backgroundColor,
        title: Text(
          'Atestar Identidade',
          textAlign: TextAlign.center,
          style: widget.theme.getTextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Você confirma que conhece pessoalmente "${sol.nomeCandidato}" e atesta que este CPF (${sol.cpfCandidato}) pertence a esta pessoa?\n\nSua chave criptográfica assinará este atestado de forma permanente.',
          style: widget.theme.getTextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: widget.theme.getTextStyle()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, Atestar'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    await ValidacaoIdentidadeService.aprovarIdentidade(
      solicitacao: sol,
      cpfValidador: widget.cpfValidador,
      nomeValidador: widget.nomeValidador,
    );

    await _carregarSolicitacoes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Identidade de ${sol.nomeCandidato} atestada com sucesso!')),
      );
    }
  }

  void _abrirFichaCandidato(String cpf) {
    final auth = context.read<AuthProvider>();
    final conta = auth.buscarContaPorCpf(cpf);
    if (conta != null) {
      FichaUsuarioDialog.mostrar(
        context,
        theme: widget.theme,
        usuario: conta,
        somenteLeitura: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF2196F3),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validação Comunitária de Identidade',
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          'Teia de Confiança Soberana Nous',
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Conteúdo da lista
              Expanded(
                child: _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : _solicitacoes.isEmpty
                        ? EstadoVazioContainer(
                            theme: theme,
                            mensagem: 'Nenhum novo cidadão aguardando atesto de identidade no momento.',
                          )
                        : ListView.separated(
                            itemCount: _solicitacoes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final sol = _solicitacoes[index];
                              return _buildCardSolicitacao(theme, sol);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSolicitacao(AppTheme theme, SolicitacaoValidacaoIdentidade sol) {
    final statusCor = sol.estaAprovado
        ? const Color(0xFF4CAF50)
        : sol.estaRejeitado
            ? theme.dangerColor
            : const Color(0xFFFFA000);

    final statusTexto = sol.estaAprovado
        ? 'Atestado'
        : sol.estaRejeitado
            ? 'Rejeitado'
            : 'Aguardando Atesto';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.borderColor,
                child: Text(
                  sol.nomeCandidato.isNotEmpty ? sol.nomeCandidato[0].toUpperCase() : '?',
                  style: theme.getTextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoRolante(
                      texto: sol.nomeCandidato,
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextoRolante(
                      texto:
                          '${sol.nomeDeUsuario.isNotEmpty ? "@${sol.nomeDeUsuario.replaceAll('@', '')} • " : ""}CPF: ${sol.cpfCandidato}',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusCor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusTexto,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusCor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.person_search_rounded, size: 16),
                label: const Text('Ver Ficha'),
                onPressed: () => _abrirFichaCandidato(sol.cpfCandidato),
              ),
              if (sol.estaPendente) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Atestar Identidade'),
                  onPressed: () => _aprovar(sol),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
