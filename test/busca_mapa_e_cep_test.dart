import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_filtros_helper.dart';
import 'package:nous/src/features/busca/models/resultado_rota_mapa.dart';
import 'package:nous/src/features/busca/services/mapa_espelhamento_service.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/cep_service.dart';
import 'package:nous/src/features/pdv/services/loja/consolidador_loja_local.dart';

Loja _criarLojaTeste({
  String id = 'loja_1',
  String nome = 'Padaria Central',
  String endereco = 'Rua Domingos de Marchi',
  String numero = '172',
  String cidade = 'São José do Rio Preto',
  String cep = '15054-631',
  DateTime? dadosAtualizadosEm,
}) {
  return Loja(
    id: id,
    cpfDonoOriginal: '11122233344',
    nome: nome,
    cnpj: '',
    telefone: '',
    endereco: endereco,
    numero: numero,
    cidade: cidade,
    cep: cep,
    email: '',
    categorias: '',
    tags: '',
    dadosAtualizadosEm: dadosAtualizadosEm,
  );
}

void main() {
  group('CepService', () {
    test('normalizarDigitos extrai apenas os dígitos do CEP', () {
      expect(CepService.normalizarDigitos('15054-631'), '15054631');
      expect(CepService.normalizarDigitos(' 15.054-631 '), '15054631');
      expect(CepService.normalizarDigitos('abc'), '');
    });
  });

  group('BuscaMapaController.lojaAptaParaMapa', () {
    test('rejeita loja coletiva Nous mesmo que possua campos preenchidos', () {
      final lojaNous = _criarLojaTeste(
        id: PdvProvider.idLojaColetivaNous,
        nome: 'Nous',
      );
      expect(BuscaMapaController.lojaAptaParaMapa(lojaNous), isFalse);

      final outraNous = _criarLojaTeste(id: 'qualquer', nome: '  nous ');
      expect(BuscaMapaController.lojaAptaParaMapa(outraNous), isFalse);
    });

    test('rejeita loja sem endereço, sem número ou sem cidade e CEP válidos', () {
      final semEndereco = _criarLojaTeste(nome: 'Belzebolos', endereco: '');
      final semNumero = _criarLojaTeste(nome: 'Belzebolos', numero: '');
      final semCidadeNemCep =
          _criarLojaTeste(nome: 'Belzebolos', cidade: '', cep: '15054');

      expect(BuscaMapaController.lojaAptaParaMapa(semEndereco), isFalse);
      expect(BuscaMapaController.lojaAptaParaMapa(semNumero), isFalse);
      expect(BuscaMapaController.lojaAptaParaMapa(semCidadeNemCep), isFalse);
    });

    test('aceita loja devidamente configurada com endereço, número e cidade ou CEP', () {
      final comCidade = _criarLojaTeste(cep: '');
      final comCep = _criarLojaTeste(cidade: '', cep: '15054-631');

      expect(BuscaMapaController.lojaAptaParaMapa(comCidade), isTrue);
      expect(BuscaMapaController.lojaAptaParaMapa(comCep), isTrue);
    });
  });

  group('MapaEspelhamentoService & EstadoNavegacaoEspelhada', () {
    test('serializa e desserializa rota espelhada preservando pontos e heading', () {
      final rota = ResultadoRotaMapa(
        pontos: const [LatLng(-20.81, -49.37), LatLng(-20.82, -49.38)],
        distanciaMetros: 1450,
        duracaoSegundos: 320,
        origemLabel: 'Seu local',
        destinoLabel: 'Providence',
      );
      final estado = EstadoNavegacaoEspelhada(
        cpf: '11122233344',
        ativo: true,
        emissorId: 'dev_outro',
        origem: rota.pontos.first,
        origemLabel: 'Seu local',
        destino: rota.pontos.last,
        destinoLabel: 'Providence',
        atual: const LatLng(-20.815, -49.375),
        heading: 42.5,
        distanciaMetros: rota.distanciaMetros,
        duracaoSegundos: rota.duracaoSegundos,
        pontos: rota.pontos,
        atualizadoEm: 1700000000000,
      );

      final restaurado = EstadoNavegacaoEspelhada.fromJson(estado.toJson());
      expect(restaurado.ativo, isTrue);
      expect(restaurado.destinoLabel, 'Providence');
      expect(restaurado.heading, 42.5);
      expect(restaurado.pontos.length, 2);
      expect(restaurado.toResultadoRota()?.distanciaMetros, 1450);
    });

    test('receberEventoRede filtra por CPF e atualiza estadoRemoto', () {
      final servico = MapaEspelhamentoService.instancia;
      servico.limparEstadoRemoto();

      final payloadOutroCpf = EstadoNavegacaoEspelhada(
        cpf: '99988877766',
        ativo: false,
        emissorId: 'dev_externo',
        atualizadoEm: 1,
      ).toJson();
      servico.receberEventoRede(payloadOutroCpf, '111.222.333-44');
      expect(servico.estadoRemoto, isNull);

      final payloadMesmoCpf = EstadoNavegacaoEspelhada(
        cpf: '11122233344',
        ativo: false,
        emissorId: 'dev_externo',
        destinoLabel: 'Loja X',
        atualizadoEm: 2,
      ).toJson();
      servico.receberEventoRede(payloadMesmoCpf, '111.222.333-44');
      expect(servico.estadoRemoto?.destinoLabel, 'Loja X');
      servico.limparEstadoRemoto();
    });
  });

  group('Loja & ConsolidadorLojaLocal', () {
    test('preserva dados cadastrais mais recentes com base em dadosAtualizadosEm', () {
      final antiga = _criarLojaTeste(
        endereco: 'Rua Antiga',
        cidade: 'Cidade Antiga',
        cep: '11111-111',
        dadosAtualizadosEm: DateTime(2026, 11, 24, 8, 0),
      );
      final recente = _criarLojaTeste(
        endereco: 'Rua Domingos de Marchi',
        cidade: 'São José do Rio Preto',
        cep: '15054-631',
        dadosAtualizadosEm: DateTime(2026, 11, 24, 9, 0),
      );

      final consolidada = ConsolidadorLojaLocal.consolidar(
        antiga,
        recente,
      );
      expect(consolidada.endereco, 'Rua Domingos de Marchi');
      expect(consolidada.cidade, 'São José do Rio Preto');
      expect(consolidada.cep, '15054-631');
    });

    test('Busca aproximada encontra "Laricas" mesmo transcrito como "Laricus"', () {
      final lojaLaricas = _criarLojaTeste(
        endereco: 'Rua Duarte Pacheco',
        cidade: 'São José do Rio Preto',
        cep: '15085-140',
      ).copyWith(nome: 'Laricas');
      final outraLoja = _criarLojaTeste(
        endereco: 'Rua Central',
        cidade: 'São José do Rio Preto',
        cep: '15010-000',
      ).copyWith(nome: 'Mercado Central');

      final filtradas = BuscaMapaFiltrosHelper.filtrarLojas(
        [outraLoja, lojaLaricas],
        'Laricus',
      );
      expect(filtradas.length, 1);
      expect(filtradas.first.nome, 'Laricas');
    });
  });
}
