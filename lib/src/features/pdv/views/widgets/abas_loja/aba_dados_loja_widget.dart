import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/views/widgets/cargos_permissoes_container.dart';
import 'package:nous/src/features/pdv/views/widgets/formulario_dados_loja.dart';
import 'package:nous/src/features/pdv/views/widgets/galeria_estilo_container.dart';
import 'package:nous/src/features/pdv/views/widgets/usuarios_participantes_container.dart';
import 'package:provider/provider.dart';

class AbaDadosLojaWidget extends StatelessWidget {
  final AppTheme theme;
  final String lojaId;
  final bool possoEditarDados;
  final bool possoGerenciarMembros;
  final Loja? lojaAtual;
  final String cpfLogado;
  final bool expandido;
  final double larguraDaTela;
  final ControllersDadosLoja controllers;
  final String logo;
  final List<MembroLoja> membros;
  final List<String> galeria;
  final List<String> arquivos;
  final List<String> musicas;
  final List<String> videos;
  final List<String> arquivosAudio;
  final Map<String, String> descricoesAnexos;
  final BoxDecoration decoracaoBloco;
  final VoidCallback onAlterarLogo;
  final VoidCallback onSalvarDados;
  final VoidCallback onConfirmarExclusao;
  final Future<UsuarioNous?> Function(String cpf) onBuscarContaPorCpf;
  final void Function(UsuarioNous usuario, PapelMembro papel) onEnviarConvite;
  final void Function(String cpf) onRemoverMembro;
  final void Function(String cpf, PapelMembro novoPapel) onAtualizarPapelMembro;
  final void Function(String cpf, String? cargoId) onVincularCargoPersonalizado;
  final VoidCallback onSairDaLoja;
  final void Function(String identificador, String novaDescricao) onAtualizarDescricaoAnexo;
  final void Function(TipoAnexoLoja tipo, String caminho) onAdicionarAnexo;
  final void Function(TipoAnexoLoja tipo, int index) onRemoverAnexo;
  final void Function(TipoAnexoLoja tipo, int index, String novoCaminho)? onSubstituirAnexo;

  const AbaDadosLojaWidget({
    super.key,
    required this.theme,
    required this.lojaId,
    required this.possoEditarDados,
    required this.possoGerenciarMembros,
    required this.lojaAtual,
    required this.cpfLogado,
    required this.expandido,
    required this.larguraDaTela,
    required this.controllers,
    required this.logo,
    required this.membros,
    required this.galeria,
    required this.arquivos,
    required this.musicas,
    required this.videos,
    required this.arquivosAudio,
    required this.descricoesAnexos,
    required this.decoracaoBloco,
    required this.onAlterarLogo,
    required this.onSalvarDados,
    required this.onConfirmarExclusao,
    required this.onBuscarContaPorCpf,
    required this.onEnviarConvite,
    required this.onRemoverMembro,
    required this.onAtualizarPapelMembro,
    required this.onVincularCargoPersonalizado,
    required this.onSairDaLoja,
    required this.onAtualizarDescricaoAnexo,
    required this.onAdicionarAnexo,
    required this.onRemoverAnexo,
    this.onSubstituirAnexo,
  });

