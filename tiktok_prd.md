# ODIADEV Viral TikTok Generator — PRD (Final)

## 1. Goal
Deliver a zero-friction demo that calls the ODIADEV Edge-TTS API and produces a ~60s Nigerian-voice MP3 that **autoplays** (or degrades gracefully to a 1-tap play) for TikTok/Reels.

## 2. Users
- ODIADEV internal, sales, and partners needing instant voiceovers.
- Creators testing Nigerian voices (Ezinne/Abeo) before onboarding.

## 3. Success Metrics
- Time to first audio ≤ 6s on average (t3.small, MP3 48kbps).
- 100% success for console generate.  
- Web demo: ≥ 95% play success (autoplay or single tap).

## 4. Functional Requirements
- Web page (`client/index.html`)
  - Inputs: API base, API key, voice select (prefill with `en-NG-*`), format.
  - Text area prefilled with a ~60s viral script.
  - On load: fetch `/voices`, choose Nigerian default, **synthesize & autoplay** when `?autoplay=1`.
  - Show **Download** button and status pill; if autoplay blocked, reveal **Tap to Play**.
  - Accept config via query params: `api`, `key`, `voice`, `format`, `text`, `autoplay`.
- Console generator (`tools/console-generate.ps1`)
  - POST to `/api/speak`, save `out/viral.mp3`, and **auto-launch** default player.
  - Parameters: `-ApiBase`, `-ApiKey`, `-Voice`, `-Format`.
- CORS must permit the page origin (server already sets `*`).
- Auth via `X-API-Key`.

## 5. Non-Goals
- Account management, rate limiting changes, analytics, or billing.

## 6. Constraints & Assumptions
- Server is ODIADEV Edge-TTS on EC2 `t3.small` (x86).
- Network variability in NG; MP3 48kbps mono preferred.
- Browser autoplay policies may block **sound-on** autoplay; must provide 1-tap fallback.

## 7. Error Handling
- Status pill surfaces `loading voices…`, `synthesizing…`, `playing`, or `tap to play`.
- Alerts with server error payload.
- Console script throws on empty/short files.

## 8. Rollout & QA
- Manual: open `client/index.html?api=http://<EC2-IP>&key=<API_KEY>&autoplay=1`.
- Console: `.\tools\console-generate.ps1 -ApiBase http://<EC2-IP> -ApiKey <API_KEY>`.
- Acceptance: MP3 plays; file size > 100KB; duration ~ 50–70s.

## 9. Risks & Mitigations
- **Autoplay blocked:** try autoplay; if fail, reveal Tap-to-Play. Console path guarantees autoplay.
- **Slow synth:** keep format low bitrate (48kbps), show live status.
- **Invalid key:** bubble server error message; do not log secrets.
