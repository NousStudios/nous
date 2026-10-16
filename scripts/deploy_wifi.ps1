# ═════════════════════════════════════════════════════════════════
# NOUS — SCRIPT DE DEPLOY VIA WI-FI (ADB OVER WI-FI)
# ═════════════════════════════════════════════════════════════════

param(
    [string]$Endereco,
    [string]$Porta,
    [string]$IP = "192.168.0.132"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Deploy do APK no Celular via Wi-Fi             " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Localizar o adb
$adbPath = $null
$candidatos = @(
    "adb",
    "D:\Dev\Android\Sdk\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

foreach ($c in $candidatos) {
    if ($c -eq "adb" -and (Get-Command adb -ErrorAction SilentlyContinue)) {
        $adbPath = "adb"
        break
    } elseif (Test-Path $c) {
        $adbPath = $c
        break
    }
}

if (-not $adbPath) {
    Write-Host "ERRO: O ADB nao foi encontrado em D:\Dev\Android\Sdk\platform-tools\adb.exe nem no PATH." -ForegroundColor Red
    exit 1
}

# 2. Definir o IP e a porta de conexão
if (-not $Endereco) {
    if ($Porta) {
        $Endereco = "$IP`:$Porta"
    } else {
        Write-Host "Abra no celular: Opcoes do desenvolvedor -> Depuracao sem fio" -ForegroundColor Yellow
        Write-Host "Veja o endereco exibido (exemplo: 192.168.0.132:42871)" -ForegroundColor Gray
        Write-Host ""
        $entrada = Read-Host "Digite a porta (ou o endereco completo IP:Porta) [Padrao IP: $IP]"
        if ($entrada -match ":") {
            $Endereco = $entrada.Trim()
        } elseif ($entrada.Trim() -ne "") {
            $Endereco = "$IP`:$($entrada.Trim())"
        } else {
            Write-Host "Nenhum endereco ou porta informados." -ForegroundColor Red
            exit 1
        }
    }
}

# 3. Verificar se o APK existe
$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace
$apkPath = "dist\Nous_Android_v1.0.0_Versao_Teste.apk"

if (-not (Test-Path $apkPath)) {
    Write-Host "APK nao encontrado em $apkPath. Compilando agora..." -ForegroundColor Yellow
    & "$PSScriptRoot\gerar_apk.ps1"
}

# 4. Conectar via Wi-Fi
Write-Host ""
Write-Host "[1/2] Conectando ao celular em $Endereco..." -ForegroundColor Yellow
& $adbPath connect $Endereco

# 5. Instalar o APK no dispositivo
Write-Host ""
Write-Host "[2/2] Instalando APK no celular..." -ForegroundColor Yellow
& $adbPath -s $Endereco install -r $apkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " SUCESSO! O Nous foi atualizado no seu celular via Wi-Fi! " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Falha na instalacao. Verifique se a tela do celular esta ligada e se autorizou o computador." -ForegroundColor Red
}
