import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'linha_info_usuario.dart';

/// Bloco encapsulado de exibição e edição dos Dados Pessoais do Usuário.
class BlocoDadosPessoaisUsuario extends StatelessWidget {
  final AppTheme theme;
  final UsuarioNous usuario;
  final bool ehProprioUsuario;
  final String? cpfVisualizador;
  final bool ocultarDados;
  final bool editandoDados;
  final String? telefone;
  final String? endereco;
  final String? redesSociais;
  final TextEditingController dataNascController;
  final TextEditingController nomeMaeController;
  final TextEditingController nomePaiController;
  final TextEditingController localNascController;
  final TextEditingController tipoSanguineoController;
  final TextEditingController estadoCivilController;
  final TextEditingController cepResidencialController;
  final TextEditingController enderecoResidencialController;
  final bool buscandoCep;
  final ValueChanged<String> onAlterarCep;
  final VoidCallback onIniciarEdicao;
  final VoidCallback onCancelarEdicao;
  final VoidCallback onSalvarEdicao;
  final void Function(String rotulo, String chave) onSolicitarAcesso;

  const BlocoDadosPessoaisUsuario({
    super.key,
    required this.theme,
    required this.usuario,
    required this.ehProprioUsuario,
    this.cpfVisualizador,
    required this.ocultarDados,
    required this.editandoDados,
    this.telefone,
    this.endereco,
    this.redesSociais,
    required this.dataNascController,
    required this.nomeMaeController,
    required this.nomePaiController,
    required this.localNascController,
    required this.tipoSanguineoController,
    required this.estadoCivilController,
    required this.cepResidencialController,
    required this.enderecoResidencialController,
    this.buscandoCep = false,
    required this.onAlterarCep,
    required this.onIniciarEdicao,
    required this.onCancelarEdicao,
    required this.onSalvarEdicao,
    required this.onSolicitarAcesso,
  });

  Widget _campoEdicao(
    String rotulo,
    TextEditingController controller, {
    String? dica,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Widget? sufixo,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: theme.getTextStyle(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: theme.getTextStyle(fontSize: 13, color: theme.textColor),
            cursorColor: theme.textColor,
            decoration: InputDecoration(
              hintText: dica,
              suffixIcon: sufixo,
              hintStyle: theme.getTextStyle(
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _borrarSeNecessario(Widget filho) {
    if (!ocultarDados) return filho;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: IgnorePointer(
          ignoring: true,
          child: filho,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _borrarSeNecessario(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Dados Pessoais',
                textAlign: TextAlign.center,
                style: theme.getTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            if (editandoDados) ...[
              _campoEdicao('Data de nascimento', dataNascController,
                  dica: 'DD/MM/AAAA'),
              _campoEdicao('Nome da Mãe', nomeMaeController,
                  dica: 'Nome completo da mãe'),
              _campoEdicao('Nome do Pai', nomePaiController,
                  dica: 'Nome completo do pai'),
              _campoEdicao('Local de Nascimento', localNascController,
                  dica: 'Cidade - UF'),
              _campoEdicao('Tipo Sanguíneo', tipoSanguineoController,
                  dica: 'Ex: O+, A-, AB+'),
              _campoEdicao('Estado Civil', estadoCivilController,
                  dica: 'Ex: Solteiro(a), Casado(a)'),
              _campoEdicao(
                'CEP',
                cepResidencialController,
                dica: '00000-000 (preenche o endereço automaticamente)',
                keyboardType: TextInputType.number,
                onChanged: onAlterarCep,
                sufixo: buscandoCep
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.textColor,
                          ),
                        ),
                      )
                    : null,
              ),
              _campoEdicao('Endereço Residencial', enderecoResidencialController,
                  dica: 'Rua, número, bairro, cidade - UF'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onCancelarEdicao,
                    child: Text(
                      'Cancelar',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      foregroundColor: theme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onSalvarEdicao,
                    child: Text(
                      'Salvar',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        color: theme.buttonTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Data de nascimento',
                valor: usuario.dataNascimento,
                chavePrivacidade: 'dataNascimento',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Nome da mãe',
                valor: usuario.nomeMae,
                chavePrivacidade: 'nomeMae',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Nome do pai',
                valor: usuario.nomePai,
                chavePrivacidade: 'nomePai',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Local de nascimento',
                valor: usuario.localNascimento,
                chavePrivacidade: 'localNascimento',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Tipo sanguíneo',
                valor: usuario.tipoSanguineo,
                chavePrivacidade: 'tipoSanguineo',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              LinhaInfoUsuario(
                theme: theme,
                rotulo: 'Estado civil',
                valor: usuario.estadoCivil,
                chavePrivacidade: 'estadoCivil',
                ehProprioUsuario: ehProprioUsuario,
                cpfVisualizador: cpfVisualizador,
                usuario: usuario,
                onSolicitarAcesso: onSolicitarAcesso,
              ),
              if (telefone != null && telefone!.isNotEmpty)
                LinhaInfoUsuario(
                  theme: theme,
                  rotulo: 'Telefone',
                  valor: telefone!,
                  chavePrivacidade: 'telefone',
                  ehProprioUsuario: ehProprioUsuario,
                  cpfVisualizador: cpfVisualizador,
                  usuario: usuario,
                  onSolicitarAcesso: onSolicitarAcesso,
                ),
              if (usuario.cepResidencial.isNotEmpty)
                LinhaInfoUsuario(
                  theme: theme,
                  rotulo: 'CEP',
                  valor: usuario.cepResidencial,
                  chavePrivacidade: 'endereco',
                  ehProprioUsuario: ehProprioUsuario,
                  cpfVisualizador: cpfVisualizador,
                  usuario: usuario,
                  onSolicitarAcesso: onSolicitarAcesso,
                ),
              if (usuario.enderecoResidencial.isNotEmpty ||
                  (endereco != null && endereco!.isNotEmpty))
                LinhaInfoUsuario(
                  theme: theme,
                  rotulo: 'Endereço residencial',
                  valor: usuario.enderecoResidencial.isNotEmpty
                      ? usuario.enderecoResidencial
                      : endereco!,
                  chavePrivacidade: 'endereco',
                  ehProprioUsuario: ehProprioUsuario,
                  cpfVisualizador: cpfVisualizador,
                  usuario: usuario,
                  onSolicitarAcesso: onSolicitarAcesso,
                ),
              if (redesSociais != null && redesSociais!.isNotEmpty)
                LinhaInfoUsuario(
                  theme: theme,
                  rotulo: 'Redes sociais',
                  valor: redesSociais!,
                  usuario: usuario,
                  onSolicitarAcesso: onSolicitarAcesso,
                ),
              if (ehProprioUsuario) ...[
                const SizedBox(height: 10),
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textColor,
                      side: BorderSide(color: theme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onIniciarEdicao,
                    icon: Icon(Icons.edit_outlined,
                        size: 16, color: theme.textColor),
                    label: Text(
                      'Editar dados pessoais',
                      style: theme.getTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
