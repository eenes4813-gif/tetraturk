# yt-dlp ve ffmpeg'i uygulamanın "tools" klasörüne indirir.
# Kullanım: derlenen klasörde (build\windows\x64\runner\Release) çalıştırın:
#   powershell -ExecutionPolicy Bypass -File setup_windows.ps1
$t = Join-Path $PSScriptRoot "tools"
New-Item -ItemType Directory -Force $t | Out-Null
Invoke-WebRequest "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile "$t\yt-dlp.exe"
$zip = Join-Path $env:TEMP "ffmpeg.zip"
Invoke-WebRequest "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile $zip
Expand-Archive $zip "$env:TEMP\ffx" -Force
Copy-Item "$env:TEMP\ffx\*\bin\ffmpeg.exe","$env:TEMP\ffx\*\bin\ffprobe.exe" $t -Force
Write-Host "Hazır: $t"
