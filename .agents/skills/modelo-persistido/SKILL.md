---
name: modelo-persistido
description: Use whenever adding or modifying a field on a persisted model in the Nous project.
---

# Modelos Persistidos e Serialização JSON no Nous

Guia rápido e cirúrgico para criação e alteração de campos em modelos serializados e persistidos (SQLite local e backups JSON).

---

## 1. Modelos Principais do Projeto

- **`Loja`** (`pdv/models/loja.dart`)
- **`UsuarioNous`** (`auth/models/usuario_nous.dart`)
- **`Cliente`** (`pdv/models/cliente.dart`)
- **`Fornecedor`** (`pdv/models/fornecedor.dart`)
- **`PedidoLoja`** (`pdv/models/pedido_loja.dart`)
- **`PedidoProgramado`** (`pdv/models/pedido_programado.dart`)
- **`ItemLoja`** (`pdv/models/item_loja.dart`)
- **`CategoriaLoja`** (`pdv/models/categoria_loja.dart`)
- **`GrupoComponentesLoja`** (`pdv/models/grupo_componentes_loja.dart`)
- **`MembroLoja`** (`pdv/models/membro_loja.dart`)
- **`CargoLoja`** (`pdv/models/cargo_loja.dart`)
- **`MesaLoja`** (`pdv/models/mesa_loja.dart`)
- **`ReferenciaLoja`** (`pdv/models/referencia_loja.dart`)
- **`MovimentoEstoque`** (`pdv/models/movimento_estoque.dart`)
- **`PagamentoFuncionario`** (`pdv/models/pagamento_funcionario.dart`)
- **`TurnoCaixa`**, **`MovimentoCaixa`** (`pdv/models/turno_caixa.dart`)
- **`ConfiguracoesImpressora`** (`pdv/models/configuracoes_impressora.dart`)
- **`RegistroAcao`** (`pdv/models/registro_acao.dart`)
- **`ConversaChat`** (`chat/models/conversa_chat.dart`)
- **`MensagemChat`** (`chat/models/mensagem_chat.dart`)
- **Submodelos:** `ItemVendido`, `PagamentoParcial`, `AcompanhamentoEscolhido`, `ItemConsumoMesa`, `ComponenteItem`, `HistoricoEdicaoMensagem`.

---

## 2. Checklist Obrigatório dos 4 Passos

Ao adicionar ou modificar qualquer campo, altere **sempre os quatro pontos**:

1. **Construtor:** declare o parâmetro nomeado (com padrão se não for `required`).
2. **`copyWith`:** adicione o parâmetro e resolva `campo ?? this.campo`.
3. **`toJson`:** mapeie `'campo': campo`.
4. **`fromJson`:** leitura segura com fallback contra nulos:
   ```dart
   campoString: json['campoString'] as String? ?? '',
   campoDouble: (json['campoDouble'] as num?)?.toDouble() ?? 0.0,
   campoInt: (json['campoInt'] as num?)?.toInt() ?? 0,
   campoBool: json['campoBool'] as bool? ?? false,
   campoEnum: StatusEnum.values.firstWhere(
     (e) => e.name == json['status'],
     orElse: () => StatusEnum.padrao,
   ),
   listaItens: (json['listaItens'] as List<dynamic>?)
       ?.map((e) => SubModelo.fromJson(e as Map<String, dynamic>))
       .toList() ?? const [],
   ```

---

## 3. Aviso de Cache e Migração

Sempre que alterar campos em modelos persistidos, avise o desenvolvedor para rodar no terminal:
```bash
flutter clean && flutter pub get
```
