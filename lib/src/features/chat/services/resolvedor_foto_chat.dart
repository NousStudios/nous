import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nous/src/core/theme/theme_controller.dart';
import 'package:nous/src/features/auth/models/usuario_nous.dart';
import 'package:nous/src/features/auth/providers/auth_provider.dart';
import 'package:nous/src/features/auth/services/contas_nous_service.dart';
import 'package:nous/src/features/chat/models/conversa_chat.dart';
import 'package:nous/src/features/chat/services/chat_service.dart';
import 'package:nous/src/features/pdv/providers/pdv_provider.dart';
import 'package:nous/src/features/pdv/services/imagem_service.dart';
import 'package:nous/src/features/pdv/services/rede_local/cliente_rede_local.dart';
import 'package:provider/provider.dart';

/// Serviço centralizado para resolução e cache rápido de fotos no chat e perfis.
class ResolvedorFotoChat {
  ResolvedorFotoChat._();
  static final ResolvedorFotoChat instancia = ResolvedorFotoChat._();

  final Map<String, String> _cacheFotos = {};

  void registrarFoto(String cpfOuIdentificador, String caminhoFoto) {
    if (caminhoFoto.trim().isEmpty) return;
    final limpo = ChatService.normalizarCpf(cpfOuIdentificador);
    if (limpo.isNotEmpty) {
      _cacheFotos[limpo] = caminhoFoto;
    }
    _cacheFotos[cpfOuIdentificador] = caminhoFoto;
  }

  void registrarContas(List<UsuarioNous> contas) {
    for (final c in contas) {
      if (c.fotoExibicao.isNotEmpty) {
        registrarFoto(c.cpf, c.fotoExibicao);
      }
    }
  }

  String obterFotoEmCache(String cpfOuIdentificador) {
    final limpo = ChatService.normalizarCpf(cpfOuIdentificador);
    if (limpo.isNotEmpty && _cacheFotos.containsKey(limpo)) {
      return _cacheFotos[limpo]!;
    }
    return _cacheFotos[cpfOuIdentificador] ?? '';
  }

  String resolverFotoSincrona({
    required String identificador,
    AuthProvider? auth,
    PdvProvider? pdv,
    Map<String, UsuarioNous>? mapaUsuarios,
  }) {
    if (identificador.isEmpty) return '';

    // 1. Cache local em memória
    final fotoCache = obterFotoEmCache(identificador);
    if (fotoCache.isNotEmpty) return fotoCache;

    final cpfNorm = ChatService.normalizarCpf(identificador);

    // 2. Mapa em memória de usuários Nous
    if (cpfNorm.isNotEmpty &&
        mapaUsuarios != null &&
        mapaUsuarios.containsKey(cpfNorm)) {
      final u = mapaUsuarios[cpfNorm]!;
      if (u.fotoExibicao.isNotEmpty) {
        registrarFoto(cpfNorm, u.fotoExibicao);
        return u.fotoExibicao;
      }
    }

    // 3. AuthProvider
    if (auth != null) {
      var fotoAuth = auth.buscarFotoPorCpf(identificador);
      if (fotoAuth.isEmpty && cpfNorm.isNotEmpty) {
        fotoAuth = auth.buscarFotoPorCpf(cpfNorm);
      }
      if (fotoAuth.isNotEmpty) {
        registrarFoto(identificador, fotoAuth);
        return fotoAuth;
      }
    }

    // 4. PdvProvider
    if (pdv != null) {
      var fotoPdv = pdv.buscarFotoClientePorCpf(identificador) ?? '';
      if (fotoPdv.isEmpty && cpfNorm.isNotEmpty) {
        fotoPdv = pdv.buscarFotoClientePorCpf(cpfNorm) ?? '';
      }
      if (fotoPdv.isNotEmpty) {
        registrarFoto(identificador, fotoPdv);
        return fotoPdv;
      }
    }

    return '';
  }

  Future<String> resolverFotoAssincrona({
    required String identificador,
    AuthProvider? auth,
    PdvProvider? pdv,
    Map<String, UsuarioNous>? mapaUsuarios,
  }) async {
    final sincronica = resolverFotoSincrona(
      identificador: identificador,
      auth: auth,
      pdv: pdv,
      mapaUsuarios: mapaUsuarios,
    );
    if (sincronica.isNotEmpty) return sincronica;

    final cpfNorm = ChatService.normalizarCpf(identificador);
    if (cpfNorm.length == 11) {
      try {
        final u = await ContasNousService.buscarPorCpf(cpfNorm);
        if (u != null && u.fotoExibicao.isNotEmpty) {
          registrarFoto(cpfNorm, u.fotoExibicao);
          return u.fotoExibicao;
        }
      } catch (_) {}
    }

    return '';
  }

