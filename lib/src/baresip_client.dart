import 'dart:async';
import 'package:flutter/services.dart';
import 'channel_names.dart';
import 'models/enumerations.dart';
import 'models/events.dart';
import 'models/sip_config.dart';

/// Singleton Dart API for the BareSip Flutter plugin.
///
/// Usage:
/// ```dart
/// final client = BareSipClient.instance;
/// await client.initialize(SipConfig(username: '2001', password: 'pass', displayName: 'Alice', host: 'sip.example.com'));
/// await client.login();
/// client.registrationStateStream.listen((e) => print(e.state));
/// ```
class BareSipClient {
  BareSipClient._();
  static final BareSipClient instance = BareSipClient._();

  static const _method = MethodChannel(kMethodChannel);
  static const _event  = EventChannel(kEventChannel);

  // Raw broadcast stream from the EventChannel — set up lazily once.
  late final Stream<Map<String, dynamic>> _raw = _event
      .receiveBroadcastStream()
      .map((e) => Map<String, dynamic>.from(e as Map))
      ..listen(_dispatch);

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
    if (config.username.trim().isEmpty) {
      throw ArgumentError.value(config.username, 'username', 'must not be blank');
    }
    if (config.host.trim().isEmpty) {
      throw ArgumentError.value(config.host, 'host', 'must not be blank');
    }
    // Ensure the event stream is subscribed before the SDK starts firing events.
    _raw; // ignore: unnecessary_statements
    await _method.invokeMethod<void>('initialize', config.toMap());
  }

  Future<void> login()    async => _method.invokeMethod<void>('login');
  Future<void> logout()   async => _method.invokeMethod<void>('logout');
  Future<void> goOnline() async => _method.invokeMethod<void>('goOnline');
  Future<void> goOffline()async => _method.invokeMethod<void>('goOffline');
  Future<void> shutdown() async => _method.invokeMethod<void>('shutdown');

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
}
