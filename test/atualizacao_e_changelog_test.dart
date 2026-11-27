import 'package:flutter_test/flutter_test.dart';
import 'package:nous/src/core/services/atualizacao_service.dart';
import 'package:nous/src/core/services/changelog_service.dart';
import 'package:nous/src/core/services/sessao_retorno_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ChangelogService - Sanitização Amigável para o Usuário', () {
    test('remove referências a arquivos .dart e links de código', () {
      const linhaBruta =
          'Implementada navegação adaptável Desktop vs Mobile ([barra_navegacao_widget.dart](file:///d:/Nous/nous/lib/barra.dart)); '
          'no Celular barra estilo WhatsApp (`BarraNavegacaoWidget`)';

      final resultado = ChangelogService.sanitizarLinhaParaUsuario(linhaBruta);

      expect(resultado, isNotNull);
      expect(resultado!.contains('.dart'), isFalse);
      expect(resultado.contains('file:///'), isFalse);
      expect(resultado.contains('`'), isFalse);
      expect(resultado.contains('Implementada navegação adaptável'), isTrue);
    });

    test('remove escopos técnicos como (`chat`, `pdv`)', () {
      const linhaBruta = '**Mensageria Estilo WhatsApp + Discord (`chat`, `pdv`):**';
      final resultado = ChangelogService.sanitizarLinhaParaUsuario(linhaBruta);

      expect(resultado, isNotNull);
      expect(resultado!.contains('chat, pdv'), isFalse);
      expect(resultado.contains('`'), isFalse);
      expect(resultado.startsWith('Mensageria Estilo WhatsApp + Discord'), isTrue);
    });

    test('descarta itens puramente técnicos de documentação interna e refatoração', () {
      const linha1 = 'Adicionada diretriz de delegação econômica para subagentes em AGENTS.md';
      const linha2 = 'Configurada a skill reatividade-e-exclusao e tabela em MAPA_DO_APP.md';
      const linha3 = 'Completados os 17 campos ausentes em PedidoLoja.copyWith';

      expect(ChangelogService.sanitizarLinhaParaUsuario(linha1), isNull);
      expect(ChangelogService.sanitizarLinhaParaUsuario(linha2), isNull);
      expect(ChangelogService.sanitizarLinhaParaUsuario(linha3), isNull);
    });
  });

  group('SessaoRetorno - Serialização e Desserialização', () {
    test('converte para json e restaura com integridade', () {
      const sessaoOriginal = SessaoRetorno(
        cpf: '12345678900',
        modoVisitante: false,
        lojaId: 'loja_restaurante_central',
        abaLoja: 1,
        slotPrincipal: 0,
        subIndicePrincipal: 1,
      );

      final json = sessaoOriginal.toJson();
      final sessaoRestaurada = SessaoRetorno.fromJson(json);

      expect(sessaoRestaurada.cpf, '12345678900');
      expect(sessaoRestaurada.modoVisitante, isFalse);
      expect(sessaoRestaurada.lojaId, 'loja_restaurante_central');
      expect(sessaoRestaurada.abaLoja, 1);
      expect(sessaoRestaurada.slotPrincipal, 0);
      expect(sessaoRestaurada.subIndicePrincipal, 1);
    });

    test('trata nulos com segurança', () {
      final sessaoVazia = SessaoRetorno.fromJson({});
      expect(sessaoVazia.cpf, '');
      expect(sessaoVazia.modoVisitante, isFalse);
      expect(sessaoVazia.lojaId, isNull);
    });
  });

  group('AtualizacaoService - Comparação de Versões Semver e Detecção de Releases', () {
    test('compara versões corretamente', () {
      expect(AtualizacaoService.versaoMaior('1.1.55', '1.1.54'), isTrue);
      expect(AtualizacaoService.versaoMaior('1.2.0', '1.1.99'), isTrue);
      expect(AtualizacaoService.versaoMaior('2.0.0', '1.99.99'), isTrue);
      expect(AtualizacaoService.versaoMaior('1.1.54', '1.1.54'), isFalse);
      expect(AtualizacaoService.versaoMaior('1.1.53', '1.1.54'), isFalse);
    });

    test('extrai número de build de títulos e corpo da release GitHub', () {
      expect(
        AtualizacaoService.extrairBuildRelease('Nous v1.1.63 (Build 165)', ''),
        165,
      );
      expect(
        AtualizacaoService.extrairBuildRelease('Nous v1.2.0', 'Versão compilada no build 170 com melhorias'),
        170,
      );
      expect(
        AtualizacaoService.extrairBuildRelease('Release sem build', 'Sem menção'),
        isNull,
      );
    });

    test('ehMaisRecente detecta versões maiores e builds superiores', () {
      // Caso 1: Versão semver estritamente maior
      expect(
        AtualizacaoService.ehMaisRecente(
          versaoRemota: '1.1.64',
          versaoLocal: '1.1.63',
          buildRemoto: 165,
          buildLocal: 165,
        ),
        isTrue,
      );

      // Caso 2: Mesma versão semver mas build superior (hotfix ou re-release)
      expect(
        AtualizacaoService.ehMaisRecente(
          versaoRemota: '1.1.63',
          versaoLocal: '1.1.63',
          buildRemoto: 166,
          buildLocal: 165,
        ),
        isTrue,
      );

      // Caso 3: Mesma versão e mesmo build (já atualizado)
      expect(
        AtualizacaoService.ehMaisRecente(
          versaoRemota: '1.1.63',
          versaoLocal: '1.1.63',
          buildRemoto: 165,
          buildLocal: 165,
        ),
        isFalse,
      );

      // Caso 4: Versão remota inferior
      expect(
        AtualizacaoService.ehMaisRecente(
          versaoRemota: '1.1.62',
          versaoLocal: '1.1.63',
          buildRemoto: 164,
          buildLocal: 165,
        ),
        isFalse,
      );
    });

    test('monitoramento contínuo pode ser iniciado e parado sem erros', () {
      AtualizacaoService.iniciarMonitoramentoContinuo(
        intervalo: const Duration(seconds: 1),
      );
      AtualizacaoService.pararMonitoramentoContinuo();
    });
  });
}
