param(
    [string] $OutputDirectory = (Join-Path $PSScriptRoot '..\WinPaste.App\Assets')
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [float] $X,
        [float] $Y,
        [float] $Width,
        [float] $Height,
        [float] $Radius
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-PointF {
    param(
        [float] $X,
        [float] $Y
    )

    return [System.Drawing.PointF]::new($X, $Y)
}

function Add-IconPolygon {
    param(
        [System.Drawing.Drawing2D.GraphicsPath] $Path,
        [float] $Scale,
        [float] $OffsetX,
        [float] $OffsetY,
        [float[]] $Coordinates
    )

    $points = New-Object System.Drawing.PointF[] ($Coordinates.Count / 2)
    for ($i = 0; $i -lt $Coordinates.Count; $i += 2) {
        $points[$i / 2] = New-PointF (($Coordinates[$i] + $OffsetX) * $Scale) (($Coordinates[$i + 1] + $OffsetY) * $Scale)
    }

    $Path.AddPolygon($points)
}

function New-IconPngBytes {
    param([int] $Size)

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 256.0
    $outer = [System.Drawing.RectangleF]::new(16 * $scale, 16 * $scale, 224 * $scale, 224 * $scale)
    $path = New-RoundedRectanglePath $outer.X $outer.Y $outer.Width $outer.Height (54 * $scale)

    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $outer,
        [System.Drawing.Color]::FromArgb(255, 50, 209, 199),
        [System.Drawing.Color]::FromArgb(255, 25, 29, 79),
        135
    )
    $blend = [System.Drawing.Drawing2D.ColorBlend]::new()
    $blend.Positions = [float[]] @(0, 0.48, 1)
    $blend.Colors = [System.Drawing.Color[]] @(
        [System.Drawing.Color]::FromArgb(255, 50, 209, 199),
        [System.Drawing.Color]::FromArgb(255, 36, 116, 216),
        [System.Drawing.Color]::FromArgb(255, 25, 29, 79)
    )
    $gradient.InterpolationColors = $blend
    $graphics.FillPath($gradient, $path)

    $inner = [System.Drawing.RectangleF]::new(29 * $scale, 29 * $scale, 198 * $scale, 198 * $scale)
    $innerPath = New-RoundedRectanglePath $inner.X $inner.Y $inner.Width $inner.Height (43 * $scale)
    $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(58, 255, 255, 255), [Math]::Max(1, 3 * $scale))
    $graphics.DrawPath($borderPen, $innerPath)

    $shinePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $shinePath.AddBezier((New-PointF (54 * $scale) (66 * $scale)), (New-PointF (80 * $scale) (43 * $scale)), (New-PointF (128 * $scale) (35 * $scale)), (New-PointF (169 * $scale) (49 * $scale)))
    $shinePath.AddBezier((New-PointF (169 * $scale) (49 * $scale)), (New-PointF (199 * $scale) (59 * $scale)), (New-PointF (217 * $scale) (82 * $scale)), (New-PointF (219 * $scale) (111 * $scale)))
    $shinePath.AddBezier((New-PointF (219 * $scale) (111 * $scale)), (New-PointF (221 * $scale) (147 * $scale)), (New-PointF (197 * $scale) (175 * $scale)), (New-PointF (163 * $scale) (185 * $scale)))
    $shinePath.AddBezier((New-PointF (163 * $scale) (185 * $scale)), (New-PointF (124 * $scale) (196 * $scale)), (New-PointF (83 * $scale) (187 * $scale)), (New-PointF (56 * $scale) (165 * $scale)))
    $shinePath.AddBezier((New-PointF (56 * $scale) (165 * $scale)), (New-PointF (44 * $scale) (155 * $scale)), (New-PointF (37 * $scale) (139 * $scale)), (New-PointF (38 * $scale) (122 * $scale)))
    $shinePath.AddBezier((New-PointF (38 * $scale) (122 * $scale)), (New-PointF (39 * $scale) (100 * $scale)), (New-PointF (44 * $scale) (79 * $scale)), (New-PointF (54 * $scale) (66 * $scale)))
    $shinePath.CloseFigure()
    $shineBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        $outer,
        [System.Drawing.Color]::FromArgb(96, 255, 255, 255),
        [System.Drawing.Color]::FromArgb(0, 255, 255, 255),
        135
    )
    $graphics.FillPath($shineBrush, $shinePath)

    $wPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    Add-IconPolygon $wPath $scale 0 0 @(41, 83, 61, 83, 78, 153, 61, 171)
    Add-IconPolygon $wPath $scale 0 0 @(73, 171, 94, 171, 108, 83, 88, 83)
    Add-IconPolygon $wPath $scale 0 0 @(98, 83, 118, 83, 135, 153, 118, 171)
    Add-IconPolygon $wPath $scale 0 0 @(130, 171, 151, 171, 165, 83, 145, 83)

    $pStemPath = New-RoundedRectanglePath (145 * $scale) (77 * $scale) (27 * $scale) (109 * $scale) (13 * $scale)
    $pBowlPath = [System.Drawing.Drawing2D.GraphicsPath]::new([System.Drawing.Drawing2D.FillMode]::Alternate)
    $pBowlOuter = New-RoundedRectanglePath (161 * $scale) (77 * $scale) (68 * $scale) (71 * $scale) (35 * $scale)
    $pBowlInner = New-RoundedRectanglePath (176 * $scale) (97 * $scale) (29 * $scale) (30 * $scale) (14 * $scale)
    $pBowlPath.AddPath($pBowlOuter, $false)
    $pBowlPath.AddPath($pBowlInner, $false)

    $shadowMatrix = [System.Drawing.Drawing2D.Matrix]::new()
    $shadowMatrix.Translate(0, 5 * $scale)
    $wShadowPath = $wPath.Clone()
    $pStemShadowPath = $pStemPath.Clone()
    $pBowlShadowPath = $pBowlPath.Clone()
    $wShadowPath.Transform($shadowMatrix)
    $pStemShadowPath.Transform($shadowMatrix)
    $pBowlShadowPath.Transform($shadowMatrix)
    $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(82, 5, 15, 35))
    $graphics.FillPath($shadowBrush, $wShadowPath)
    $graphics.FillPath($shadowBrush, $pStemShadowPath)
    $graphics.FillPath($shadowBrush, $pBowlShadowPath)

    $letterBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(41 * $scale, 77 * $scale, 188 * $scale, 109 * $scale),
        [System.Drawing.Color]::White,
        [System.Drawing.Color]::FromArgb(255, 223, 251, 255),
        35
    )
    $graphics.FillPath($letterBrush, $wPath)
    $graphics.FillPath($letterBrush, $pStemPath)
    $graphics.FillPath($letterBrush, $pBowlPath)

    $strokePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(58, 232, 248, 255), [Math]::Max(1, 1.5 * $scale))
    $strokePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawPath($strokePen, $wPath)
    $graphics.DrawPath($strokePen, $pStemPath)
    $graphics.DrawPath($strokePen, $pBowlPath)

    $stream = [System.IO.MemoryStream]::new()
    $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bytes = $stream.ToArray()

    $strokePen.Dispose()
    $letterBrush.Dispose()
    $shadowBrush.Dispose()
    $wShadowPath.Dispose()
    $pStemShadowPath.Dispose()
    $pBowlShadowPath.Dispose()
    $shadowMatrix.Dispose()
    $wPath.Dispose()
    $pStemPath.Dispose()
    $pBowlPath.Dispose()
    $pBowlOuter.Dispose()
    $pBowlInner.Dispose()
    $shineBrush.Dispose()
    $shinePath.Dispose()
    $borderPen.Dispose()
    $innerPath.Dispose()
    $gradient.Dispose()
    $path.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    $stream.Dispose()

    return $bytes
}

