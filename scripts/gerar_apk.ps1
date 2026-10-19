# ═════════════════════════════════════════════════════════════════
# NOUS — SCRIPT DE BUILD DO APK ANDROID (RELEASE)
# ═════════════════════════════════════════════════════════════════

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Compilacao do APK Android (Release)            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

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

# Sincroniza automaticamente a versão no AtualizacaoService.dart para garantir fidelidade total
$caminhoService = "lib\src\core\services\atualizacao_service.dart"
if (Test-Path $caminhoService) {
    $serviceContent = Get-Content $caminhoService -Raw
    $serviceContent = $serviceContent -replace "static (?:const )?String versaoAtual = '.*?';", "static String versaoAtual = '$versao';"
    $serviceContent = $serviceContent -replace "static (?:const )?int buildAtual = \d+;", "static int buildAtual = $build;"
    Set-Content -Path $caminhoService -Value $serviceContent -NoNewline
    Write-Host "[*] Versao sincronizada no AtualizacaoService.dart: v$versao (Build $build)" -ForegroundColor Cyan
}

Write-Host "[1/2] Compilando versao Release para Android (APK v$versao • Build $build)..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: A compilacao do APK Android falhou. Verifique os erros acima." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/2] Build concluida com sucesso! Copiando para dist/..." -ForegroundColor Green

if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
}

$nomeApk = "Nous_Android_v${versao}_Versao_Teste.apk"
Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "dist\$nomeApk" -Force
Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "dist\Nous_Android_v1.0.0_Versao_Teste.apk" -Force

# Exclui versões antigas de APK na pasta dist/, mantendo apenas a versão atual e a cópia de compatibilidade v1.0.0
Get-ChildItem -Path "dist" -Filter "Nous_Android_v*.apk" -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -ne $nomeApk -and $_.Name -ne "Nous_Android_v1.0.0_Versao_Teste.apk"
} | ForEach-Object {
    Write-Host "[*] Removendo versao antiga do APK: $($_.Name)" -ForegroundColor DarkGray
    Remove-Item $_.FullName -Force
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " SUCESSO! APK gerado e copiado para a pasta 'dist/':" -ForegroundColor Green
Write-Host " dist\$nomeApk" -ForegroundColor White
Write-Host " dist\Nous_Android_v1.0.0_Versao_Teste.apk (compatibilidade)" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Green
