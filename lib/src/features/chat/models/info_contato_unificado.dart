class InfoContatoUnificado {
  final String identificador;
  final String cpfNormalizado;
  final String titulo;
  final String subtitulo;
  final String foto;
  final bool ehMembro;
  final bool ehCliente;

  const InfoContatoUnificado({
    required this.identificador,
    required this.cpfNormalizado,
    required this.titulo,
    required this.subtitulo,
    this.foto = '',
    this.ehMembro = false,
    this.ehCliente = false,
  });

  InfoContatoUnificado copyWith({
    String? titulo,
    String? foto,
    String? subtitulo,
    bool? ehCliente,
  }) {
    return InfoContatoUnificado(
      identificador: identificador,
      cpfNormalizado: cpfNormalizado,
      titulo: titulo ?? this.titulo,
      subtitulo: subtitulo ?? this.subtitulo,
      foto: foto ?? this.foto,
      ehMembro: ehMembro,
      ehCliente: ehCliente ?? this.ehCliente,
    );
  }
}
