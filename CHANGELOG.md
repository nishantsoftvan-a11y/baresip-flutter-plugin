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
