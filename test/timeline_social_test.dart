import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nous/src/features/timeline/models/interacao_social.dart';
import 'package:nous/src/features/timeline/models/publicacao_social.dart';
import 'package:nous/src/features/timeline/models/salvos_denuncia_social.dart';
import 'package:nous/src/features/timeline/models/story_social.dart';
import 'package:nous/src/features/timeline/services/timeline_repositorio_sqlite.dart';
import 'package:nous/src/features/timeline/services/timeline_service.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_repositorio.dart';
import 'package:nous/src/features/timeline/services/timeline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    TimelineRepositorioSqlite.definirDbParaTestes(db);
    await TimelineRepositorioSqlite.garantirTabelas(db);
  });

  group('Rede Social / Timeline Nous', () {
    test('PublicacaoSocial serializa e preserva coautores, mosaico e download', () {
      final agora = DateTime(2026, 11, 17, 16, 0);
      final pub = PublicacaoSocial(
        id: 'pub_teste_1',
        autorCpf: '11122233344',
        autorNome: 'Leonardo',
        coautoresCpfs: const ['55566677788', '99988877766'],
        tipo: TipoFeedSocial.fotos,
        texto: 'Mosaico sem corte',
        padraoExibicao: PadraoExibicaoMidia.mosaico,
        colunasMosaico: 4,
        permitirDownload: false,
        criadaEm: agora,
        atualizadaEm: agora,
      );

      final restaurada = PublicacaoSocial.fromJson(pub.toJson());
      expect(restaurada.id, 'pub_teste_1');
      expect(restaurada.coautoresCpfs, ['55566677788', '99988877766']);
      expect(restaurada.padraoExibicao, PadraoExibicaoMidia.mosaico);
      expect(restaurada.colunasMosaico, 4);
      expect(restaurada.permitirDownload, false);
    });

    test('Publicação colaborativa exige aceite para aparecer no perfil do marcado e não duplica', () async {
      final pub = await TimelineService.criarPublicacao(
        autorCpf: '111.222.333-44',
        autorNome: 'Leonardo',
        tipo: TipoFeedSocial.fotos,
        texto: 'Post em equipe',
        coautoresCpfs: ['222.333.444-55', '333.444.555-66'],
        padraoExibicao: PadraoExibicaoMidia.original,
      );

      final feedAutor = await TimelineService.listarFeedDoUsuario(
        cpf: '11122233344',
        tipo: TipoFeedSocial.fotos,
      );
      final feedCoautor2Antes = await TimelineService.listarFeedDoUsuario(
        cpf: '33344455566',
        tipo: TipoFeedSocial.fotos,
      );

      expect(feedAutor.where((p) => p.id == pub.id).length, 1);
      expect(feedCoautor2Antes.where((p) => p.id == pub.id).length, 0);
      expect(pub.coautoresPendentesCpfs, containsAll(['22233344455', '33344455566']));

      await TimelineService.responderConviteColaboracao(
        publicacaoId: pub.id,
        usuarioCpf: '33344455566',
        aceitar: true,
      );
      await TimelineService.responderConviteColaboracao(
        publicacaoId: pub.id,
        usuarioCpf: '22233344455',
        aceitar: false,
      );

      final feedCoautor2Depois = await TimelineService.listarFeedDoUsuario(
        cpf: '33344455566',
        tipo: TipoFeedSocial.fotos,
      );
      final feedCoautor1Depois = await TimelineService.listarFeedDoUsuario(
        cpf: '22233344455',
        tipo: TipoFeedSocial.fotos,
      );

      expect(feedCoautor2Depois.where((p) => p.id == pub.id).length, 1);
      expect(feedCoautor1Depois.where((p) => p.id == pub.id).length, 0);
    });

    test('Like e Deslike não duplicam e alternam corretamente por CPF', () async {
      const pubId = 'pub_reacao_1';

      await TimelineService.alternarReacao(
        publicacaoId: pubId,
        usuarioCpf: '111.222.333-44',
        usuarioNome: 'Leonardo',
        tipo: TipoReacaoSocial.like,
      );
      var reacoes = await TimelineService.listarReacoes(pubId);
      expect(reacoes.length, 1);
      expect(reacoes.first.tipo, TipoReacaoSocial.like);

      // Troca de Like para Deslike pelo mesmo usuário -> continua 1 registro
      await TimelineService.alternarReacao(
        publicacaoId: pubId,
        usuarioCpf: '11122233344',
        usuarioNome: 'Leonardo',
        tipo: TipoReacaoSocial.deslike,
      );
      reacoes = await TimelineService.listarReacoes(pubId);
      expect(reacoes.length, 1);
      expect(reacoes.first.tipo, TipoReacaoSocial.deslike);

      // Clicar em Deslike novamente remove a reação
      await TimelineService.alternarReacao(
        publicacaoId: pubId,
        usuarioCpf: '11122233344',
        usuarioNome: 'Leonardo',
        tipo: TipoReacaoSocial.deslike,
      );
      reacoes = await TimelineService.listarReacoes(pubId);
      expect(reacoes, isEmpty);
    });

    test('Republicação determinística não duplica e aparece no feed de Interações', () async {
      final original = await TimelineService.criarPublicacao(
        autorCpf: '44455566677',
        autorNome: 'Ana',
        tipo: TipoFeedSocial.escritos,
        texto: 'Texto original',
      );

      await TimelineService.republicar(
        original: original,
        meuCpf: '77788899900',
        meuNome: 'Carlos',
      );
      await TimelineService.republicar(
        original: original,
        meuCpf: '77788899900',
        meuNome: 'Carlos',
      );

      final reposts = await TimelineService.listarFeedDoUsuario(
        cpf: '77788899900',
        tipo: TipoFeedSocial.republicacoes,
      );
      expect(reposts.length, 1);

      await TimelineService.adicionarComentario(
        publicacaoId: original.id,
        autorCpf: '77788899900',
        autorNome: 'Carlos',
        texto: 'Excelente texto!',
      );

      final interacoes =
          await TimelineService.listarInteracoesDoUsuario('77788899900');
      expect(interacoes.length, greaterThanOrEqualTo(2));
      expect(interacoes.any((i) => i.tipoAcao == 'republicacao'), isTrue);
      expect(interacoes.any((i) => i.tipoAcao == 'comentario'), isTrue);
    });

    test('StorySocial expira após 24h a menos que seja destaque permanente', () {
      final passado = DateTime.now().subtract(const Duration(hours: 25));
      final expirado = StorySocial(
        id: 'st_1',
        autorCpf: '111',
        criadoEm: passado,
        expiraEm: passado.add(const Duration(hours: 24)),
      );
      final destaque = expirado.copyWith(
        id: 'st_2',
        ehDestaquePermanente: true,
        expiraEm: null,
      );

      expect(expirado.estaAtivo, isFalse);
      expect(destaque.estaAtivo, isTrue);
    });

    test('Timelines visíveis padrão, auto-ativação, salvos e denúncias', () async {
      const cpf = '88899900011';
      final iniciais = await TimelineService.obterTimelinesVisiveis(cpf);
      expect(iniciais, [
        TipoFeedSocial.fotos,
        TipoFeedSocial.videos,
        TipoFeedSocial.interacoes,
      ]);

      // Publicar música ativa automaticamente a timeline de músicas
      final pubMusica = await TimelineService.criarPublicacao(
        autorCpf: cpf,
        autorNome: 'Músico',
        tipo: TipoFeedSocial.musicas,
        texto: 'Faixa 1',
      );
      final aposMusica = await TimelineService.obterTimelinesVisiveis(cpf);
      expect(aposMusica.contains(TipoFeedSocial.musicas), isTrue);

      // Salvar em lista padrão (pública) e lista privada
      final listaPadrao =
          await TimelineService.obterOuCriarListaPadraoSalvos(cpf);
      await TimelineService.salvarPublicacaoEmLista(
        listaId: listaPadrao.id,
        usuarioCpf: cpf,
        publicacaoId: pubMusica.id,
      );
      final listaPrivada = await TimelineService.criarListaSalvos(
        donoCpf: cpf,
        nome: 'Privada',
        visibilidade: VisibilidadeListaSalvos.privada,
      );
      final pubEscrito = await TimelineService.criarPublicacao(
        autorCpf: '12345678900',
        autorNome: 'Outro',
        tipo: TipoFeedSocial.escritos,
        texto: 'Nota privada',
      );
      await TimelineService.salvarPublicacaoEmLista(
        listaId: listaPrivada.id,
        usuarioCpf: cpf,
        publicacaoId: pubEscrito.id,
      );

      // Visitante vê apenas lista pública; dono vê ambas
      final visaoVisitante = await TimelineService.listarPublicacoesSalvas(
        donoPerfilCpf: cpf,
        visualizadorCpf: '99999999999',
      );
      final visaoDono = await TimelineService.listarPublicacoesSalvas(
        donoPerfilCpf: cpf,
        visualizadorCpf: cpf,
      );
      expect(visaoVisitante.length, 1);
      expect(visaoDono.length, 2);

      // Denúncia registrada aparece para ambos os envolvidos
      await TimelineService.registrarDenuncia(
        denuncianteCpf: '99999999999',
        denuncianteNome: 'Visitante',
        alvoCpf: cpf,
        alvoNome: 'Músico',
        motivo: 'Conteúdo impróprio',
      );
      final denuncias = await TimelineService.listarDenunciasDoUsuario(cpf);
      expect(denuncias.length, 1);
      expect(denuncias.first.motivo, 'Conteúdo impróprio');
    });

    test('Feed de Descoberta indexa #tags no SQLite e filtra por timelines', () async {
      await TimelineService.criarPublicacao(
        autorCpf: '10101010101',
        autorNome: 'Autor Meme',
        tipo: TipoFeedSocial.escritos,
        texto: 'Olha esse #meme novo muito bom #humor',
      );
      await TimelineService.criarPublicacao(
        autorCpf: '20202020202',
        autorNome: 'Autor Notícia',
        tipo: TipoFeedSocial.escritos,
        texto: 'Resumo do dia #noticias',
      );

      final memes = await TimelineService.listarPublicacoesDescoberta(
        tags: ['meme', 'humor'],
      );
      final noticias = await TimelineService.listarPublicacoesDescoberta(
        tags: ['noticias'],
      );
      final todas = await TimelineService.listarPublicacoesDescoberta();

      expect(memes.length, 1);
      expect(memes.first.autorNome, 'Autor Meme');
      expect(noticias.length, 1);
      expect(noticias.first.autorNome, 'Autor Notícia');
      expect(todas.length, greaterThanOrEqualTo(2));
    });

    test('Arquivo de Stories, visualizações e sincronização de exclusão (tombstone)', () async {
      final story = await TimelineService.criarStory(
        autorCpf: '30303030303',
        autorNome: 'Criador Story',
        texto: 'Story 24h',
      );
      final visto = await TimelineService.registrarVisualizacaoStory(
        story,
        '40404040404',
      );
      expect(visto.visualizadoPorCpfs, contains('40404040404'));

      final historico = await TimelineService.listarTodosStoriesHistorico(
        '30303030303',
      );
      expect(historico.any((s) => s.id == story.id), isTrue);

      final pub = await TimelineService.criarPublicacao(
        autorCpf: '30303030303',
        autorNome: 'Criador Story',
        tipo: TipoFeedSocial.escritos,
        texto: 'Post para excluir em rede',
      );
      expect(
        await TimelineService.contarPublicacoesDoUsuario('30303030303'),
        1,
      );

      final pubExcluidaRemota = pub.copyWith(
        excluida: true,
        atualizadaEm: DateTime.now().add(const Duration(seconds: 5)),
      );
      await TimelineService.mesclarSnapshotSocial({
        'publicacoes': [pubExcluidaRemota.toJson()],
      });

      expect(
        await TimelineService.contarPublicacoesDoUsuario('30303030303'),
        0,
      );
    });

    test('Comentários com sub-respostas de sub-respostas, múltiplos fixados e exclusão', () async {
      final pub = await TimelineService.criarPublicacao(
        autorCpf: '50505050505',
        autorNome: 'Autora Post',
        tipo: TipoFeedSocial.fotos,
        texto: 'Post com carrossel e debate',
        midias: const [
          MidiaPublicacao(
            caminhoRelativo: 'foto1.jpg',
            alinhamentoX: -0.4,
            alinhamentoY: 0.3,
            escalaZoom: 1.8,
          ),
        ],
      );
      expect(pub.midias.first.escalaZoom, 1.8);
      expect(pub.midias.first.alinhamentoX, -0.4);

      final c1 = await TimelineService.adicionarComentario(
        publicacaoId: pub.id,
        autorCpf: '60606060606',
        autorNome: 'Comentarista 1',
        texto: 'Comentário raiz',
      );
      final c2 = await TimelineService.adicionarComentario(
        publicacaoId: pub.id,
        autorCpf: '70707070707',
        autorNome: 'Comentarista 2',
        texto: 'Sub-resposta nível 1',
        respostaDeId: c1.id,
      );
      final c3 = await TimelineService.adicionarComentario(
        publicacaoId: pub.id,
        autorCpf: '50505050505',
        autorNome: 'Autora Post',
        texto: 'Sub-resposta nível 2',
        respostaDeId: c2.id,
      );

      // Fixa múltiplos comentários (c1 e c3)
      await TimelineService.alternarFixarComentario(c1);
      await TimelineService.alternarFixarComentario(c3);

      var lista = await TimelineService.listarComentarios(pub.id);
      expect(lista.length, 3);
      expect(lista.where((c) => c.fixado).length, 2);
      expect(lista.any((c) => c.id == c3.id && c.respostaDeId == c2.id), isTrue);

      // Exclui c2
      await TimelineService.excluirComentario(c2);
      lista = await TimelineService.listarComentarios(pub.id);
      expect(lista.length, 2);

      // Verifica se aparece na timeline Interações do comentarista
      final interacoes = await TimelineService.listarInteracoesDoUsuario(
        '60606060606',
      );
      expect(interacoes.any((i) => i.tipoAcao == 'comentario'), isTrue);
    });

    test('Delta Sync exporta apenas alterações posteriores ao corte (desde)', () async {
      final antes = DateTime.now().add(const Duration(seconds: 10));
      final snapVazio = await TimelineService.exportarSnapshotSocial(
        desde: antes,
      );
      expect(snapVazio['incremental'], isTrue);
      expect((snapVazio['publicacoes'] as List), isEmpty);

      final snapCompleto = await TimelineService.exportarSnapshotSocial();
      expect(snapCompleto['incremental'], isFalse);
      expect((snapCompleto['publicacoes'] as List), isNotEmpty);
    });

    test('Republicações não aparecem como postagem fantasma no Feed de Descoberta', () async {
      final original = await TimelineService.criarPublicacao(
        autorCpf: '80808080808',
        autorNome: 'Fotógrafa',
        tipo: TipoFeedSocial.fotos,
        texto: 'Foto original única #teste_fantasma',
        midias: const [MidiaPublicacao(caminhoRelativo: 'unica.jpg')],
      );
      await TimelineService.republicar(
        original: original,
        meuCpf: '90909090909',
        meuNome: 'Repostador',
      );
      final descoberta = await TimelineService.listarPublicacoesDescoberta(
        tags: ['teste_fantasma'],
      );
      expect(descoberta.length, 1);
      expect(descoberta.first.id, original.id);
      expect(descoberta.first.tipo, TipoFeedSocial.fotos);
    });

    test('Escudo 1: autor logado não ressuscita postagem antiga ausente enviada por outro nó', () async {
      const cpfAutor = '55566677700';
      await TimelineService.criarPublicacao(
        autorCpf: cpfAutor,
        autorNome: 'Leonardo',
        tipo: TipoFeedSocial.fotos,
        texto: 'Postagem atual ativa',
      );

      final zumbiAntigo = PublicacaoSocial(
        id: 'pub_zumbi_antiga_1',
        autorCpf: cpfAutor,
        autorNome: 'Leonardo',
        tipo: TipoFeedSocial.fotos,
        texto: 'Post excluído há dias',
        criadaEm: DateTime.now().subtract(const Duration(days: 3)),
        atualizadaEm: DateTime.now().subtract(const Duration(days: 3)),
        excluida: false,
      );

      await TimelineSyncRepositorio.mesclarSnapshotSocial(
        {
          'remetenteCpf': '99988877711',
          'publicacoes': [zumbiAntigo.toJson()],
        },
        cpfLogado: cpfAutor,
      );

      final mapa = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
        ['pub_zumbi_antiga_1'],
        incluirExcluidas: true,
      );
      expect(mapa['pub_zumbi_antiga_1']?.excluida, isTrue);
      final total = await TimelineService.contarPublicacoesDoUsuario(cpfAutor);
      expect(total, 1);
    });

    test('Escudo 2: balcão limpa posts antigos de um autor que enviou sua lista ativa completa', () async {
      const cpfAutor = '44433322211';
      const cpfBalcao = '11122233399';
      final antiga = PublicacaoSocial(
        id: 'pub_balcao_antiga_1',
        autorCpf: cpfAutor,
        autorNome: 'Autor',
        tipo: TipoFeedSocial.fotos,
        texto: 'Post antigo no balcão',
        criadaEm: DateTime.now().subtract(const Duration(days: 2)),
        atualizadaEm: DateTime.now().subtract(const Duration(days: 2)),
        excluida: false,
      );
      await TimelineRepositorioSqlite.salvarPublicacao(antiga);

      await TimelineSyncRepositorio.mesclarSnapshotSocial(
        {
          'remetenteCpf': cpfAutor,
          'autorPossuiHistorico': true,
          'offset': 0,
          'idsPublicacoesAtivas': ['pub_autor_real_1'],
          'publicacoes': [],
        },
        cpfLogado: cpfBalcao,
      );

      final mapa = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
        ['pub_balcao_antiga_1'],
        incluirExcluidas: true,
      );
      expect(mapa['pub_balcao_antiga_1']?.excluida, isTrue);
    });

    test('WebSocket processarEventoRemoto respeita LWW e não ressuscita post excluído localmente', () async {
      final pub = await TimelineService.criarPublicacao(
        autorCpf: '77788899900',
        autorNome: 'Autor WS',
        tipo: TipoFeedSocial.escritos,
        texto: 'Texto antes de excluir',
      );
      await TimelineService.excluirPublicacao(pub);

      final eventoAntigo = pub.copyWith(
        excluida: false,
        atualizadaEm: pub.criadaEm,
      );

      await TimelineSyncService.processarEventoRemoto({
        'tipo': 'timeline_publicacao',
        'publicacao': eventoAntigo.toJson(),
      });

      final mapa = await TimelineRepositorioSqlite.buscarPublicacoesPorIds(
        [pub.id],
        incluirExcluidas: true,
      );
      expect(mapa[pub.id]?.excluida, isTrue);
    });
  });
}
