import 'dart:async';
import 'package:flutter/services.dart';
import 'channel_names.dart';
import 'models/enumerations.dart';
import 'models/events.dart';
import 'models/sip_config.dart';

/// Singleton Dart API for the BareSip Flutter plugin.
class BareSipClient {
  BareSipClient._() {
    // Subscribe to the EventChannel immediately on construction so that
    // onListen fires on the Android side before any SDK calls are made.
    // This prevents the collectors=0 race where events fire before the
    // SdkCallbackImpl is registered.
    _subscribeToEvents();
  }

  static final BareSipClient instance = BareSipClient._();

  static const _method = MethodChannel(kMethodChannel);
  static const _event  = EventChannel(kEventChannel);

  StreamSubscription<Map<String, dynamic>>? _eventSub; // ignore: unused_field
  bool _eventSubscribed = false;

  // Per-type broadcast controllers.
  final _regCtrl   = StreamController<RegistrationStateEvent>.broadcast();
  final _callCtrl  = StreamController<CallStateEvent>.broadcast();
  final _audioCtrl = StreamController<AudioRouteEvent>.broadcast();
  final _netCtrl   = StreamController<NetworkStateEvent>.broadcast();
  final _errCtrl   = StreamController<SdkErrorEvent>.broadcast();

  /// Stream of SIP registration state changes.
  Stream<RegistrationStateEvent> get registrationStateStream => _regCtrl.stream;

  /// Stream of SIP call state changes.
  Stream<CallStateEvent> get callStateStream => _callCtrl.stream;

  /// Stream of audio route changes.
  Stream<AudioRouteEvent> get audioRouteStream => _audioCtrl.stream;

  /// Stream of network connectivity changes.
  Stream<NetworkStateEvent> get networkStateStream => _netCtrl.stream;

  /// Stream of SDK runtime errors.
  Stream<SdkErrorEvent> get errorStream => _errCtrl.stream;

  /// Subscribes to the EventChannel. Safe to call multiple times — only
  /// subscribes once. Called eagerly in the constructor so that the Android
  /// SdkStreamHandler.onListen fires before any SDK method calls.
  void _subscribeToEvents() {
    if (_eventSubscribed) return;
    _eventSubscribed = true;
    _eventSub = _event
        .receiveBroadcastStream()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .listen(
          _dispatch,
          onError: (e) {
            // EventChannel errors are non-fatal — re-subscribe on next initialize
            _eventSubscribed = false;
            _eventSub = null;
          },
        );
  }

