# ═════════════════════════════════════════════════════════════════
# NOUS — SCRIPT DE BUILD DO APK ANDROID (RELEASE)
# ═════════════════════════════════════════════════════════════════

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Compilacao do APK Android (Release)            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

Write-Host "[1/2] Compilando versao Release para Android (APK)..." -ForegroundColor Yellow
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

Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "dist\Nous_Android_v1.0.0_Versao_Teste.apk" -Force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " SUCESSO! APK gerado e copiado para a pasta 'dist/':" -ForegroundColor Green
Write-Host " dist\Nous_Android_v1.0.0_Versao_Teste.apk" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
