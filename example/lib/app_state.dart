import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:baresip_flutter/baresip_flutter.dart';

/// Central state manager for the entire app.
/// Credentials are now stored in the native SDK via DataStore.
class AppState extends ChangeNotifier {
  final _client = BareSipClient.instance;

  // ── Config ────────────────────────────────────────────────────────────────
  SipConfig? config;

  // ── Registration ──────────────────────────────────────────────────────────
  RegistrationState regState = RegistrationState.offline;
  String regReason = '';

  // ── Call ──────────────────────────────────────────────────────────────────
  CallState? callState;
  String callPeerUri = '';
  int callId = 0;
  Duration callDuration = Duration.zero;
  Timer? _durationTimer;

  // Tracks whether the SDK currently has a live call object.
  // Set to true on first non-closed call event, false when CLOSED arrives.
  bool _callAlive = false;

  // ── Audio ─────────────────────────────────────────────────────────────────
  AudioRoute currentRoute = AudioRoute.earpiece;
  bool isMuted = false;
  bool isOnHold = false;

  // ── Network ───────────────────────────────────────────────────────────────
  bool networkConnected = true;

  // ── Error ─────────────────────────────────────────────────────────────────
  String? lastError;

  // ── Busy flag ─────────────────────────────────────────────────────────────
  bool isBusy = false;

  // ── Subscriptions ─────────────────────────────────────────────────────────
  final List<StreamSubscription> _subs = [];

