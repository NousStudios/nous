import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/texto_rolante.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:nous/src/features/pdv/services/rede_local/servidor_rede_local.dart';
import 'package:nous/src/features/pdv/views/widgets/estado_vazio_container.dart';

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

String _formatarCpf(String cpf) {
  final digitos = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.length != 11) return cpf;
  return '${digitos.substring(0, 3)}.${digitos.substring(3, 6)}.'
      '${digitos.substring(6, 9)}-${digitos.substring(9, 11)}';
}

/// Card que exibe a lista de trabalhadores e status dos seus dispositivos na rede local.
class BlocoTrabalhadoresStatusWidget extends StatelessWidget {
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

  List<TerminalConectadoInfo> _obterDispositivosDoMembro(String cpfMembro) {
    final digitosMembro = cpfMembro.replaceAll(RegExp(r'\D'), '');
    if (digitosMembro.isEmpty) return [];

    final servidor = ServidorRedeLocal();
    final cliente = ClienteRedeLocal();

    List<TerminalConectadoInfo> todas;
    if (servidor.ativo) {
      todas = servidor.obterTodasPresencas();
    } else if (cliente.conectado) {
      todas = cliente.presencasAtivas.value;
      final meuCpf = cpfLogado.replaceAll(RegExp(r'\D'), '');
      final jaTemEu = todas.any((t) => t.cpf?.replaceAll(RegExp(r'\D'), '') == meuCpf);
      if (!jaTemEu && meuCpf == digitosMembro) {
        todas = [
          ...todas,
          TerminalConectadoInfo(
            id: 'este_dispositivo',
            nome: cliente.nomeDispositivo,
            ip: 'Local',
            cpf: meuCpf,
            conectadoEm: DateTime.now(),
          ),
        ];
      }
    } else {
      todas = [];
    }

    return todas.where((t) {
      final cpfTerm = (t.cpf ?? '').replaceAll(RegExp(r'\D'), '');
      return cpfTerm.isNotEmpty && cpfTerm == digitosMembro;
    }).toList();
  }

  Widget _linhaDeMembro(BuildContext context, AppTheme theme, MembroLoja membro) {
    final auth = context.watch<AuthProvider>();
    final pdv = context.watch<PdvProvider>();

    String foto = auth.buscarFotoPorCpf(membro.cpf);
    if (foto.isEmpty) {
      foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
    }

    final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
    final temFoto = fotoResolvida != null;
    final dispositivos = _obterDispositivosDoMembro(membro.cpf);
    final estaOnline = dispositivos.isNotEmpty;

    final cargoPers = membro.cargoPersonalizadoId != null
        ? pdv
            .buscarPorId(lojaId)
            ?.cargosPersonalizados
            .where((c) => c.id == membro.cargoPersonalizadoId)
            .firstOrNull
        : null;
    final rotuloCargo = cargoPers != null
        ? '${_rotuloPapel(membro.papel)} (${cargoPers.nome})'
        : _rotuloPapel(membro.papel);

    return _MembroLinhaComHover(
      builder: (hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hover
              ? theme.borderColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hover ? theme.textColor : theme.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: theme.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: temFoto
                        ? Image.file(
                            File(fotoResolvida),
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
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
                      Text(
                        membro.nome.isEmpty ? 'Sem nome' : membro.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$rotuloCargo • ${_formatarCpf(membro.cpf)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.getTextStyle(
                          fontSize: 10,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estaOnline
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : theme.secondaryTextColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: estaOnline
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : theme.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: estaOnline
                              ? Colors.greenAccent
                              : theme.secondaryTextColor.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        estaOnline
                            ? (dispositivos.length > 1
                                ? 'Online (${dispositivos.length})'
                                : 'Online')
                            : 'Offline',
                        style: theme.getTextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: estaOnline
                              ? Colors.greenAccent
                              : theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (estaOnline) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dispositivos.map((disp) {
                  final ehBalcao = disp.nome.toLowerCase().contains('balcão') ||
                      disp.id.contains('balcao');
                  final icone = ehBalcao
                      ? Icons.computer_rounded
                      : Icons.smartphone_rounded;

                  return Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icone,
                          size: 12,
                          color: theme.textColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: TextoRolante(
                            texto: '${disp.nome}${disp.ip.isNotEmpty && disp.ip != "Local" ? " (${disp.ip})" : ""}',
                            textAlign: TextAlign.start,
                            style: theme.getTextStyle(
                              fontSize: 10,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 11,
                    color: theme.secondaryTextColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Nenhum dispositivo conectado na rede local',
                    style: theme.getTextStyle(
                      fontSize: 10,
                      color: theme.secondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loja = context.watch<PdvProvider>().buscarPorId(lojaId);
    final membros = loja?.membros ?? membrosFallback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _decoracaoDoBloco(theme),
      child: Column(
        children: [
          _tituloDoBloco(theme, 'Lista de Trabalhadores'),
          const SizedBox(height: 12),
          if (membros.isEmpty)
            EstadoVazioContainer(
              theme: theme,
              mensagem: 'Nenhum trabalhador cadastrado ainda.',
            )
          else
            for (final membro in membros) _linhaDeMembro(context, theme, membro),
        ],
      ),
    );
  }
}

class _MembroLinhaComHover extends StatefulWidget {
  final Widget Function(bool hover) builder;

  const _MembroLinhaComHover({required this.builder});

  @override
  State<_MembroLinhaComHover> createState() => _MembroLinhaComHoverState();
}

class _MembroLinhaComHoverState extends State<_MembroLinhaComHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}
