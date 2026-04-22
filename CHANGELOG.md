## 0.2.1

### Fix

- Fixed `BareSipSdk-release.aar` resolution when using pub.dev package — now looks for AAR in host app's `android/app/libs/` first, then falls back to plugin's own libs

---

### Bug Fixes & Improvements

**Audio Transmission Fixed:**
- Fixed audio not transmitting to remote party (one-way audio issue)
- Fixed SDP advertising private IP — server RTP proxy now handles NAT traversal
- Fixed codec registration: normalized codec names to full baresip format (`PCMU/8000/1`, `PCMA/8000/1`, `opus/48000/2`, `G722/16000/1`)
- Fixed double audio focus acquisition causing `AUDIOFOCUS_LOSS_TRANSIENT` interruption

**Stability Fixes:**
- Fixed SIGSEGV crash when `hangup()` called after remote BYE (double `ua_hangup` on freed pointer)
- Fixed `call_destroy` causing `pthread_mutex_lock on destroyed mutex` (SIGABRT) — baresip owns call lifecycle on `call closed` event
- Fixed `conf_configure` failure (`writing /config: Is a directory`) when service restarts after app kill
- Fixed incoming call events silently dropped due to `event_buf[256]` overflow with long hostnames — increased to 2048 bytes
- Fixed SIP trace logging thread buffer truncating SDP lines — increased from 128 to 2048 bytes
- Added null pointer guards in `ua_hangup` and `call_destroy` JNI to prevent native crashes

**Call Flow Improvements:**
- Correct baresip API sequence: `ua_call_alloc` + `call_connect` for outgoing (not `ua_connect`)
- `call_start_audio` called at correct time (on `ESTABLISHED` event, not before)
- `ended` flag on `SdkCallState` prevents double hangup operations
- `onCallClosed` never calls `call_destroy` — baresip already owns the call memory
- Single audio focus acquisition per call (guarded against re-acquisition)

**Configuration:**
- Removed invalid config keys that caused `conf_configure` failures
- Removed non-existent `.so` module directives (all modules statically linked)
- Static module registration via `mod_add()` for codecs, audio, NAT modules
- Log level now correctly uses `SdkConfig.logLevel`

**Breaking Changes:**
- None

---

## 0.1.0

### Initial Release

**Features:**
- ✅ SIP registration and authentication
- ✅ Outgoing and incoming call support
- ✅ Real-time event streaming (registration, call state, audio route, network, errors)
- ✅ Call controls (answer, reject, hangup, mute, hold)
- ✅ Audio routing (earpiece, speaker, wired headset, Bluetooth)
- ✅ Permission checking helper
- ✅ Foreground service for background operation
- ✅ Automatic registration retry (5 attempts, 30s intervals)
- ✅ Service persistence after app kill
- ✅ Comprehensive error handling

**Platform Support:**
- Android: ✅ (minSdk 29 / Android 10+)
- iOS: ❌ (not supported)

**Requirements:**
- Flutter SDK: 3.19.0+
- Dart SDK: 3.3.0+
- Android compileSdk: 34+
- Kotlin: 2.2.x
- BareSip SDK AAR (included in setup)

**Known Limitations:**
- Android only
- Requires BareSip SDK AAR in host app's libs folder
- Service stops when app is killed (use credential persistence for auto-login)

**Documentation:**
- Comprehensive README with setup guide
- API reference with all methods and events
- Example app demonstrating all features
- Troubleshooting section

**Breaking Changes:**
- None (initial release)
