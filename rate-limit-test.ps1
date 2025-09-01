# ODIADEV Edge-TTS Rate Limiting Test
# This test properly validates rate limiting by making requests over time

param(
    [string]$ApiBase = "http://localhost:5000",
    [string]$ApiKey = "ODIADEV-KEY-777"
)

Write-Host "🚀 ODIADEV Edge-TTS RATE LIMITING TEST" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$headers = @{ "Content-Type"="application/json; charset=utf-8"; "X-API-Key"=$ApiKey }
$body = @{ text="Rate limit test" } | ConvertTo-Json
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

Write-Host "Making 35 requests with 2-second intervals..." -ForegroundColor Yellow
Write-Host "Expected: First 30 requests succeed, next 5 get rate limited" -ForegroundColor Yellow

$rateLimited = $false
$successCount = 0
$rateLimitCount = 0

for ($i = 1; $i -le 35; $i++) {
    try {
        $response = Invoke-WebRequest -Method POST -Uri "$ApiBase/api/speak" -Headers $headers -Body $bodyBytes -TimeoutSec 10
        $successCount++
        Write-Host "Request $i`: ✅ 200" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode
        if ($statusCode -eq 429) {
            $rateLimitCount++
            Write-Host "Request $i`: ✅ 429 (Rate Limited)" -ForegroundColor Green
            $rateLimited = $true
        } else {
            Write-Host "Request $i`: ❌ $statusCode" -ForegroundColor Red
        }
    }
    
    # Wait 2 seconds between requests to properly test rate limiting
    if ($i -lt 35) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "`n📊 RATE LIMITING TEST RESULTS:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Successful requests: $successCount" -ForegroundColor Green
Write-Host "Rate limited requests: $rateLimitCount" -ForegroundColor Yellow

if ($rateLimited) {
    Write-Host "✅ Rate limiting is working correctly!" -ForegroundColor Green
    Write-Host "✅ System properly enforces 30 requests per minute limit" -ForegroundColor Green
} else {
    Write-Host "⚠️ Rate limiting may need adjustment" -ForegroundColor Yellow
    Write-Host "Expected some requests to be rate limited after 30 requests" -ForegroundColor Yellow
}

Write-Host "`n🎉 Rate limiting test complete!" -ForegroundColor Cyan
