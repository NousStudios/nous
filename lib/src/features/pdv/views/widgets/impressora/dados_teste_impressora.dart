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
    cliente: 'Rosa Luxemburgo',
    cnpj: '187.119.190-00',
    telefone: '(11) 91871-1919',
    endereco: 'Praça da Liga Espartaquista, 1919 - Berlim',
    descricao: 'Teórica marxista, economista e revolucionária internacionalista',
    itens: [
      MapEntry('1x Reforma ou Revolução?', 16.0),
      MapEntry('1x Greve de Massas, Partido e Sindicatos', 14.0),
      MapEntry('1x A Acumulação do Capital', 28.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Pierre-Joseph Proudhon',
    cnpj: '180.918.650-00',
    telefone: '(11) 91840-1865',
    endereco: 'Rua do Mutualismo, 1840 - Besançon',
    descricao: 'Tipógrafo, economista político e pioneiro do mutualismo',
    itens: [
      MapEntry('1x O Que É a Propriedade?', 18.0),
      MapEntry('1x Do Princípio Federativo', 15.0),
      MapEntry('1x Sistema das Contradições Econômicas', 24.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Vladimir Lenin',
    cnpj: '187.019.240-00',
    telefone: '(11) 91917-1924',
    endereco: 'Avenida dos Sovietes, 1917 - Petrogrado',
    descricao: 'Revolucionário e teórico da organização operária e dos sovietes',
    itens: [
      MapEntry('1x O Estado e a Revolução', 15.0),
      MapEntry('1x Que Fazer?', 14.0),
      MapEntry('1x Imperialismo, Fase Superior do Capitalismo', 16.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Neno Vasco',
    cnpj: '187.819.200-00',
    telefone: '(11) 91906-1920',
    endereco: 'Rua da Terra Livre, 1906 - São Paulo / Lisboa',
    descricao: 'Anarcossindicalista e escritor luso-brasileiro do movimento operário',
    itens: [
      MapEntry('1x Concepção Anarquista do Sindicalismo', 12.0),
      MapEntry('1x Jornal A Terra Livre (Edição Operária)', 5.0),
      MapEntry('1x Da Porta da Europa', 10.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'José Oiticica',
    cnpj: '188.219.570-00',
    telefone: '(11) 91918-1957',
    endereco: 'Largo da Ação Direta, 1918 - Rio de Janeiro',
    descricao: 'Filólogo, professor e militante anarquista brasileiro',
    itens: [
      MapEntry('1x A Doutrina Anarquista ao Alcance de Todos', 10.0),
      MapEntry('1x Jornal Ação Direta (Rio de Janeiro)', 5.0),
      MapEntry('1x Insurreição Operária e Educação Popular', 0.0),
    ],
  ),
  PerfilHistoricoAnarquista(
    cliente: 'Voltairine de Cleyre',
    cnpj: '186.619.120-00',
    telefone: '(11) 91866-1912',
    endereco: 'Travessa do Anarquismo Sem Adjetivos, 1900 - Filadélfia',
    descricao: 'Ensaísta, poeta e oradora do anarquismo sem adjetivos',
    itens: [
      MapEntry('1x Anarquismo e Tradições Americanas', 12.0),
      MapEntry('1x Ação Direta (Conferência Histórica)', 10.0),
      MapEntry('1x Escritos Selecionados pela Liberdade', 0.0),
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
