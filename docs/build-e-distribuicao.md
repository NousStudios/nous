# Build, Instalador e Distribuição

## 1. Versão

- Fonte da verdade: `pubspec.yaml` (`version:`). Hoje **v1.1.0+102**.
- **Regra de incremento de versão (limite 99 por casa):** cada casa semântica (`MAJOR.MINOR.PATCH`) vai de `0` até `99`. Quando o `PATCH` chega em `99`, o próximo ciclo avança o `MINOR` e reinicia o `PATCH` em `0` (ex.: `1.0.99` → `1.1.0`, `1.1.1`, `1.1.2`... até `1.1.99` → `1.2.0`), mantendo o `+build` sempre crescente.
- O nome dos arquivos em `dist/` utiliza o padrão versionado `Nous_Instalador_v${versao}_Versao_Teste.exe` e `Nous_Android_v${versao}_Versao_Teste.apk`.
- Ao subir a versão, o `gerar_instalador.ps1` sincroniza `AtualizacaoService.dart` antes de compilar.

## 2. Pasta `dist/`

- Windows (Instalador): `dist/Nous_Instalador_v1.0.62_Versao_Teste.exe` (Inno Setup 6, com ícone, dependências C++ e SQLite, para primeira instalação).
- Windows (Atualização Transparente In-App): `dist/Nous_Windows_v1.0.62.zip` (pacote compactado da pasta Release para auto-update sem instalador, estilo Discord/VS Code).
- Android: `dist/Nous_Android_v1.0.62_Versao_Teste.apk` (modo Release).
- O pipeline apaga versões antigas e mantém só a mais recente.

## 3. Scripts (`scripts/`)

| Script | O que faz |
|---|---|
| `gerar_instalador.ps1` | Extrai versão e build do `pubspec.yaml`, sincroniza `AtualizacaoService.dart`, compila o APK Android atualizado (`gerar_apk.ps1`) para `dist/`, depois `flutter build windows --release`, gera o pacote `Nous_Windows_v${versao}.zip` para atualizações silenciosas in-app, empacota com Inno Setup 6 (`windows/installer.iss`, `ISCC.exe`) e entrega o `.exe` em `dist/`. Remove instaladores e zips de versões anteriores em `dist/`. |
| `gerar_apk.ps1` | Compila `flutter build apk --release` e copia o resultado para `dist/Nous_Android_v${versao}_Versao_Teste.apk`, excluindo APKs de versões antigas. |
| `deploy_wifi.ps1` | Conecta ao celular por ADB sobre Wi-Fi e instala o APK atualizado. |
| `converter_icone.ps1` | Converte `assets/images/logo.png` em `app_icon.ico` (multirresolução) e, no Android, `ic_launcher.png` com fundo preto sólido `#000000` e o Adaptive Icon oficial (`res/mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_foreground.png` centralizado na safe zone), sem halos nos launchers. |

**Por que o APK entra no instalador Windows:** o computador balcão distribui atualizações aos celulares pelo Wi-Fi, sem internet. Compilar o APK antes do Inno Setup impede empacotar um APK defasado dentro do `.exe`.

## 4. Atualização por Wi-Fi e GitHub Releases

