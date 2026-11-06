Add-Type -AssemblyName System.Drawing

$width = 1024
$height = 500
$bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# 1. Fundo Gradiente Tropical Céu / Oceano
$topColor = [System.Drawing.Color]::FromArgb(255, 78, 227, 253)    # #4EE3FD
$botColor = [System.Drawing.Color]::FromArgb(255, 18, 124, 174)   # #127CAE
$rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $botColor, 90.0)
$g.FillRectangle($brush, $rect)
$brush.Dispose()

# 2. Brilho Solar Radial Suave no Topo
$sunPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$sunPath.AddEllipse(200, -150, 624, 500)
$pbg = New-Object System.Drawing.Drawing2D.PathGradientBrush($sunPath)
$pbg.CenterColor = [System.Drawing.Color]::FromArgb(80, 255, 255, 255)
$pbg.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 78, 227, 253))
$g.FillPath($pbg, $sunPath)
$pbg.Dispose()
$sunPath.Dispose()

# 3. Arte Central do Robô e Lâmina (de icon_1024.png)
$iconPath = "assets/brand/icon_1024.png"
if (Test-Path $iconPath) {
    $icon = [System.Drawing.Image]::FromFile($iconPath)
    # Desenha o ícone centrado proporcionalmente no banner
    # O centro visual do ícone fica ligeiramente deslocado para a direita para equilibrar
    $artSize = 540
    $destX = ($width - $artSize) / 2
    $destY = ($height - $artSize) / 2
    $g.DrawImage($icon, $destX, $destY, $artSize, $artSize)
    $icon.Dispose()
}

# 4. Salvar como PNG 24-bit padrão Google Play
$outPath = "assets/brand/feature_graphic_1024x500.png"
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host "Feature graphic gerado com sucesso em: $outPath (1024x500 px, 24bpp)" -ForegroundColor Green
