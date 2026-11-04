import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';
import 'package:nous/src/features/pdv/models/cargo_loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';

String _rotuloPapel(PapelMembro papel) {
  switch (papel) {
    case PapelMembro.dono:
      return 'Dono';
    case PapelMembro.socio:
      return 'Sócio';
    case PapelMembro.admin:
      return 'Admin';
    case PapelMembro.funcionario:
      return 'Funcionário';
  }
}

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String _dataCurta(DateTime d) =>
    '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';

/// Card interativo para exibir e gerenciar um membro participante da loja.
class CardMembroLojaWidget extends StatefulWidget {
  final AppTheme theme;
  final MembroLoja membro;
  final List<MembroLoja> membros;
  final List<CargoLoja> cargosPersonalizados;
  final String cpfLogado;
  final bool podeGerenciar;
  final bool ehLojaColetivaNous;
  final VoidCallback onAbrirIdentidade;
  final VoidCallback onAbrirTrocaDePapel;
  final VoidCallback onConfirmarRemocao;
  final void Function(String rotulo, String chave) onSolicitarAcessoAoDado;

  const CardMembroLojaWidget({
    super.key,
    required this.theme,
    required this.membro,
    required this.membros,
    required this.cargosPersonalizados,
    required this.cpfLogado,
    required this.podeGerenciar,
    required this.ehLojaColetivaNous,
    required this.onAbrirIdentidade,
    required this.onAbrirTrocaDePapel,
    required this.onConfirmarRemocao,
    required this.onSolicitarAcessoAoDado,
  });

  @override
  State<CardMembroLojaWidget> createState() => _CardMembroLojaWidgetState();
}

class _CardMembroLojaWidgetState extends State<CardMembroLojaWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final membro = widget.membro;
    final ehVoce = membro.cpf == widget.cpfLogado;
    final podeEditarPapel = !widget.ehLojaColetivaNous && widget.podeGerenciar && !ehVoce;

    final meuMembro = widget.membros.firstWhere(
      (m) => m.cpf == widget.cpfLogado,
      orElse: () => MembroLoja(
        cpf: widget.cpfLogado,
        nome: '',
        papel: PapelMembro.funcionario,
        desde: DateTime.now(),
      ),
    );
    final souDono = meuMembro.papel == PapelMembro.dono;
    final souSocio = meuMembro.papel == PapelMembro.socio;

    bool podeExcluir = false;
    if (!widget.ehLojaColetivaNous) {
      if (ehVoce) {
        podeExcluir = true;
      } else if (souDono) {
        podeExcluir = true;
      } else if (souSocio) {
        podeExcluir = membro.papel == PapelMembro.admin ||
            membro.papel == PapelMembro.funcionario;
      }
    }

    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();

    String foto = auth.buscarFotoPorCpf(membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
    }

    final temFoto = ImagemService.existe(foto);

    final contaMembro = auth.buscarContaPorCpf(membro.cpf);
    final nomePrivado = contaMembro?.dadoEstaPrivado('nome') ?? false;

    String nomeExibido = membro.nome.isEmpty ? 'Sem nome' : membro.nome;
    bool olhoNomeAberto = false;
    VoidCallback? aoClicarOlhoNome;

    if (nomePrivado && contaMembro != null) {
      if (ehVoce) {
        final revelado = auth.dadoEstaReveladoParaDono('nome');
        olhoNomeAberto = revelado;
        aoClicarOlhoNome = () => auth.alternarRevelacaoParaDono('nome');
        nomeExibido = revelado
            ? (contaMembro.nome.isNotEmpty ? contaMembro.nome : 'Sem nome')
            : (contaMembro.apelido.isNotEmpty ? contaMembro.apelido : '••••••••');
      } else {
        final autorizado = contaMembro.dadoAutorizadoPara('nome', widget.cpfLogado);
        if (!autorizado) {
          aoClicarOlhoNome = () => widget.onSolicitarAcessoAoDado('Nome', 'nome');
          nomeExibido = contaMembro.apelido.isNotEmpty ? contaMembro.apelido : '••••••••';
        }
      }
    }

    String cpfExibido;
    bool olhoCpfAberto = false;
    VoidCallback? aoClicarOlhoCpf;

    if (ehVoce) {
      final revelado = auth.dadoEstaReveladoParaDono('cpf');
      olhoCpfAberto = revelado;
      aoClicarOlhoCpf = () => auth.alternarRevelacaoParaDono('cpf');
      cpfExibido = CpfValidator.formatProtegido(membro.cpf, revelado: revelado);
    } else {
      final privado = contaMembro?.dadoEstaPrivado('cpf') ?? true;
      final autorizado = contaMembro?.dadoAutorizadoPara('cpf', widget.cpfLogado) ?? false;
      final revelado = !privado || autorizado;
      olhoCpfAberto = revelado;
      if (!revelado) {
        aoClicarOlhoCpf = () => widget.onSolicitarAcessoAoDado('CPF', 'cpf');
      }
      cpfExibido = CpfValidator.formatProtegido(membro.cpf, revelado: revelado);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onAbrirIdentidade,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _hover
                ? theme.borderColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover ? theme.textColor : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: temFoto
                      ? ImagemService.construirImagem(
                          foto,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          fallback: Icon(
                            Icons.person,
                            size: 20,
                            color: theme.textColor,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 20,
                          color: theme.textColor,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nomeExibido,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.getTextStyle(
                              fontSize: 13,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        if (aoClicarOlhoNome != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: aoClicarOlhoNome,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                olhoNomeAberto
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 14,
                                color: theme.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final String rotuloCargo;
                        if (membro.cargoPersonalizadoId == 'desenvolvedor') {
                          rotuloCargo = '${_rotuloPapel(membro.papel)} • Desenvolvedor';
                        } else {
                          final cargoNome = widget.cargosPersonalizados
                              .where((c) => c.id == membro.cargoPersonalizadoId)
                              .firstOrNull
                              ?.nome;
                          rotuloCargo = cargoNome != null && cargoNome.isNotEmpty
                              ? '${_rotuloPapel(membro.papel)} ($cargoNome)'
                              : _rotuloPapel(membro.papel);
                        }
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$rotuloCargo • $cpfExibido'
                                ' • desde ${_dataCurta(membro.desde)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.getTextStyle(
                                  fontSize: 10,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                            if (aoClicarOlhoCpf != null) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: aoClicarOlhoCpf,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    olhoCpfAberto
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 13,
                                    color: theme.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (podeEditarPapel)
                IconButton(
                  tooltip: 'Trocar papel',
                  icon: Icon(Icons.edit, size: 18, color: theme.textColor),
                  onPressed: widget.onAbrirTrocaDePapel,
                ),
              if (podeExcluir)
                IconButton(
                  tooltip: ehVoce
                      ? 'Sair da loja'
                      : (souDono && membro.papel == PapelMembro.dono)
                          ? 'Solicitar saída de dono'
                          : 'Remover',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: widget.onConfirmarRemocao,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
