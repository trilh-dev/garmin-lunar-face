$sdkPath = (Get-ChildItem -Path "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Select-Object -First 1).FullName
$env:PATH = "$sdkPath\bin;" + $env:PATH

Write-Host "Building Garmin Watch Face..."
monkeyc.bat -d fr55 -f monkey.jungle -o bin\GarminWatchFace.prg -y developer_key.der

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please check your code for errors."
    exit $LASTEXITCODE
}

Write-Host "Build successful!"

# Check if simulator is running, if not start it
$simProcess = Get-Process -Name "simulator" -ErrorAction SilentlyContinue
if (-not $simProcess) {
    Write-Host "Simulator is not running. Starting Simulator..."
    Start-Process simulator.exe
    Write-Host "Waiting 8 seconds for Simulator to boot..."
    Start-Sleep -Seconds 8
}

Write-Host "Deploying new build to Simulator..."
monkeydo.bat "d:\Antigravity Project\Garmin_Watch_Face\bin\GarminWatchFace.prg" fr55
