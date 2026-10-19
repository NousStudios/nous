# ═════════════════════════════════════════════════════════════════
# NOUS — SCRIPT DE BUILD E GERAÇÃO DE INSTALADOR WINDOWS
# ═════════════════════════════════════════════════════════════════

param(
    [switch]$IncluirAndroid
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Compilacao e Geracao do Instalador Windows     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

# Extrai a versão e build de pubspec.yaml logo no início
$versao = "1.0.9"
$build = 10
if (Test-Path "pubspec.yaml") {
    $conteudo = Get-Content "pubspec.yaml"
    foreach ($linha in $conteudo) {
        if ($linha -match "^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+?([0-9]*)") {
            $versao = $matches[1]
            if ($matches[2]) {
                $build = [int]$matches[2]
            }
            break
        }
    }
}

# Sincroniza automaticamente a versão no AtualizacaoService.dart antes de compilar
$caminhoService = "lib\src\core\services\atualizacao_service.dart"
if (Test-Path $caminhoService) {
    $serviceContent = Get-Content $caminhoService -Raw
    $serviceContent = $serviceContent -replace "static (?:const )?String versaoAtual = '.*?';", "static String versaoAtual = '$versao';"
    $serviceContent = $serviceContent -replace "static (?:const )?int buildAtual = \d+;", "static int buildAtual = $build;"
    Set-Content -Path $caminhoService -Value $serviceContent -NoNewline
    Write-Host "[*] Versao sincronizada no AtualizacaoService.dart: v$versao (Build $build)" -ForegroundColor Cyan
}

Write-Host "[1/3] Compilando versao Release para Windows Desktop (v$versao • Build $build)..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: A compilacao do Flutter falhou. Verifique os erros acima." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Build Windows concluida com sucesso!" -ForegroundColor Green
Write-Host "Arquivos binarios gerados em: build\windows\x64\runner\Release\" -ForegroundColor Gray
Write-Host ""

$apkDestino = "dist\Nous_Android_v${versao}_Versao_Teste.apk"

# Compila o APK Android atualizado para garantir que o instalador Windows nunca empacote APK defasado
Write-Host "[*] Compilando/atualizando APK Android (v$versao • Build $build) para inclusao no instalador Windows..." -ForegroundColor Yellow
& "$PSScriptRoot\gerar_apk.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "AVISO: Falha na compilacao do APK Android. Continuando com o instalador Windows..." -ForegroundColor Red
}

# Localiza o Inno Setup Compiler
$isccPath = $null
$candidatos = @(
    "iscc",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)

foreach ($c in $candidatos) {
    if ($c -eq "iscc" -and (Get-Command iscc -ErrorAction SilentlyContinue)) {
        $isccPath = "iscc"
        break
    } elseif (Test-Path $c) {
        $isccPath = $c
        break
    }
}

if ($isccPath) {
    Write-Host "[3/3] Inno Setup detectado! Gerando instalador executavel..." -ForegroundColor Yellow
    
    if (-not (Test-Path "dist")) {
        New-Item -ItemType Directory -Path "dist" | Out-Null
    }

    & $isccPath "/DMyAppVersion=$versao" "windows\installer.iss"

    if ($LASTEXITCODE -eq 0) {
        $nomeInstaladorAtual = "Nous_Instalador_v${versao}_Versao_Teste.exe"

        # Exclui instaladores de versões antigas na pasta dist/, mantendo apenas o mais recente
        Get-ChildItem -Path "dist" -Filter "Nous_Instalador_v*.exe" -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne $nomeInstaladorAtual
        } | ForEach-Object {
            Write-Host "[*] Removendo instalador antigo: $($_.Name)" -ForegroundColor DarkGray
            Remove-Item $_.FullName -Force
        }

        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host " SUCESSO! Instalador gerado na pasta 'dist/':" -ForegroundColor Green
        Write-Host " dist\$nomeInstaladorAtual" -ForegroundColor White
        Write-Host "==========================================================" -ForegroundColor Green
    } else {
        Write-Host "Ocorreu um erro ao compilar o instalador com o Inno Setup." -ForegroundColor Red
    }
} else {
    Write-Host "[3/3] Inno Setup 6 nao encontrado no sistema." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A pasta da aplicacao ja esta pronta e funciona de forma autonoma em:" -ForegroundColor Gray
    Write-Host "  build\windows\x64\runner\Release\nous.exe" -ForegroundColor White
    Write-Host ""
    Write-Host "Para gerar o arquivo de instalacao oficial (Nous_Instalador_v${versao}_Versao_Teste.exe):" -ForegroundColor Cyan
    Write-Host "1. Instale o Inno Setup executando no terminal do Windows:" -ForegroundColor Cyan
    Write-Host "   winget install JRSoftware.InnoSetup" -ForegroundColor White
    Write-Host "2. Execute este script novamente: .\scripts\gerar_instalador.ps1" -ForegroundColor Cyan
}