  void _dispatch(Map<String, dynamic> event) {
    switch (event['type'] as String?) {
      case 'registrationState':
        _regCtrl.add(RegistrationStateEvent.fromMap(event));
      case 'callState':
        _callCtrl.add(CallStateEvent.fromMap(event));
      case 'audioRoute':
        _audioCtrl.add(AudioRouteEvent.fromMap(event));
      case 'networkState':
        _netCtrl.add(NetworkStateEvent.fromMap(event));
      case 'error':
        _errCtrl.add(SdkErrorEvent.fromMap(event));
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Initialise the SDK with [config]. Must be called before any other method.
  Future<void> initialize(SipConfig config) async {
    // Validate configuration
    final errors = _validateConfig(config);
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid SipConfig: ${errors.join('; ')}');
    }
    
    // Ensure the EventChannel subscription is active.
    _subscribeToEvents();
    // Wait for the Android onListen to fire by doing a round-trip method call.
    // receiveBroadcastStream() sends a message to Android, but onListen fires
    // asynchronously. By doing a method channel call AFTER subscribing, we
    // guarantee the onListen has completed before initialize() proceeds,
    // because method channel calls are processed in order on the platform thread.
    await _method.invokeMethod<void>('ping').catchError((_) {});
    await _method.invokeMethod<void>('initialize', config.toMap());
  }

  /// Validates SipConfig and returns list of error messages (empty if valid).
  List<String> _validateConfig(SipConfig config) {
    final errors = <String>[];
    
    if (config.username.trim().isEmpty) {
      errors.add('username must not be blank');
    }
    if (config.password.trim().isEmpty) {
      errors.add('password must not be blank');
    }
    if (config.displayName.trim().isEmpty) {
      errors.add('displayName must not be blank');
    }
    if (config.host.trim().isEmpty) {
      errors.add('host must not be blank');
    }
    if (config.host.contains(' ')) {
      errors.add('host must not contain spaces');
    }
    if (config.port < 1 || config.port > 65535) {
      errors.add('port must be in range 1-65535, got ${config.port}');
    }
    
    // Validate transport
    const validTransports = ['tcp', 'udp', 'tls', 'ws', 'wss'];
    if (!validTransports.contains(config.transport.toLowerCase())) {
      errors.add('transport must be one of ${validTransports.join(', ')}, got \'${config.transport}\'');
    }
    
    // Validate medianat if specified
    if (config.medianat.isNotEmpty) {
      const validMedianat = ['stun', 'turn', 'ice'];
      if (!validMedianat.contains(config.medianat.toLowerCase())) {
        errors.add('medianat must be one of ${validMedianat.join(', ')} or empty, got \'${config.medianat}\'');
      }
    }
    
    // Validate mediaenc if specified
    if (config.mediaenc.isNotEmpty) {
      const validMediaenc = ['srtp', 'srtp-mand', 'srtp-mandb', 'dtls_srtp', 'zrtp'];
      if (!validMediaenc.contains(config.mediaenc.toLowerCase())) {
        errors.add('mediaenc must be one of ${validMediaenc.join(', ')} or empty, got \'${config.mediaenc}\'');
      }
    }
    
    if (config.audioCodecs.isEmpty) {
      errors.add('audioCodecs must not be empty');
    }
    
    if (config.logLevel < 0 || config.logLevel > 4) {
      errors.add('logLevel must be in range 0-4, got ${config.logLevel}');
    }
    
    return errors;
  }

  Future<void> login()     async => _method.invokeMethod<void>('login');
  Future<void> logout({bool clearCredentials = false}) async => 
      _method.invokeMethod<void>('logout', {'clearCredentials': clearCredentials});
  Future<void> goOnline()  async => _method.invokeMethod<void>('goOnline');
  Future<void> goOffline() async => _method.invokeMethod<void>('goOffline');
  Future<void> shutdown()  async => _method.invokeMethod<void>('shutdown');

  // ── Call control ─────────────────────────────────────────────────────────

  Future<void> startCall(String peerUri) async {
    if (peerUri.trim().isEmpty) {
      throw ArgumentError.value(peerUri, 'peerUri', 'must not be blank');
    }
    await _method.invokeMethod<void>('startCall', {'peerUri': peerUri});
  }

  Future<void> answerCall() async => _method.invokeMethod<void>('answerCall');
  Future<void> rejectCall() async => _method.invokeMethod<void>('rejectCall');
  Future<void> hangup()     async => _method.invokeMethod<void>('hangup');
  Future<void> mute(bool muted) async =>
      _method.invokeMethod<void>('mute', {'muted': muted});
  Future<void> hold(bool hold) async =>
      _method.invokeMethod<void>('hold', {'hold': hold});

  // ── Audio ─────────────────────────────────────────────────────────────────

  Future<void> setAudioRoute(AudioRoute route) async =>
      _method.invokeMethod<void>('setAudioRoute', {'route': route.wireName});

  Future<List<AudioRoute>> getAvailableRoutes() async {
    final raw = await _method.invokeListMethod<String>('getAvailableRoutes') ?? [];
    return raw.map(AudioRoute.fromString).toList();
  }

  Future<AudioRoute> getCurrentRoute() async {
    final raw = await _method.invokeMethod<String>('getCurrentRoute') ?? 'EARPIECE';
    return AudioRoute.fromString(raw);
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<List<String>> getMissingPermissions() async =>
      await _method.invokeListMethod<String>('getMissingPermissions') ?? [];

  // ── Credential Management ─────────────────────────────────────────────────

  /// Checks if credentials are stored and auto-login is enabled.
  /// Useful for determining if the app should show login screen or auto-login.
  Future<bool> hasStoredCredentials() async {
    try {
      return await _method.invokeMethod<bool>('hasStoredCredentials') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves stored SIP configuration (without password for security).
  /// Returns null if no credentials are stored or auto-login is disabled.
  /// Useful for displaying current user info in UI.
  /// 
  /// Returns a map with keys: username, displayName, host, port, transport
  Future<Map<String, dynamic>?> getStoredConfig() async {
    try {
      final result = await _method.invokeMethod<Map<Object?, Object?>>('getStoredConfig');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  // ── Advanced ──────────────────────────────────────────────────────────────

  /// Adds a custom SIP header to all outgoing requests.
  /// Useful for P-Asserted-Identity, X-Custom headers, etc.
  /// 
  /// Example:
  /// ```dart
  /// await client.addCustomHeader(
  ///   'P-Asserted-Identity', 
  ///   '"John Doe" <sip:john@example.com>'
  /// );
  /// ```
  Future<void> addCustomHeader(String name, String value) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be blank');
    }
    await _method.invokeMethod<void>('addCustomHeader', {
      'name': name,
      'value': value,
    });
  }

  /// Builds a properly formatted SIP URI from a username/number.
  /// 
  /// Per RFC 3261, this creates a clean Address of Record (AOR) without port or
  /// transport parameters. Routing is handled by the outbound proxy configured
  /// in the account settings.
  /// 
  /// - If [userOrUri] already starts with `sip:` or `sips:`, returns it unchanged
  /// - Otherwise, builds `scheme:user@domain` using the configured account
  /// - [domain] is optional; if not provided, uses the domain from current config
  /// 
  /// Examples:
  /// ```dart
  /// buildSipUri('2001')                    // → 'sip:2001@configured-domain.com'
  /// buildSipUri('alice', 'example.com')    // → 'sip:alice@example.com'
  /// buildSipUri('sip:bob@domain.com')      // → 'sip:bob@domain.com' (unchanged)
  /// ```
  String buildSipUri(String userOrUri, {String? domain, SipConfig? config}) {
    final trimmed = userOrUri.trim();
    
    // If already a full URI, return as-is
    if (trimmed.startsWith('sip:') || trimmed.startsWith('sips:')) {
      return trimmed;
    }
    
    // Determine domain
    final targetDomain = domain?.split(':').first ?? 
                        config?.host.split(':').first;
    
    if (targetDomain == null) {
      throw ArgumentError('No domain specified and no config available');
    }
    
    // Determine scheme based on transport
    final scheme = (config?.transport == 'tls' || config?.transport == 'wss') 
        ? 'sips' 
        : 'sip';
    
    // Build clean AOR: scheme:user@domain (no port, no transport)
    return '$scheme:$trimmed@$targetDomain';
  }
}
