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

    final conta = digitos.length == 11
        ? await ContasNousService.buscarPorCpf(digitos)
        : null;

    final emailsConta = conta?.emails
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final nomeConta = conta?.nome.trim().toLowerCase() ?? '';

    String nome = conta?.nome ?? '';
    String email =
        (conta != null && conta.emails.isNotEmpty) ? conta.emails.first : '';
    String foto = conta?.foto ?? '';
    String telefone = '';
    String endereco = '';
    String numero = '';
    String redesSociais = '';
    String descricao = '';
    String origem = conta != null ? 'Conta Nous (${conta.nome})' : '';

    final prefs = await SharedPreferences.getInstance();
    final chavesLojas =
        prefs.getKeys().where((k) => k.startsWith('nous_lojas_')).toList();

    for (final chave in chavesLojas) {
      final texto = prefs.getString(chave);
      if (texto == null || texto.isEmpty) continue;

      try {
        final lista = jsonDecode(texto) as List<dynamic>;
        for (final item in lista) {
          final loja = Loja.fromJson(item as Map<String, dynamic>);

          // 1. Vasculha cadastros de clientes da loja
          for (final c in loja.clientesLoja) {
            final cDoc = c.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
            final cEmail = c.email.trim().toLowerCase();
            final cNome = c.nome.trim().toLowerCase();

            final mesmoDoc = cDoc.isNotEmpty && cDoc == digitos;
            final mesmoEmail = cEmail.isNotEmpty && emailsConta.contains(cEmail);
            final mesmoNome = nomeConta.isNotEmpty && cNome == nomeConta;

            if (mesmoDoc || mesmoEmail || mesmoNome) {
              if (nome.isEmpty && c.nome.isNotEmpty) nome = c.nome;
              if (email.isEmpty && c.email.isNotEmpty) email = c.email;
              if (telefone.isEmpty && c.telefone.isNotEmpty) {
                telefone = c.telefone;
              }
              if (endereco.isEmpty && c.endereco.isNotEmpty) {
                endereco = c.endereco;
              }
              if (numero.isEmpty && c.numero.isNotEmpty) {
                numero = c.numero;
              }
              if (redesSociais.isEmpty && c.redesSociais.isNotEmpty) {
                redesSociais = c.redesSociais;
              }
              if (descricao.isEmpty && c.descricao.isNotEmpty) {
                descricao = c.descricao;
              }
              if (foto.isEmpty && c.foto.isNotEmpty) {
                foto = c.foto;
              }
              if (origem.isEmpty) origem = 'Cadastro prévio de cliente';
            }
          }

          // 2. Vasculha fornecedores cadastrados na loja
          for (final f in loja.fornecedoresLoja) {
            final fDoc = f.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
            final fEmail = f.email.trim().toLowerCase();
            final fNome = f.nome.trim().toLowerCase();

            final mesmoDoc = fDoc.isNotEmpty && fDoc == digitos;
            final mesmoEmail = fEmail.isNotEmpty && emailsConta.contains(fEmail);
            final mesmoNome = nomeConta.isNotEmpty && fNome == nomeConta;

            if (mesmoDoc || mesmoEmail || mesmoNome) {
              if (nome.isEmpty && f.nome.isNotEmpty) nome = f.nome;
              if (email.isEmpty && f.email.isNotEmpty) email = f.email;
              if (telefone.isEmpty && f.telefone.isNotEmpty) {
                telefone = f.telefone;
              }
              if (endereco.isEmpty && f.endereco.isNotEmpty) {
                endereco = f.endereco;
              }
              if (numero.isEmpty && f.numero.isNotEmpty) {
                numero = f.numero;
              }
              if (redesSociais.isEmpty && f.redesSociais.isNotEmpty) {
                redesSociais = f.redesSociais;
              }
              if (foto.isEmpty && f.foto.isNotEmpty) {
                foto = f.foto;
              }
              if (origem.isEmpty) origem = 'Fornecedor local "${f.nome}"';
            }
          }

          // 3. Verifica dados da própria Loja (se for a loja criada por esse CPF ou coincidir o CNPJ)
          final cnpjLoja = loja.cnpj.replaceAll(RegExp(r'[^0-9]'), '');
          final lojaDoCpf = chave.endsWith('_$digitos') ||
              loja.cpfDonoOriginal == digitos ||
              (cnpjLoja.isNotEmpty && cnpjLoja == digitos);

          if (lojaDoCpf) {
            if (nome.isEmpty && loja.nome.isNotEmpty) nome = loja.nome;
            if (email.isEmpty && loja.email.isNotEmpty) email = loja.email;
            if (telefone.isEmpty && loja.telefone.isNotEmpty) {
              telefone = loja.telefone;
            }
            if (endereco.isEmpty && loja.endereco.isNotEmpty) {
              endereco = loja.endereco;
            }
            if (numero.isEmpty && loja.numero.isNotEmpty) {
              numero = loja.numero;
            }
            if (redesSociais.isEmpty && loja.redesSociais.isNotEmpty) {
              redesSociais = loja.redesSociais;
            }
            if (foto.isEmpty && loja.logo.isNotEmpty) {
              foto = loja.logo;
            }
            if (origem.isEmpty) origem = 'Loja local "${loja.nome}"';
          }
        }
      } catch (_) {}
    }

    // 4. Se a descrição ainda estiver vazia e a conta tiver dados pessoais adicionais, enriquece a descrição
    if (descricao.isEmpty && conta != null) {
      final partes = <String>[];
      if (conta.dataNascimento.isNotEmpty) {
        partes.add('Nasc: ${conta.dataNascimento}');
      }
      if (conta.localNascimento.isNotEmpty) {
        partes.add('Naturalidade: ${conta.localNascimento}');
      }
      if (conta.estadoCivil.isNotEmpty) {
        partes.add('Estado Civil: ${conta.estadoCivil}');
      }
      if (conta.tipoSanguineo.isNotEmpty) {
        partes.add('Tipo Sanguíneo: ${conta.tipoSanguineo}');
      }
      if (partes.isNotEmpty) {
        descricao = partes.join(' • ');
      }
    }

    if (nome.isEmpty && telefone.isEmpty && endereco.isEmpty && email.isEmpty) {
      return null;
    }

    return DadosAutopreenchimento(
      nome: nome,
      telefone: telefone,
      endereco: endereco,
      numero: numero,
      email: email,
      redesSociais: redesSociais,
      descricao: descricao,
      foto: foto,
      origem: origem.isEmpty ? 'Cadastro local' : origem,
    );
  }
}
