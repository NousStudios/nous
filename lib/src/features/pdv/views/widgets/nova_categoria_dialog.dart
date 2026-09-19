import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';

// Popup "Nova Categoria" / "Editar Categoria". Mesma tela para os dois
// casos: se "categoriaParaEditar" vier preenchida, os campos começam
// já preenchidos com os dados dela, o título vira "Editar Categoria" e
// o botão vira "Salvar" em vez de "Criar" — mesmo padrão já usado no
// NovoItemDialog e no NovoGrupoComponentesDialog. Continua não
// salvando nada por conta própria, só monta o objeto CategoriaLoja
// (novo ou editado) e entrega para quem chamou via onCriar.
class NovaCategoriaDialog extends StatefulWidget {
  final AppTheme theme;

  // Grupos de componentes já existentes, para preencher o seletor.
  final List<GrupoComponentesLoja> gruposComponentes;

  // NOVO: quando preenchida, o popup abre em modo de EDIÇÃO desta
  // categoria em vez de criação de uma nova.
  final CategoriaLoja? categoriaParaEditar;

  final void Function(CategoriaLoja categoria) onCriar;

  const NovaCategoriaDialog({
    super.key,
    required this.theme,
    required this.gruposComponentes,
    this.categoriaParaEditar,
    required this.onCriar,
  });

  // Função de conveniência, mesmo padrão do NovoItemDialog.mostrar.
  static Future<void> mostrar(
    BuildContext context, {
    required AppTheme theme,
    required List<GrupoComponentesLoja> gruposComponentes,
    CategoriaLoja? categoriaParaEditar,
    required void Function(CategoriaLoja categoria) onCriar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => NovaCategoriaDialog(
        theme: theme,
        gruposComponentes: gruposComponentes,
        categoriaParaEditar: categoriaParaEditar,
        onCriar: onCriar,
      ),
    );
  }

  @override
  State<NovaCategoriaDialog> createState() => _NovaCategoriaDialogState();
}

class _NovaCategoriaDialogState extends State<NovaCategoriaDialog> {
  final _nomeController = TextEditingController();

  String? _grupoSelecionadoId;
  TipoItemLoja? _tipo;

  @override
  void initState() {
    super.initState();

    final categoria = widget.categoriaParaEditar;
    if (categoria == null) return; // modo criação: campos começam vazios

    _nomeController.text = categoria.nome;
    _grupoSelecionadoId = categoria.grupoComponentesId;
    _tipo = categoria.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // Mesmo popup de seleção usado no NovoItemDialog, mas reescrito aqui
  // dentro. Como este popup só precisa selecionar UMA coisa (o grupo de
  // componentes), não criei um arquivo compartilhado ainda — se no
  // futuro mais popups precisarem do mesmo seletor, vale a pena juntar
  // num widget só, reaproveitado pelos três.
  void _abrirSeletorDeGrupo() {
    final theme = widget.theme;
    final opcoes = {
      for (final grupo in widget.gruposComponentes) grupo.id: grupo.nome,
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.borderColor),
          ),
          title: Text(
            'Grupo de componentes',
            textAlign: TextAlign.center,
            style: theme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Nenhum', style: theme.getTextStyle()),
                    trailing: _grupoSelecionadoId == null
                        ? Icon(Icons.check, color: theme.buttonColor)
                        : null,
                    onTap: () {
                      setState(() => _grupoSelecionadoId = null);
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  for (final entrada in opcoes.entries)
                    ListTile(
                      title: Text(entrada.value, style: theme.getTextStyle()),
                      trailing: _grupoSelecionadoId == entrada.key
                          ? Icon(Icons.check, color: theme.buttonColor)
                          : null,
                      onTap: () {
                        setState(() => _grupoSelecionadoId = entrada.key);
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _criar() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final categoriaExistente = widget.categoriaParaEditar;

    final categoria = categoriaExistente != null
        ? categoriaExistente.copyWith(
            nome: nome,
            grupoComponentesId: _grupoSelecionadoId,
            tipo: _tipo,
          )
        : CategoriaLoja.nova(
            nome: nome,
            grupoComponentesId: _grupoSelecionadoId,
            tipo: _tipo,
          );

    widget.onCriar(categoria);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final editando = widget.categoriaParaEditar != null;

    final larguraTela = MediaQuery.sizeOf(context).width;
    final larguraPopup = larguraTela < 380 ? larguraTela * 0.9 : 340.0;

    final nomeGrupoSelecionado = widget.gruposComponentes
        .where((g) => g.id == _grupoSelecionadoId)
        .map((g) => g.nome)
        .firstOrNull;

    return AlertDialog(
      backgroundColor: theme.cardBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: theme.borderColor, width: 1.5),
      ),
      title: Text(
        editando ? 'Editar Categoria' : 'Nova Categoria',
        textAlign: TextAlign.center,
        style: theme.getTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.textColor,
        ),
      ),
      content: SizedBox(
        width: larguraPopup,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quadrado de foto — decorativo por enquanto, mesmo
              // estágio dos containers de Galeria/Arquivos.
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: theme.secondaryTextColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              ThemedTextField(
                theme: theme,
                controller: _nomeController,
                label: 'Nome da nova categoria',
              ),
              const SizedBox(height: 12),

              // Campo "de mentirinha", mesmo padrão do NovoItemDialog:
              // parece um ThemedTextField, mas ao tocar abre o popup de
              // seleção em vez do teclado.
              GestureDetector(
                onTap: _abrirSeletorDeGrupo,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nomeGrupoSelecionado ?? 'Grupo de componentes',
                          style: theme.getTextStyle(
                            fontSize: 14,
                            color: nomeGrupoSelecionado != null
                                ? theme.textColor
                                : theme.secondaryTextColor,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down,
                          color: theme.secondaryTextColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Produto / Serviço, mesmo padrão visual do NovoItemDialog
              // (rótulo em cima, bolinha embaixo).
              RadioGroup<TipoItemLoja>(
                groupValue: _tipo,
                onChanged: (valor) => setState(() => _tipo = valor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _opcaoTipo(theme, 'Produto', TipoItemLoja.produto),
                    const SizedBox(width: 32),
                    _opcaoTipo(theme, 'Serviço', TipoItemLoja.servico),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: theme.getTextStyle(color: theme.secondaryTextColor),
          ),
        ),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              side: BorderSide(color: theme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: _criar,
            child: Text(
              editando ? 'Salvar' : 'Criar',
              style: theme.getTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _opcaoTipo(AppTheme theme, String rotulo, TipoItemLoja valor) {
    return Column(
      children: [
        Text(rotulo, style: theme.getTextStyle(fontSize: 13)),
        // ALTERADO: mesmo ajuste já feito no NovoItemDialog —
        // buttonColor é transparente no tema escuro padrão, o que
        // fazia a bolinha do Radio "sumir" ao selecionar. borderColor
        // é sempre uma cor sólida (branco no escuro, preto no claro).
        Radio<TipoItemLoja>(value: valor, activeColor: theme.borderColor),
      ],
    );
  }
}