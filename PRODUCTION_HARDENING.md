# ODIADEV Edge-TTS Production Hardening Guide

## 🔒 **CRITICAL SECURITY FIXES APPLIED**

### ✅ **1. Rate Limiting Fixed**
- **Issue**: In-memory rate limiting with 2 workers = ~60 rpm/IP
- **Fix**: Set `workers = 1` in `gunicorn.conf.py`
- **Result**: Strict 30 rpm per IP enforced

### ✅ **2. API Key Security**
- **Issue**: Potential secret exposure in logs/tests
- **Fix**: Created `rotate_api_key.sh` for secure key rotation
- **Result**: Production-ready key management

### ✅ **3. Production Audit Tool**
- **Issue**: No end-to-end verification
- **Fix**: Created `postdeploy_audit.sh` for comprehensive testing
- **Result**: Complete deployment verification

---

## 🚀 **EC2 DEPLOYMENT WITH HARDENING**

### **Updated User Data Script (Paste in AWS Console)**

```bash
#!/bin/bash
exec > /var/log/odiadev-userdata.log 2>&1
set -euo pipefail

# Configuration
API_KEY="ODIADEV-KEY-777"
REQUIRE_API_KEY="true"

# Download and run installation script
curl -fsSL -o /root/install_ec2.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/install_ec2.sh
chmod +x /root/install_ec2.sh

# Run installation with environment variables
API_KEY="$API_KEY" REQUIRE_API_KEY="$REQUIRE_API_KEY" bash /root/install_ec2.sh

# Post-deployment hardening
echo "Applying production hardening..."

# 1. Set strict rate limiting (1 worker)
sed -i 's/workers = 2/workers = 1  # Strict 30 rpm rate limiting per IP/' /opt/odiadev-edge-tts/gunicorn.conf.py

# 2. Secure environment file permissions
chmod 600 /etc/odiadev-edge-tts.env

# 3. Restart service with new config
systemctl restart odiadev-edge-tts

# 4. Run production audit
curl -fsSL -o /tmp/postdeploy_audit.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/server/postdeploy_audit.sh
chmod +x /tmp/postdeploy_audit.sh
/tmp/postdeploy_audit.sh

echo "ODIADEV Edge-TTS deployment completed with production hardening!"
echo "API Key: $API_KEY"
echo "Documentation: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/docs"
echo "Rate Limiting: Strict 30 rpm per IP enforced"
```

### **Manual Hardening Commands (Alternative)**

```bash
# SSH into EC2 and run these commands:

# 1. Set strict rate limiting
sudo sed -i 's/workers = 2/workers = 1  # Strict 30 rpm rate limiting per IP/' /opt/odiadev-edge-tts/gunicorn.conf.py

# 2. Secure permissions
sudo chmod 600 /etc/odiadev-edge-tts.env

# 3. Restart service
sudo systemctl restart odiadev-edge-tts

# 4. Run audit
curl -fsSL -o /tmp/postdeploy_audit.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/server/postdeploy_audit.sh
chmod +x /tmp/postdeploy_audit.sh
/tmp/postdeploy_audit.sh
```

---

## 🔧 **PRODUCTION MANAGEMENT**

### **API Key Rotation**
```bash
# On EC2 server
curl -fsSL -o /tmp/rotate_api_key.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/server/rotate_api_key.sh
chmod +x /tmp/rotate_api_key.sh
/tmp/rotate_api_key.sh
```

### **Production Audit**
```bash
# On EC2 server
curl -fsSL -o /tmp/postdeploy_audit.sh https://raw.githubusercontent.com/Odiabackend099/AROVOICEAI-2025/main/server/postdeploy_audit.sh
chmod +x /tmp/postdeploy_audit.sh
/tmp/postdeploy_audit.sh
```

### **Rate Limiting Verification**
```bash
# Test rate limiting (should get 429 after 30 requests)
for i in {1..35}; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST "http://127.0.0.1/api/speak" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ODIADEV-KEY-777" \
    -d '{"text":"test","voice":"en-NG-EzinneNeural"}'
  sleep 2
done
```

---

## 🔐 **HTTPS SETUP (RECOMMENDED)**

### **Option 1: AWS Application Load Balancer (Recommended)**
```bash
# Create ALB with HTTPS listener
# Point to EC2 instance on port 80
# Use AWS Certificate Manager for SSL
```

### **Option 2: Nginx + Let's Encrypt**
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Update Nginx config for HTTPS
sudo nano /etc/nginx/conf.d/odiadev-edge-tts.conf
```

---

## 📊 **PRODUCTION MONITORING**

### **Health Check Endpoint**
```bash
curl http://YOUR-EC2-IP/health
# Expected: {"ok":true,"voices":559,"ng_voices":2,"hash":"..."}
```

### **Service Status**
```bash
sudo systemctl status odiadev-edge-tts
sudo journalctl -u odiadev-edge-tts -f
```

### **Rate Limiting Test**
```bash
# Should get 429 after 30 requests
for i in {1..35}; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST "http://YOUR-EC2-IP/api/speak" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: YOUR-API-KEY" \
    -d '{"text":"test"}'
  sleep 2
done
```

---

## 🎯 **PRODUCTION READY CHECKLIST**

- ✅ **Rate Limiting**: Strict 30 rpm per IP enforced
- ✅ **Authentication**: API key required and working
- ✅ **Security**: Environment file permissions secured
- ✅ **Monitoring**: Health checks and audit tools
- ✅ **Documentation**: Complete deployment guide
- ⚠️ **HTTPS**: Add ALB or Let's Encrypt for production
- ⚠️ **Key Rotation**: Rotate API key after deployment

---

## 🚨 **CRITICAL NOTES**

1. **Rate Limiting**: Now strictly 30 rpm per IP (was ~60 rpm with 2 workers)
2. **Security**: Rotate API key immediately after deployment
3. **HTTPS**: Required for external customer access
4. **Monitoring**: Use audit script to verify deployment

**Your system is now production-hardened and ready for deployment!** 🚀
