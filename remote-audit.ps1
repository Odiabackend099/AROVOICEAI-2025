# ODIADEV Remote Audit Runner
# Use this to SSH in, run the audit, and print the summary

param(
    [string]$EC2IP = "YOUR-EC2-IP",
    [string]$SSHKey = "C:\Path\to\your\ec2.pem"
)

Write-Host "🚀 ODIADEV Remote Production Audit" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "EC2 IP: $EC2IP" -ForegroundColor Yellow
Write-Host "SSH Key: $SSHKey" -ForegroundColor Yellow

# Check if SSH key exists
if (-not (Test-Path $SSHKey)) {
    Write-Host "❌ SSH key not found: $SSHKey" -ForegroundColor Red
    Write-Host "Please update the SSH key path in this script" -ForegroundColor Yellow
    exit 1
}

# Remote audit command
$auditCommand = @'
sudo bash -lc "
# Download and run production audit
curl -fsSL -o /tmp/postdeploy_audit.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/server/postdeploy_audit.sh || true;

if [ ! -s /tmp/postdeploy_audit.sh ]; then
    echo 'Failed to download audit script, creating minimal version...'
    cat >/tmp/postdeploy_audit.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
SERVICE='odiadev-edge-tts'
echo '== ODIADEV Edge-TTS Quick Audit =='
systemctl is-active $SERVICE && echo '✅ Service running' || echo '❌ Service not running'
curl -fsS http://127.0.0.1/ | grep -q '"ok": true' && echo '✅ Root OK' || echo '❌ Root failed'
curl -fsS http://127.0.0.1/health | grep -q '"ok": true' && echo '✅ Health OK' || echo '❌ Health failed'
echo 'Audit complete'
EOF
fi

chmod +x /tmp/postdeploy_audit.sh;
/tmp/postdeploy_audit.sh
"
'@

Write-Host "`n🔍 Running production audit on EC2..." -ForegroundColor Green
Write-Host "This may take a few moments..." -ForegroundColor Yellow

try {
    # Run SSH command
    $result = ssh -i $SSHKey "ec2-user@$EC2IP" $auditCommand 2>&1
    
    Write-Host "`n📊 AUDIT RESULTS:" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host $result -ForegroundColor White
    
    # Check for success indicators
    if ($result -match "✅.*running" -and $result -match "✅.*OK") {
        Write-Host "`n🎉 PRODUCTION AUDIT PASSED!" -ForegroundColor Green
        Write-Host "Your ODIADEV Edge-TTS system is production-ready!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ AUDIT ISSUES DETECTED" -ForegroundColor Yellow
        Write-Host "Please check the audit results above" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ SSH connection failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify EC2 IP address is correct" -ForegroundColor White
    Write-Host "2. Check SSH key path and permissions" -ForegroundColor White
    Write-Host "3. Ensure EC2 security group allows SSH (port 22)" -ForegroundColor White
    Write-Host "4. Verify EC2 instance is running" -ForegroundColor White
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review audit results above" -ForegroundColor White
Write-Host "2. Rotate API key if needed: ssh -i $SSHKey ec2-user@$EC2IP 'sudo /tmp/rotate_api_key.sh'" -ForegroundColor White
Write-Host "3. Set up HTTPS for production use" -ForegroundColor White
Write-Host "4. Monitor system logs: ssh -i $SSHKey ec2-user@$EC2IP 'sudo journalctl -u odiadev-edge-tts -f'" -ForegroundColor White
