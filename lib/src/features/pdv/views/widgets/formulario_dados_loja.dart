import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/core/widgets/themed_text_field.dart';
import 'package:nous/src/features/pdv/services/cep_service.dart';
import 'package:nous/src/features/pdv/services/cnpj_input_formatter.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/telefone_input_formatter.dart';
import 'package:nous/src/features/pdv/views/widgets/loja/seletor_localizacao_mapa_loja_widget.dart';

class ControllersDadosLoja {
  final nome = TextEditingController();
  final cnpj = TextEditingController();
  final telefone = TextEditingController();
  final endereco = TextEditingController();
  final numero = TextEditingController();
  final cidade = TextEditingController();
  final cep = TextEditingController();
  final email = TextEditingController();
  final redesSociais = TextEditingController();
  final categorias = TextEditingController();
  final tags = TextEditingController();
  double? latitude;
  double? longitude;

  void dispose() {
    nome.dispose();
    cnpj.dispose();
    telefone.dispose();
    endereco.dispose();
    numero.dispose();
    cidade.dispose();
    cep.dispose();
    email.dispose();
    redesSociais.dispose();
    categorias.dispose();
    tags.dispose();
  }
}

class FormularioDadosLoja extends StatefulWidget {
  final AppTheme theme;
  final ControllersDadosLoja controllers;
  final String logo;
  final VoidCallback? onAlterarLogo;
  final bool podeEditarDados;
  final bool podeEditarLocalizacao;
  final void Function(double latitude, double longitude)?
      onLocalizacaoConfirmada;

  const FormularioDadosLoja({
    super.key,
    required this.theme,
    required this.controllers,
    this.logo = '',
    this.onAlterarLogo,
    this.podeEditarDados = true,
    this.podeEditarLocalizacao = true,
    this.onLocalizacaoConfirmada,
  });

  @override
  State<FormularioDadosLoja> createState() => _FormularioDadosLojaState();
}

class _FormularioDadosLojaState extends State<FormularioDadosLoja> {
  bool _buscandoCep = false;
  String _ultimoCepConsultado = '';

  @override
  void initState() {
    super.initState();
    _ultimoCepConsultado =
        CepService.normalizarDigitos(widget.controllers.cep.text);
  }

  Future<void> _aoAlterarCep(String valor) async {
    final digitos = CepService.normalizarDigitos(valor);
    if (digitos.length != 8 || digitos == _ultimoCepConsultado) {
      return;
    }
    _ultimoCepConsultado = digitos;
    if (mounted) setState(() => _buscandoCep = true);

    final resultado = await CepService.buscar(digitos);
    if (!mounted) return;
    setState(() => _buscandoCep = false);

    if (resultado == null) return;
    if (resultado.logradouro.isNotEmpty) {
      widget.controllers.endereco.text = resultado.logradouro;
    }
    if (resultado.cidade.isNotEmpty) {
      widget.controllers.cidade.text = resultado.cidade;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final controllers = widget.controllers;
    final providerLogo = ImagemService.obterImageProvider(widget.logo);
    final temLogo = providerLogo != null;
    final consultaEndereco = [
      controllers.endereco.text.trim(),
      controllers.numero.text.trim(),
      controllers.cidade.text.trim(),
      controllers.cep.text.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    return Column(
      children: [
        AbsorbPointer(
          absorbing: !widget.podeEditarDados,
          child: Column(
            children: [
              InkWell(
          onTap: widget.onAlterarLogo,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: theme.cardBackgroundColor,
            backgroundImage: providerLogo,
            child: temLogo
                ? null
                : Icon(
                    Icons.add_a_photo_outlined,
                    size: 36,
                    color: theme.secondaryTextColor,
                  ),
          ),
        ),
        const SizedBox(height: 20),

        ThemedTextField(
          theme: theme,
          controller: controllers.nome,
          label: 'Nome da Loja',
          obrigatorio: true,
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ThemedTextField(
                theme: theme,
                controller: controllers.cnpj,
                label: 'CNPJ',
                tipoDeTeclado: TextInputType.number,
                formatadores: [CnpjInputFormatter()],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ThemedTextField(
                theme: theme,
                controller: controllers.telefone,
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
                controller: controllers.endereco,
                label: 'Endereço',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ThemedTextField(
                theme: theme,
                controller: controllers.numero,
                label: 'Nº',
                tipoDeTeclado: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ThemedTextField(
          theme: theme,
          controller: controllers.cidade,
          label: 'Cidade',
        ),
        const SizedBox(height: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemedTextField(
              theme: theme,
              controller: controllers.cep,
              label: 'CEP',
              tipoDeTeclado: TextInputType.number,
              formatadores: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                LengthLimitingTextInputFormatter(9),
              ],
              onChanged: _aoAlterarCep,
            ),
            if (_buscandoCep) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Buscando endereço e cidade pelo CEP...',
                    style: theme.getTextStyle(
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SeletorLocalizacaoMapaLojaWidget(
          theme: theme,
          latitude: controllers.latitude,
          longitude: controllers.longitude,
          logoLoja: widget.logo,
          nomeLoja: controllers.nome.text,
          enderecoConsulta: consultaEndereco,
          cidadeFallback: controllers.cidade.text.trim().isNotEmpty
              ? controllers.cidade.text.trim()
              : null,
          podeEditar: widget.podeEditarLocalizacao,
          onCoordenadaAlterada: (lat, lon) {
            setState(() {
              controllers.latitude = lat;
              controllers.longitude = lon;
            });
            widget.onLocalizacaoConfirmada?.call(lat, lon);
          },
        ),
        const SizedBox(height: 12),

        AbsorbPointer(
          absorbing: !widget.podeEditarDados,
          child: Column(
            children: [
              ThemedTextField(
                theme: theme,
                controller: controllers.email,
                label: 'Email',
                tipoDeTeclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              ThemedTextField(
                theme: theme,
                controller: controllers.redesSociais,
                label: 'Redes Sociais',
              ),
              const SizedBox(height: 12),

              ThemedTextField(
                theme: theme,
                controller: controllers.categorias,
                label: 'Categorias',
              ),
              const SizedBox(height: 12),

              ThemedTextField(
                theme: theme,
                controller: controllers.tags,
                label: 'Descrição',
                linhas: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}