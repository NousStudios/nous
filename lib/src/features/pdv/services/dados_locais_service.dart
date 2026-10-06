import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

class DadosAutopreenchimento {
  final String nome;
  final String telefone;
  final String endereco;
  final String numero;
  final String email;
  final String redesSociais;
  final String descricao;
  final String foto;
  final String origem;

  const DadosAutopreenchimento({
    required this.nome,
    this.telefone = '',
    this.endereco = '',
    this.numero = '',
    this.email = '',
    this.redesSociais = '',
    this.descricao = '',
    this.foto = '',
    required this.origem,
  });
}

class DadosLocaisService {
  DadosLocaisService._();

  static Future<DadosAutopreenchimento?> buscarPorDocumento(
    String documento,
  ) async {
    final digitos = documento.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length != 11 && digitos.length != 14) return null;

    // 1. Se for CPF (11 dígitos), verifica primeiro as contas de usuários Nous na máquina
    if (digitos.length == 11) {
      final conta = await ContasNousService.buscarPorCpf(digitos);
      if (conta != null) {
        String telefone = '';
        String endereco = '';
        String numero = '';
        String redesSociais = '';
        String foto = conta.foto;

        // Tenta enriquecer com dados prévios de cliente ou loja caso essa conta já possua cadastros
        final dadosComplementares =
            await _buscarEmLojasClientesEFornecedores(digitos);
        if (dadosComplementares != null) {
          telefone = dadosComplementares.telefone;
          endereco = dadosComplementares.endereco;
          numero = dadosComplementares.numero;
          redesSociais = dadosComplementares.redesSociais;
          if (foto.isEmpty) {
            foto = dadosComplementares.foto;
          }
        }

        return DadosAutopreenchimento(
          nome: conta.nome,
          telefone: telefone,
          endereco: endereco,
          numero: numero,
          email: conta.emails.isNotEmpty ? conta.emails.first : '',
          redesSociais: redesSociais,
          foto: foto,
          origem: 'Conta Nous (${conta.nome})',
        );
      }
    }

    // 2. Busca em Lojas, Clientes e Fornecedores locais
    return await _buscarEmLojasClientesEFornecedores(digitos);
  }

  static Future<DadosAutopreenchimento?> _buscarEmLojasClientesEFornecedores(
    String digitos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final chavesLojas =
        prefs.getKeys().where((k) => k.startsWith('nous_lojas_')).toList();

    // 2a. Verifica se é o CNPJ de alguma Loja cadastrada nesta máquina
    for (final chave in chavesLojas) {
      final texto = prefs.getString(chave);
      if (texto == null || texto.isEmpty) continue;

      try {
        final lista = jsonDecode(texto) as List<dynamic>;
        for (final item in lista) {
          final loja = Loja.fromJson(item as Map<String, dynamic>);
          final cnpjLoja = loja.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
          if (cnpjLoja.isNotEmpty && cnpjLoja == digitos) {
            return DadosAutopreenchimento(
              nome: loja.nome,
              telefone: loja.telefone,
              endereco: loja.endereco,
              numero: loja.numero,
              email: loja.email,
              redesSociais: loja.redesSociais,
              foto: loja.logo,
              origem: 'Loja local "${loja.nome}"',
            );
          }
        }
      } catch (_) {}
    }

    // 2b. Verifica se já existe em clientes cadastrados de qualquer loja da máquina
    for (final chave in chavesLojas) {
      final texto = prefs.getString(chave);
      if (texto == null || texto.isEmpty) continue;

      try {
        final lista = jsonDecode(texto) as List<dynamic>;
        for (final item in lista) {
          final loja = Loja.fromJson(item as Map<String, dynamic>);

          for (final c in loja.clientesLoja) {
            final cDoc = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
            if (cDoc.isNotEmpty && cDoc == digitos) {
              return DadosAutopreenchimento(
                nome: c.nome,
                telefone: c.telefone,
                endereco: c.endereco,
                numero: c.numero,
                email: c.email,
                redesSociais: c.redesSociais,
                descricao: c.descricao,
                foto: c.foto,
                origem: 'Cadastro prévio de cliente',
              );
            }
          }

          // 2c. Verifica se já existe em fornecedores de qualquer loja da máquina
          for (final f in loja.fornecedoresLoja) {
            final fDoc = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
            if (fDoc.isNotEmpty && fDoc == digitos) {
              return DadosAutopreenchimento(
                nome: f.nome,
                telefone: f.telefone,
                endereco: f.endereco,
                numero: f.numero,
                email: f.email,
                redesSociais: f.redesSociais,
                foto: f.foto,
                origem: 'Fornecedor local "${f.nome}"',
              );
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
