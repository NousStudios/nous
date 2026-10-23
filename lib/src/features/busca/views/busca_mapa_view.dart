import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/custom_app_bar.dart';
import 'package:nous/src/core/widgets/floating_bottom_nav_bar.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/auth/views/widgets/ficha_usuario_dialog.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/views/dados_perfil_view.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

enum FiltroBusca { todos, lojas, perfis }

/// Tela de Busca & Mapa do Nous.
/// Permite localizar lojas soberanas e perfis de usuários na rede,
/// com suporte completo para seguir/deixar de seguir cidadãos e visitar lojas.
class BuscaMapaView extends StatefulWidget {
  const BuscaMapaView({super.key});

  @override
  State<BuscaMapaView> createState() => _BuscaMapaViewState();
}

class _BuscaMapaViewState extends State<BuscaMapaView> {
  final TextEditingController _buscaController = TextEditingController();
  FiltroBusca _filtro = FiltroBusca.todos;
  List<UsuarioNous> _todosUsuarios = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    ClienteRedeLocal().presencasAtivas.addListener(_aoMudarRede);
    ClienteRedeLocal().estaConectado.addListener(_aoMudarRede);
  }

  void _aoMudarRede() {
    if (mounted) _carregarDados();
  }

  @override
  void dispose() {
    ClienteRedeLocal().presencasAtivas.removeListener(_aoMudarRede);
    ClienteRedeLocal().estaConectado.removeListener(_aoMudarRede);
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final contas = await ContasNousService.carregarTodas();
    final usuarios = contas.where((u) {
      final cpfLimpo = u.cpf.replaceAll(RegExp(r'\D'), '');
      return cpfLimpo.length == 11 &&
          u.nome.trim().toLowerCase() != 'blackview' &&
          u.nome.trim().toLowerCase() != 'celular';
    }).toList();

    if (mounted) {
      setState(() {
        _todosUsuarios = usuarios;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeController.currentTheme,
      builder: (context, theme, _) {
        final auth = context.watch<AuthProvider>();
        final pdv = context.watch<PdvProvider>();
        final termo = _buscaController.text.trim().toLowerCase();

        // Filtra lojas
        final lojasFiltradas = (_filtro == FiltroBusca.perfis)
            ? <Loja>[]
            : pdv.lojas.where((l) {
                if (termo.isEmpty) return true;
                final nome = l.nome.toLowerCase();
                final doc = l.cnpj.toLowerCase();
                final cat = l.categorias.toLowerCase();
                final tags = l.tags.toLowerCase();
                final end = l.endereco.toLowerCase();
                return nome.contains(termo) ||
                    doc.contains(termo) ||
                    cat.contains(termo) ||
                    tags.contains(termo) ||
                    end.contains(termo);
              }).toList();

        // Filtra perfis Nous
        final perfisFiltrados = (_filtro == FiltroBusca.lojas)
            ? <UsuarioNous>[]
            : _todosUsuarios.where((u) {
                if (termo.isEmpty) return true;
                final nome = u.nome.toLowerCase();
                final apelido = u.apelido.toLowerCase();
                final username = u.nomeDeUsuario.toLowerCase();
                final cpfDigitos = u.cpf.replaceAll(RegExp(r'\D'), '');
                return nome.contains(termo) ||
                    apelido.contains(termo) ||
                    username.contains(termo) ||
                    cpfDigitos.contains(termo);
              }).toList();

        final totalResultados = lojasFiltradas.length + perfisFiltrados.length;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: const CustomAppBar(
            title: 'Busca & Mapa',
            showBackButton: false,
          ),
          bottomNavigationBar: const FloatingBottomNavBar(
            maxWidth: 680,
            slotSelecionado: 2,
            subIndiceSelecionado: 0,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Barra de Pesquisa
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _buscaController,
                          cursorColor: theme.textColor,
                          style: theme.getTextStyle(
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar lojas, produtos, @usuários ou CPF...',
                            hintStyle: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.secondaryTextColor
                                  .withValues(alpha: 0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: theme.secondaryTextColor,
                            ),
                            suffixIcon: _buscaController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: theme.secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      _buscaController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Filtros (Chips)
                      Row(
                        children: [
                          _buildFiltroChip(
                            theme: theme,
                            titulo: 'Todos',
                            filtro: FiltroBusca.todos,
                            icone: Icons.grid_view_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildFiltroChip(
                            theme: theme,
                            titulo: 'Lojas (${lojasFiltradas.length})',
                            filtro: FiltroBusca.lojas,
                            icone: Icons.storefront_rounded,
                          ),
                          const SizedBox(width: 8),
                          _buildFiltroChip(
                            theme: theme,
                            titulo: 'Perfis (${perfisFiltrados.length})',
                            filtro: FiltroBusca.perfis,
                            icone: Icons.people_alt_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Lista de Resultados
                      Expanded(
                        child: _carregando
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: theme.textColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : totalResultados == 0
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        EstadoVazioContainer(
                                          theme: theme,
                                          mensagem:
                                              'Nenhuma loja ou perfil encontrado para esta busca.',
                                        ),
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          onPressed: () {
                                            _buscaController.clear();
                                            setState(() =>
                                                _filtro = FiltroBusca.todos);
                                          },
                                          icon: Icon(
                                            Icons.refresh_rounded,
                                            size: 16,
                                            color: theme.textColor,
                                          ),
                                          label: Text(
                                            'Limpar busca',
                                            style: theme.getTextStyle(
                                              color: theme.textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    children: [
                                      // Seção Lojas
                                      if (lojasFiltradas.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            'Lojas (${lojasFiltradas.length})',
                                            style: theme.getTextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                        for (final loja in lojasFiltradas)
                                          _buildCardLoja(
                                            context: context,
                                            theme: theme,
                                            loja: loja,
                                          ),
                                        const SizedBox(height: 14),
                                      ],

                                      // Seção Perfis
                                      if (perfisFiltrados.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            'Perfis Nous (${perfisFiltrados.length})',
                                            style: theme.getTextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                        for (final perfil in perfisFiltrados)
                                          _buildCardPerfil(
                                            context: context,
                                            theme: theme,
                                            perfil: perfil,
                                            auth: auth,
                                          ),
                                      ],
                                    ],
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltroChip({
    required AppTheme theme,
    required String titulo,
    required FiltroBusca filtro,
    required IconData icone,
  }) {
    final ativo = _filtro == filtro;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filtro = filtro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ativo
              ? theme.textColor
              : theme.cardBackgroundColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ativo
                ? theme.textColor
                : theme.borderColor.withValues(alpha: 0.6),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 14,
              color: ativo ? theme.backgroundColor : theme.secondaryTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                color: ativo ? theme.backgroundColor : theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLoja({
    required BuildContext context,
    required AppTheme theme,
    required Loja loja,
  }) {
    final temFoto = ImagemService.existe(loja.logo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: temFoto
                  ? ImagemService.construirImagem(
                      loja.logo,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      fallback: Icon(
                        Icons.storefront_rounded,
                        size: 24,
                        color: theme.textColor,
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      size: 24,
                      color: theme.textColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoRolante(
                  texto: loja.nome,
                  style: theme.getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${loja.categorias.isNotEmpty ? loja.categorias : "Comércio Local"} • ${loja.endereco.isNotEmpty ? loja.endereco : "Local"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.buttonColor,
              foregroundColor: theme.buttonTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DadosPerfilView(lojaId: loja.id),
                ),
              );
            },
            child: Text(
              'Visitar',
              style: theme.getTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPerfil({
    required BuildContext context,
    required AppTheme theme,
    required UsuarioNous perfil,
    required AuthProvider auth,
  }) {
    final contaPropria = auth.contaAtual;
    final ehProprio = contaPropria != null &&
        contaPropria.cpf.replaceAll(RegExp(r'\D'), '') ==
            perfil.cpf.replaceAll(RegExp(r'\D'), '');

    final fotoResolvida = ImagemService.resolverCaminhoExistente(perfil.foto);
    final temFoto = fotoResolvida != null;
    final seguindo = contaPropria?.estaSeguindo(perfil.cpf) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              FichaUsuarioDialog.mostrar(
                context,
                theme: theme,
                usuario: perfil,
                somenteLeitura: !ehProprio,
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.borderColor.withValues(alpha: 0.3),
              backgroundImage:
                  temFoto ? FileImage(File(fotoResolvida)) : null,
              child: !temFoto
                  ? Icon(Icons.person, size: 24, color: theme.textColor)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PerfilSocialView(
                      usuarioAlvo: perfil,
                      mostrarBotaoVoltar: true,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          perfil.nome.isNotEmpty
                              ? perfil.nome
                              : perfil.usernameExibicao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      if (ehProprio) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.borderColor.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Você',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perfil.usernameExibicao,
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.buttonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${perfil.seguidores.length} seguidores • ${perfil.seguindo.length} seguindo',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (ehProprio)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.borderColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                FichaUsuarioDialog.mostrar(
                  context,
                  theme: theme,
                  usuario: perfil,
                  somenteLeitura: false,
                );
              },
              child: Text(
                'Identidade',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            )
          else if (seguindo)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.borderColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await auth.alternarSeguir(perfil.cpf);
                await _carregarDados();
              },
              icon: Icon(
                Icons.check_rounded,
                size: 15,
                color: theme.textColor,
              ),
              label: Text(
                'Seguindo',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await auth.alternarSeguir(perfil.cpf);
                await _carregarDados();
              },
              icon: Icon(
                Icons.person_add_alt_1_rounded,
                size: 15,
                color: theme.buttonTextColor,
              ),
              label: Text(
                'Seguir',
                style: theme.getTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}