---
name: modelo-persistido
description: Use whenever adding or modifying a field on a persisted model in the Nous project.
---

# Modelos Persistidos e Serialização JSON no Nous

Diretrizes obrigatórias para criação, alteração ou extensão de campos em qualquer modelo de dados serializado e persistido localmente no Nous.

---

## 1. Modelos do Projeto

Aplica-se a todos os modelos persistidos em disco (banco local SQLite via `BancoDadosService` e arquivos de backup JSON):

### Modelos Principais
- **`UsuarioNous`** (`lib/src/features/auth/models/usuario_nous.dart`): Identidade cidadã e dados civis.
- **`Loja`** (`lib/src/features/pdv/models/loja.dart`): Dados da loja, cofre e configurações operacionais.
- **`Cliente`** (`lib/src/features/pdv/models/cliente.dart`): Cadastro de clientes com CPF/CNPJ.
- **`Fornecedor`** (`lib/src/features/pdv/models/fornecedor.dart`): Cadastro de fornecedores.
- **`PedidoLoja`** (`lib/src/features/pdv/models/pedido_loja.dart`): Pedidos, comandas e pagamentos.
- **`ItemLoja`** (`lib/src/features/pdv/models/item_loja.dart`): Produtos, ficha técnica e controle de estoque.
- **`CategoriaLoja`** (`lib/src/features/pdv/models/categoria_loja.dart`): Categorias de itens.
- **`GrupoComponentesLoja`** (`lib/src/features/pdv/models/grupo_componentes_loja.dart`): Grupos de acompanhamentos e adicionais.
- **`MembroLoja`** (`lib/src/features/pdv/models/membro_loja.dart`): Papéis operacionais e permissões na loja.
- **`ReferenciaLoja`** (`lib/src/features/pdv/models/referencia_loja.dart`): Ponte de acesso ao cofre do titular.
- **`MovimentoEstoque`** (`lib/src/features/pdv/models/movimento_estoque.dart`): Histórico de entradas/saídas de estoque.
- **`PagamentoFuncionario`** (`lib/src/features/pdv/models/pagamento_funcionario.dart`): Registro de rateio e retiradas financeiras.
- **`RegistroAcao`** (`lib/src/features/pdv/models/registro_acao.dart`): Trilha de auditoria transparente.
- **`ConviteLoja`** (`lib/src/features/notificacoes/models/convite_loja.dart`): Convites, governança e deliberações.
- **`ConfiguracoesImpressora`** (`lib/src/features/pdv/models/configuracoes_impressora.dart`): Parâmetros de impressão térmica 58mm.
- **`AppTheme`** (`lib/src/core/theme/theme_controller.dart`): Esquema de temas e customizações visuais.

### Submodelos Serializados
- **`ItemVendido`**, **`PagamentoParcial`**, **`AcompanhamentoEscolhido`** (em `pedido_loja.dart`).
- **`ComponenteItem`** (em `item_loja.dart`).

---

## 2. As Quatro Regras Fundamentais de Engenharia

### 1. Atualização Quádrupla Obrigatória
Sempre que adicionar ou modificar qualquer campo, atualize os 4 pontos sem exceção:
1. **Construtor da classe** (com parâmetro nomeado).
2. **Método `copyWith`** (preservando o valor caso receba nulo).
3. **Método `toJson`** (chave correspondente no mapa).
4. **Factory `fromJson`** (com leitura segura e valor padrão).

### 2. Valores Padrão Obrigatórios no `fromJson`
**Nunca confie em nulos vindos do disco.** Versões anteriores ou backups antigos podem não conter campos novos. Sempre use fallbacks:
- `json['campo'] as String? ?? ''`
- `(json['valor'] as num?)?.toDouble() ?? 0.0`
- `json['ativo'] as bool? ?? false`
- `(json['itens'] as List<dynamic>?)?.map(...).toList() ?? []`

### 3. Enums Defensivos com `firstWhere` e `orElse`
Nunca acesse enums por índice ou `byName` sem fallback defensivo. Se o valor for desconhecido ou renomeado, o sistema deve assumir o enum padrão sem quebrar:
```dart
tipo: TipoMovimentoEstoque.values.firstWhere(
  (e) => e.name == (json['tipo'] as String?),
  orElse: () => TipoMovimentoEstoque.ajusteManual,
)
```

### 4. Aviso Proativo de Limpeza de Cache
Ao finalizar a edição de qualquer modelo persistido, avise obrigatoriamente o desenvolvedor para rodar no terminal:
```bash
flutter clean && flutter pub get
```

---

## 3. Exemplo Canônico de Implementação

```dart
class ExemploModelo {
  final String id;
  final String nome;
  final double preco;
  final bool ativo;

  const ExemploModelo({
    required this.id,
    required this.nome,
    this.preco = 0.0,
    this.ativo = true,
  });

  ExemploModelo copyWith({
    String? id,
    String? nome,
    double? preco,
    bool? ativo,
  }) {
    return ExemploModelo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'preco': preco,
      'ativo': ativo,
    };
  }

  factory ExemploModelo.fromJson(Map<String, dynamic> json) {
    return ExemploModelo(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      preco: (json['preco'] as num?)?.toDouble() ?? 0.0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}
```
