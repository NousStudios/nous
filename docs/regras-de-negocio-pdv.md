# Regras de Negócio do PDV

O que cada tela mostra está em `MAPA_DO_APP.md`. Aqui ficam **as regras de cálculo e de comportamento**.

## 1. Perfis profissionais

- **Loja Padrão:** varejo em geral, venda direta no balcão.
- **Restaurante:** cardápio, componentes/adicionais, mesas e comandas abertas.
- **Fretes e Viagens:** transporte individual e entregas.

## 2. Vendas

- **Venda avulsa vs. categorizada:** item da aba "Todos" (ou por busca/bipador) cobra só o preço base. O valor da categoria só soma se ela foi selecionada antes (ex.: Açaí R$ 17,00 + Copo R$ 2,00 = R$ 19,00).
- **Variantes:** `ItemLoja.variantes`. O item vendido (`ItemVendido`) guarda `varianteNome` (SQLite e JSON), exibido como `Nome ($varianteNome)` no carrinho, comanda, relatórios e cupom. Rascunhos (`_ItemRascunho`) preservam a variante.
- **Itens vendidos** guardam a foto do produto. Também `nomeCategoria`, `precoCategoria`, `nomeExibicao`, `precoUnitario`.
- **Desconto e acréscimo:** valor em R$ ou `%` (ex.: `10%`, `2.5%`); % sobre o subtotal dos itens; cupom discrimina `Desconto (X%)` / `Acréscimo (X%)`.
- **Frete:** `PedidoLoja.frete`, somado ao total e discriminado na comanda térmica.
- **Pagamentos múltiplos:** `List<PagamentoParcial>`, lidos por `pedido.todosPagamentos`. `PedidoLoja.pagamentosExtras` guarda todos os pagamentos de fechamento de mesa (sem descartar o índice 0).
- **Troco:** excesso real sobre o total (`TotalPagamentos - Total`); grava o valor líquido recebido.
- **À Prazo:** nome padronizado `'À Prazo'`; `PedidoLoja.temAPrazo` tolera `'A Prazo'` e `'Fiado / A Prazo'`.
  - Venda quitada ou sem débito a prazo nasce com `quitado: true` e `valorPago: total`.
  - Venda a prazo ou mista registra em `valorPago` o recebido na hora (`valorPagoNaoPrazo`), para `valorRestante` ser exato.
  - Cancelados são excluídos de `aPrazoEmAberto`, relatórios e faturamento.
  - Modo Balcão: À Prazo exige cliente cadastrado (não existe "Consumidor Final" pendente).
  - Fechamento de mesa à prazo exige cliente (cadastro rápido se necessário); `clienteId` é vinculado automaticamente se existir cliente com o nome da comanda.
- **Quitação universal (`aplicarPagamentoAPrazo`):** quita por `clienteId` **e** por `clienteNome`. **Quitação rápida** na comanda (`quitarPedidoLoja`): confirma valor, escolhe forma, gera suprimento no caixa se for dinheiro, registra auditoria.
- **Venda concluída:** `VendaConcluidaDialog` protegido (`PopScope(canPop: false)`); sair pergunta salvar ou descartar.
- **Impressão automática ao concluir:** `ConfiguracoesImpressora.imprimirAutomaticoAoConcluir`.

## 3. Pedidos

