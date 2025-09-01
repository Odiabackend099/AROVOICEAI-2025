# ODIADEV Monetization Script Generator for EC2
param(
    [string]$ApiBase = "",  # Your EC2 IP will go here
    [string]$ApiKey = "",   # Your production API key will go here
    [string]$Voice = "en-NG-EzinneNeural",
    [string]$Format = "mp3_48k"
)

if (-not $ApiBase) {
    Write-Host "⚠️  Please provide your EC2 API base URL" -ForegroundColor Yellow
    Write-Host "Example: .\monetization-script.ps1 -ApiBase 'http://YOUR-EC2-IP' -ApiKey 'YOUR-API-KEY'" -ForegroundColor Cyan
    exit 1
}

if (-not $ApiKey) {
    Write-Host "⚠️  Please provide your API key" -ForegroundColor Yellow
    Write-Host "Example: .\monetization-script.ps1 -ApiBase 'http://YOUR-EC2-IP' -ApiKey 'YOUR-API-KEY'" -ForegroundColor Cyan
    exit 1
}

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $Here "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir "monetization-strategy.mp3"

# Monetization-focused script (optimized for 1 minute / ~750 chars)
$MonetizationText = @"
Listen up! Your AROVOICEAI platform isn't just tech - it's a goldmine waiting to be tapped. Here's how we turn this into serious revenue streams.

First, API-as-a-Service. Charge creators five to twenty dollars monthly for unlimited voice generation. Nigerian content creators alone represent a fifty million dollar market.

Second, white-label licensing. Sell this platform to agencies, media companies, and ed-tech startups for ten to fifty thousand per license. They rebrand it, we collect royalties.

Third, voice marketplace. Let users upload custom voice models, take thirty percent commission on each sale. Think Fiverr meets voice cloning.

Fourth, enterprise contracts. News stations, e-learning platforms, audiobook publishers - they'll pay fifty to two hundred thousand annually for unlimited commercial usage.

The numbers are insane. Conservative estimate: fifty thousand monthly revenue within six months. Scale properly, and we're looking at multi-million dollar valuations.

Ready to build this empire? Let's monetize AROVOICEAI and dominate the voice tech space!
"@

# Validate text length
if ($MonetizationText.Length -gt 800) {
    Write-Host "⚠️  Script too long ($($MonetizationText.Length) chars). Truncating to 800..." -ForegroundColor Yellow
    $MonetizationText = $MonetizationText.Substring(0, 800)
}

$payload = @{ text=$MonetizationText; voice=$Voice; format=$Format }
$body = $payload | ConvertTo-Json -Depth 5
$headers = @{ "Content-Type"="application/json; charset=utf-8"; "X-API-Key"=$ApiKey }

Write-Host "🚀 Generating monetization strategy audio from EC2..." -ForegroundColor Green
Write-Host "📡 API Base: $ApiBase" -ForegroundColor Cyan
Write-Host "🎤 Voice: $Voice" -ForegroundColor Cyan
Write-Host "📝 Script length: $($MonetizationText.Length) chars" -ForegroundColor Yellow

try {
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    Invoke-WebRequest -Method POST -Uri "$ApiBase/api/speak" -Headers $headers -Body $bodyBytes -OutFile $out -TimeoutSec 180
    
    if (Test-Path $out) {
        $fileSize = (Get-Item $out).Length
        Write-Host "SUCCESS! Generated: $out" -ForegroundColor Green
        Write-Host "File size: $([math]::Round($fileSize / 1024, 1)) KB" -ForegroundColor White
        Write-Host "Playing monetization strategy..." -ForegroundColor Cyan
        
        # Auto-play the monetization audio
        Start-Process $out
        
        Write-Host ""
        Write-Host "MONETIZATION OPPORTUNITIES:" -ForegroundColor Yellow
        Write-Host "- API Subscriptions: 5-20/month per creator" -ForegroundColor White
        Write-Host "- White-label Licenses: 10K-50K per company" -ForegroundColor White
        Write-Host "- Voice Marketplace: 30% commission" -ForegroundColor White
        Write-Host "- Enterprise Contracts: 50K-200K annually" -ForegroundColor White
        Write-Host "- Target Revenue: 50K+/month within 6 months" -ForegroundColor Green
    } else {
        throw "Audio file not created"
    }
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "- Check if EC2 server is running" -ForegroundColor White
        Write-Host "- Verify API key is correct" -ForegroundColor White
        Write-Host "- Test health endpoint: $ApiBase/health" -ForegroundColor White
}
