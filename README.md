# baresip_flutter

A Flutter plugin that bridges the **BareSip SIP SDK** (Android AAR) to Dart via `MethodChannel` and `EventChannel`. It provides a clean, typed Dart API for SIP registration, outgoing/incoming calls, audio routing, and real-time event streaming.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Project Structure](#project-structure)
3. [Step 1 — Build the BareSip SDK AAR](#step-1--build-the-baresip-sdk-aar)
4. [Step 2 — Add the Plugin to Your Flutter App](#step-2--add-the-plugin-to-your-flutter-app)
5. [Step 3 — Android Setup](#step-3--android-setup)
   - [3.1 Copy the AAR](#31-copy-the-aar)
   - [3.2 Configure build.gradle.kts](#32-configure-buildgradlekts)
   - [3.3 AndroidManifest.xml Permissions](#33-androidmanifestxml-permissions)
6. [Step 4 — Dart Setup](#step-4--dart-setup)
   - [4.1 Initialize the SDK](#41-initialize-the-sdk)
   - [4.2 SIP Registration](#42-sip-registration)
   - [4.3 Listening to Events](#43-listening-to-events)
   - [4.4 Making Calls](#44-making-calls)
   - [4.5 Receiving Calls](#45-receiving-calls)
   - [4.6 Call Controls](#46-call-controls)
   - [4.7 Audio Routing](#47-audio-routing)
   - [4.8 Permission Checking](#48-permission-checking)
7. [Step 5 — Persist Credentials for Auto-Login](#step-5--persist-credentials-for-auto-login)
8. [API Reference](#api-reference)
   - [SipConfig](#sipconfig)
   - [BareSipClient](#barsesipclient)
   - [Enumerations](#enumerations)
   - [Event Classes](#event-classes)
   - [Error Codes](#error-codes)
9. [Known Constraints](#known-constraints)
10. [Troubleshooting](#troubleshooting)

---

## Requirements

| Requirement | Minimum version |
|---|---|
| Flutter SDK | 3.19.0 |
| Dart SDK | 3.3.0 |
| Android `minSdk` | 29 (Android 10) |
| Android `compileSdk` | 34+ |
| Kotlin | 2.2.x |
| Android Gradle Plugin | 8.x |
| `baresip-sdk-release.aar` | Built from the `BareSipSdk` module |

> **Architecture:** Only `arm64-v8a` is fully supported. `armeabi-v7a` is ready once the native libraries are added to the SDK.

---

## Project Structure

```
your_project/
├── android/
│   ├── app/
│   │   ├── libs/
│   │   │   └── baresip-sdk-release.aar   ← AAR goes here (host app)
│   │   ├── src/main/AndroidManifest.xml  ← permissions go here
│   │   └── build.gradle.kts              ← AAR dependency declared here
│   └── ...
├── lib/
│   └── main.dart
└── pubspec.yaml
```

---

## Step 1 — Build the BareSip SDK AAR

From the root of the `BareSipFinal` Android project, run:

```bash
./gradlew :BareSipSdk:assembleRelease
```

The output AAR is at:

```
android/libs/BareSipSdk-release.aar
```

---

## Step 2 — Add the Plugin to Your Flutter App

In your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Path dependency (local development)
  baresip_flutter:
    path: ../baresip_flutter

  # OR published package (when available on pub.dev)
  # baresip_flutter: ^0.1.0

  # Required companion packages
  permission_handler: ^11.3.1
  shared_preferences: ^2.3.3   # only if you want auto-login persistence
```

Run:

```bash
flutter pub get
```

---

## Step 3 — Android Setup

### 3.1 Copy the AAR

The AAR **must be placed in the host app's `libs/` directory**, not just the plugin's. This is because Android Gradle Plugin does not allow a library module (the plugin) to embed another local AAR.

```bash
mkdir -p android/app/libs
cp path/to/BareSipSdk-release.aar android/app/libs/baresip-sdk-release.aar
```

### 3.2 Configure `build.gradle.kts`

In `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.your.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.your.app"
        minSdk = 29          // ← Required: BareSipSdk requires API 29+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // IMPORTANT: Prevent stripping of native .so files inside the AAR
    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/arm64-v8a/*.so", "**/armeabi-v7a/*.so")
            useLegacyPackaging = true
        }
    }
}

// Required to resolve the local AAR
repositories {
    flatDir { dirs("libs") }
}

dependencies {
    // BareSip SDK AAR — provides classes and native .so at runtime
    implementation(files("libs/baresip-sdk-release.aar"))

    // Transitive runtime dependencies required by the AAR
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
```

> **Why `implementation(files(...))` in the app?**
> The plugin declares the AAR as `compileOnly` (for compilation only). The host app must provide the AAR at runtime so the classes and native `.so` files are packaged into the final APK.

### 3.3 AndroidManifest.xml Permissions

In `android/app/src/main/AndroidManifest.xml`, add all of the following inside `<manifest>`:

```xml
<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Audio — required for microphone access during calls -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

<!-- Phone — required for call management -->
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />

<!-- Foreground service — required to keep SIP registered in background -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />

<!-- Wake lock — prevents device sleep during calls -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Notifications — required on Android 13+ for foreground service notification -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Vibration — for incoming call alerts -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Boot — to restart service after device reboot (optional) -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Bluetooth audio routing -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

**Runtime permissions** (must be requested at runtime via `permission_handler`):

| Permission | When to request |
|---|---|
| `RECORD_AUDIO` | Before calling `login()` |
| `CALL_PHONE` | Before calling `login()` |
| `READ_PHONE_STATE` | Before calling `login()` |
| `BLUETOOTH_CONNECT` | Before using Bluetooth audio (Android 12+) |
| `POST_NOTIFICATIONS` | On app start (Android 13+) |

---

## Step 4 — Dart Setup

Import the plugin:

```dart
import 'package:baresip_flutter/baresip_flutter.dart';
```

### 4.1 Initialize the SDK

`initialize()` must be called **before** any other method. It configures the SIP stack with your account credentials.

```dart
final client = BareSipClient.instance;

await client.initialize(SipConfig(
  username:    '2001',
  password:    'your_password',
  displayName: 'Alice',
  host:        'sip.example.com',   // hostname only — no port suffix
  port:        5060,                // default: 5060
  transport:   'tcp',               // 'tcp', 'udp', or 'tls' — default: 'tcp'
  audioCodecs: ['PCMU', 'PCMA', 'opus', 'G722'],  // default
  stunServer:  '',                  // optional STUN server
  logLevel:    2,                   // 0=Error … 4=Trace, default: 2
));
```

> **Important:** The `host` field must be the **hostname only** — do not include the port (e.g. use `sip.example.com`, not `sip.example.com:5060`). The SDK appends the port internally from the `port` field.

### 4.2 SIP Registration

```dart
// Register with the SIP server
await client.login();

// Unregister but keep the service running (go offline)
await client.logout();

// Re-register without restarting the service
await client.goOnline();

// Unregister without stopping the service
await client.goOffline();

// Fully shut down the SDK and stop the foreground service
await client.shutdown();
```

### 4.3 Listening to Events

All events are delivered as typed Dart streams. Subscribe before calling `login()`.

```dart
// Registration state changes
client.registrationStateStream.listen((RegistrationStateEvent e) {
  print('Registration: ${e.state}');  // RegistrationState enum
  print('Reason: ${e.reason}');       // e.g. "401 Unauthorized"
});

// Call state changes
client.callStateStream.listen((CallStateEvent e) {
  print('Call state: ${e.state}');    // CallState enum
  print('Peer URI: ${e.peerUri}');    // e.g. "sip:2002@sip.example.com"
  print('Call ID: ${e.callId}');      // int
});

// Audio route changes
client.audioRouteStream.listen((AudioRouteEvent e) {
  print('Audio route: ${e.route}');   // AudioRoute enum
});

// Network connectivity changes
client.networkStateStream.listen((NetworkStateEvent e) {
  print('Network connected: ${e.connected}');  // bool
});

// SDK runtime errors
client.errorStream.listen((SdkErrorEvent e) {
  print('Error [${e.code}]: ${e.message}');
});
```

### 4.4 Making Calls

Pass either a plain extension number or a full SIP URI:

```dart
// Plain extension — the plugin auto-builds sip:<number>@<host>
await client.startCall('2002');

// Full SIP URI
await client.startCall('sip:2002@sip.example.com');
```

> `startCall` throws `ArgumentError` if `peerUri` is blank, and throws `PlatformException` with code `SDK_NOT_INITIALIZED` if `initialize()` has not been called.

### 4.5 Receiving Calls

Incoming calls arrive on `callStateStream` with `state == CallState.incoming`:

```dart
client.callStateStream.listen((e) {
  if (e.state == CallState.incoming) {
    print('Incoming call from ${e.peerUri}');
    // Show your incoming call UI, then:
    await client.answerCall();   // to answer
    // or
    await client.rejectCall();   // to reject
  }
});
```

### 4.6 Call Controls

```dart
await client.hangup();          // end the active call
await client.mute(true);        // mute microphone
await client.mute(false);       // unmute microphone
await client.hold(true);        // put call on hold
await client.hold(false);       // resume call from hold
```

### 4.7 Audio Routing

```dart
// Switch to speaker
await client.setAudioRoute(AudioRoute.speaker);

// Switch to earpiece
await client.setAudioRoute(AudioRoute.earpiece);

// Get all available routes on this device
final List<AudioRoute> routes = await client.getAvailableRoutes();

// Get the currently active route
final AudioRoute current = await client.getCurrentRoute();
```

Available `AudioRoute` values: `earpiece`, `speaker`, `wiredHeadset`, `bluetooth`.

### 4.8 Permission Checking

Query which permissions are missing before calling `login()`:

```dart
final List<String> missing = await client.getMissingPermissions();

if (missing.isNotEmpty) {
  // Request them using permission_handler
  for (final p in missing) {
    print('Missing: $p');
  }
}
```

---

## Step 5 — Persist Credentials for Auto-Login

When the app is killed from the recents screen, the foreground service is also stopped. To automatically re-register when the app is relaunched, persist credentials to `SharedPreferences` and restore them on startup.

Add `shared_preferences: ^2.3.3` to your `pubspec.yaml`, then:

```dart
// credentials_store.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baresip_flutter/baresip_flutter.dart';

class CredentialsStore {
  static Future<void> save(SipConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sip_username',    config.username);
    await prefs.setString('sip_password',    config.password);
    await prefs.setString('sip_display_name',config.displayName);
    await prefs.setString('sip_host',        config.host);
    await prefs.setInt   ('sip_port',        config.port);
    await prefs.setString('sip_transport',   config.transport);
    await prefs.setBool  ('sip_auto_login',  true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sip_auto_login', false);
  }

  static Future<SipConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('sip_auto_login') ?? false)) return null;
    final username = prefs.getString('sip_username');
    final password = prefs.getString('sip_password');
    final host     = prefs.getString('sip_host');
    if (username == null || password == null || host == null) return null;
    return SipConfig(
      username:    username,
      password:    password,
      displayName: prefs.getString('sip_display_name') ?? username,
      host:        host,
      port:        prefs.getInt('sip_port') ?? 5060,
      transport:   prefs.getString('sip_transport') ?? 'tcp',
    );
  }
}
```

In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedConfig = await CredentialsStore.load();
  runApp(MyApp(savedConfig: savedConfig));
}
```

On app start, if `savedConfig != null`, call `initialize(savedConfig)` then `login()` automatically.

Call `CredentialsStore.clear()` when the user explicitly unregisters so the next launch shows the login screen.

---

## API Reference

### SipConfig

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `username` | `String` | ✅ | — | SIP username / extension |
| `password` | `String` | ✅ | — | SIP password |
| `displayName` | `String` | ✅ | — | Caller ID display name |
| `host` | `String` | ✅ | — | SIP server hostname (no port) |
| `port` | `int` | | `5060` | SIP server port |
| `transport` | `String` | | `'tcp'` | `'tcp'`, `'udp'`, or `'tls'` |
| `audioCodecs` | `List<String>` | | `['PCMU','PCMA','opus','G722']` | Codec priority list |
| `stunServer` | `String` | | `''` | STUN server URI (optional) |
| `logLevel` | `int` | | `2` | 0=Error, 1=Warn, 2=Info, 3=Debug, 4=Trace |

### BareSipClient

All methods are on the singleton `BareSipClient.instance`.

**Lifecycle**

| Method | Description |
|---|---|
| `initialize(SipConfig)` | Configure the SDK. Must be called first. |
| `login()` | Start SIP registration and foreground service. |
| `logout()` | Unregister and stop the foreground service. |
| `goOnline()` | Re-register without restarting the service. |
| `goOffline()` | Unregister while keeping the service alive. |
| `shutdown()` | Fully stop the SDK. |

**Call Control**

| Method | Description |
|---|---|
| `startCall(String peerUri)` | Initiate an outgoing call. |
| `answerCall()` | Answer an incoming call. |
| `rejectCall()` | Reject an incoming call. |
| `hangup()` | End the active call. |
| `mute(bool muted)` | Mute or unmute the microphone. |
| `hold(bool hold)` | Hold or resume the call. |

**Audio**

| Method | Returns | Description |
|---|---|---|
| `setAudioRoute(AudioRoute)` | `Future<void>` | Switch audio output. |
| `getAvailableRoutes()` | `Future<List<AudioRoute>>` | List available routes. |
| `getCurrentRoute()` | `Future<AudioRoute>` | Get active route. |

**Permissions**

| Method | Returns | Description |
|---|---|---|
| `getMissingPermissions()` | `Future<List<String>>` | Returns missing Android permission strings. |

**Streams**

| Stream | Type | Description |
|---|---|---|
| `registrationStateStream` | `Stream<RegistrationStateEvent>` | SIP registration state changes. |
| `callStateStream` | `Stream<CallStateEvent>` | Call lifecycle events. |
| `audioRouteStream` | `Stream<AudioRouteEvent>` | Audio route changes. |
| `networkStateStream` | `Stream<NetworkStateEvent>` | Network connectivity changes. |
| `errorStream` | `Stream<SdkErrorEvent>` | SDK runtime errors. |

### Enumerations

**`RegistrationState`**

| Value | Meaning |
|---|---|
| `registering` | Registration in progress |
| `registered` | Successfully registered |
| `failed` | Registration failed (check `reason`) |
| `unregistering` | Unregistration in progress |
| `offline` | Not registered |

**`CallState`**

| Value | Meaning |
|---|---|
| `incoming` | Incoming call ringing |
| `outgoing` | Outgoing call initiated |
| `ringing` | Remote party is ringing |
| `established` | Call connected and active |
| `held` | Call on hold |
| `closed` | Call ended |

**`AudioRoute`**

| Value | Meaning |
|---|---|
| `earpiece` | Phone earpiece (default during calls) |
| `speaker` | Loudspeaker |
| `wiredHeadset` | Wired headset / headphones |
| `bluetooth` | Bluetooth headset |

### Event Classes

**`RegistrationStateEvent`**

| Field | Type | Description |
|---|---|---|
| `state` | `RegistrationState` | New registration state |
| `reason` | `String` | Reason string (e.g. `"401 Unauthorized"`) |

**`CallStateEvent`**

| Field | Type | Description |
|---|---|---|
| `state` | `CallState` | New call state |
| `peerUri` | `String` | Remote party SIP URI |
| `callId` | `int` | Internal call identifier |

**`AudioRouteEvent`**

| Field | Type | Description |
|---|---|---|
| `route` | `AudioRoute` | New active audio route |

**`NetworkStateEvent`**

| Field | Type | Description |
|---|---|---|
| `connected` | `bool` | `true` if network is available |

**`SdkErrorEvent`**

| Field | Type | Description |
|---|---|---|
| `code` | `int` | SDK error code |
| `message` | `String` | Human-readable error description |

### Error Codes

`PlatformException` codes thrown by the plugin:

| Code | Cause | Resolution |
|---|---|---|
| `SDK_NOT_INITIALIZED` | Method called before `initialize()` | Call `initialize()` first |
| `INVALID_ARGUMENT` | Blank `username`, `host`, or `peerUri` | Validate inputs before calling |
| `SDK_ERROR` | Native SDK threw an exception | Check `message` for details |

---

## Known Constraints

- **Android only.** iOS is not supported by this plugin.
- **`minSdk = 29`** (Android 10). The BareSip native library requires API 29+.
- **AAR must be in the host app's `libs/`** — not just the plugin's. Android Gradle Plugin does not allow library modules to embed local AARs.
- **`useLegacyPackaging = true`** is required in the host app's `packaging.jniLibs` block to prevent the native `.so` files from being stripped.
- **Killing the app** stops the foreground service. Use `SharedPreferences` to persist credentials and auto-login on relaunch (see Step 5).
- **SIP URI format:** Pass the hostname only in `SipConfig.host` — no port suffix. The SDK appends the port internally. When calling `startCall`, you can pass a plain extension (`2002`) or a full URI (`sip:2002@host`).

---

## Troubleshooting

**`NoClassDefFoundError: SdkCallback`**
The AAR is not in the host app's `libs/`. Copy `baresip-sdk-release.aar` to `android/app/libs/` and add `implementation(files("libs/baresip-sdk-release.aar"))` to `android/app/build.gradle.kts`.

**`minSdkVersion X cannot be smaller than version 29`**
Set `minSdk = 29` in `android/app/build.gradle.kts`.

**`Direct local .aar file dependencies are not supported when building an AAR`**
This happens if you try to add the AAR to the plugin's `build.gradle.kts` as `implementation`. Keep it as `compileOnly` in the plugin and `implementation` in the host app only.

**`ua_connect failed: 2` / `404 User Not Found`**
The callee is not registered on the SIP server at that moment. Both parties must be registered simultaneously. This is a server-side response, not a plugin bug.

**Registration events not received in Flutter**
The `EventChannel` stream must be subscribed before `login()` is called. `BareSipClient.instance` sets up the stream lazily on first access — calling `initialize()` triggers this. Ensure you subscribe to streams before or immediately after `initialize()`.

**App killed → user goes offline**
This is expected Android behaviour. Implement credential persistence (Step 5) to auto-login on relaunch. The `BareSipService` returns `START_STICKY` so Android will restart it, but the SIP stack needs credentials to re-register.

**Duplicate port in SIP URI (`host:5060:5060`)**
Do not include the port in the `host` field of `SipConfig`. Use `sip.example.com`, not `sip.example.com:5060`.
