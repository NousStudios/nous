import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

class CabecalhoFichaUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final bool ehProprioUsuario;
  final String cpfVisualizador;
  final bool ocultarDados;
  final String? fotoResolvida;
  final TextEditingController apelidoController;
  final TextEditingController nomeController;
  final bool nomePrivadoDono;
  final bool nomeReveladoDono;
  final bool cpfReveladoDono;
  final VoidCallback onAlternarOcultarDados;
  final VoidCallback onAoClicarFoto;
  final ValueChanged<String> onSalvarApelido;
  final ValueChanged<String> onSalvarNome;
  final VoidCallback onAlternarRevelacaoNome;
  final VoidCallback onAlternarRevelacaoCpf;
  final void Function(String rotulo, String chave) onSolicitarAcesso;

  const CabecalhoFichaUsuario({
    super.key,
    required this.theme,
    required this.usuario,
    required this.ehProprioUsuario,
    required this.cpfVisualizador,
    required this.ocultarDados,
    required this.fotoResolvida,
    required this.apelidoController,
    required this.nomeController,
    required this.nomePrivadoDono,
    required this.nomeReveladoDono,
    required this.cpfReveladoDono,
    required this.onAlternarOcultarDados,
    required this.onAoClicarFoto,
    required this.onSalvarApelido,
    required this.onSalvarNome,
    required this.onAlternarRevelacaoNome,
    required this.onAlternarRevelacaoCpf,
    required this.onSolicitarAcesso,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoResolvida != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: ocultarDados
                  ? 'Mostrar dados sensíveis'
                  : 'Ocultar dados sensíveis',
              icon: Icon(
                ocultarDados
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.secondaryTextColor,
              ),
              onPressed: onAlternarOcultarDados,
            ),
            Text(
              'Identidade do Usuário',
              style: theme.getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, color: theme.secondaryTextColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Avatar Clicável (apenas se for o próprio usuário)
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: ehProprioUsuario ? onAoClicarFoto : null,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: temFoto
                  ? Image.file(
                      File(fotoResolvida!),
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        size: 48,
                        color: theme.textColor,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 48,
                      color: theme.textColor,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Apelido (acima do nome real, na mesma grafia do CPF)
        if (ehProprioUsuario)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: apelidoController,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 13,
                  color: theme.secondaryTextColor,
                ),
                cursorColor: theme.textColor,
                decoration: _campoDecoracao(
                  label: 'Apelido',
                  hint: 'Digite seu apelido',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: onSalvarApelido,
              ),
            ),
          )
        else if (usuario.apelido.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              usuario.apelido,
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ),

        if (ehProprioUsuario)
          _buildNomeProprioEditavel()
        else
          _buildNomeVisitante(),

        const SizedBox(height: 6),

        // Nome de Usuário Nous com Selo de Verificado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              usuario.usernameExibicao.isNotEmpty
                  ? usuario.usernameExibicao
                  : '@usuario',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.secondaryTextColor,
              ),
            ),
            if (usuario.verificado || usuario.validadoPorCpf.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Tooltip(
                message: 'Conta Verificada pela Comunidade Nous',
                child: Icon(
                  Icons.verified,
                  size: 15,
                  color: Color(0xFF34B7F1),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),

        _borrarSeNecessario(_buildCpf()),
      ],
    );
  }

  InputDecoration _campoDecoracao({
    required String label,
    required String hint,
    required EdgeInsets contentPadding,
  }) {
    final bordaSuave = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: theme.borderColor.withValues(alpha: 0.5),
      ),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: theme.getTextStyle(
        fontSize: 12,
        color: theme.secondaryTextColor,
      ),
      hintText: hint,
      hintStyle: theme.getTextStyle(
        fontSize: 13,
        color: theme.secondaryTextColor.withValues(alpha: 0.6),
      ),
      isDense: true,
      contentPadding: contentPadding,
      border: bordaSuave,
      enabledBorder: bordaSuave,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.textColor),
      ),
    );
  }

  Widget _buildNomeProprioEditavel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Center(
        child: SizedBox(
          width: 260,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: nomeController,
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
                cursorColor: theme.textColor,
                decoration: _campoDecoracao(
                  label: 'Nome Próprio',
                  hint: 'Digite seu nome completo',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: nomePrivadoDono ? 28 : 10,
                    vertical: 8,
                  ),
                ),
                onChanged: onSalvarNome,
              ),
              if (nomePrivadoDono)
                Positioned(
                  right: 6,
                  child: InkWell(
                    onTap: onAlternarRevelacaoNome,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        nomeReveladoDono
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                        color: theme.secondaryTextColor,
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

  Widget _buildNomeVisitante() {
    final estaPrivado = usuario.dadoEstaPrivado('nome');
    final autorizado = usuario.dadoAutorizadoPara('nome', cpfVisualizador);
    final nomeTexto = estaPrivado && !autorizado
        ? (usuario.apelido.isNotEmpty ? usuario.apelido : '••••••••')
        : (usuario.nome.isEmpty ? 'Nome do Usuário' : usuario.nome);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          nomeTexto,
          textAlign: TextAlign.center,
          style: theme.getTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        if (estaPrivado && !autorizado) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => onSolicitarAcesso('Nome', 'nome'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 15,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCpf() {
    final estaPrivado = usuario.dadoEstaPrivado('cpf');

    bool censurado = false;
    bool olhoAberto = false;
    VoidCallback? aoClicarOlho;

    if (ehProprioUsuario) {
      // O próprio usuário sempre tem o olho disponível para alternar (ex: para tirar prints com segurança)
      censurado = !cpfReveladoDono;
      olhoAberto = cpfReveladoDono;
      aoClicarOlho = onAlternarRevelacaoCpf;
    } else if (estaPrivado) {
      final autorizado = usuario.dadoAutorizadoPara('cpf', cpfVisualizador);
      if (!autorizado) {
        censurado = true;
        olhoAberto = false;
        aoClicarOlho = () => onSolicitarAcesso('CPF', 'cpf');
      }
    }

    Widget? widgetOlho;
    if (aoClicarOlho != null) {
      widgetOlho = InkWell(
        onTap: aoClicarOlho,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(
            olhoAberto
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 15,
            color: theme.secondaryTextColor,
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              CpfValidator.formatProtegido(
                usuario.cpf,
                revelado: !censurado,
              ),
              style: theme.getTextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          if (widgetOlho != null)
            Positioned(
              right: 12,
              child: widgetOlho,
            ),
        ],
      ),
    );
  }

  Widget _borrarSeNecessario(Widget child) {
    if (!ocultarDados) return child;
    return IgnorePointer(
      ignoring: true,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
        child: child,
      ),
    );
  }
}
