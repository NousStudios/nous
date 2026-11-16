import 'package:nous/src/features/pdv/models/categoria_loja.dart';
import 'package:nous/src/features/pdv/models/cliente.dart';
import 'package:nous/src/features/pdv/models/fornecedor.dart';
import 'package:nous/src/features/pdv/models/grupo_componentes_loja.dart';
import 'package:nous/src/features/pdv/models/item_loja.dart';
import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/models/membro_loja.dart';
import 'package:nous/src/features/pdv/models/mesa_loja.dart';
import 'package:nous/src/features/pdv/models/movimento_estoque.dart';
import 'package:nous/src/features/pdv/models/pagamento_funcionario.dart';
import 'package:nous/src/features/pdv/models/pedido_loja.dart';
import 'package:nous/src/features/pdv/models/registro_acao.dart';
import 'package:nous/src/features/pdv/models/turno_caixa.dart';
import 'package:nous/src/features/pdv/services/backup_service.dart';

/// Helper responsável pela mesclagem profunda e não-destrutiva de objetos [Loja]
/// durante importações de backup.
class BackupMergeHelper {
  BackupMergeHelper._();

  static Loja mesclarLojas({
    required Loja existente,
    required Loja importada,
  }) {
    final categoriasFinal = existente.categorias.trim().isNotEmpty
        ? existente.categorias
        : importada.categorias;

    final nomeFinal = existente.nome.trim().isNotEmpty
        ? existente.nome
        : importada.nome;
    final cnpjFinal = existente.cnpj.trim().isNotEmpty
        ? existente.cnpj
        : importada.cnpj;
    final telefoneFinal = existente.telefone.trim().isNotEmpty
        ? existente.telefone
        : importada.telefone;
    final enderecoFinal = existente.endereco.trim().isNotEmpty
        ? existente.endereco
        : importada.endereco;
    final numeroFinal = existente.numero.trim().isNotEmpty
        ? existente.numero
        : importada.numero;
    final emailFinal = existente.email.trim().isNotEmpty
        ? existente.email
        : importada.email;
    final redesSociaisFinal = existente.redesSociais.trim().isNotEmpty
        ? existente.redesSociais
        : importada.redesSociais;
    final tagsFinal = existente.tags.trim().isNotEmpty
        ? existente.tags
        : importada.tags;
    final logoFinal = existente.logo.trim().isNotEmpty
        ? existente.logo
        : importada.logo;

    final itensMesclados = <ItemLoja>[...existente.itensLoja];
    for (final itemImp in importada.itensLoja) {
      final idx = itensMesclados.indexWhere((i) {
        if (i.id == itemImp.id) return true;
        return i.nome.trim().isNotEmpty &&
            i.nome.trim().toLowerCase() == itemImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        itensMesclados.add(itemImp);
      } else {
        final atual = itensMesclados[idx];
        final imagensUnidas =
            <String>{...atual.imagens, ...itemImp.imagens}.toList();
        final variantesUnidas = <VarianteItem>[...atual.variantes];
        for (final v in itemImp.variantes) {
          if (!variantesUnidas.any((existenteV) =>
              existenteV.nome.trim().toLowerCase() ==
              v.nome.trim().toLowerCase())) {
            variantesUnidas.add(v);
          }
        }

        itensMesclados[idx] = atual.copyWith(
          tipo: atual.tipo ?? itemImp.tipo,
          preco: atual.preco.trim().isNotEmpty ? atual.preco : itemImp.preco,
          precoCusto: atual.precoCusto.trim().isNotEmpty
              ? atual.precoCusto
              : itemImp.precoCusto,
          codigoBarras: atual.codigoBarras.trim().isNotEmpty
              ? atual.codigoBarras
              : itemImp.codigoBarras,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : itemImp.descricao,
          estoqueMinimo: atual.estoqueMinimo.trim().isNotEmpty
              ? atual.estoqueMinimo
              : itemImp.estoqueMinimo,
          unidadeBase: atual.unidadeBase != UnidadeItemLoja.un
              ? atual.unidadeBase
              : itemImp.unidadeBase,
          consumoPorVenda: atual.consumoPorVenda != 1.0
              ? atual.consumoPorVenda
              : itemImp.consumoPorVenda,
          imagens: imagensUnidas,
          variantes: variantesUnidas,
          possuiDelivery: atual.possuiDelivery || itemImp.possuiDelivery,
        );
      }
    }

    final clientesMesclados = <Cliente>[...existente.clientesLoja];
    for (final cImp in importada.clientesLoja) {
      final idx = clientesMesclados.indexWhere((c) {
        if (c.id == cImp.id) return true;
        if (BackupService.mesmoDocumento(c.cnpj, cImp.cnpj)) return true;
        return c.nome.trim().isNotEmpty &&
            c.nome.trim().toLowerCase() == cImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        clientesMesclados.add(cImp);
      } else {
        final atual = clientesMesclados[idx];
        clientesMesclados[idx] = atual.copyWith(
          cnpj: atual.cnpj.trim().isNotEmpty ? atual.cnpj : cImp.cnpj,
          telefone: atual.telefone.trim().isNotEmpty
              ? atual.telefone
              : cImp.telefone,
          endereco: atual.endereco.trim().isNotEmpty
              ? atual.endereco
              : cImp.endereco,
          numero: atual.numero.trim().isNotEmpty ? atual.numero : cImp.numero,
          email: atual.email.trim().isNotEmpty ? atual.email : cImp.email,
          redesSociais: atual.redesSociais.trim().isNotEmpty
              ? atual.redesSociais
              : cImp.redesSociais,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : cImp.descricao,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : cImp.foto,
        );
      }
    }

    final categoriasLojaMescladas =
        <CategoriaLoja>[...existente.categoriasLoja];
    for (final catImp in importada.categoriasLoja) {
      final idx = categoriasLojaMescladas.indexWhere((c) {
        if (c.id == catImp.id) return true;
        return c.nome.trim().isNotEmpty &&
            c.nome.trim().toLowerCase() == catImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        categoriasLojaMescladas.add(catImp);
      } else {
        final atual = categoriasLojaMescladas[idx];
        final itemIdsUnidos =
            <String>{...atual.itemIds, ...catImp.itemIds}.toList();
        final grupoIdsUnidos =
            <String>{...atual.grupoIds, ...catImp.grupoIds}.toList();
        categoriasLojaMescladas[idx] = atual.copyWith(
          itemIds: itemIdsUnidos,
          grupoIds: grupoIdsUnidos,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : catImp.foto,
          tipo: atual.tipo ?? catImp.tipo,
        );
      }
    }

    final fornecedoresMesclados = <Fornecedor>[...existente.fornecedoresLoja];
    for (final fImp in importada.fornecedoresLoja) {
      final idx = fornecedoresMesclados.indexWhere((f) {
        if (f.id == fImp.id) return true;
        if (BackupService.mesmoDocumento(f.cnpj, fImp.cnpj)) return true;
        return f.nome.trim().isNotEmpty &&
            f.nome.trim().toLowerCase() == fImp.nome.trim().toLowerCase();
      });

      if (idx == -1) {
        fornecedoresMesclados.add(fImp);
      } else {
        final atual = fornecedoresMesclados[idx];
        fornecedoresMesclados[idx] = atual.copyWith(
          cnpj: atual.cnpj.trim().isNotEmpty ? atual.cnpj : fImp.cnpj,
          telefone: atual.telefone.trim().isNotEmpty
              ? atual.telefone
              : fImp.telefone,
          endereco: atual.endereco.trim().isNotEmpty
              ? atual.endereco
              : fImp.endereco,
          numero: atual.numero.trim().isNotEmpty ? atual.numero : fImp.numero,
          email: atual.email.trim().isNotEmpty ? atual.email : fImp.email,
          redesSociais: atual.redesSociais.trim().isNotEmpty
              ? atual.redesSociais
              : fImp.redesSociais,
          descricao: atual.descricao.trim().isNotEmpty
              ? atual.descricao
              : fImp.descricao,
          foto: atual.foto.trim().isNotEmpty ? atual.foto : fImp.foto,
        );
      }
    }

    final gruposMesclados =
        <GrupoComponentesLoja>[...existente.gruposComponentesLoja];
    for (final gImp in importada.gruposComponentesLoja) {
      final idx = gruposMesclados.indexWhere((g) {
        if (g.id == gImp.id) return true;
        return g.nome.trim().isNotEmpty &&
            g.nome.trim().toLowerCase() == gImp.nome.trim().toLowerCase();
      });
      if (idx == -1) {
        gruposMesclados.add(gImp);
      }
    }

    final acoesMescladas = <RegistroAcao>[...existente.acoes];
    for (final aImp in importada.acoes) {
      if (!acoesMescladas.any((a) => a.id == aImp.id)) {
        acoesMescladas.add(aImp);
      }
    }
    acoesMescladas.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final pedidosMesclados = <PedidoLoja>[...existente.pedidosLoja];
    for (final pImp in importada.pedidosLoja) {
      if (!pedidosMesclados.any((p) => p.id == pImp.id)) {
        pedidosMesclados.add(pImp);
      }
    }
    pedidosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final estoqueMesclado = <MovimentoEstoque>[...existente.movimentosEstoque];
    for (final mImp in importada.movimentosEstoque) {
      if (!estoqueMesclado.any((m) => m.id == mImp.id)) {
        estoqueMesclado.add(mImp);
      }
    }
    estoqueMesclado.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final pagamentosMesclados =
        <PagamentoFuncionario>[...existente.pagamentosFuncionarios];
    for (final pagImp in importada.pagamentosFuncionarios) {
      if (!pagamentosMesclados.any((pag) => pag.id == pagImp.id)) {
        pagamentosMesclados.add(pagImp);
      }
    }
    pagamentosMesclados.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    final membrosMesclados = <MembroLoja>[...existente.membros];
    for (final mImp in importada.membros) {
      if (!membrosMesclados.any((m) => m.cpf == mImp.cpf)) {
        membrosMesclados.add(mImp);
      }
    }

    final mesasMescladas = <MesaLoja>[...existente.mesas];
    for (final mesaImp in importada.mesas) {
      if (!mesasMescladas.any((m) =>
          m.id == mesaImp.id ||
          (m.numero.trim().isNotEmpty &&
              m.numero.trim() == mesaImp.numero.trim()))) {
        mesasMescladas.add(mesaImp);
      }
    }

    final galeriaFinal =
        <String>{...existente.galeria, ...importada.galeria}.toList();
    final arquivosFinal =
        <String>{...existente.arquivos, ...importada.arquivos}.toList();
    final musicasFinal =
        <String>{...existente.musicas, ...importada.musicas}.toList();
    final videosFinal =
        <String>{...existente.videos, ...importada.videos}.toList();
    final audiosFinal =
        <String>{...existente.arquivosAudio, ...importada.arquivosAudio}
            .toList();
    final descricoesFinal = <String, String>{
      ...importada.descricoesAnexos,
      ...existente.descricoesAnexos,
    };

    final impressoraFinal = (existente.configuracoesImpressora.nomeImpressora.isNotEmpty ||
            existente.configuracoesImpressora.enderecoRede.isNotEmpty)
        ? existente.configuracoesImpressora
        : importada.configuracoesImpressora;

    final turnosMesclados = <TurnoCaixa>[...existente.turnosCaixa];
    for (final tImp in importada.turnosCaixa) {
      if (!turnosMesclados.any((t) => t.id == tImp.id)) {
        turnosMesclados.add(tImp);
      }
    }
    turnosMesclados.sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));

    final atalhosFinais = <String, String>{
      ...importada.atalhosTeclado,
      ...existente.atalhosTeclado,
    };

    final tempoFinal = existente.tempoConclusaoMinutos > 0
        ? existente.tempoConclusaoMinutos
        : importada.tempoConclusaoMinutos;

    final sonsFinal = <String, String>{
      ...importada.sonsAlertas,
      ...existente.sonsAlertas,
    };

    return existente.copyWith(
      nome: nomeFinal,
      cnpj: cnpjFinal,
      telefone: telefoneFinal,
      endereco: enderecoFinal,
      numero: numeroFinal,
      email: emailFinal,
      redesSociais: redesSociaisFinal,
      categorias: categoriasFinal,
      tags: tagsFinal,
      logo: logoFinal,
      categoriasLoja: categoriasLojaMescladas,
      itensLoja: itensMesclados,
      gruposComponentesLoja: gruposMesclados,
      clientesLoja: clientesMesclados,
      fornecedoresLoja: fornecedoresMesclados,
      pedidosLoja: pedidosMesclados,
      acoes: acoesMescladas,
      membros: membrosMesclados,
      mesas: mesasMescladas,
      movimentosEstoque: estoqueMesclado,
      pagamentosFuncionarios: pagamentosMesclados,
      turnosCaixa: turnosMesclados,
      galeria: galeriaFinal,
      arquivos: arquivosFinal,
      musicas: musicasFinal,
      videos: videosFinal,
      arquivosAudio: audiosFinal,
      descricoesAnexos: descricoesFinal,
      configuracoesImpressora: impressoraFinal,
      sonsAlertas: sonsFinal,
      atalhosTeclado: atalhosFinais,
      tempoConclusaoMinutos: tempoFinal,
      layoutExpandido: existente.layoutExpandido,
      tipoLayoutMaior: existente.tipoLayoutMaior.isNotEmpty
          ? existente.tipoLayoutMaior
          : importada.tipoLayoutMaior,
    );
  }
}
