# Script para expor o servidor local do Nous (porta 8080) pela internet
# via Cloudflare Quick Tunnel (sem precisar de dominio nem abrir portas no roteador).

param(
    [int]$Porta = 8080
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   NOUS - Tunel de Servidor Provisorio (Cloudflare)       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
    $caminhoPadrao = "$env:ProgramFiles (x86)\cloudflared\cloudflared.exe"
    $caminhoPadrao64 = "$env:ProgramFiles\cloudflared\cloudflared.exe"
    if (Test-Path $caminhoPadrao64) {
        $cloudflared = $caminhoPadrao64
    } elseif (Test-Path $caminhoPadrao) {
        $cloudflared = $caminhoPadrao
    } else {
        Write-Host "[ERRO] cloudflared nao encontrado. Instale com: winget install Cloudflare.cloudflared" -ForegroundColor Red
        exit 1
    }
} else {
    $cloudflared = $cloudflared.Source
}

Write-Host "[1/2] Verificando se o servidor do Nous esta ativo na porta $Porta..." -ForegroundColor Yellow
try {
    $tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port $Porta -WarningAction SilentlyContinue
    if (-not $tcp.TcpTestSucceeded) {
        Write-Host "[AVISO] A porta $Porta ainda nao esta respondendo." -ForegroundColor DarkYellow
        Write-Host "        Abra o Nous no PC, va em Sincronizacao em Rede Wi-Fi e inicie o servidor na porta $Porta." -ForegroundColor DarkYellow
        Write-Host ""
    } else {
        Write-Host "[OK] Servidor do Nous detectado na porta $Porta!" -ForegroundColor Green
    }
} catch {}

Write-Host "[2/2] Abrindo tunel seguro HTTPS/WSS para http://127.0.0.1:$Porta ..." -ForegroundColor Yellow
Write-Host "      Quando aparecer o link 'https://....trycloudflare.com', copie e cole no Nous do celular!" -ForegroundColor Green
Write-Host "      Mantenha esta janela aberta enquanto o servidor estiver no ar. (Ctrl+C para encerrar)" -ForegroundColor Gray
Write-Host ""

& $cloudflared tunnel --url "http://127.0.0.1:$Porta"
