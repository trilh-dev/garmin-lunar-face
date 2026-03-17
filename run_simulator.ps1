$sdkPath = (Get-ChildItem -Path "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Select-Object -First 1).FullName
$env:PATH = "$sdkPath\bin;" + $env:PATH
Write-Host "Starting Simulator..."
Start-Process simulator.exe
Write-Host "Waiting 8 seconds for Simulator to boot..."
Start-Sleep -Seconds 8
Write-Host "Deploying WatchFace..."
monkeydo.bat "d:\Antigravity Project\Garmin_Watch_Face\bin\GarminWatchFace.prg" fr55