- O servidor local expõe `GET /api/versao`, `GET /api/download_apk` (Android), `GET /api/download_exe` (Windows) e `GET /api/download_zip` (Windows in-app silencioso).
- `ManipuladorMidiaServidor.obterArquivoApk()`, `obterArquivoExe()` e `obterArquivoZipWindows()` procuram o pacote correspondente à versão atual em `dist/`, na pasta do executável e (para `.exe` no Android) em `/storage/emulated/0/Download` e `Download/Nous`.
- O cliente compara `buildRemota > buildAtual || (buildRemota == buildAtual && versaoMaior(versaoRemota, versaoAtual))`. Se a plataforma tiver o binário disponível no servidor (`temApk` no Android / `temZip` ou `temExe` no Windows), baixa e instala via Wi-Fi.
- **Atualização Transparente (Discord / VS Code Style) e Retorno de Sessão:** No Windows, o app prioriza o download do `.zip`. Antes de atualizar, o app salva a sessão transitória do operador (`SessaoRetornoService`), extrai o pacote em staging via ferramentas nativas (`tar` ou PowerShell), dispara um script detached que aguarda a liberação dos arquivos, substitui os binários da aplicação e reabre o `nous.exe`. Ao reiniciar, `SessaoRetornoHelper` lê `sessao_retorno.json`, realiza auto-login e devolve o operador na mesma tela ou loja onde parou.
- **Prioridade GitHub Releases + Fallback Wi-Fi Local:** ao iniciar o app (`main.dart`), `AtualizacaoService.verificarAtualizacao(silencioso: true)` consulta `releases/latest` no GitHub em segundo plano, extraindo o `browser_download_url` direto do asset `.zip` (ou `.exe` / `.apk`). Se estiver offline ou sem resposta do GitHub, a verificação via rede local (`/api/versao` + `/api/download_zip` ou `/api/download_exe`) assume automaticamente como plano B.
- **Padrão obrigatório de notas no GitHub Releases:** toda release publicada no GitHub deve seguir exatamente o padrão visual e estrutural adotado na `v1.1.55`:
  - Título: `Nous vX.Y.Z (Build N)`
  - Cabeçalho do corpo: `## Novidades da versão vX.Y.Z`
  - Seções temáticas com emoji (`### 🛒 Título da Seção`), seguidas de tópicos em Markdown (`- **Nome da melhoria:** descrição clara em linguagem acessível ao usuário final.`). Nunca publicar releases com texto corrido sem formatação.
- **Resiliência a HTTP 429 (Rate Limiting) e Fallback:** endpoints de atualização e relógio no `SegurancaServidorRelay` são imunes a cooldowns de navegação, com tolerância ampliada na rede local. No download in-app (`AtualizacaoService`), são enviados cabeçalhos reais de navegador com retentativa exponencial com leitura de `Retry-After`; se o rate limit externo do GitHub persistir, o app aciona fallback automático para download direto no navegador ou disponibiliza botão manual no `CardStatusAtualizacao`.
- `AtualizacaoDialog` e `DespachanteClienteRede` preservam a atualização encontrada: nenhuma das fontes apaga o aviso válido encontrado pela outra.

## 5. Windows

- **Dados** em `%APPDATA%\Nous` (`nous.db`, imagens, `backups/`). Intactos em reinstalações e atualizações.
- **Instância única** no runner Win32 (`windows/runner/main.cpp`): `CreateMutex` nomeado `Nous_Single_Instance_Mutex`; a segunda instância aborta e traz a janela existente à frente (evita concorrência no SQLite).
- **Tela cheia real** (`JanelaWindowsService`, FFI com `user32.dll`): F11 alterna `WS_POPUP` cobrindo 100% da tela. Detecta `IsZoomed`; ao sair, restaura maximizada (`SW_MAXIMIZE`) ou o tamanho livre anterior (`SW_RESTORE`).

## 6. Inicialização (`main.dart`)

Ordem: `AtualizacaoService.inicializar()` → `BancoDadosService.inicializar()` → `ThemeController.init()` → (em segundo plano) `ImagemService.unificarDiretoriosImagens()` e `LojasService.autocuraImagensDeLojas()` → handler global F11 → `BackupService.realizarBackupAutomaticoSeNecessario()` → `runApp(MyApp)`. Providers: `AuthProvider`, `PdvProvider`, `NotificacoesProvider`. Tela inicial: `LoginView`.

## 7. Dependências principais (`pubspec.yaml`)

`provider`, `sqflite_common_ffi`, `sqlite3_flutter_libs`, `shared_preferences`, `path_provider`, `path`, `ffi`, `file_selector`, `printing`, `pdf`, `audioplayers`, `google_fonts`, `flex_color_picker`, `flutter_colorpicker`. Assets: `assets/images/`, `assets/icons/`, `assets/sounds/`, fonte `Belleza`. Não adicionar pacotes sem alinhamento prévio.
