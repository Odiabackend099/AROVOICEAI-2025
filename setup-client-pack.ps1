# === ODIADEV — Create client tools + run (EDIT the two vars) ===
param(
    [string]$ApiBase = "http://localhost:5000",  # Change to your EC2 IP e.g. http://3.90.12.34
    [string]$ApiKey  = "ODIADEV-KEY-777"         # Your API key from server
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot

Write-Host "ODIADEV Client Pack Setup" -ForegroundColor Green
Write-Host "API Base: $ApiBase" -ForegroundColor Cyan
Write-Host "API Key:  $ApiKey" -ForegroundColor Cyan

# Ensure directories exist
New-Item -ItemType Directory -Force -Path "$ROOT\client" | Out-Null
New-Item -ItemType Directory -Force -Path "$ROOT\tools"  | Out-Null
New-Item -ItemType Directory -Force -Path "$ROOT\out"    | Out-Null

Write-Host "Directories created" -ForegroundColor Green

# Test console script first (autoplay via OS)
Write-Host "Testing console generator..." -ForegroundColor Yellow
try {
    & "$ROOT\tools\console-generate.ps1" -ApiBase $ApiBase -ApiKey $ApiKey
    Write-Host "Console test completed - MP3 should be playing!" -ForegroundColor Green
} catch {
    Write-Host "Console test failed: $_" -ForegroundColor Red
    Write-Host "Check your API base URL and key." -ForegroundColor Yellow
}

# Open web demo with query params (attempt autoplay)
Write-Host "Opening web demo..." -ForegroundColor Yellow
$qs = "api=$([uri]::EscapeDataString($ApiBase))&key=$([uri]::EscapeDataString($ApiKey))&autoplay=1"
$webPath = "file:///$($ROOT.Replace('\','/'))/client/index.html?$qs"
Write-Host "Web URL: $webPath" -ForegroundColor Gray
Start-Process $webPath

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Generated files:" -ForegroundColor Cyan
Write-Host "   client/index.html - Web interface with autoplay" -ForegroundColor White
Write-Host "   tools/console-generate.ps1 - Console generator" -ForegroundColor White
Write-Host "   tiktok_prd.md - Product requirements" -ForegroundColor White
Write-Host "   out/viral.mp3 - Generated audio" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "   * Update ApiBase and ApiKey variables in this script for your EC2" -ForegroundColor White
Write-Host "   * Test with your deployed API on EC2" -ForegroundColor White
Write-Host "   * Share the web demo URL with query params for instant testing" -ForegroundColor White
