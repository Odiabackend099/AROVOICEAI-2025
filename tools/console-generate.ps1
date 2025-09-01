# ODIADEV Console TikTok Generator — Windows
param(
  [string]$ApiBase = "http://YOUR-EC2-IP",
  [string]$ApiKey  = "ODIADEV-KEY-777",
  [string]$Voice   = "en-NG-EzinneNeural",
  [string]$Format  = "mp3_48k"
)
$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $Here "..\out"; New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "viral.mp3"

# ~60s viral script (shortened to fit 800 char limit)
$Text = @"
Stop scrolling! This voice is generated live by ODIADEV Edge-TTS — hosted on our own server, no third-party keys.

Here's the sauce: type your script, choose a Nigerian voice like Ezinne or Abeo, tap Generate, and the audio drops instantly as MP3 for TikTok, Reels, or WhatsApp status. It's fast on 3G and sounds natural.

Ideas for today: mini tutorial, product shout-out, price update, or motivational hook. Keep it punchy and end with a call to action.

Ready to level up your content? Try ODIADEV Edge-TTS now — link in bio or DM for access. No wahala, just clean audio that makes people stop and listen. Let's go!
"@

$payload = @{ text=$Text; voice=$Voice; format=$Format }
$body = $payload | ConvertTo-Json -Depth 5
$headers = @{ "Content-Type"="application/json; charset=utf-8"; "X-API-Key"=$ApiKey }

Write-Host "⇒ Hitting $ApiBase/api/speak …" -ForegroundColor Cyan
Write-Host "Text length: $($Text.Length) chars" -ForegroundColor Yellow

# Use -Body parameter directly with UTF8 encoding
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-WebRequest -Method POST -Uri "$ApiBase/api/speak" -Headers $headers -Body $bodyBytes -OutFile $out -TimeoutSec 180
if (-not (Test-Path $out) -or ((Get-Item $out).Length -lt 10000)) { throw "Synthesis failed or empty file." }
Write-Host "✅ Saved: $out" -ForegroundColor Green

# Autoplay via default media player
Start-Process $out
