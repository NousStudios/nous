import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/core/services/banco_dados_service.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/services/cpf_validator.dart';

/// Registro histórico soberano de contas Nous que foram criadas e posteriormente excluídas.
class ContaExcluidaNous {
  final String cpf;
  final String nome;
  final String apelido;
  final String localNascimento;
  final String criadoEm;
  final String excluidoEm;

  const ContaExcluidaNous({
    required this.cpf,
    required this.nome,
    this.apelido = '',
    this.localNascimento = '',
    this.criadoEm = '',
    required this.excluidoEm,
  });

  factory ContaExcluidaNous.fromMap(Map<String, dynamic> map) {
    return ContaExcluidaNous(
      cpf: map['cpf']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      apelido: map['apelido']?.toString() ?? '',
      localNascimento: map['local_nascimento']?.toString() ??
          map['localNascimento']?.toString() ??
          '',
      criadoEm: map['criado_em']?.toString() ??
          map['criadoEm']?.toString() ??
          '',
      excluidoEm: map['excluido_em']?.toString() ??
          map['excluidoEm']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'cpf': cpf,
        'nome': nome,
        'apelido': apelido,
        'localNascimento': localNascimento,
        'criadoEm': criadoEm,
        'excluidoEm': excluidoEm,
      };
}

/// Serviço para registrar, listar e remover do histórico as contas excluídas no Nous.
class ContasExcluidasService {
  ContasExcluidasService._();

  static bool _tabelaCriada = false;

  static Future<void> _garantirTabela(Database db) async {
    if (_tabelaCriada) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contas_excluidas_nous (
        cpf TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        apelido TEXT NOT NULL DEFAULT '',
        local_nascimento TEXT NOT NULL DEFAULT '',
        criado_em TEXT NOT NULL DEFAULT '',
        excluido_em TEXT NOT NULL
      );
    ''');
    _tabelaCriada = true;
  }

  static Future<ContaExcluidaNous?> registrarExclusao(UsuarioNous usuario) async {
    final cpfLimpo = CpfValidator.onlyDigits(usuario.cpf);
    if (cpfLimpo.isEmpty) return null;

    final registro = ContaExcluidaNous(
      cpf: cpfLimpo,
      nome: usuario.nome.isNotEmpty ? usuario.nome : usuario.nomeExibicao,
      apelido: usuario.apelido,
      localNascimento: usuario.localNascimento,
      criadoEm: usuario.criadoEm,
      excluidoEm: DateTime.now().toIso8601String(),
    );
    await salvarRegistro(registro);
    return registro;
  }

  static Future<void> salvarRegistro(ContaExcluidaNous registro) async {
    final cpfLimpo = CpfValidator.onlyDigits(registro.cpf);
    if (cpfLimpo.isEmpty) return;

    final db = await BancoDadosService.db;
    await _garantirTabela(db);
    await db.insert(
      'contas_excluidas_nous',
      {
        'cpf': cpfLimpo,
        'nome': registro.nome,
        'apelido': registro.apelido,
        'local_nascimento': registro.localNascimento,
        'criado_em': registro.criadoEm,
        'excluido_em': registro.excluidoEm,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ContaExcluidaNous>> carregarTodas() async {
    final db = await BancoDadosService.db;
    await _garantirTabela(db);
    final rows = await db.query(
      'contas_excluidas_nous',
      orderBy: 'excluido_em DESC',
    );
    return rows.map(ContaExcluidaNous.fromMap).toList();
  }

  static Future<void> removerPorCpf(String cpf) async {
    final cpfLimpo = CpfValidator.onlyDigits(cpf);
    if (cpfLimpo.isEmpty) return;
    final db = await BancoDadosService.db;
    await _garantirTabela(db);
    await db.delete(
      'contas_excluidas_nous',
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
    );
  }
}