  AppState() {
    _subs.addAll([
      _client.registrationStateStream.listen(_onReg),
      _client.callStateStream.listen(_onCall),
      _client.audioRouteStream.listen(_onAudio),
      _client.networkStateStream.listen(_onNetwork),
      _client.errorStream.listen(_onError),
    ]);
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isRegistered => regState == RegistrationState.registered;

  /// True when the UI should show the call screen.
  bool get isInCall =>
      callState != null &&
      callState != CallState.closed &&
      _callAlive;

  bool get isCallActive => callState == CallState.established;
  bool get hasIncoming  => callState == CallState.incoming;

  String get regLabel {
    switch (regState) {
      case RegistrationState.registering:   return 'Registering';
      case RegistrationState.registered:    return 'Registered';
      case RegistrationState.failed:        return 'Unregistered';
      case RegistrationState.unregistering: return 'Unregistered';
      case RegistrationState.offline:       return 'Idle';
    }
  }

  String get callLabel {
    switch (callState) {
      case CallState.incoming:    return 'Incoming call';
      case CallState.outgoing:    return 'Calling…';
      case CallState.ringing:     return 'Ringing…';
      case CallState.established: return _formatDuration(callDuration);
      case CallState.held:        return 'On hold';
      case CallState.closed:
      case null:                  return '';
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── URI helper ────────────────────────────────────────────────────────────

  /// Ensures [input] is a full SIP URI.
  /// - Already a full URI (starts with `sip:` or `sips:`) → returned as-is
  /// - Plain number/username → `sip:<input>@<host>` (clean AOR format)
  ///
  /// Per RFC 3261, the URI should be the Address of Record (AOR) without
  /// port or transport parameters. Routing is handled by the outbound proxy
  /// configured in the account settings.
  String _buildSipUri(String input) {
    final trimmed = input.trim();
    
    // If already a full URI, return as-is
    if (trimmed.startsWith('sip:') || trimmed.startsWith('sips:')) {
      return trimmed;
    }
    
    final cfg = config;
    if (cfg != null) {
      // Sanitize input to remove spaces
      final sanitized = trimmed.replaceAll(RegExp(r'\s+'), '');
      
      // Clean host (remove port if accidentally included)
      final cleanHost = cfg.host.split(':').first;
      
      // Use sips: scheme for TLS/WSS, sip: for others
      final scheme = (cfg.transport == 'tls' || cfg.transport == 'wss') 
          ? 'sips' 
          : 'sip';
      
      // Build clean AOR: scheme:user@domain (no port, no transport)
      // Outbound proxy in account config handles routing
      return '$scheme:$sanitized@$cleanHost:5060';
    }
    
    return trimmed;
  }

  // ── SDK actions ───────────────────────────────────────────────────────────

  Future<void> initialize(SipConfig cfg) async {
    _setBusy(true);
    try {
      await _client.initialize(cfg);
      config = cfg;
      // Credentials are automatically saved by SDK to DataStore
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  /// Initializes the SDK and immediately calls login() in one atomic operation.
  /// Use this for auto-login on startup — avoids the mounted-check race where
  /// initialize() triggers a rebuild that unmounts the calling widget before
  /// login() can be called.
  /// The [_autoLoginDone] flag prevents duplicate calls if the widget rebuilds.
  bool _autoLoginDone = false;

  Future<void> initializeAndLogin(SipConfig cfg) async {
    if (_autoLoginDone) return;
    _autoLoginDone = true;
    _setBusy(true);
    try {
      // Check if SDK already has this config stored
      final hasStored = await _client.hasStoredCredentials();
      
      if (hasStored) {
        // SDK already initialized with these credentials, just login
        config = cfg;
        notifyListeners();
        await _client.login();
      } else {
        // First time, initialize and login
        await _client.initialize(cfg);
        config = cfg;
        // Credentials are automatically saved by SDK to DataStore
        notifyListeners();
        // login() immediately after — no widget lifecycle dependency
        await _client.login();
      }
    } catch (e) {
      _autoLoginDone = false; // allow retry on error
      lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> login() async {
    _setBusy(true);
    try {
      await _client.login();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }
  /// Logs out and goes offline but keeps the config — stays on HomeScreen.
  Future<void> goOffline() async {
    _setBusy(true);
    try {
      await _client.logout();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  /// Logs out AND clears config — navigates back to SetupScreen.
  Future<void> unregisterAndReset() async {
    _setBusy(true);
    try {
      // Clear credentials from SDK DataStore
      await _client.logout(clearCredentials: true);
    } catch (e) {
      lastError = e.toString();
    } finally {
      _setBusy(false);
    }
    // Clear local state
    _autoLoginDone = false; // allow fresh login next time
    config = null;
    regState = RegistrationState.offline;
    regReason = '';
    _clearCallState();
    notifyListeners();
  }

  Future<void> startCall(String input) async {
    final uri = _buildSipUri(input);
    _setBusy(true);
    try {
      await _client.startCall(uri);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> answerCall() async {
    if (!_callAlive) return;
    try {
      await _client.answerCall();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectCall() async {
    if (!_callAlive) return;
    try {
      await _client.rejectCall();
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> hangup() async {
    // Only call hangup if the SDK still has a live call object.
    if (!_callAlive) {
      _clearCallState();
      return;
    }
    try {
      await _client.hangup();
    } catch (e) {
      // If hangup itself throws, the call is already gone — clean up locally.
      _clearCallState();
      lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleMute() async {
    if (!_callAlive) return;
    isMuted = !isMuted;
    try {
      await _client.mute(isMuted);
    } catch (e) {
      isMuted = !isMuted;
      lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleHold() async {
    if (!_callAlive) return;
    isOnHold = !isOnHold;
    try {
      await _client.hold(isOnHold);
    } catch (e) {
      isOnHold = !isOnHold;
      lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    final next = currentRoute == AudioRoute.speaker
        ? AudioRoute.earpiece
        : AudioRoute.speaker;
    try {
      await _client.setAudioRoute(next);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  // ── Stream handlers ───────────────────────────────────────────────────────

  void _onReg(RegistrationStateEvent e) {
    regState  = e.state;
    regReason = e.reason;
    notifyListeners();
  }

  void _onCall(CallStateEvent e) {
    callPeerUri = e.peerUri;
    callId      = e.callId;

    if (e.state == CallState.closed) {
      _stopTimer();
      _callAlive = false;
      callState  = null;       // immediately clear — no delay
      isMuted    = false;
      isOnHold   = false;
      callDuration = Duration.zero;
    } else {
      _callAlive = true;
      callState  = e.state;
      if (e.state == CallState.established) {
        _startTimer();
      }
    }
    notifyListeners();
  }

  void _onAudio(AudioRouteEvent e) {
    currentRoute = e.route;
    notifyListeners();
  }

  void _onNetwork(NetworkStateEvent e) {
    networkConnected = e.connected;
    notifyListeners();
  }

  void _onError(SdkErrorEvent e) {
    lastError = '[${e.code}] ${e.message}';

    // If an SDK error arrives while we think a call is in progress,
    // the call object is likely already dead — reset call state so the
    // UI returns to the dialpad and we don't try to call hangup() on a
    // dangling pointer.
    if (_callAlive &&
        (callState == CallState.outgoing ||
         callState == CallState.ringing  ||
         callState == CallState.incoming)) {
      _stopTimer();
      _callAlive   = false;
      callState    = null;
      callPeerUri  = '';
      callDuration = Duration.zero;
    }

    notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _clearCallState() {
    _stopTimer();
    _callAlive   = false;
    callState    = null;
    callPeerUri  = '';
    callDuration = Duration.zero;
    isMuted      = false;
    isOnHold     = false;
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _setBusy(bool v) {
    isBusy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _stopTimer();
    super.dispose();
  }
}
