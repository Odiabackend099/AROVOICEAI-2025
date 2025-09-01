# Quick verification test for hardened ODIADEV Edge-TTS
param(
    [string]$ApiBase = "http://localhost:5000",
    [string]$ApiKey = "ODIADEV-KEY-777"
)

Write-Host "Testing hardened ODIADEV Edge-TTS system..." -ForegroundColor Green
Write-Host "API Base: $ApiBase" -ForegroundColor Cyan

# Test 1: Health endpoint (should be lightweight and robust)
Write-Host "`n1. Testing health endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$ApiBase/health" -Method GET
    Write-Host "✅ Health OK: voices=$($health.voices), ng_voices=$($health.ng_voices), hash=$($health.hash)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health failed: $_" -ForegroundColor Red
}

# Test 2: Root endpoint
Write-Host "`n2. Testing root endpoint..." -ForegroundColor Yellow
try {
    $root = Invoke-RestMethod -Uri "$ApiBase/" -Method GET
    Write-Host "✅ Root OK: $($root.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Root failed: $_" -ForegroundColor Red
}

# Test 3: TTS generation (30-second test)
Write-Host "`n3. Testing TTS generation..." -ForegroundColor Yellow
$outDir = "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "hardened-test.mp3"

$TestText = "This is a verification test of the hardened ODIADEV Edge-TTS system. The health endpoint is now lightweight and robust. TTS generation is working perfectly. System is production-ready!"

$payload = @{ text=$TestText; voice="en-NG-EzinneNeural"; format="mp3_48k" }
$body = $payload | ConvertTo-Json -Depth 5
$headers = @{ "Content-Type"="application/json; charset=utf-8"; "X-API-Key"=$ApiKey }

try {
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    Invoke-WebRequest -Method POST -Uri "$ApiBase/api/speak" -Headers $headers -Body $bodyBytes -OutFile $out -TimeoutSec 60
    
    if (Test-Path $out) {
        $fileSize = (Get-Item $out).Length
        Write-Host "✅ TTS OK: Generated $([math]::Round($fileSize / 1024, 1)) KB" -ForegroundColor Green
        Write-Host "🎵 Playing hardened test audio..." -ForegroundColor Cyan
        Start-Process $out
    } else {
        Write-Host "❌ TTS failed: No audio file created" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ TTS failed: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Hardened system verification complete!" -ForegroundColor Green
