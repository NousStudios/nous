---
name: imagem-e-fotos
description: Use whenever adding, displaying, storing, or syncing an image, avatar, or thumbnail in the Nous project.
---

# Ecossistema de Imagens, Avatares e Continuidade Visual no Nous

Diretrizes obrigatórias para seleção, salvamento local, persistência, renderização e sincronização de fotos e avatares em todas as entidades do Nous.

---

## 1. Princípios Inegociáveis de Continuidade Visual

### 1.1 Proibição de Elementos Fictícios
Se um componente visual possui espaço para avatar, logotipo ou miniatura, ela **NUNCA é meramente decorativa**. Deve ser persistida, vinculada ao modelo de dados e exibida em todas as telas que representam aquela entidade (telas de gestão, comandas, relatórios, cadastros e listas).

### 1.2 Sem Ícones Estáticos Enganosos
Nunca exiba `Icon(Icons.account_circle)` ou `Icon(Icons.person)` de forma estática onde há fotos ou CPF associado. Sempre renderize `CircleAvatar` ou `Image.file` com `FileImage(File(caminhoFoto))` da imagem real e utilize o ícone nativo apenas como fallback limpo caso a foto inexista ou o arquivo físico não seja encontrado no disco.

### 1.3 Sem Sobreposições Sujas
Nunca sobreponha ícones secundários (como canetinhas de edição `Icons.edit` ou câmeras flutuantes) sobre avatares ou fotos de formulários. O próprio avatar/container deve ser interativo (usando `InkWell` com `CircleBorder()` ou `BorderRadius` apropriado).

---

## 2. Fluxo de Seleção e Remoção com `OpcoesImagemDialog`

Todo formulário de cadastro ou edição com foto deve seguir estritamente o fluxo padronizado:
- **Se o campo já contém foto:** o toque/clique no avatar abre o diálogo intermediário `OpcoesImagemDialog.mostrar(...)`, oferecendo as opções:
  1. *"Procurar nova imagem"* (abre o seletor `openFile`).
  2. *"Retirar imagem"* (limpa o campo).
  3. *"Cancelar"*.
- **Se o campo está vazio:** o clique abre diretamente o seletor de arquivos (`openFile`).

### Exemplo Canônico de Formulário
```dart
Future<void> _alterarFoto() async {
  if (_foto.isNotEmpty) {
    OpcoesImagemDialog.mostrar(
      context,
      theme: theme,
      titulo: 'Foto do Registro',
      onEscolherNova: _selecionarNovaFoto,
      onRemover: () => setState(() => _foto = ''),
    );
  } else {
    await _selecionarNovaFoto();
  }
}

Future<void> _selecionarNovaFoto() async {
  const grupo = XTypeGroup(
    label: 'Imagens',
    extensions: ['jpg', 'jpeg', 'png', 'webp'],
  );
  final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
  if (arquivo == null) return;

  final salvo = await ImagemService.salvarImagemLocal(arquivo.path);
  if (salvo == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.cardBackgroundColor,
          content: Text(
            'A foto deve ser uma imagem válida de até meio giga (500MB).',
            style: theme.getTextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    return;
  }

  setState(() => _foto = salvo);
}
```

### Renderização do Avatar em Formulários
```dart
InkWell(
  onTap: _alterarFoto,
  customBorder: const CircleBorder(),
  child: CircleAvatar(
    radius: 40,
    backgroundColor: theme.cardBackgroundColor,
    backgroundImage: (_foto.isNotEmpty && File(_foto).existsSync())
        ? FileImage(File(_foto))
        : null,
    child: (_foto.isEmpty || !File(_foto).existsSync())
        ? Icon(
            Icons.person,
            size: 44,
            color: theme.secondaryTextColor,
          )
        : null,
  ),
)
```

---

## 3. Armazenamento Local Soberano (`ImagemService`)

Localizado em `lib/src/features/pdv/services/imagem_service.dart`:
- As imagens são armazenadas localmente no cofre de dados do usuário: `%APPDATA%/Nous/imagens` no Windows ou `~/.nous/imagens` em outros sistemas.
- **Limite:** Até 500MB por arquivo (`ImagemService.limiteBytesMeioGiga`).
- **Formatos:** `jpg`, `jpeg`, `png`, `webp`, `gif`, `bmp`.
- O método `ImagemService.salvarImagemLocal(caminhoOriginal)` cria uma cópia com nome único (`img_<id>.<ext>`) e retorna o caminho absoluto gravado.

---

## 4. Sincronização Bidirecional e Continuidade de Fotos por CPF

No Nous, a foto de uma pessoa real nunca fica fragmentada. Todas as telas e módulos convergem para o CPF do cidadão:

### 4.1 Continuidade de Fotos de Contas Locais
O `AuthProvider` mantém cache das contas registradas na máquina através de `ContasNousService.carregarTodas()`. Para exibir a foto de qualquer membro ou trabalhador:
```dart
String foto = auth.buscarFotoPorCpf(membro.cpf);
if (foto.isEmpty) {
  foto = pdv.buscarFotoClientePorCpf(membro.cpf) ?? '';
}
final temFoto = foto.isNotEmpty && File(foto).existsSync();
```
Essa regra se aplica a:
- **"Status da Loja" -> "Lista de Trabalhadores"**: miniatura da foto com hover na barra.
- **"Usuários Participantes"**: miniatura real do membro da loja.
- **"Registrar Pagamento"**: seletor dropdown com miniatura redonda do trabalhador.
- **Diálogo de Convite de Membro**: ao digitar o CPF, exibe o avatar da conta encontrada.
- **"Usar cliente como fornecedor"**: foto real do cliente no cadastro de fornecedores.

### 4.2 Sincronização Bidirecional Conta ↔ Cliente
- Quando o cidadão atualiza a foto do seu perfil Nous, chama-se `pdv.sincronizarFotoUsuarioEmClientes(cpf, novaFoto)`, replicando a nova imagem para todos os cadastros de clientes que possuam aquele mesmo CPF.
- Quando a aplicação inicializa ou detecta uma conta sem foto mas com cliente cadastrado com o mesmo CPF, chama-se `auth.sincronizarFotoComClienteSeNecessario(fotoCliente)`, puxando a foto do cliente para a conta.

### 4.3 Autopreenchimento Local Unificado (`DadosLocaisService`)
Ao preencher documento (CPF com 11 dígitos ou CNPJ com 14 dígitos), `DadosLocaisService.buscarPorDocumento` pesquisa no cofre local (contas de usuários, clientes anteriores e lojas locais). Se houver cadastro, a foto é autopreenchida automaticamente no formulário.

---

## 5. Miniaturas em Listas e Barras

Para itens de listas (trabalhadores, clientes, fornecedores):
```dart
Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: theme.borderColor.withValues(alpha: 0.6),
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: temFoto
        ? Image.file(File(foto), fit: BoxFit.cover)
        : Icon(Icons.person, size: 18, color: theme.secondaryTextColor),
  ),
)
```

---

## 6. Fotos de Produtos, Comandas e Pedidos

- **Modelos:** Tanto `ItemLoja` quanto `ItemVendido` persistem o campo `foto`.
- **Fluxo Completo:** A imagem cadastrada no item acompanha todo o ciclo de vida da venda:
  - Miniatura na vitrine e catálogo do PDV.
  - Miniatura no carrinho e lista de seleção.
  - Miniatura nas abas de gestão de pedidos (`Novos`, `Aceitos`, `Concluídos`).
  - Miniatura nas comandas visuais (`ComandaPedido`) e no diálogo detalhado do pedido (`PedidoAceitoDialog`).