function New-IconDibBytes {
    param([int] $Size)

    $pngBytes = New-IconPngBytes $Size
    $pngStream = [System.IO.MemoryStream]::new($pngBytes)
    $bitmap = [System.Drawing.Bitmap]::new($pngStream)

    $rowBytes = $Size * 4
    $maskRowBytes = [int]([Math]::Ceiling($Size / 32.0) * 4)
    $xorBytesLength = $rowBytes * $Size
    $maskBytesLength = $maskRowBytes * $Size
    $stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.BinaryWriter]::new($stream)

    $writer.Write([UInt32]40)
    $writer.Write([Int32]$Size)
    $writer.Write([Int32]($Size * 2))
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]0)
    $writer.Write([UInt32]($xorBytesLength + $maskBytesLength))
    $writer.Write([Int32]0)
    $writer.Write([Int32]0)
    $writer.Write([UInt32]0)
    $writer.Write([UInt32]0)

    for ($y = $Size - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $Size; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $writer.Write([byte]$pixel.B)
            $writer.Write([byte]$pixel.G)
            $writer.Write([byte]$pixel.R)
            $writer.Write([byte]$pixel.A)
        }
    }

    $writer.Write((New-Object byte[] $maskBytesLength))
    $bytes = $stream.ToArray()

    $writer.Dispose()
    $stream.Dispose()
    $bitmap.Dispose()
    $pngStream.Dispose()

    return $bytes
}

function Write-IconFile {
    param(
        [string] $Path,
        [int[]] $Sizes
    )

    $largestSize = ($Sizes | Sort-Object -Descending | Select-Object -First 1)
    $pngBytes = New-IconPngBytes $largestSize
    $pngStream = [System.IO.MemoryStream]::new($pngBytes)
    $bitmap = [System.Drawing.Bitmap]::new($pngStream)
    $handle = $bitmap.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($handle)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    $icon.Save($stream)

    $stream.Dispose()
    $icon.Dispose()
    $bitmap.Dispose()
    $pngStream.Dispose()
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$pngPath = Join-Path $OutputDirectory 'AppIcon.png'
$icoPath = Join-Path $OutputDirectory 'AppIcon.ico'

[System.IO.File]::WriteAllBytes($pngPath, (New-IconPngBytes 256))
Write-IconFile $icoPath @(64)

Write-Host "Generated $pngPath"
Write-Host "Generated $icoPath"
