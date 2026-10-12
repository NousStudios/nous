import 'package:flutter/material.dart';

class ModeloLayoutDesktop {
  final String id;
  final String titulo;
  final String subtitulo;
  final String descricao;
  final IconData icone;
  final List<String> caracteristicas;
  final double larguraMaxima;

  const ModeloLayoutDesktop({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.icone,
    required this.caracteristicas,
    required this.larguraMaxima,
  });

  static const List<ModeloLayoutDesktop> modelosDisponiveis = [
    ModeloLayoutDesktop(
      id: 'balcao_operacional',
      titulo: 'Balcão Operacional / Varejo Ágil',
      subtitulo: 'PDV Caixa para alto fluxo com leitor de código de barras',
      descricao:
          'Projetado para operadores de caixa no comércio tradicional (mercearias, drogarias, padarias). Em tela cheia, disponibiliza a barra lateral com teclas de atalho F1–F12 em evidência, busca contínua para leitores de código de barras e catálogo fluido.',
      icone: Icons.point_of_sale_outlined,
      caracteristicas: [
        'Barra de atalhos rápidos F1–F12 com badges de alta visibilidade',
        'Vitrine central fluida com cards otimizados para clique rápido',
        'Leitor de código de barras USB integrado com bip contínuo',
        'Rodapé operacional com saldo de caixa e fechamento ágil',
      ],
      larguraMaxima: double.infinity,
    ),
    ModeloLayoutDesktop(
      id: 'painel_duplo',
      titulo: 'Painel Duplo Comercial / Vitrine & Categorias',
      subtitulo: 'Divisão em painéis paralelos com navegação por categorias',
      descricao:
          'Estrutura em duas colunas amplas consagrada em supermercados e lojas de variedades: navegação imediata por categorias e grupos à esquerda e vitrine de catálogo espaçosa à direita, aproveitando toda a extensão horizontal do monitor.',
      icone: Icons.view_sidebar_outlined,
      caracteristicas: [
        'Painel lateral fixo de categorias e grupos de componentes',
        'Catálogo de produtos em grade moderna expansiva',
        'Abas de gerenciamento distribuídas em colunas paralelas',
        'Ideal para lojas com muitos produtos e departamentos',
      ],
      larguraMaxima: double.infinity,
    ),
    ModeloLayoutDesktop(
      id: 'totem_touch',
      titulo: 'Totem & Balcão Touchscreen',
      subtitulo: 'Elementos ampliados para telas sensíveis ao toque',
      descricao:
          'Otimizado para estações de autoatendimento, monitores touch de frente de caixa ou tablets desktop. Botões com área de toque generosa, tipografia destacada e fotos grandes para operação sem mouse ou teclado físico.',
      icone: Icons.touch_app_outlined,
      caracteristicas: [
        'Botões táteis de alto contraste e área de toque expandida',
        'Cards de produtos com fotos grandes e preços em destaque',
        'Teclado numérico virtual acessível com um toque',
        'Navegação simplificada para clientes e operadores rápidos',
      ],
      larguraMaxima: double.infinity,
    ),
    ModeloLayoutDesktop(
      id: 'restaurante_comandas',
      titulo: 'Salão, Mesas & Comandas',
      subtitulo: 'Especialização para bares, lanchonetes e alimentação',
      descricao:
          'Layout panorâmico voltado para a rotina de restaurantes: mapa visual de mesas e comandas abertas à esquerda, acompanhamentos e consumo no centro, e atalhos rápidos para fechamento e conferência no balcão.',
      icone: Icons.restaurant_outlined,
      caracteristicas: [
        'Visão panorâmica de mesas livres, ocupadas e reservadas',
        'Acesso imediato a comandas individuais e pedidos da cozinha',
        'Divisão de conta igualitária calculada com 1 clique',
        'Adição rápida de adicionais e componentes de pratos',
      ],
      larguraMaxima: double.infinity,
    ),
    ModeloLayoutDesktop(
      id: 'dashboard_executivo',
      titulo: 'Dashboard Gerencial & Gestão Coletiva',
      subtitulo: 'Visão executiva com transparência radical e fluxo em tempo real',
      descricao:
          'Painel de controle unificado com máxima transparência: cards de métricas financeiras em tempo real (entradas, saídas, saldo, projeções), histórico de auditoria de ações ao vivo e visão completa das vendas do dia em tela cheia.',
      icone: Icons.dashboard_customize_outlined,
      caracteristicas: [
        'Cards de métricas financeiras e fluxo de caixa ao vivo',
        'Trilha de auditoria transparente com visualização de autores',
        'Gestão de trabalhadores e retiradas em colunas executivas',
        'Ideal para fechamentos de turno e deliberação da equipe',
      ],
      larguraMaxima: double.infinity,
    ),
  ];

  static ModeloLayoutDesktop obterPorId(String id) {
    return modelosDisponiveis.firstWhere(
      (m) => m.id == id,
      orElse: () => modelosDisponiveis.first,
    );
  }
}
