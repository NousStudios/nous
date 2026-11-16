import 'package:nous/src/features/pdv/models/loja.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';

/// Centraliza a regra de isolamento (tenant) no balcão/servidor local.
/// Impede que o servidor aceite, grave, toque som ou retransmita eventos de PDV
/// (pedidos, estoque, mesas, clientes, loja) pertencentes a lojas que não são
/// operadas por este balcão.
class AutorizadorLojaBalcao {
  AutorizadorLojaBalcao._();

  /// Retorna a [Loja] autorizada caso [lojaIdBruto] seja efetivamente hospedada
  /// ou operada pelo balcão atual; caso contrário retorna `null`.
  static Loja? obterLojaHospedada({
    required String? lojaIdBruto,
    required Loja? lojaAtiva,
    required PdvProvider? pdvProvider,
    String? cpfOperadorBalcao,
  }) {
    final lojaIdAlvo = PdvProvider.normalizarIdLoja((lojaIdBruto ?? '').trim());
    if (lojaIdAlvo.isEmpty) {
      return null;
    }

    if (lojaIdAlvo == PdvProvider.idLojaColetivaNous) {
      return null;
    }

    if (lojaAtiva != null &&
        PdvProvider.normalizarIdLoja(lojaAtiva.id) == lojaIdAlvo) {
      return lojaAtiva;
    }

    if (pdvProvider == null) {
      return null;
    }

    final lojaCandidata = pdvProvider.buscarPorId(lojaIdAlvo);
    if (lojaCandidata == null) {
      return null;
    }

    final cpfNorm = _normalizarCpf(
      cpfOperadorBalcao?.isNotEmpty == true
          ? cpfOperadorBalcao!
          : (pdvProvider.cpfAtual ?? ''),
    );

    if (cpfNorm.length != 11) {
      return null;
    }

    final ehDono = _normalizarCpf(lojaCandidata.cpfDonoOriginal) == cpfNorm;
    final ehMembro = lojaCandidata.membros.any(
      (m) => _normalizarCpf(m.cpf) == cpfNorm,
    );

    return (ehDono || ehMembro) ? lojaCandidata : null;
  }

  static String _normalizarCpf(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');
}
