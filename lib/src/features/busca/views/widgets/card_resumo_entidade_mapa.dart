import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/views/perfil_social_view.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/models/projeto_comunitario.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/views/vitrine_loja_view.dart';

class CardResumoEntidadeMapa extends StatelessWidget {
  final BuscaMapaController controller;
  final AppTheme theme;
  final VoidCallback? onCriarProjetoNoPonto;

  const CardResumoEntidadeMapa({
    super.key,
    required this.controller,
    required this.theme,
    this.onCriarProjetoNoPonto,
  });

  @override
  Widget build(BuildContext context) {
    final loja = controller.lojaSelecionada;
    if (loja != null) {
      return _buildCardLoja(context, loja);
    }
    final perfil = controller.perfilSelecionado;
    if (perfil != null) {
      return _buildCardPerfil(context, perfil);
    }
    final projeto = controller.projetoSelecionado;
    if (projeto != null) {
      return _buildCardProjeto(context, projeto);
    }
    final ponto = controller.pontoMapaSelecionado;
    if (ponto != null) {
      return _buildCardPontoMapa(context, ponto);
    }
    return const SizedBox.shrink();
  }

  Widget _buildCardPontoMapa(BuildContext context, LatLng ponto) {
    return _containerBase(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.place_rounded,
                  size: 20,
                  color: theme.buttonColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local selecionado no mapa',
                      style: theme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      controller.enderecoPontoSelecionado.isNotEmpty
                          ? controller.enderecoPontoSelecionado
                          : '${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 11.5,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                onPressed: controller.limparSelecaoEntidade,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => controller.tracarRotaPara(
                    destino: ponto,
                    destinoLabel: controller.enderecoPontoSelecionado.isNotEmpty
                        ? controller.enderecoPontoSelecionado
                        : 'Ponto no mapa',
                  ),
                  icon: Icon(
                    Icons.directions_rounded,
                    size: 17,
                    color: theme.textColor,
                  ),
                  label: Text(
                    'Rota até aqui',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onCriarProjetoNoPonto,
                  icon: Icon(
                    Icons.handyman_outlined,
                    size: 17,
                    color: theme.buttonTextColor,
                  ),
                  label: Text(
                    'Criar projeto',
                    style: theme.getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _containerBase(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardLoja(BuildContext context, Loja loja) {
    final logoResolvida = ImagemService.resolverCaminhoExistente(loja.logo);
    final temLogo = logoResolvida != null;
    final end = [loja.endereco, loja.numero]
        .where((e) => e.trim().isNotEmpty)
        .join(', ');
    final coord = controller.coordenadasLojas[loja.id];

    return _containerBase(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                backgroundImage:
                    temLogo ? FileImage(File(logoResolvida)) : null,
                child: !temLogo
                    ? Icon(Icons.storefront_rounded, color: theme.textColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            loja.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (loja.aberta
                                    ? theme.buttonColor
                                    : theme.borderColor)
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loja.aberta ? 'Aberta' : 'Fechada',
                            style: theme.getTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: loja.aberta
                                  ? theme.textColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (end.isNotEmpty)
                      Text(
                        end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    if (loja.categorias.isNotEmpty)
                      Text(
                        loja.categorias,
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
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                onPressed: controller.limparSelecaoEntidade,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (coord != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => controller.tracarRotaPara(
                      destino: coord,
                      destinoLabel: loja.nome,
                    ),
                    icon: Icon(
                      Icons.directions_rounded,
                      size: 17,
                      color: theme.textColor,
                    ),
                    label: Text(
                      'Rota',
                      style: theme.getTextStyle(
                        fontSize: 12.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              if (coord != null) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor,
                    foregroundColor: theme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VitrineLojaView(
                          lojaId: loja.id,
                          lojaFallback: loja,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.store_mall_directory_outlined,
                    size: 17,
                    color: theme.buttonTextColor,
                  ),
                  label: Text(
                    'Visitar Perfil Público',
                    style: theme.getTextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.buttonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardPerfil(BuildContext context, UsuarioNous perfil) {
    final fotoResolvida =
        ImagemService.resolverCaminhoExistente(perfil.fotoExibicao);
    final temFoto = fotoResolvida != null;
    final meuCpfNorm =
        context.read<AuthProvider>().cpf.replaceAll(RegExp(r'\D'), '');
    final ehProprioUsuario = meuCpfNorm.isNotEmpty &&
        perfil.cpf.replaceAll(RegExp(r'\D'), '') == meuCpfNorm;
    final tituloPerfil =
        perfil.nome.isNotEmpty ? perfil.nome : perfil.usernameExibicao;

    return _containerBase(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.borderColor.withValues(alpha: 0.3),
                backgroundImage:
                    temFoto ? FileImage(File(fotoResolvida)) : null,
                child: !temFoto
                    ? Icon(Icons.person_rounded, color: theme.textColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ehProprioUsuario ? '$tituloPerfil (Você)' : tituloPerfil,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    if (perfil.usernameExibicao.isNotEmpty)
                      Text(
                        perfil.usernameExibicao,
                        style: theme.getTextStyle(
                          fontSize: 11.5,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    if (perfil.biografiaPara(
                      context.read<AuthProvider>().contaAtual?.cpf ?? '',
                    ).trim().isNotEmpty)
                      Text(
                        perfil.biografiaPara(
                          context.read<AuthProvider>().contaAtual?.cpf ?? '',
                        ).trim(),
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
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                onPressed: controller.limparSelecaoEntidade,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                foregroundColor: theme.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PerfilSocialView(
                      usuarioAlvo: perfil,
                      mostrarBotaoVoltar: true,
                    ),
                  ),
                );
              },
              child: Text(
                'Ver Perfil Público',
                style: theme.getTextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: theme.buttonTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardProjeto(BuildContext context, ProjetoComunitario projeto) {
    final auth = context.read<AuthProvider>();
    final cpf = auth.cpf.replaceAll(RegExp(r'\D'), '');
    final nome = auth.contaAtual?.nomeExibicao.isNotEmpty == true
        ? auth.contaAtual!.nomeExibicao
        : (auth.contaAtual?.nome ?? 'Cidadão Nous');
    final apoiou = projeto.apoiadoresCpfs.contains(cpf);
    final ehResponsavel =
        cpf.isNotEmpty && projeto.responsavelCpf.replaceAll(RegExp(r'\D'), '') == cpf;

    final statusTexto = projeto.status == StatusProjetoComunitario.concluido
        ? 'Concluído'
        : (projeto.status == StatusProjetoComunitario.emAndamento
            ? 'Em execução'
            : 'Aberto');

    return _containerBase(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.handyman_outlined,
                  size: 20,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projeto.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.getTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      '${projeto.categoria} • $statusTexto',
                      style: theme.getTextStyle(
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.secondaryTextColor,
                ),
                onPressed: controller.limparSelecaoEntidade,
              ),
            ],
          ),
          if (projeto.descricao.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              projeto.descricao.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.getTextStyle(
                fontSize: 12,
                color: theme.textColor,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            projeto.temResponsavel
                ? 'Responsável: ${projeto.responsavelNome}'
                : 'Aguardando voluntário/responsável • Criado por ${projeto.criadorNome}',
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => controller.alternarApoioProjeto(projeto, cpf),
                icon: Icon(
                  apoiou ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  size: 15,
                  color: theme.textColor,
                ),
                label: Text(
                  '${projeto.apoiadoresCpfs.length}',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => controller.tracarRotaPara(
                  destino: LatLng(projeto.latitude, projeto.longitude),
                  destinoLabel: projeto.titulo,
                ),
                child: Text(
                  'Rota',
                  style: theme.getTextStyle(
                    fontSize: 12,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!projeto.temResponsavel &&
                  projeto.status == StatusProjetoComunitario.aberto)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        controller.assumirProjeto(projeto, cpf, nome),
                    child: Text(
                      'Assumir',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                )
              else if (ehResponsavel &&
                  projeto.status != StatusProjetoComunitario.concluido)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => controller.concluirProjeto(projeto),
                    child: Text(
                      'Concluir',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
