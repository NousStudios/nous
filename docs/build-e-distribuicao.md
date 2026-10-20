# Build, Instalador e Distribuição

## 1. Versão

- Fonte da verdade: `pubspec.yaml` (`version:`). Hoje **v1.0.12+13**.
- O nome dos arquivos em `dist/` utiliza o padrão versionado `Nous_Instalador_v${versao}_Versao_Teste.exe` e `Nous_Android_v${versao}_Versao_Teste.apk`, além de manter a cópia `v1.0.0_Versao_Teste` por compatibilidade com scripts legados.
- Ao subir a versão, o `gerar_instalador.ps1` sincroniza `AtualizacaoService.dart` antes de compilar.

## 2. Pasta `dist/`

- Windows: `dist/Nous_Instalador_v1.0.12_Versao_Teste.exe` (Inno Setup 6, com ícone, dependências C++ e SQLite).
- Android: `dist/Nous_Android_v1.0.12_Versao_Teste.apk` (modo Release).
- Compatibilidade: `dist/Nous_Android_v1.0.0_Versao_Teste.apk`.
- O pipeline apaga versões antigas e mantém só a mais recente e a cópia de compatibilidade acima.

## 3. Scripts (`scripts/`)

| Script | O que faz |
|---|---|
| `gerar_instalador.ps1` | Extrai versão e build do `pubspec.yaml`, sincroniza `AtualizacaoService.dart`, compila o APK Android atualizado (`gerar_apk.ps1`) para `dist/`, depois `flutter build windows --release`, empacota com Inno Setup 6 (`windows/installer.iss`, `ISCC.exe`) e entrega o `.exe` em `dist/`. Remove instaladores de versões anteriores em `dist/`. |
| `gerar_apk.ps1` | Compila `flutter build apk --release` e copia o resultado para `dist/Nous_Android_v${versao}_Versao_Teste.apk` e `dist/Nous_Android_v1.0.0_Versao_Teste.apk`, excluindo APKs de versões antigas. |
| `deploy_wifi.ps1` | Conecta ao celular por ADB sobre Wi-Fi e instala o APK atualizado. |
| `converter_icone.ps1` | Converte `assets/images/logo.png` em `app_icon.ico` (multirresolução) e, no Android, `ic_launcher.png` com fundo preto sólido `#000000` e o Adaptive Icon oficial (`res/mipmap-anydpi-v26/ic_launcher.xml` e `ic_launcher_foreground.png` centralizado na safe zone), sem halos nos launchers. |

**Por que o APK entra no instalador Windows:** o computador balcão distribui atualizações aos celulares pelo Wi-Fi, sem internet. Compilar o APK antes do Inno Setup impede empacotar um APK defasado dentro do `.exe`.

## 4. Atualização por Wi-Fi (local-first)

- O balcão expõe `GET /api/versao` e `GET /api/download_apk`.
- `ServidorRedeLocal._obterArquivoApk()` só oferece o APK que contenha a versão atual do sistema (`v$versao`), evitando loops de atualização.
- O celular compara `buildRemota > buildAtual || versaoMaior(versaoRemota, versaoAtual)`. Se for a mesma versão, o botão e o card somem (`temAtualizacao = false`).
- Com versão superior: botão na `CustomAppBar`; ao clicar, baixa os bytes dentro do app com barra de progresso, grava em armazenamento temporário e abre o instalador nativo via `FileProvider` (`MethodChannel("com.nous.app/instalador")`, método `instalarApk`).
- **Versão real no Android:** o método nativo `obterVersaoApp` do mesmo `MethodChannel` lê o `PackageManager` (`versionName`, `longVersionCode`) e alimenta `AtualizacaoService.inicializar()` em `main.dart`, evitando descompasso de constantes e reinstalação infinita.
- `AtualizacaoDialog` e `AtualizacaoService` priorizam a fonte local e protegem `temAtualizacao` e `infoAtualizacao`: buscas secundárias na internet não podem apagar o aviso do balcão.

## 5. Windows

- **Dados** em `%APPDATA%\Nous` (`nous.db`, imagens, `backups/`). Intactos em reinstalações e atualizações.
- **Instância única** no runner Win32 (`windows/runner/main.cpp`): `CreateMutex` nomeado `Nous_Single_Instance_Mutex`; a segunda instância aborta e traz a janela existente à frente (evita concorrência no SQLite).
- **Tela cheia real** (`JanelaWindowsService`, FFI com `user32.dll`): F11 alterna `WS_POPUP` cobrindo 100% da tela. Detecta `IsZoomed`; ao sair, restaura maximizada (`SW_MAXIMIZE`) ou o tamanho livre anterior (`SW_RESTORE`).

## 6. Inicialização (`main.dart`)

Ordem: `AtualizacaoService.inicializar()` → `BancoDadosService.inicializar()` → `ThemeController.init()` → (em segundo plano) `ImagemService.unificarDiretoriosImagens()` e `LojasService.autocuraImagensDeLojas()` → handler global F11 → `BackupService.realizarBackupAutomaticoSeNecessario()` → `runApp(MyApp)`. Providers: `AuthProvider`, `PdvProvider`, `NotificacoesProvider`. Tela inicial: `LoginView`.

## 7. Dependências principais (`pubspec.yaml`)

`provider`, `sqflite_common_ffi`, `sqlite3_flutter_libs`, `shared_preferences`, `path_provider`, `path`, `ffi`, `file_selector`, `printing`, `pdf`, `audioplayers`, `google_fonts`, `flex_color_picker`, `flutter_colorpicker`. Assets: `assets/images/`, `assets/icons/`, `assets/sounds/`, fonte `Belleza`. Não adicionar pacotes sem alinhamento prévio.
