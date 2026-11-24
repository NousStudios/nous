import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Responsável pela criação, migração, índices e backfill de colunas
/// das tabelas sociais no SQLite do Nous.
class TimelineSchemaSqlite {
  TimelineSchemaSqlite._();

  static Future<void> garantirTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS publicacoes_sociais (
        id TEXT PRIMARY KEY,
        autor_cpf TEXT NOT NULL,
        tipo TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        excluida INTEGER NOT NULL DEFAULT 0,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pub_autor_data ON publicacoes_sociais (autor_cpf, criada_em DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pub_tipo_data ON publicacoes_sociais (tipo, criada_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS publicacoes_coautores (
        publicacao_id TEXT NOT NULL,
        cpf TEXT NOT NULL,
        PRIMARY KEY (publicacao_id, cpf)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pub_coautores_cpf ON publicacoes_coautores (cpf);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reacoes_sociais (
        id TEXT PRIMARY KEY,
        publicacao_id TEXT NOT NULL,
        usuario_cpf TEXT NOT NULL,
        tipo TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reacoes_pub ON reacoes_sociais (publicacao_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reacoes_usuario ON reacoes_sociais (usuario_cpf, criada_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comentarios_sociais (
        id TEXT PRIMARY KEY,
        publicacao_id TEXT NOT NULL,
        autor_cpf TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        excluido INTEGER NOT NULL DEFAULT 0,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comentarios_pub ON comentarios_sociais (publicacao_id, criada_em ASC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_comentarios_autor ON comentarios_sociais (autor_cpf, criada_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stories_sociais (
        id TEXT PRIMARY KEY,
        autor_cpf TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        expira_em TEXT,
        excluido INTEGER NOT NULL DEFAULT 0,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stories_autor ON stories_sociais (autor_cpf, criado_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS feeds_personalizados (
        id TEXT PRIMARY KEY,
        dono_cpf TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_feeds_dono ON feeds_personalizados (dono_cpf);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS listas_salvos_sociais (
        id TEXT PRIMARY KEY,
        dono_cpf TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_listas_salvos_dono ON listas_salvos_sociais (dono_cpf);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS itens_salvos_sociais (
        id TEXT PRIMARY KEY,
        lista_id TEXT NOT NULL,
        usuario_cpf TEXT NOT NULL,
        publicacao_id TEXT NOT NULL,
        salvo_em TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_itens_salvos_usuario ON itens_salvos_sociais (usuario_cpf, salvo_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS denuncias_sociais (
        id TEXT PRIMARY KEY,
        denunciante_cpf TEXT NOT NULL,
        alvo_cpf TEXT NOT NULL,
        publicacao_id TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_denuncias_envolvidos ON denuncias_sociais (denunciante_cpf, alvo_cpf, criada_em DESC);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS timelines_visiveis_perfil (
        cpf TEXT PRIMARY KEY,
        tipos_json TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS publicacoes_tags (
        publicacao_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (publicacao_id, tag)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pub_tags_tag ON publicacoes_tags (tag);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS descoberta_tags_config (
        cpf TEXT PRIMARY KEY,
        abas_json TEXT NOT NULL
      );
    ''');

    for (final tabela in const [
      'publicacoes_sociais',
      'stories_sociais',
      'reacoes_sociais',
      'comentarios_sociais',
      'listas_salvos_sociais',
      'itens_salvos_sociais',
      'denuncias_sociais',
    ]) {
      try {
        await db.execute('ALTER TABLE $tabela ADD COLUMN atualizada_em TEXT;');
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_${tabela}_att ON $tabela (atualizada_em);',
        );
      } catch (_) {}
      final colCriado = (tabela == 'stories_sociais')
          ? 'criado_em'
          : (tabela == 'itens_salvos_sociais' ? 'salvo_em' : 'criada_em');
      try {
        await db.execute(
          'UPDATE $tabela SET atualizada_em = $colCriado WHERE atualizada_em IS NULL;',
        );
      } catch (_) {}
    }

    try {
      await db.execute(
        'ALTER TABLE publicacoes_sociais ADD COLUMN arquivada INTEGER NOT NULL DEFAULT 0;',
      );
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE stories_sociais ADD COLUMN arquivado INTEGER NOT NULL DEFAULT 0;',
      );
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notificacoes_sociais (
        id TEXT PRIMARY KEY,
        destinatario_cpf TEXT NOT NULL,
        criada_em TEXT NOT NULL,
        lida INTEGER NOT NULL DEFAULT 0,
        dados_json TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notif_soc_dest ON notificacoes_sociais (destinatario_cpf, lida, criada_em DESC);',
    );
  }
}