  Widget buildAvatar(
    BuildContext context, {
    required AppTheme theme,
    required ConversaChat conversa,
    double raio = 22,
  }) {
    if (conversa.ehGrupo) {
      final providerGrupo = ImagemService.obterImageProvider(conversa.foto);
      if (providerGrupo != null) {
        return CircleAvatar(
          radius: raio,
          backgroundColor: theme.borderColor.withValues(alpha: 0.3),
          backgroundImage: providerGrupo,
        );
      }
      return _AvatarComAutocura(
        conversa: conversa,
        theme: theme,
        raio: raio,
        fotoRemota: conversa.foto,
        ehGrupo: true,
        ehLoja: false,
      );
    }

    final auth = context.read<AuthProvider?>();
    final pdv = context.read<PdvProvider?>();
    final meuCpf = ChatService.normalizarCpf(auth?.contaAtual?.cpf ?? '');
    final minhaFoto = auth?.contaAtual?.fotoExibicao ?? '';
    final minhaFotoBase = auth?.contaAtual?.foto ?? '';

    // 1. Identificar se a conversa é estritamente com uma LOJA
    final bool ehContatoLoja = conversa.ehLoja ||
        conversa.subtitulo.trim().toLowerCase() == 'loja' ||
        conversa.identificador.startsWith('loja_');

    // 2. Se for pessoa física, identifica o CPF do contato (jamais confunde com loja)
    var idParaFoto = '';
    if (!ehContatoLoja) {
      idParaFoto = ChatService.normalizarCpf(conversa.identificador);
      if (idParaFoto.length != 11 && conversa.id.startsWith('user_')) {
        idParaFoto = ChatService.extrairOutroCpf(conversa.id, meuCpf);
      }
    }

    final ehContatoCpf = idParaFoto.length == 11;
    final ehProprioUsuario = !ehContatoLoja && meuCpf.isNotEmpty && idParaFoto == meuCpf;

    // Identifica logo da loja do escopo para profilaxia contra contaminação
    String idLojaEscopo = conversa.lojaId ?? '';
    if (idLojaEscopo.isEmpty && conversa.id.contains('loja_')) {
      final partes = conversa.id.split('_');
      final idx = partes.indexOf('loja');
      if (idx != -1 && idx + 1 < partes.length) {
        idLojaEscopo = 'loja_${partes[idx + 1]}';
      }
    }
    final lojaDoEscopo = pdv != null && idLojaEscopo.isNotEmpty
        ? (pdv.buscarPorId(idLojaEscopo) ??
            (idLojaEscopo.startsWith('loja_')
                ? pdv.buscarPorId(idLojaEscopo.substring(5))
                : null))
        : null;
    final logoLoja = lojaDoEscopo?.logo ?? '';

    String? fotoUsar = conversa.foto;
    if (ehContatoLoja) {
      // Conversa com loja: O avatar é EXCLUSIVAMENTE a logo da loja (ou fallback de loja), NUNCA foto civil de pessoa física!
      fotoUsar = (logoLoja.isNotEmpty && ImagemService.existe(logoLoja))
          ? logoLoja
          : (conversa.foto.isNotEmpty &&
                  ImagemService.existe(conversa.foto) &&
                  conversa.foto != minhaFoto &&
                  conversa.foto != minhaFotoBase
              ? conversa.foto
              : null);
    } else if (!conversa.ehGrupo) {
      if (ehProprioUsuario) {
        // Se a conversa for com o próprio usuário logado (ex.: dono abrindo seu próprio contato
        // na loja como cliente), exibe soberanamente a foto civil do usuário!
        fotoUsar = minhaFoto.isNotEmpty
            ? minhaFoto
            : (minhaFotoBase.isNotEmpty ? minhaFotoBase : conversa.foto);
        if (logoLoja.isNotEmpty && fotoUsar == logoLoja) {
          fotoUsar = minhaFoto.isNotEmpty ? minhaFoto : minhaFotoBase;
        }
      } else if (ehContatoCpf) {
        // Se for um contato de pessoa física com CPF:
        // Jamais exibe logo de loja nem a foto do operador logado
        if (fotoUsar.isEmpty ||
            (logoLoja.isNotEmpty && fotoUsar == logoLoja) ||
            (minhaFoto.isNotEmpty && fotoUsar == minhaFoto) ||
            (minhaFotoBase.isNotEmpty && fotoUsar == minhaFotoBase)) {
          fotoUsar = null;
        }
      }
    }

    ImageProvider? providerFoto;
    if (fotoUsar != null &&
        fotoUsar.isNotEmpty &&
        ImagemService.existe(fotoUsar)) {
      providerFoto = ImagemService.obterImageProvider(fotoUsar);
    }

    String fotoRecuperada = '';

    if (providerFoto == null) {
      if (ehContatoLoja) {
        // Se for Loja no modo social, busca EXCLUSIVAMENTE a logo cadastrada na própria loja no PdvProvider.
        final idLoja = idLojaEscopo.isNotEmpty
            ? idLojaEscopo
            : (conversa.lojaId ?? conversa.identificador);
        final loja = pdv?.buscarPorId(idLoja) ??
            (idLoja.startsWith('loja_')
                ? pdv?.buscarPorId(idLoja.substring(5))
                : null);
        if (loja != null &&
            loja.logo.isNotEmpty &&
            ImagemService.existe(loja.logo) &&
            loja.logo != minhaFoto &&
            loja.logo != minhaFotoBase) {
          providerFoto = ImagemService.obterImageProvider(loja.logo);
        }
      } else {
        if (ehProprioUsuario) {
          fotoRecuperada = minhaFoto.isNotEmpty ? minhaFoto : minhaFotoBase;
        } else if (idParaFoto.isNotEmpty) {
          fotoRecuperada = resolverFotoSincrona(
            identificador: idParaFoto,
            auth: auth,
            pdv: pdv,
          );
        }
        if (fotoRecuperada.isNotEmpty &&
            (logoLoja.isEmpty || fotoRecuperada != logoLoja) &&
            ImagemService.existe(fotoRecuperada)) {
          providerFoto = ImagemService.obterImageProvider(fotoRecuperada);
        }
      }
    }

    if (providerFoto != null) {
      return CircleAvatar(
        radius: raio,
        backgroundColor: theme.borderColor.withValues(alpha: 0.3),
        backgroundImage: providerFoto,
      );
    }

    // Retorna avatar com autocura ativa: se a imagem remota não existe fisicamente no aparelho (ex.: Rosa),
    // baixa imediatamente em background via WiFi e faz transição automática sem travar a interface
    return _AvatarComAutocura(
      conversa: conversa,
      theme: theme,
      raio: raio,
      fotoRemota: fotoRecuperada.isNotEmpty ? fotoRecuperada : fotoUsar,
      cpf: idParaFoto.length == 11 ? idParaFoto : null,
      ehGrupo: false,
      ehLoja: ehContatoLoja,
    );
  }

