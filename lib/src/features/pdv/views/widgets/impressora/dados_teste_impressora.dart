class PerfilHistoricoAnarquista {
  final String cliente;
  final String cnpj;
  final String telefone;
  final String endereco;
  final String descricao;
  final List<MapEntry<String, double>> itens;

  const PerfilHistoricoAnarquista({
    required this.cliente,
    required this.cnpj,
    required this.telefone,
    required this.endereco,
    required this.descricao,
    required this.itens,
  });
}

const List<PerfilHistoricoAnarquista> kPerfisHistoricosAnarquistas = [
  PerfilHistoricoAnarquista(
    cliente: 'Nestor Makhno',
    cnpj: '191.719.210-00',
    telefone: '(11) 91917-1921',
    endereco: 'Rua Nestor Makhno, 1917 - Comuna de Huliaipole',
    descricao: 'Comandante do Exército Insurrecional Revolucionário da Ucrânia',
    itens: [
      MapEntry('1x Revolução Social', 0.0),
      MapEntry('1x Autogerenciamento dos Meios de Produção', 0.0),
      MapEntry('1x Plataforma Organizacional dos Anarquistas', 20.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Piotr Kropotkin',
    cnpj: '184.219.210-00',
    telefone: '(11) 91892-1921',
    endereco: 'Alameda da Conquista do Pão, 1892 - Dmitrov',
    descricao: 'Teórico do comunismo anárquico e da cooperação entre os seres',
    itens: [
      MapEntry('1x A Conquista do Pão (Edição Popular)', 15.0),
      MapEntry('1x Apoio Mútuo: Fator de Evolução', 18.0),
      MapEntry('1x Pão e Liberdade para Toda a Comunidade', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Mikhail Bakunin',
    cnpj: '181.418.760-00',
    telefone: '(11) 91868-1876',
    endereco: 'Avenida da Aliança dos Trabalhadores, 1868 - Berna',
    descricao: 'Defensor intransigente da liberdade coletiva e do federalismo',
    itens: [
      MapEntry('1x Deus e o Estado (Tradução Coletiva)', 12.0),
      MapEntry('1x Destruição do Estado e das Classes', 0.0),
      MapEntry('1x Federação Internacional de Trabalhadores Livres', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Emma Goldman',
    cnpj: '186.919.400-00',
    telefone: '(11) 91910-1940',
    endereco: 'Travessa Mãe Terra, 1910 - East Village',
    descricao: 'Militante anarcofeminista, conferencista e escritora',
    itens: [
      MapEntry('1x Se Não Posso Dançar, Não É Minha Revolução', 0.0),
      MapEntry('1x Anarquismo e Outros Ensaios', 14.0),
      MapEntry('1x Emancipação dos Corpos e das Mentes', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Errico Malatesta',
    cnpj: '185.319.320-00',
    telefone: '(11) 91897-1932',
    endereco: 'Rua Volontà, 1897 - Ancona',
    descricao: 'Agitador operário e teórico da ação direta organizada',
    itens: [
      MapEntry('1x Entre Camponeses: Diálogo Emancipador', 8.0),
      MapEntry('1x A Anarquia e o Método da Liberdade', 10.0),
      MapEntry('1x Solidariedade Humana Contra a Exploração', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Maria Lacerda de Moura',
    cnpj: '188.719.450-00',
    telefone: '(11) 91923-1945',
    endereco: 'Rua da Escola Nova, 1923 - Barbacena / SP',
    descricao: 'Pioneira do anarcofeminismo e da educação racionalista no Brasil',
    itens: [
      MapEntry('1x Educação Libertária e Amor Livre', 0.0),
      MapEntry('1x Revista Renascença nº 1', 10.0),
      MapEntry('1x Emancipação Integral da Mulher', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Edgard Leuenroth',
    cnpj: '188.119.680-00',
    telefone: '(11) 91917-1968',
    endereco: 'Rua da Mooca e Brás, 1917 - São Paulo',
    descricao: 'Articulação operária da primeira grande greve geral do Brasil',
    itens: [
      MapEntry('1x Jornada de Trabalho de 8 Horas Sem Patrão', 0.0),
      MapEntry('1x Jornal A Plebe (Edição de Resistência)', 5.0),
      MapEntry('1x Fundo Sindical de Solidariedade Mútua', 25.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Louise Michel',
    cnpj: '187.103.180-00',
    telefone: '(11) 91871-0318',
    endereco: 'Boulevard dos Communards, 1871 - Montmartre',
    descricao: 'Educadora libertária e combatente das barricadas da Comuna',
    itens: [
      MapEntry('1x Democracia Direta e Mandato Revogável', 0.0),
      MapEntry('1x Oficinas de Trabalho Coletivo Autogeridas', 0.0),
      MapEntry('1x Memórias da Comuna Revolucionária', 22.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Lucía Sánchez Saornil',
    cnpj: '193.607.190-00',
    telefone: '(11) 91936-0719',
    endereco: 'Rambla das Coletivizações, 1936 - Barcelona',
    descricao: 'Poeta e cofundadora da federação libertária Mujeres Libres',
    itens: [
      MapEntry('1x Coletivização Agrária de Aragão', 0.0),
      MapEntry('1x Revista Mujeres Libres nº 1', 12.0),
      MapEntry('1x Auto-organização Contra o Fascismo', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Trabalhador Autogestionário Nous',
    cnpj: '072.072.072-00',
    telefone: '(11) 97272-0720',
    endereco: 'Viela Ação Direta Popular, 72 - Brasil',
    descricao: 'Poder popular sem intermediários, autogestão real e soberania',
    itens: [
      MapEntry('1x Unidade Tática e Coerência Prática', 0.0),
      MapEntry('1x O Estado na Mão do Povo Como Software', 0.0),
      MapEntry('1x Plataforma Livre Nous (Acesso Soberano)', 0.0),
    ],
  ),
];

const Map<String, String> kRotulosCamposCliente = {
  'cnpj': 'CNPJ',
  'telefone': 'Telefone',
  'endereco': 'Endereço',
  'email': 'Email',
  'redesSociais': 'Redes sociais',
  'descricao': 'Descrição',
};