- Status: **Novo → Aceito → Concluído**, ou **Cancelado** (de Novo ou Aceito).
- **Cancelar** (`CancelarPedidoDialog`): motivo obrigatório; opção de devolver ao estoque. Pedido vai para "Cancelados" e **nunca é apagado**. Gera auditoria (`pedidoCancelado`, `movimentoEstoqueRegistrado`). Não conta no faturamento nem nas entradas do Financeiro.
- **Estorno de estoque** devolve a quantidade ponderada pela receita (`quantidade * consumoPorVenda`) e estorna recursivamente os acompanhamentos.
- **Excluir pedido** da lista: pergunta se estorna o estoque; registra entrada com autor e justificativa.
- **Tempo de conclusão:** `Loja.tempoConclusaoMinutos`; pedido `aceito` que passar do prazo dispara "O Pedido #N já foi concluído?".
- **Pedidos programados:** `PedidoProgramado` (`id`, `lojaId`, `clienteId`, `clienteNome`, `clienteTelefone`, `clienteEndereco`, `itens`, `valorTotal`, `formaPagamento`, `horario`, `diasSemana` 1=Seg…7=Dom, `datasEspecificas`, `modoProgramacao` ('dias_semana' | 'datas_especificas'), `ativo`, `dataCriacao`, `ultimaDataGerado`). `coincideComData` decide se roda na data; `descricaoFrequencia` gera textos como "Qua, Qui, Sex às 12:00". Gera `PedidoLoja` `novo` sem duplicar (usa `ultimaDataGerado`). `toPedidoLoja` recebe `nomeVendedor` e `cnpjVendedor` da loja, gerando comanda com cabeçalho completo nos relatórios. Só o balcão roda o timer de geração.

## 4. Mesas (Restaurante)

- Mesa: `livre`/`ocupada`, número, descrição/capacidade, cliente, atendente.
- Auditoria: `itemAdicionadoMesa`, `itemRemovidoMesa` (obrigatório ao remover), `mesaLiberada`, `mesaTransferida`.
- **Fechamento:** pagamento único ou dividido; 10% de atendimento opcional; desconto. **Bloqueia** se faltar quitar ou se a soma dos pagamentos ultrapassar o total.
- **Baixa de estoque proporcional:** `item.quantidade * itemCadastrado.consumoPorVenda` e, para adicionais, `acomp.quantidadePorUnidade * item.quantidade * acompCadastrado.consumoPorVenda` (sem truncar g/ml).
- Impressão de conferência: `ImpressaoService.imprimirConferenciaMesa`.

## 5. Estoque

- Unidades `un`, `g`, `ml`. Formatação automática (`formatarQuantidadeComUnidade`): ≥ 1000 g → kg, ≥ 1000 ml → L (1500 g → 1,5 kg; −1000 g → −1 kg); abaixo mantém a unidade base.
- **Baixa automática é sugestão** (`BaixaEstoqueDialog`); o humano confirma.
- **Custo unitário:** `C_unit = C_total / Q` (ex.: 50 copos por R$ 35,00 = R$ 0,70/un), calculado nos dois sentidos, salvo em `ItemLoja.precoCusto`. Mostra "Custo Unitário da Última Compra".
- **Estoque baixo/esgotado:** `PdvProvider.todosItensEstoqueBaixo` (produto não-serviço com saldo < 10 ou ≤ 0). Alimenta o sino. Ao repor (entrada): `pdv.adicionarMovimentoEstoque` + `pdv.registrarAcao` (`TipoAcao.movimentoEstoqueRegistrado`) + recálculo; com saldo ≥ 10 o alerta some.
- `ItemLoja` implementa `operator ==` e `hashCode` por `id` (necessário para `DropdownButton`).
- **Estoque inicial** no cadastro rápido gera `MovimentoEstoque.ajuste` de entrada.
- `ItemLoja` guarda `codigoBarras` e `precoCusto`.
- **Reset de transações:** consolida o saldo físico de cada item com movimentos de ajuste (`custoUnitario: 0.0`, `custoTotal: 0.0`); o saldo permanece intocado, o histórico de compras com custo some do Financeiro.

## 6. Caixa (turno)

- **Abertura:** fundo de troco, CPF e nome do responsável, data/hora.
- **Suprimento** (entrada) e **Sangria** (saída): justificativa obrigatória, auditadas em `RegistroAcao`, integradas ao turno. Quitação de fiado em dinheiro com caixa aberto gera suprimento automático.
- **Fechamento cego:** conta Dinheiro, Crédito, Débito, PIX e Outros sem ver o esperado.
- **Dinheiro líquido:** `Entradas em Dinheiro − Troco`, considerando pedidos `aceito` e `concluido` do turno. Venda simples já é líquida (`p.valor`); só em pagamentos múltiplos o troco é abatido, **sem dupla dedução** (`_vendasDinheiro`).
- **Saldo em mãos:** `Saldo Inicial + Suprimentos − Sangrias + Vendas em Dinheiro Líquidas`.
- **Discriminação no fechamento e cupom:** `Vendas em Dinheiro (+)`, `Vendas Pix / Cartão (+)`, `Vendas à Prazo / Fiado (a receber)` (não entra no saldo de caixa).
- Comprovantes: `imprimirFechamentoCaixa`, `imprimirMovimentoCaixa` (com linha de assinatura).
- **Apagar turno:** `PdvProvider.excluirTurnoCaixa`, registra `TipoAcao.turnoCaixaExcluido`.

