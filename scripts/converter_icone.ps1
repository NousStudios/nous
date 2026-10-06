# ═════════════════════════════════════════════════════════════════
# CONVERSOR DE LOGO (PNG) PARA ÍCONE WINDOWS (.ICO MULTIRRESOLUÇÃO)
# ═════════════════════════════════════════════════════════════════

Add-Type -AssemblyName System.Drawing

$origem = "d:\Nous\nous\assets\images\logo.png"
$destino = "d:\Nous\nous\windows\runner\resources\app_icon.ico"

if (-not (Test-Path $origem)) {
    Write-Host "Arquivo de logo nao encontrado: $origem" -ForegroundColor Red
    exit 1
}

$bmpOriginal = [System.Drawing.Bitmap]::FromFile($origem)
$tamanhos = @(256, 128, 64, 48, 32, 16)
$pngBytesList = @()

foreach ($tam in $tamanhos) {
    $bmpRedimensionado = New-Object System.Drawing.Bitmap($tam, $tam)
    $g = [System.Drawing.Graphics]::FromImage($bmpRedimensionado)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $g.DrawImage($bmpOriginal, 0, 0, $tam, $tam)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmpRedimensionado.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += ,$ms.ToArray()
    $ms.Dispose()
    $bmpRedimensionado.Dispose()
}

$bmpOriginal.Dispose()

# Escreve o arquivo ICO binário
$fs = [System.IO.File]::Create($destino)
$bw = New-Object System.IO.BinaryWriter($fs)

# Header ICO
$bw.Write([uint16]0) # Reserved
$bw.Write([uint16]1) # Type (1 = Icon)
$bw.Write([uint16]$tamanhos.Length) # Quantidade de imagens

# Calcula offset inicial (Header = 6 bytes + Diretórios = 16 * N bytes)
$offset = 6 + (16 * $tamanhos.Length)

for ($i = 0; $i -lt $tamanhos.Length; $i++) {
    $tam = $tamanhos[$i]
    $bytes = $pngBytesList[$i]

    # Diretório
    $w = if ($tam -eq 256) { 0 } else { $tam }
    $h = if ($tam -eq 256) { 0 } else { $tam }

    $bw.Write([byte]$w)
    $bw.Write([byte]$h)
    $bw.Write([byte]0)   # ColorCount
    $bw.Write([byte]0)   # Reserved
    $bw.Write([uint16]1) # Planes
    $bw.Write([uint16]32) # BitCount
    $bw.Write([uint32]$bytes.Length) # BytesInRes
    $bw.Write([uint32]$offset) # ImageOffset

    $offset += $bytes.Length
}

# Escreve o conteúdo das imagens PNG
for ($i = 0; $i -lt $tamanhos.Length; $i++) {
    $bw.Write($pngBytesList[$i])
}

$bw.Flush()
$bw.Close()
$fs.Close()

Write-Host "Icone gerado com sucesso em: $destino" -ForegroundColor Green