  void limpar() {
    _cacheFotos.clear();
  }
}

class _AvatarComAutocura extends StatefulWidget {
  final ConversaChat conversa;
  final AppTheme theme;
  final double raio;
  final String? fotoRemota;
  final String? cpf;
  final bool ehGrupo;
  final bool ehLoja;

  const _AvatarComAutocura({
    required this.conversa,
    required this.theme,
    required this.raio,
    this.fotoRemota,
    this.cpf,
    required this.ehGrupo,
    required this.ehLoja,
  });

  @override
  State<_AvatarComAutocura> createState() => _AvatarComAutocuraState();
}

class _AvatarComAutocuraState extends State<_AvatarComAutocura> {
  String? _fotoLocal;
  bool _baixando = false;

  @override
  void initState() {
    super.initState();
    _verificarEBaixar();
  }

  @override
  void didUpdateWidget(covariant _AvatarComAutocura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoRemota != widget.fotoRemota || oldWidget.cpf != widget.cpf) {
      _fotoLocal = null;
      _verificarEBaixar();
    }
  }

  void _verificarEBaixar() {
    final remota = widget.fotoRemota?.trim() ?? '';
    final cpf = widget.cpf?.trim();

    // 1. Tenta resolver localmente primeiro
    if (remota.isNotEmpty) {
      final resolvido = ImagemService.resolverCaminhoExistente(remota);
      if (resolvido != null && File(resolvido).existsSync()) {
        _fotoLocal = resolvido;
        return;
      }
    }

    if (cpf != null && cpf.isNotEmpty) {
      final emCache = ResolvedorFotoChat.instancia.obterFotoEmCache(cpf);
      if (emCache.isNotEmpty) {
        final resolvido = ImagemService.resolverCaminhoExistente(emCache);
        if (resolvido != null && File(resolvido).existsSync()) {
          _fotoLocal = resolvido;
          return;
        }
      }
    }

    // 2. Se não temos localmente, dispara download assíncrono transparente
    if (!_baixando && (remota.isNotEmpty || (cpf != null && cpf.length == 11))) {
      _baixando = true;
      ClienteRedeLocal().baixarImagemRemota(remota, cpf: cpf).then((baixado) {
        if (!mounted) return;
        _baixando = false;
        if (baixado.isNotEmpty && ImagemService.existe(baixado)) {
          setState(() {
            _fotoLocal = baixado;
          });
          if (cpf != null && cpf.isNotEmpty) {
            ResolvedorFotoChat.instancia.registrarFoto(cpf, baixado);
          }
          ChatService.notificarAlteracao();
        }
      }).catchError((_) {
        if (mounted) _baixando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fotoLocal != null && _fotoLocal!.isNotEmpty) {
      final provider = ImagemService.obterImageProvider(_fotoLocal);
      if (provider != null) {
        return CircleAvatar(
          radius: widget.raio,
          backgroundColor: widget.theme.borderColor.withValues(alpha: 0.3),
          backgroundImage: provider,
        );
      }
    }

    if (widget.ehGrupo) {
      return CircleAvatar(
        radius: widget.raio,
        backgroundColor: widget.theme.buttonColor.withValues(alpha: 0.2),
        child: Icon(
          Icons.groups_outlined,
          size: widget.raio * 1.1,
          color: widget.theme.textColor,
        ),
      );
    }

    return CircleAvatar(
      radius: widget.raio,
      backgroundColor: widget.theme.buttonColor.withValues(alpha: 0.15),
      child: Icon(
        widget.ehLoja ? Icons.storefront_outlined : Icons.person_outline,
        size: widget.raio * 1.1,
        color: widget.theme.textColor,
      ),
    );
  }
}