## 7. Financeiro

- **Transparência:** o trabalhador vê os mesmos números do dono.
- **Sugestão de divisão igualitária:** `Cota = BaseRateio / Membros`, com `BaseRateio = Entradas − ComprasEstoque` (resultado operacional do período), **constante** (não degrada conforme os anteriores recebem). Ajustes manuais permitidos e auditados com o delta em relação à sugestão.
- **Filtro de período:** Hoje, Semana, Mês, Tudo (`PeriodoFinanceiro`) ou personalizado (`PeriodoFinanceiro.personalizado`): um dia (só "De") ou intervalo ("De" e "Até"). Imprimir, DRE e PDF respeitam o período escolhido.
- **DRE:** Receita Operacional Bruta, (−) CMV, (=) Lucro Bruto + margem %, (−) Pagamentos a Trabalhadores, (=) Resultado Líquido + margem %. PDF próprio de página única (`dre_AAAAMMDD_HHMM.pdf`), separado do relatório geral (`financeiro_AAAAMMDD_HHMM.pdf`).
- Filtros de data: `_DataInputFormatter` mantém o cursor no lugar ao editar no meio da data.

## 8. Clientes e fornecedores

- Documento: `CpfOuCnpjInputFormatter` (11 dígitos CPF `000.000.000-00`; 12–14 dígitos CNPJ `00.000.000/0000-00`).
- **Autopreenchimento (`DadosLocaisService`):** cruza contas Nous, lojas locais e cadastros prévios (por CPF do cofre, e-mails associados e nome).
- **Busca universal (`correspondeABusca`):** nome, rua, número, CPF/CNPJ (com ou sem pontuação), telefone (com ou sem pontuação), e-mail, redes, descrição. Usada em Clientes, Fornecedores e Nova Venda.
- **Extrato PDF:** `ImpressaoService.exportarExtratoClientePDF` (A4: dados, dívida a prazo, tabela de pedidos).
- Foto do usuário por CPF propaga para clientes e fornecedores originados dele.
- Exclusão de cliente preserva o histórico de pedidos concluídos.

## 9. Membros, papéis e permissões

- Papéis: `Dono`, `Sócio`, `Admin`, `Funcionário`. Regras de exclusão e consentimento: ver `AGENTS.md` (invariante 4).
- Notificações: `TipoNotificacao.solicitacaoExclusaoDono`, `remocaoLoja`, `alteracaoPapel`.
- `ConviteLoja` persiste `cpfDonoOriginal`, para convite enviado por Sócio/Admin salvar a loja no cofre do dono titular (evita "A loja deste convite não está mais disponível").
- Permissões em `PermissaoLojaConst` (inclui `gerenciarMembros`, `resetarTransacoes`). Padrões por papel em `Loja.permissoesPadraoPorPapel`; personalizações em `Loja.permissoesCargosNativos`; cargos criados em `Loja.cargosPersonalizados` (`vincularCargoAoMembro`, `atribuirCargoMembro`, `adicionarCargoLoja`, `atualizarPapelMembro`).
- **Normalização de CPF** (`PdvProvider._mesmoCpf`): `meuMembro`, `lojasQueAdministro`, `lojasQueParticipo` e `sairDaLoja` funcionam independentemente de máscara.
- `AuthProvider` mantém cache de fotos de todas as contas locais (`ContasNousService.carregarTodas()`); foto por `auth.buscarFotoPorCpf` com fallback `pdv.buscarFotoClientePorCpf`.

