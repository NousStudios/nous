import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nous/src/features/busca/controllers/busca_mapa_controller.dart';
import 'package:nous/src/features/busca/controllers/helpers/busca_mapa_filtros_helper.dart';
import 'package:nous/src/features/busca/models/avaliacao_produto.dart';
import 'package:nous/src/features/compras/services/carrinho_compras_service.dart';
import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';

void main() {
  group('BuscaMapaFiltrosHelper - Proximidade e Busca Comercial', () {
    final lojaSP = Loja(
      id: 'loja_sp',
      nome: 'Padaria Paulista',
      cnpj: '',
      telefone: '',
      email: '',
      categorias: '',
      tags: '',
      endereco: 'Av Paulista',
      numero: '1000',
      cidade: 'São Paulo',
      latitude: -23.5614,
      longitude: -46.6559,
      itensLoja: const [
        ItemLoja(
          id: 'item_cafe_sp',
          nome: 'Café Artesanal',
          preco: '18,50',
          tipo: TipoItemLoja.produto,
        ),
      ],
    );

    final lojaBA = Loja(
      id: 'loja_ba',
      nome: 'Empório Salvador',
      cnpj: '',
      telefone: '',
      email: '',
      categorias: '',
      tags: '',
      endereco: 'Rua Chile',
      numero: '50',
      cidade: 'Salvador',
      latitude: -12.9714,
      longitude: -38.5014,
      itensLoja: const [
        ItemLoja(
          id: 'item_cafe_ba',
          nome: 'Café Artesanal Baiano',
          preco: '22,00',
          tipo: TipoItemLoja.produto,
        ),
        ItemLoja(
          id: 'item_acaraje_ba',
          nome: 'Acarajé Congelado',
          preco: '35,00',
          tipo: TipoItemLoja.produto,
        ),
      ],
    );

    test('ordena produtos do mais próximo para o mais distante mantendo itens de outros estados', () {
      // Usuário em São Paulo (próximo à Av. Paulista)
      final resultados = BuscaMapaFiltrosHelper.filtrarProdutos(
        [lojaBA, lojaSP],
        'Café',
        {FiltroBuscaMapa.produtos},
        latUsuario: -23.5505,
        lonUsuario: -46.6333,
      );

      expect(resultados.length, 2);
      expect(resultados.first.loja.id, 'loja_sp');
      expect(resultados.last.loja.id, 'loja_ba');
      expect(resultados.first.distanciaKm! < 10.0, isTrue);
      expect(resultados.last.distanciaKm! > 1000.0, isTrue);
    });

    test('exibe produto que só existe na Bahia para usuário em São Paulo', () {
      final resultados = BuscaMapaFiltrosHelper.filtrarProdutos(
        [lojaSP, lojaBA],
        'Acarajé',
        {FiltroBuscaMapa.produtos},
        latUsuario: -23.5505,
        lonUsuario: -46.6333,
      );

      expect(resultados.length, 1);
      expect(resultados.first.item.id, 'item_acaraje_ba');
      expect(resultados.first.loja.cidade, 'Salvador');
    });

    test('usa mapa de coordenadas geocodificadas quando loja não tem lat/lon persistidos', () {
      final lojaSemLatLon = Loja(
        id: 'loja_geo',
        nome: 'Oficina Local',
        cnpj: '',
        telefone: '',
        email: '',
        categorias: '',
        tags: '',
        endereco: 'Rua das Flores',
        numero: '12',
        cidade: 'São Paulo',
        itensLoja: const [
          ItemLoja(
            id: 'serv_1',
            nome: 'Manutenção Elétrica',
            preco: '120,00',
            tipo: TipoItemLoja.servico,
          ),
        ],
      );

      final resultados = BuscaMapaFiltrosHelper.filtrarProdutos(
        [lojaSemLatLon],
        'Elétrica',
        {FiltroBuscaMapa.servicos},
        latUsuario: -23.5505,
        lonUsuario: -46.6333,
        coordenadasLojas: {
          'loja_geo': const LatLng(-23.5515, -46.6340),
        },
      );

      expect(resultados.length, 1);
      expect(resultados.first.distanciaKm, isNotNull);
      expect(resultados.first.distanciaKm! < 1.0, isTrue);
      expect(resultados.first.distanciaFormatada.contains('m de você'), isTrue);
    });
  });

  group('BuscaMapaController - Gatilho da Tela Comercial', () {
    test('não abre catálogo ao apenas ligar filtro Produtos sem buscar; abre ao digitar busca', () {
      final ctrl = BuscaMapaController();
      addTearDown(ctrl.dispose);

      ctrl.alternarFiltro(FiltroBuscaMapa.produtos);
      expect(ctrl.exibirCatalogoComercial, isFalse);
      expect(ctrl.painelBuscaExpandido, isFalse);

      ctrl.atualizarBusca('café');
      expect(ctrl.exibirCatalogoComercial, isTrue);

      ctrl.atualizarBusca('');
      expect(ctrl.exibirCatalogoComercial, isFalse);

      ctrl.confirmarBuscaComercial();
      expect(ctrl.exibirCatalogoComercial, isTrue);

      ctrl.alternarFiltro(FiltroBuscaMapa.produtos);
      ctrl.alternarFiltro(FiltroBuscaMapa.lojas);
      expect(ctrl.exibirCatalogoComercial, isFalse);
    });
  });

  group('CarrinhoComprasService - Parsing de Preço', () {
    test('converte corretamente preços em formato BR e decimal', () {
      expect(CarrinhoComprasService.parsePreco('12,50'), 12.5);
      expect(CarrinhoComprasService.parsePreco('R\$ 1.250,90'), 1250.9);
      expect(CarrinhoComprasService.parsePreco('19.90'), 19.9);
      expect(CarrinhoComprasService.parsePreco(''), 0.0);
    });
  });

  group('AvaliacaoProduto - Serialização e Validação', () {
    test('serializa e restaura avaliação com clamp de 1 a 5 estrelas', () {
      final aval = AvaliacaoProduto(
        id: 'av_1',
        itemId: 'item_1',
        lojaId: 'loja_1',
        autorCpf: '12345678900',
        autorNome: 'João',
        estrelas: 1,
        comentario: 'Não gostei do acabamento.',
        criadoEm: DateTime(2026, 11, 26, 10, 30),
        curtidas: 3,
      );

      final restaurada = AvaliacaoProduto.fromJson(aval.toJson());
      expect(restaurada.id, 'av_1');
      expect(restaurada.estrelas, 1);
      expect(restaurada.comentario, 'Não gostei do acabamento.');
      expect(restaurada.curtidas, 3);
    });
  });

  group('BuscaMapaFiltrosHelper - Categorias Compostas', () {
    test(
      'combina categoria (ex: Açaí R\$ 20) com item (ex: Copo 300ml R\$ 2) formando R\$ 22 e permite busca pela categoria',
      () {
        const copo300 = ItemLoja(
          id: 'copo_300',
          nome: 'Copo 300ml',
          preco: '2,00',
          tipo: TipoItemLoja.produto,
        );
        const catAcai = CategoriaLoja(
          id: 'cat_acai',
          nome: 'Açaí',
          preco: '20,00',
          tipo: TipoItemLoja.produto,
          itemIds: ['copo_300'],
          grupoIds: ['grp_doces'],
        );
        final lojaLaricas = Loja(
          id: 'laricas',
          nome: 'Laricas',
          cnpj: '',
          telefone: '',
          email: '',
          categorias: 'Doces e Açaí',
          tags: '',
          endereco: 'Centro',
          numero: '100',
          cidade: 'São José do Rio Preto',
          itensLoja: const [copo300],
          categoriasLoja: const [catAcai],
        );

        final resultadosAcai = BuscaMapaFiltrosHelper.filtrarProdutos(
          [lojaLaricas],
          'açaí',
          {FiltroBuscaMapa.produtos},
        );
        expect(resultadosAcai, isNotEmpty);
        expect(resultadosAcai.first.nomeExibicao, 'Açaí - Copo 300ml');
        expect(resultadosAcai.first.precoTotal, 22.0);
        expect(resultadosAcai.first.precoTexto, 'R\$ 22,00');
        expect(resultadosAcai.first.grupoIdsAcompanhamentos, ['grp_doces']);

        final resultadosCopo = BuscaMapaFiltrosHelper.filtrarProdutos(
          [lojaLaricas],
          'copo 300ml',
          {FiltroBuscaMapa.produtos},
        );
        expect(resultadosCopo.length, 2);
        expect(resultadosCopo.first.nomeExibicao, 'Açaí - Copo 300ml');
        expect(resultadosCopo.last.nomeExibicao, 'Copo 300ml');
        expect(resultadosCopo.last.precoTotal, 2.0);
      },
    );
  });
}
