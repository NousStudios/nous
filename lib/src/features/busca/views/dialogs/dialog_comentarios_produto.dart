import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_modelos.dart';
import 'package:nous/src/features/busca/models/avaliacao_produto.dart';
import 'package:nous/src/features/busca/services/avaliacoes_produto_service.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

/// Diálogo centralizado de Comentários e Avaliações do produto (Print 5),
/// com cabeçalho de 5 estrelas clicáveis para filtrar por nota (ex: 1 estrela primeiro).
class DialogComentariosProduto extends StatefulWidget {
  final ProdutoMapaItem produto;
  final AppTheme theme;
  final VoidCallback? aoAtualizar;

  const DialogComentariosProduto({
    super.key,
    required this.produto,
    required this.theme,
    this.aoAtualizar,
  });

  @override
  State<DialogComentariosProduto> createState() =>
      _DialogComentariosProdutoState();
}

class _DialogComentariosProdutoState extends State<DialogComentariosProduto> {
  List<AvaliacaoProduto> _avaliacoes = [];
  bool _carregando = true;
  int? _filtroEstrela; // null = todas; 1..5 = filtra pela nota exata
  bool _escrevendoAvaliacao = false;
  int _notaNova = 5;
  final TextEditingController _textoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AvaliacoesProdutoService.versaoAtualizacao.addListener(_carregar);
    _carregar();
  }

  @override
  void dispose() {
    AvaliacoesProdutoService.versaoAtualizacao.removeListener(_carregar);
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await AvaliacoesProdutoService.obterAvaliacoes(
      widget.produto.item.id,
      filtroEstrelas: _filtroEstrela,
    );
    if (mounted) {
      setState(() {
        _avaliacoes = lista;
        _carregando = false;
      });
    }
  }

  void _alternarFiltroEstrela(int estrela) {
    setState(() {
      _filtroEstrela = _filtroEstrela == estrela ? null : estrela;
    });
    _carregar();
  }

  Future<void> _enviarAvaliacao() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final cpf = auth.contaAtual?.cpf ?? auth.cpf;
    final nome = auth.contaAtual?.nome ?? 'Cliente Nous';
    final foto = auth.contaAtual?.fotoExibicao ?? '';

    final ok = await AvaliacoesProdutoService.adicionarAvaliacao(
      itemId: widget.produto.item.id,
      lojaId: widget.produto.loja.id,
      autorCpf: cpf.isEmpty ? 'visitante' : cpf,
      autorNome: nome,
      autorFoto: foto,
      estrelas: _notaNova,
      comentario: texto,
    );

    if (ok && mounted) {
      _textoCtrl.clear();
      setState(() {
        _escrevendoAvaliacao = false;
        _filtroEstrela = null;
      });
      widget.aoAtualizar?.call();
      await _carregar();
    }
  }

  Future<void> _reagir(AvaliacaoProduto aval, bool curtir) async {
    await AvaliacoesProdutoService.reagirAvaliacao(
      avaliacaoId: aval.id,
      curtir: curtir,
    );
    if (!mounted) return;
    setState(() {
      final idx = _avaliacoes.indexWhere((a) => a.id == aval.id);
      if (idx >= 0) {
        final atual = _avaliacoes[idx];
        _avaliacoes[idx] = atual.copyWith(
          curtidas: curtir ? atual.curtidas + 1 : atual.curtidas,
          descurtidas: !curtir ? atual.descurtidas + 1 : atual.descurtidas,
        );
      }
    });
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Dialog(
      backgroundColor: theme.cardBackgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho: Título + Fechar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avaliações e Comentários',
                          style: theme.getTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          widget.produto.item.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: Icon(Icons.close_rounded, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cabeçalho com as 5 estrelas como filtro (1★ até 5★) — Pedido explícito do usuário
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    if (_filtroEstrela == null) ...[
                      Text(
                        'Filtrar comentários por estrelas (toque em uma nota):',
                        textAlign: TextAlign.center,
                        style: theme.getTextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: List.generate(5, (i) {
                        final estrela = i + 1;
                        final selecionado = _filtroEstrela == estrela;
                        return InkWell(
                          onTap: () => _alternarFiltroEstrela(estrela),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selecionado
                                  ? theme.buttonColor
                                  : theme.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selecionado
                                    ? theme.buttonColor
                                    : theme.borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: selecionado
                                      ? theme.buttonTextColor
                                      : theme.textColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$estrela',
                                  style: theme.getTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selecionado
                                        ? theme.buttonTextColor
                                        : theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Formulário expansível para deixar avaliação
              if (_escrevendoAvaliacao)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sua nota:',
                            style: theme.getTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (i) {
                            final n = i + 1;
                            return InkWell(
                              onTap: () => setState(() => _notaNova = n),
                              child: Icon(
                                n <= _notaNova
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 22,
                                color: theme.textColor,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textoCtrl,
                        maxLines: 3,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          color: theme.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Conte como foi sua experiência com o produto...',
                          hintStyle: theme.getTextStyle(
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _escrevendoAvaliacao = false),
                            child: Text(
                              'Cancelar',
                              style: theme.getTextStyle(
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.buttonColor,
                              foregroundColor: theme.buttonTextColor,
                            ),
                            onPressed: _enviarAvaliacao,
                            child: Text(
                              'Publicar',
                              style: theme.getTextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.buttonTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Lista de Comentários
              Flexible(
                child: _carregando
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: theme.textColor,
                          ),
                        ),
                      )
                    : _avaliacoes.isEmpty
                        ? EstadoVazioContainer(
                            theme: theme,
                            mensagem: _filtroEstrela != null
                                ? 'Nenhuma avaliação com $_filtroEstrela estrelas.'
                                : 'Seja o primeiro a avaliar este produto!',
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _avaliacoes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final a = _avaliacoes[i];
                              final avatarProvider =
                                  ImagemService.obterImageProvider(a.autorFoto);
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.backgroundColor
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.borderColor
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: theme.borderColor
                                              .withValues(alpha: 0.3),
                                          backgroundImage: avatarProvider,
                                          child: avatarProvider == null
                                              ? Text(
                                                  a.autorNome.isNotEmpty
                                                      ? a.autorNome[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: theme.getTextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.textColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                a.autorNome,
                                                style: theme.getTextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  ...List.generate(5, (s) {
                                                    return Icon(
                                                      s < a.estrelas
                                                          ? Icons.star_rounded
                                                          : Icons
                                                              .star_outline_rounded,
                                                      size: 13,
                                                      color: theme.textColor,
                                                    );
                                                  }),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatarData(a.criadoEm),
                                                    style: theme.getTextStyle(
                                                      fontSize: 10.5,
                                                      color: theme
                                                          .secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      a.comentario,
                                      style: theme.getTextStyle(
                                        fontSize: 12.5,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _reagir(a, true),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.thumb_up_outlined,
                                                  size: 14,
                                                  color:
                                                      theme.secondaryTextColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${a.curtidas}',
                                                  style: theme.getTextStyle(
                                                    fontSize: 11,
                                                    color: theme
                                                        .secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () => _reagir(a, false),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.thumb_down_outlined,
                                                  size: 14,
                                                  color:
                                                      theme.secondaryTextColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${a.descurtidas}',
                                                  style: theme.getTextStyle(
                                                    fontSize: 11,
                                                    color: theme
                                                        .secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 10),

              // Botão para escrever avaliação
              if (!_escrevendoAvaliacao)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        setState(() => _escrevendoAvaliacao = true),
                    icon: Icon(
                      Icons.rate_review_outlined,
                      size: 18,
                      color: theme.textColor,
                    ),
                    label: Text(
                      'Escrever avaliação',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