## 10. Persistência e backup

- **SQLite** (`nous.db`, `BancoDadosService`, `sqflite_common_ffi`): tabelas `lojas`, `pedidos` (índices `loja_id`, `data_hora DESC`, `status`), `movimentos_estoque` (índices `loja_id`, `data_hora DESC`), `pagamentos_funcionarios`, `referencias_loja`, `contas_usuarios`, `convites`. Migração automática dos dados legados de `shared_preferences` na primeira execução.
- **Exclusão de loja** (`LojasService.salvar`) apaga em cascata `pedidos`, `movimentos_estoque` e `pagamentos_funcionarios`.
- **Backup** (`BackupService`): substituir ou mesclar. Mescla compara CNPJ ignorando pontuação (`mesmoDocumento`) ou `id`; **nunca duplica loja**. Categoria mais especializada prevalece (ex.: `Restaurante` com mesas sobre `Loja Padrão`). Unifica itens, clientes, categorias, grupos, `RegistroAcao`, pedidos, movimentos, turnos, pagamentos e anexos, e (`mesclarLojas`) `turnosCaixa`, `atalhosTeclado`, `tempoConclusaoMinutos`, `codigoBarras`, `precoCusto`, `unidadeBase`, `consumoPorVenda`. Depois recarrega `AuthProvider`, `PdvProvider`, `NotificacoesProvider`.
- Backup automático diário em `%APPDATA%\Nous\backups`, até 30 versões (`realizarBackupAutomaticoSeNecessario()` no `main.dart`).

## 11. Impressão térmica

- Bobinas 58 mm e 80 mm (`larguraPapelMm`). Calibração bilateral: `margemEsquerdaMm` (padrão 5.0) e `margemDireitaMm` (padrão 3.0), passos de 0,5 mm.
- Serviço: `ImpressaoService` (PDF). Funções: comanda, conferência de mesa, fechamento de caixa, movimento de caixa, extrato de cliente, DRE, financeiro, exemplo.
- **`linhaDupla` / `linhaComanda`:**
  - Se a coluna direita é valor monetário (`R$ ...`): esquerda em `Expanded` com respiro de 8 px; valor à direita com largura fixa.
  - Se a direita **não** é preço (pagamento, operador, observação): o rótulo da esquerda mantém largura natural (`Text('$rotulo:')`) e a direita recebe `Expanded` alinhada à direita (evita "Pa/ga/m/en/to").
  - Dados do cliente (`linhaDadoCliente`): rótulo intacto, valor em `Expanded(softWrap: true)`.
- Prévia: 10 perfis históricos do anarquismo (Makhno, Bakunin, Malatesta, Kropotkin, Emma Goldman, Durruti, Maria Lacerda de Moura, Comuna de Paris, CNT/FAI, Nous Autogestão), com canais oficiais do Nous (`nousstudios72@gmail.com`, `@nous.studios72`).

## 12. Auditoria, Transparência Radical e Arquitetura Blockchain

- **Registro Universal e Transparência Radical:** Toda ação relevante registra autor (nome, CPF, e-mail), data/hora e descrição/delta: movimentos de estoque, cancelamentos, itens de mesa, pagamentos a membros, sangrias, suprimentos, exclusão de turno, deliberações, etc. A aba "Ações" em Relatórios permite auditar e navegar até o cliente ou pedido relacionado.
- **Execução Local-First Ultrarrápida no SQLite:** Para garantir máxima fluidez de interface (60 fps), respostas em milissegundos e usabilidade de rede social massiva, os registros operacionais do PDV e da mensageria são persistidos diretamente no banco SQLite local, sem amarras de processamento pesado no fluxo rotineiro.
- **Blockchain Reservado para Autogestão Social (`features/autogestao`):** A arquitetura de livro-razão imutável, encadeamento criptográfico estrito (hashes de blocos, bloco gênese e validação de cadeia) fica reservada especificamente para as ferramentas de governança social soberana — assembleias deliberativas, votações de urnas populares e auditoria de contratos coletivos —, onde o custo computacional de validação criptográfica é justificado pela inviolabilidade do consenso social.
