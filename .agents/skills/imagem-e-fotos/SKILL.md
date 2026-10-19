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

### 1.2 Sem Ícones Estáticos Enganosos e Uso Mandatório de `resolverCaminhoExistente`
Nunca exiba `Icon(Icons.account_circle)` ou `Icon(Icons.person)` de forma estática onde há fotos ou CPF associado. Sempre utilize `ImagemService.resolverCaminhoExistente(caminho)` antes de testar a existência ou renderizar. **NUNCA use `File(caminho).existsSync()` diretamente sem passar por `ImagemService.resolverCaminhoExistente(caminho)`**, pois caminhos podem ter barras invertidas, caminhos de outras plataformas (ex.: `/data/user/0/...` do Android sincronizado com Windows) ou diretórios legados (`com.example\nous\Nous\imagens`).
Utilize o ícone nativo apenas como fallback limpo caso a foto inexista ou o arquivo físico não seja encontrado no disco.

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

### Renderização do Avatar em Formulários (Resiliente)
```dart
final fotoResolvida = ImagemService.resolverCaminhoExistente(_foto);
final temFoto = fotoResolvida != null;

InkWell(
  onTap: _alterarFoto,
  customBorder: const CircleBorder(),
  child: CircleAvatar(
    radius: 40,
    backgroundColor: theme.cardBackgroundColor,
    backgroundImage: temFoto ? FileImage(File(fotoResolvida)) : null,
    child: !temFoto
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

## 3. Armazenamento Local Soberano e Resolução Resiliente (`ImagemService`)

Localizado em `lib/src/features/pdv/services/imagem_service.dart`:
- As imagens são armazenadas localmente no cofre de dados do usuário: `%APPDATA%/Nous/imagens` no Windows ou `~/.nous/imagens` em outros sistemas.
- **Limite:** Até 500MB por arquivo (`ImagemService.limiteBytesMeioGiga`).
- **Formatos:** `jpg`, `jpeg`, `png`, `webp`, `gif`, `bmp`.
- O método `ImagemService.salvarImagemLocal(caminhoOriginal)` cria uma cópia com nome único (`img_<id>.<ext>`) e retorna o caminho absoluto gravado.
- **Resolução Resiliente (`ImagemService.resolverCaminhoExistente`):**
  Ao ler qualquer caminho persistido no banco ou recebido pela rede, o método busca:
  1. O caminho exato.
  2. O caminho normalizado com separadores do sistema.
  3. O arquivo pelo nome base (`basename`) em todos os diretórios possíveis da aplicação (incluindo diretórios legados como `com.example\nous\Nous\imagens`).
- **Unificação de Diretórios (`ImagemService.unificarDiretoriosImagens`):**
  Executado na inicialização em background, migra arquivos de imagens de diretórios legados para a pasta oficial atual, prevenindo fragmentação.

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
final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
final temFoto = fotoResolvida != null;
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
final fotoResolvida = ImagemService.resolverCaminhoExistente(foto);
final temFoto = fotoResolvida != null;

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
        ? Image.file(File(fotoResolvida), fit: BoxFit.cover)
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

---

## 7. Proteção Contra Sobrescrita de Imagens na Sincronização Wi-Fi

Ao sincronizar entre computador balcão (servidor) e celulares Android (terminais móveis):
- **O servidor NUNCA sobrescreve suas fotos locais com caminhos do Android:** Se um celular enviar uma atualização de loja (`POST /api/loja/atualizar`) contendo caminhos móveis (ex.: `/data/user/0/...`), o servidor verifica se o arquivo remoto existe nele. Se não existir e o servidor já possuir uma foto local válida, a foto local é **preservada intacta**, impedindo que logos de loja, categorias ou produtos sumam do computador balcão.
- **Upload de Novas Mídias:** Fotos criadas no terminal móvel são enviadas via `POST /api/upload_imagem` com seus bytes brutos antes da atualização da loja, sendo gravadas na pasta de imagens do servidor e retornando o novo caminho local válido.

---

## 8. Reconciliação Mútua e Autocura Bidirecional de Imagens (Self-Healing Mesh)

Independente de quem estiver operando como Servidor ou Cliente (Computador Balcão ou Smartphone):
- **Inspeção de Lacunas no Servidor:** O endpoint `GET /api/loja` inspeciona o sistema de arquivos local do host e retorna `imagensAusentes` (logo, categorias, itens, clientes ou fornecedores cujos arquivos não existem em disco ou estão vazios).
- **Reparo Ativo pelo Cliente:** O cliente compara a loja recebida com seu cofre local (`LojasService.carregarLojaPorId`). Para cada lacuna do servidor que o cliente possui fisicamente em disco, o cliente faz o upload dos bytes via `POST /api/upload_imagem`, recompõe o catálogo e notifica o servidor via `POST /api/loja/atualizar`.
- **Cache Determinístico de Upload:** O cliente registra os caminhos em `_mapaUploadsRealizados[caminhoServidor] = caminhoLocal`. Ao aplicar a loja atualizada, resolve instantaneamente o arquivo local sem novo download.
- **Simetria Total:** Se o computador estiver sem imagens e o celular tiver, o celular cura o computador. Se o celular estiver sem imagens e o computador tiver, o computador cura o celular. A aplicação opera de forma unificada e auto-regenerativa em qualquer topologia.

### 8.1 Autocura de Identidades e Fotos de Perfil em Malha (Mesh)
- **Lacunas de Usuários no Servidor:** O endpoint `GET /api/loja` e o evento `dados_iniciais` inspecionam os membros da loja e retornam `fotosUsuariosAusentes` contendo os CPFs de quem não possui imagem física válida no disco do host.
- **Validação Física Estrita no Host:** No `GET /api/usuario?cpf=...`, se o servidor possuir um caminho que não existe no disco local, sanitiza para `foto: ''` antes de responder, evitando mentir para a rede sobre a posse da mídia.
- **Cura Ativa pelo Nó Conectado:** O cliente que possui a foto física em disco (em `ContasLocais`, `ClientesLoja` ou `DadosLocaisService`) faz o upload automático via `POST /api/upload_imagem` e dispara `POST /api/usuario`. O servidor salva a foto, grava no SQLite e replica via WebSocket `usuario_atualizado` para todos os terminais.
- **Auto-Atualização do Dispositivo do Titular:** Quando o celular do titular (ex.: mãe) recebe o evento `usuario_atualizado`, baixa a foto física via `baixarImagemRemota` e chama `AuthProvider.recarregarConta()`, refletindo a foto na tela instantaneamente.

---

## 9. Blindagem Centralizada de Lojas e Autocura Proativa (`LojasService`)

Para erradicar categoricamente o problema de imagens desaparecidas após sincronizações em rede Wi-Fi ou entre plataformas (Windows ↔ Android):
- **Consolidação Obrigatória (`LojasService.consolidarLojaComImagensLocais`):**
  Toda e qualquer operação de salvamento de loja (`salvarLojaIndividual`, `adicionarOuAtualizarLoja`, `/api/loja/atualizar`, `/api/sincronizar_perfis_usuario` e `loja_atualizada`) passa por `consolidarLojaComImagensLocais`.
  Se a loja recebida contiver fotos que não existem fisicamente neste disco (ex.: caminhos `/data/user/0/...` no Windows ou `C:\Users\...` no Android), mas o cofre local já possuía fotos físicas válidas, **as fotos locais são 100% preservadas**.
- **Autocura na Inicialização (`LojasService.autocuraImagensDeLojas`):**
  Executada no `main.dart` ao abrir a aplicação, verifica todas as lojas no SQLite. Se alguma foto estiver quebrada ou com caminho de outro sistema, busca automaticamente pelos nomes de arquivos físicos no disco e pelos backups automáticos em `Nous/backups/*.json`, curando o SQLite silenciosamente.

