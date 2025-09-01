# Quick 30-Second Test for ODIADEV Edge-TTS
param(
    [string]$ApiBase = "http://localhost:5000",
    [string]$ApiKey = "ODIADEV-KEY-777",
    [string]$Voice = "en-NG-EzinneNeural"
)

$ErrorActionPreference = "Stop"
$outDir = "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "quick-test.mp3"

# 30-second test script (~300 chars)
$TestText = @"
This is a thirty-second verification test of your ODIADEV Edge-TTS system. 
The audio is being generated from your local server right now. 
If you can hear this clearly, your TTS system is working perfectly. 
This confirms your API is functional and ready for production use. 
Test completed successfully!
"@

$payload = @{ text=$TestText; voice=$Voice; format="mp3_48k" }
$body = $payload | ConvertTo-Json -Depth 5
$headers = @{ "Content-Type"="application/json; charset=utf-8"; "X-API-Key"=$ApiKey }

Write-Host "Generating 30-second test audio..." -ForegroundColor Green
Write-Host "API: $ApiBase" -ForegroundColor Cyan
Write-Host "Voice: $Voice" -ForegroundColor Cyan
Write-Host "Text length: $($TestText.Length) chars" -ForegroundColor Yellow

try {
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    Invoke-WebRequest -Method POST -Uri "$ApiBase/api/speak" -Headers $headers -Body $bodyBytes -OutFile $out -TimeoutSec 60
    
    if (Test-Path $out) {
        $fileSize = (Get-Item $out).Length
        Write-Host "SUCCESS! Test audio generated: $out" -ForegroundColor Green
        Write-Host "File size: $([math]::Round($fileSize / 1024, 1)) KB" -ForegroundColor White
        Write-Host "Playing test audio now..." -ForegroundColor Cyan
        
        # Auto-play the test audio
        Start-Process $out
        
        Write-Host ""
        Write-Host "VERIFICATION COMPLETE!" -ForegroundColor Green
        Write-Host "If you can hear the audio, your system is working!" -ForegroundColor White
    } else {
        throw "Audio file not created"
    }
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    Write-Host "Check if server is running on $ApiBase" -ForegroundColor Yellow
}
