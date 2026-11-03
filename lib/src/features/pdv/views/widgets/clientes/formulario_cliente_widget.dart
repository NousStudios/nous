import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/utils/texto_formatters.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/services/cnpj_ou_cpf_input_formatter.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/telefone_input_formatter.dart';
import 'package:nous/src/features/pdv/views/widgets/opcoes_imagem_dialog.dart';

class FormularioClienteWidget extends StatelessWidget {
  final AppTheme theme;
  final Cliente? editando;
  final String foto;
  final String? aviso;
  final TextEditingController nomeController;
  final TextEditingController cnpjController;
  final TextEditingController telefoneController;
  final TextEditingController enderecoController;
  final TextEditingController numeroController;
  final TextEditingController emailController;
  final TextEditingController redesSociaisController;
  final TextEditingController descricaoController;
  final ValueChanged<String> onFotoAlterada;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;
  final VoidCallback onExcluir;

  const FormularioClienteWidget({
    super.key,
    required this.theme,
    required this.editando,
    required this.foto,
    required this.aviso,
    required this.nomeController,
    required this.cnpjController,
    required this.telefoneController,
    required this.enderecoController,
    required this.numeroController,
    required this.emailController,
    required this.redesSociaisController,
    required this.descricaoController,
    required this.onFotoAlterada,
    required this.onSalvar,
    required this.onCancelar,
    required this.onExcluir,
  });

  Future<void> _alterarFotoCliente(BuildContext context) async {
    if (foto.isNotEmpty) {
      OpcoesImagemDialog.mostrar(
        context,
        theme: theme,
        titulo: 'Foto do Cliente',
        onEscolherNova: () => _selecionarNovaFotoCliente(context),
        onRemover: () => onFotoAlterada(''),
      );
    } else {
      await _selecionarNovaFotoCliente(context);
    }
  }

  Future<void> _selecionarNovaFotoCliente(BuildContext context) async {
    const grupo = XTypeGroup(
      label: 'Imagens',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
    if (arquivo == null) return;

    final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
    if (salvo == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.cardBackgroundColor,
            content: Text(
              'A foto deve ser uma imagem válida de até meio giga (500MB).',
              style: theme.getTextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
      return;
    }

    onFotoAlterada(salvo);
  }

  Widget _botao(
    String rotulo,
    VoidCallback aoPressionar, {
    bool destaque = false,
  }) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return theme.borderColor.withValues(alpha: 0.18);
          }
          return (destaque && theme.buttonColor != Colors.transparent)
              ? theme.buttonColor
              : Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (destaque && theme.buttonColor != Colors.transparent) {
            return theme.buttonTextColor;
          }
          return theme.textColor;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return BorderSide(color: theme.textColor, width: 1.4);
          }
          return BorderSide(color: theme.borderColor, width: 1.0);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      onPressed: aoPressionar,
      child: Text(
        rotulo,
        style: theme.getTextStyle(
          fontSize: 12,
          fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
          color: (destaque && theme.buttonColor != Colors.transparent)
              ? theme.buttonTextColor
              : theme.textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              editando != null ? 'Editar Cliente' : 'Novo Cliente',
              textAlign: TextAlign.center,
              style: theme.getTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          InkWell(
            onTap: () => _alterarFotoCliente(context),
            customBorder: const CircleBorder(),
            child: Builder(
              builder: (context) {
                final fotoResolvida =
                    ImagemService.resolverCaminhoExistente(foto);
                return CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.cardBackgroundColor,
                  backgroundImage: fotoResolvida != null
                      ? FileImage(File(fotoResolvida))
                      : null,
                  child: fotoResolvida == null
                      ? Icon(
                          Icons.person,
                          size: 44,
                          color: theme.secondaryTextColor,
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ThemedTextField(
            theme: theme,
            controller: nomeController,
            label: 'Nome do Cliente',
            obrigatorio: true,
            formatadores: [PrimeiraLetraMaiusculaFormatter()],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: cnpjController,
                  label: 'CNPJ ou CPF',
                  tipoDeTeclado: TextInputType.number,
                  formatadores: [CpfOuCnpjInputFormatter()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ThemedTextField(
                  theme: theme,
                  controller: telefoneController,
                  label: 'Telefone',
                  tipoDeTeclado: TextInputType.phone,
                  formatadores: [TelefoneInputFormatter()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ThemedTextField(
                  theme: theme,
                  controller: enderecoController,
                  label: 'Endereço',
                  formatadores: [PrimeiraLetraMaiusculaFormatter()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ThemedTextField(
                  theme: theme,
                  controller: numeroController,
                  label: 'Nº',
                  tipoDeTeclado: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ThemedTextField(
            theme: theme,
            controller: emailController,
            label: 'Email',
            tipoDeTeclado: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          ThemedTextField(
            theme: theme,
            controller: redesSociaisController,
            label: 'Redes Sociais',
          ),
          const SizedBox(height: 12),
          ThemedTextField(
            theme: theme,
            controller: descricaoController,
            label: 'Descrição',
            linhas: 4,
          ),
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(aviso!, style: theme.getTextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (editando != null) ...[
                _botao('Cancelar', onCancelar),
                const SizedBox(width: 8),
              ],
              _botao(
                editando != null ? 'Salvar' : 'Cadastrar',
                onSalvar,
                destaque: true,
              ),
            ],
          ),
          if (editando != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onExcluir,
              child: Text(
                'Excluir Cliente',
                style: theme.getTextStyle(
                  fontSize: 12,
                  color: theme.dangerColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
