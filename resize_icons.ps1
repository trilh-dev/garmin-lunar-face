Add-Type -AssemblyName System.Drawing
$dir = "d:\Antigravity Project\Garmin_Watch_Face\resources\drawables\"
$files = Get-ChildItem "$dir\*.png" | Where-Object { $_.Name -ne "launcher_icon.png" }

foreach ($file in $files) {
    Write-Host "Resizing $($file.Name)..."
    $img = [System.Drawing.Image]::FromFile($file.FullName)
    $resized = New-Object System.Drawing.Bitmap(24, 24)
    $g = [System.Drawing.Graphics]::FromImage($resized)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, 24, 24)
    $g.Dispose()
    $img.Dispose()
    
    $outputPath = $file.FullName
    $resized.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $resized.Dispose()
}
Write-Host "Done!"
