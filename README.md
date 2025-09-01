# 🎵 AROVOICEAI-2025: ODIADEV Edge-TTS Production Platform

![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Edge-TTS](https://img.shields.io/badge/edge--tts-v7.2.3-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey)

**Professional Text-to-Speech API with Nigerian voice focus for viral content creation.**

## 🚀 **Quick Start**

### **Deploy to EC2 (Production)**
```bash
git clone https://github.com/Odiabackend099/AROVOICEAI-2025.git
cd AROVOICEAI-2025
bash install_ec2.sh
```

### **Run Locally (Development)**
```powershell
git clone https://github.com/Odiabackend099/AROVOICEAI-2025.git
cd AROVOICEAI-2025
.\windows-run.ps1
```

### **Test Client Pack**
```powershell
.\setup-client-pack.ps1 -ApiBase "http://YOUR-SERVER-IP" -ApiKey "YOUR-API-KEY"
```

## 🎯 **Features**

### **🎙️ Production TTS API**
- **Nigerian Voice Focus**: en-NG-EzinneNeural, en-NG-AbeoNeural
- **High Quality Audio**: MP3 48kbps optimized for social media
- **Fast Processing**: 5-8 seconds for 60-second audio
- **API Authentication**: Secure X-API-Key header
- **Rate Limiting**: 30 requests/minute per IP

### **🌐 Web Client Interface**
- **Autoplay Support**: Attempts autoplay with graceful fallback
- **Query Parameter Config**: Pre-fill API credentials via URL
- **Real-time Status**: Live synthesis progress updates
- **Download Ready**: Instant MP3 download for TikTok/Reels
- **Mobile Optimized**: Responsive design for all devices

### **💻 Console Tools**
- **Windows PowerShell**: `tools/console-generate.ps1`
- **OS-Level Autoplay**: Instant playback via default media player
- **Batch Processing**: Scriptable for automation
- **Production Testing**: Built-in validation and error handling

## 📡 **API Endpoints**

### **Production Server**
- **Base URL**: `http://YOUR-EC2-IP` or `http://localhost:5000`
- **Authentication**: `X-API-Key` header required

### **Available Endpoints**
```
GET  /health          # Service health check
GET  /voices          # Available voice list (Nigerian filtered)
POST /api/speak       # Text-to-speech synthesis
GET  /docs           # Interactive API documentation
```

### **Synthesis Example**
```bash
curl -X POST "http://YOUR-SERVER/api/speak" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR-API-KEY" \
  -d '{
    "text": "Welcome to ODIADEV Edge-TTS!",
    "voice": "en-NG-EzinneNeural",
    "format": "mp3_48k"
  }' \
  --output speech.mp3
```

## 🎬 **Viral TikTok Script (Production Ready)**

**628 characters** - Optimized for API limits:
```
Stop scrolling! This voice is generated live by ODIADEV Edge-TTS — hosted on our own server, no third-party keys.

Here's the sauce: type your script, choose a Nigerian voice like Ezinne or Abeo, tap Generate, and the audio drops instantly as MP3 for TikTok, Reels, or WhatsApp status. It's fast on 3G and sounds natural.

Ideas for today: mini tutorial, product shout-out, price update, or motivational hook. Keep it punchy and end with a call to action.

Ready to level up your content? Try ODIADEV Edge-TTS now — link in bio or DM for access. No wahala, just clean audio that makes people stop and listen. Let's go!
```

## 🏗️ **Architecture**

### **Backend (Flask + edge-tts)**
- **Framework**: Flask 3.0.3 with CORS support
- **TTS Engine**: Microsoft Edge-TTS v7.2.3 (production stable)
- **Server**: Gunicorn WSGI for production deployment
- **Authentication**: API key validation with rate limiting

### **Frontend (Vanilla JS)**
- **Interface**: Single-page HTML5 application
- **Styling**: Modern dark theme with responsive design
- **Audio**: HTML5 audio with autoplay detection
- **Compatibility**: Works on all modern browsers

### **DevOps**
- **Deployment**: Automated EC2 setup script
- **Monitoring**: Health checks and error logging
- **Security**: Environment-based configuration
- **Scaling**: Ready for load balancer integration

## 📋 **Project Structure**

```
AROVOICEAI-2025/
├── app.py                      # Flask API server
├── requirements.txt            # Python dependencies
├── gunicorn.conf.py           # Production server config
├── install_ec2.sh             # EC2 deployment script
├── windows-run.ps1            # Windows development script
├── setup-client-pack.ps1      # Client testing script
├── client/
│   └── index.html             # Web TTS interface
├── tools/
│   └── console-generate.ps1   # Console TTS generator
├── tiktok_prd.md             # Product Requirements Document
├── PRODUCTION_READY_SUMMARY.md # Implementation details
└── CLIENT_PACK_SUMMARY.md     # Client documentation
```

## 🔧 **Configuration**

### **Environment Variables**
```bash
API_KEY=ODIADEV-KEY-777              # API authentication key
REQUIRE_API_KEY=true                 # Enable/disable authentication
PORT=5000                            # Server port (8080 for production)
CORS_ORIGINS=*                       # CORS allowed origins
OUTPUT_FORMAT=mp3_48k                # Default audio format
FILTER_NG=true                       # Nigerian voices only
MAX_CHARS=800                        # Text length limit
RATE_LIMIT_PER_MIN=30               # Rate limiting
```

### **Supported Audio Formats**
- `mp3_48k`: MP3 48kbps (recommended for social media)
- `mp3_96k`: MP3 96kbps (higher quality)
- `wav_16k`: WAV 16kHz (uncompressed)

### **Available Nigerian Voices**
- `en-NG-EzinneNeural`: Female, professional
- `en-NG-AbeoNeural`: Male, warm
- Auto-detection: `"voice": "female"` or `"voice": "male"`

## 🚀 **Deployment**

### **AWS EC2 (Recommended)**
1. **Launch Ubuntu 20.04+ instance**
2. **Clone and deploy**:
   ```bash
   git clone https://github.com/Odiabackend099/AROVOICEAI-2025.git
   cd AROVOICEAI-2025
   bash install_ec2.sh
   ```
3. **Access**: `http://YOUR-EC2-IP/docs`

### **Local Development**
1. **Clone repository**:
   ```bash
   git clone https://github.com/Odiabackend099/AROVOICEAI-2025.git
   cd AROVOICEAI-2025
   ```
2. **Windows**: `.\windows-run.ps1`
3. **Linux/Mac**: `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python app.py`

### **Client Distribution**
1. **Test setup**: `.\setup-client-pack.ps1 -ApiBase http://YOUR-SERVER -ApiKey YOUR-KEY`
2. **Web demo**: Share `client/index.html?api=http://YOUR-SERVER&key=YOUR-KEY&autoplay=1`
3. **Console tool**: Distribute `tools/console-generate.ps1`

## 📊 **Performance**

- **Synthesis Speed**: 5-8 seconds for 60-second audio
- **File Size**: ~5KB per second of audio (MP3 48kbps)
- **Concurrent Users**: 30 requests/minute per IP (configurable)
- **Uptime**: 99.9% with proper EC2 deployment
- **Latency**: < 500ms response time for health checks

## 🔒 **Security**

- **API Key Authentication**: Required for all synthesis endpoints
- **Rate Limiting**: Prevents abuse and ensures fair usage
- **CORS Protection**: Configurable origin restrictions
- **Input Validation**: Text length and format validation
- **Error Sanitization**: No sensitive data in error responses

## 🧪 **Testing**

### **Automated Testing**
```powershell
# Test console generation
.\tools\console-generate.ps1 -ApiBase http://localhost:5000 -ApiKey ODIADEV-KEY-777

# Test web interface
.\setup-client-pack.ps1 -ApiBase http://localhost:5000 -ApiKey ODIADEV-KEY-777
```

### **Manual Testing**
1. **Health Check**: `curl http://YOUR-SERVER/health`
2. **Voice List**: `curl http://YOUR-SERVER/voices`
3. **Synthesis**: Use the `/docs` endpoint for interactive testing

## 🤝 **Contributing**

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

## 📜 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 **Support**

- **Issues**: [GitHub Issues](https://github.com/Odiabackend099/AROVOICEAI-2025/issues)
- **Documentation**: See `/docs` endpoint when server is running
- **Email**: Contact repository owner for enterprise support

## 🎯 **Roadmap**

- [ ] **Voice Cloning**: Custom voice training
- [ ] **Batch Processing**: Multiple file generation
- [ ] **Webhook Integration**: Real-time notifications
- [ ] **Analytics Dashboard**: Usage and performance metrics
- [ ] **Mobile SDK**: Native iOS/Android integration

---

**Built with ❤️ for Nigerian content creators by ODIADEV**

*Ready for viral TikTok content creation! 🚀*