  Widget _blocoDadosInstitucionaisNous(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: decoracaoBloco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.all_inclusive_rounded,
                    size: 40,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _itemDadoFixoLojaNous(
            rotulo: 'Nome da Loja',
            valor: 'Nous',
            icone: Icons.storefront_outlined,
          ),
          const SizedBox(height: 12),
          _itemDadoFixoLojaNous(
            rotulo: 'Email',
            valor: 'nousstudios72@gmail.com',
            icone: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          _itemDadoFixoLojaNous(
            rotulo: 'Redes Sociais',
            valor: '@nous.studios72',
            icone: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 12),
          _itemDadoFixoLojaNous(
            rotulo: 'Categorias',
            valor: 'Autogestão, Comunidade, Software Livre',
            icone: Icons.category_outlined,
          ),
          const SizedBox(height: 12),
          _itemDadoFixoLojaNous(
            rotulo: 'Descrição',
            valor: 'Software Universal de Autogestão Comercial e Social',
            icone: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _itemDadoFixoLojaNous({
    required String rotulo,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: theme.secondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: theme.getTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: theme.getTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdv = context.read<PdvProvider>();
    final bool ehLojaNous = lojaId == PdvProvider.idLojaColetivaNous;

    final Widget blocoFormularioOuDados = ehLojaNous
        ? _blocoDadosInstitucionaisNous(context)
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: decoracaoBloco,
            child: Column(
              children: [
                AbsorbPointer(
                  absorbing: !possoEditarDados,
                  child: FormularioDadosLoja(
                    theme: theme,
                    controllers: controllers,
                    logo: logo,
                    onAlterarLogo: onAlterarLogo,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onSalvarDados,
                    child: Text(
                      'Salvar Dados',
                      style: theme.getTextStyle(
                        fontSize: 13,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onConfirmarExclusao,
                  child: Text(
                    'Excluir Loja',
                    style: theme.getTextStyle(
                      fontSize: 13,
                      color: theme.dangerColor,
                    ),
                  ),
                ),
              ],
            ),
          );

    final meuCpfLimpo = cpfLogado.replaceAll(RegExp(r'\D'), '');
    final meuMembro = lojaAtual?.membros
        .where((m) => m.cpf.replaceAll(RegExp(r'\D'), '') == meuCpfLimpo)
        .firstOrNull;
    final ehDonoOuSocio = meuMembro?.papel == PapelMembro.dono ||
        meuMembro?.papel == PapelMembro.socio;

    final blocoCargos = CargosEPermissoesContainer(
      theme: theme,
      cargosPersonalizados: lojaAtual?.cargosPersonalizados ?? const [],
      permissoesCargosNativos: lojaAtual?.permissoesCargosNativos ?? const {},
      podeGerenciar: possoGerenciarMembros,
      ehDonoOuSocio: ehDonoOuSocio,
      ehLojaColetivaNous: ehLojaNous,
      usuarioLogadoEhDesenvolvedor: meuMembro?.cargoPersonalizadoId == 'desenvolvedor',
      onAlternarDesenvolvedor: () => pdv.alternarFuncaoDesenvolvedorNous(cpfLogado),
      onAdicionarCargo: (novoCargo) => pdv.adicionarCargoLoja(lojaId, novoCargo),
      onAtualizarCargo: (cargo) => pdv.atualizarCargoLoja(lojaId, cargo),
      onRemoverCargo: (cargoId) => pdv.removerCargoLoja(lojaId, cargoId),
      onAtualizarPermissoesCargoNativo: (papel, permissoes) =>
          pdv.atualizarPermissoesCargoNativo(lojaId, papel, permissoes),
    );

    final blocoMembros = UsuariosParticipantesContainer(
      theme: theme,
      membros: membros,
      cargosPersonalizados: lojaAtual?.cargosPersonalizados ?? const [],
      cpfLogado: cpfLogado,
      podeGerenciar: possoGerenciarMembros,
      ehLojaColetivaNous: ehLojaNous,
      buscarConta: onBuscarContaPorCpf,
      onEnviarConvite: onEnviarConvite,
      onRemover: onRemoverMembro,
      onAtualizarPapel: onAtualizarPapelMembro,
      onVincularCargoPersonalizado: onVincularCargoPersonalizado,
      onSair: onSairDaLoja,
    );

    final blocoGalerias = [
      GaleriaEstiloContainer(
        theme: theme,
        titulo: 'Galeria',
        itens: galeria,
        tipo: TipoAnexoLoja.galeria,
        descricoes: descricoesAnexos,
        onAtualizarDescricao: onAtualizarDescricaoAnexo,
        onAdicionar: (caminho) => onAdicionarAnexo(TipoAnexoLoja.galeria, caminho),
        onRemover: (index) => onRemoverAnexo(TipoAnexoLoja.galeria, index),
        onSubstituirItem: onSubstituirAnexo != null
            ? (index, novo) => onSubstituirAnexo!(TipoAnexoLoja.galeria, index, novo)
            : null,
      ),
      const SizedBox(height: 16),
      GaleriaEstiloContainer(
        theme: theme,
        titulo: 'Arquivos',
        itens: arquivos,
        tipo: TipoAnexoLoja.arquivos,
        descricoes: descricoesAnexos,
        onAtualizarDescricao: onAtualizarDescricaoAnexo,
        onAdicionar: (caminho) => onAdicionarAnexo(TipoAnexoLoja.arquivos, caminho),
        onRemover: (index) => onRemoverAnexo(TipoAnexoLoja.arquivos, index),
      ),
      const SizedBox(height: 16),
      GaleriaEstiloContainer(
        theme: theme,
        titulo: 'Músicas',
        itens: musicas,
        tipo: TipoAnexoLoja.musicas,
        descricoes: descricoesAnexos,
        onAtualizarDescricao: onAtualizarDescricaoAnexo,
        onAdicionar: (caminho) => onAdicionarAnexo(TipoAnexoLoja.musicas, caminho),
        onRemover: (index) => onRemoverAnexo(TipoAnexoLoja.musicas, index),
      ),
      const SizedBox(height: 16),
      GaleriaEstiloContainer(
        theme: theme,
        titulo: 'Vídeos',
        itens: videos,
        tipo: TipoAnexoLoja.videos,
        descricoes: descricoesAnexos,
        onAtualizarDescricao: onAtualizarDescricaoAnexo,
        onAdicionar: (caminho) => onAdicionarAnexo(TipoAnexoLoja.videos, caminho),
        onRemover: (index) => onRemoverAnexo(TipoAnexoLoja.videos, index),
      ),
      const SizedBox(height: 16),
      GaleriaEstiloContainer(
        theme: theme,
        titulo: 'Arquivos de Áudio',
        itens: arquivosAudio,
        tipo: TipoAnexoLoja.arquivosAudio,
        descricoes: descricoesAnexos,
        onAtualizarDescricao: onAtualizarDescricaoAnexo,
        onAdicionar: (caminho) => onAdicionarAnexo(TipoAnexoLoja.arquivosAudio, caminho),
        onRemover: (index) => onRemoverAnexo(TipoAnexoLoja.arquivosAudio, index),
      ),
    ];

    if (expandido && larguraDaTela > 850) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                blocoFormularioOuDados,
                const SizedBox(height: 16),
                blocoCargos,
                const SizedBox(height: 16),
                blocoMembros,
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              children: blocoGalerias,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        blocoFormularioOuDados,
        const SizedBox(height: 16),
        blocoCargos,
        const SizedBox(height: 16),
        blocoMembros,
        const SizedBox(height: 16),
        ...blocoGalerias,
      ],
    );
  }
}
