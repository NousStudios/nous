# ═════════════════════════════════════════════════════════════════
# NOUS — SCRIPT DE BUILD E GERAÇÃO DE INSTALADOR WINDOWS
# ═════════════════════════════════════════════════════════════════

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Compilacao e Geracao do Instalador Windows     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

Write-Host "[1/3] Compilando versao Release para Windows Desktop..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO: A compilacao do Flutter falhou. Verifique os erros acima." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Build concluida com sucesso!" -ForegroundColor Green
Write-Host "Arquivos binarios gerados em: build\windows\x64\runner\Release\" -ForegroundColor Gray
Write-Host ""

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

    & $isccPath "windows\installer.iss"

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host " SUCESSO! Instalador gerado na pasta 'dist/':" -ForegroundColor Green
        Write-Host " dist\Nous_Instalador_v1.0.0_Versao_Teste.exe" -ForegroundColor White
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
    Write-Host "Para gerar o arquivo de instalacao oficial (Nous_Instalador_v1.0.0_Versao_Teste.exe):" -ForegroundColor Cyan
    Write-Host "1. Instale o Inno Setup executando no terminal do Windows:" -ForegroundColor Cyan
    Write-Host "   winget install JRSoftware.InnoSetup" -ForegroundColor White
    Write-Host "2. Execute este script novamente: .\scripts\gerar_instalador.ps1" -ForegroundColor Cyan
}
