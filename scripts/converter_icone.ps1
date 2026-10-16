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

Write-Host "Icone Windows gerado com sucesso em: $destino" -ForegroundColor Green

# ═════════════════════════════════════════════════════════════════
# GERAÇÃO DE ÍCONES ANDROID (MIPMAPS TRADICIONAIS E ADAPTIVE ICONS)
# ═════════════════════════════════════════════════════════════════
$androidRes = "d:\Nous\nous\android\app\src\main\res"

# Densidades e tamanhos para ic_launcher.png tradicional (fundo preto total)
$androidDensidades = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

# Tamanhos correspondentes para ic_launcher_foreground.png (108dp base para adaptive icon)
$androidForegroundTamanhos = @{
    "mipmap-mdpi"    = 108
    "mipmap-hdpi"    = 162
    "mipmap-xhdpi"   = 216
    "mipmap-xxhdpi"  = 324
    "mipmap-xxxhdpi" = 432
}

$bmpOriginal = [System.Drawing.Bitmap]::FromFile($origem)

foreach ($item in $androidDensidades.GetEnumerator()) {
    $pasta = Join-Path $androidRes $item.Key
    if (-not (Test-Path $pasta)) {
        New-Item -ItemType Directory -Path $pasta | Out-Null
    }
    $tam = $item.Value
    $caminhoIcone = Join-Path $pasta "ic_launcher.png"

    # 1. Ícone tradicional com fundo 100% PRETO SÓLIDO (#000000)
    $bmpRedimensionado = New-Object System.Drawing.Bitmap($tam, $tam)
    $g = [System.Drawing.Graphics]::FromImage($bmpRedimensionado)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    # Preenche 100% do quadrado com preto puro (evita halos claros do launcher do celular)
    $g.Clear([System.Drawing.Color]::Black)

    # Logo centralizada com margem segura de 8%
    $margem = [int]($tam * 0.08)
    $larguraLogo = $tam - (2 * $margem)
    $g.DrawImage($bmpOriginal, $margem, $margem, $larguraLogo, $larguraLogo)
    $g.Dispose()

    $bmpRedimensionado.Save($caminhoIcone, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpRedimensionado.Dispose()

    # 2. Adaptive Icon Foreground (108dp base com logo na safe zone central)
    $tamFore = $androidForegroundTamanhos[$item.Key]
    $caminhoForeground = Join-Path $pasta "ic_launcher_foreground.png"

    $bmpFore = New-Object System.Drawing.Bitmap($tamFore, $tamFore)
    $gFore = [System.Drawing.Graphics]::FromImage($bmpFore)
    $gFore.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gFore.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gFore.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gFore.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $gFore.Clear([System.Drawing.Color]::Transparent)
    $tamLogoFore = [int]($tamFore * 0.68)
    $offsetFore = [int](($tamFore - $tamLogoFore) / 2)
    $gFore.DrawImage($bmpOriginal, $offsetFore, $offsetFore, $tamLogoFore, $tamLogoFore)
    $gFore.Dispose()

    $bmpFore.Save($caminhoForeground, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpFore.Dispose()

    Write-Host "Icone Android ($tam x $tam) e Foreground ($tamFore x $tamFore) gerados em: $pasta" -ForegroundColor Green
}

$bmpOriginal.Dispose()
Write-Host "Todos os icones Android gerados com fundo preto total e suporte a Adaptive Icon!" -ForegroundColor Green

