import 'enumerations.dart';

class RegistrationStateEvent {
  final RegistrationState state;
  final String reason;
  const RegistrationStateEvent({required this.state, required this.reason});

  factory RegistrationStateEvent.fromMap(Map<String, dynamic> m) =>
      RegistrationStateEvent(
        state:  RegistrationState.fromString(m['state'] as String),
        reason: (m['reason'] as String?) ?? '',
      );
}

class CallStateEvent {
  final CallState state;
  final String peerUri;
  final int callId;
  const CallStateEvent({required this.state, required this.peerUri, required this.callId});

  factory CallStateEvent.fromMap(Map<String, dynamic> m) => CallStateEvent(
    state:   CallState.fromString(m['state'] as String),
    peerUri: (m['peerUri'] as String?) ?? '',
    callId:  (m['callId']  as int?)    ?? 0,
  );
}

class AudioRouteEvent {
  final AudioRoute route;
  const AudioRouteEvent({required this.route});

  factory AudioRouteEvent.fromMap(Map<String, dynamic> m) =>
      AudioRouteEvent(route: AudioRoute.fromString(m['route'] as String));
}

class NetworkStateEvent {
  final bool connected;
  const NetworkStateEvent({required this.connected});

  factory NetworkStateEvent.fromMap(Map<String, dynamic> m) =>
      NetworkStateEvent(connected: (m['connected'] as bool?) ?? false);
}

class SdkErrorEvent {
  final int code;
  final String message;
  const SdkErrorEvent({required this.code, required this.message});

  factory SdkErrorEvent.fromMap(Map<String, dynamic> m) => SdkErrorEvent(
    code:    (m['code']    as int?)    ?? 0,
    message: (m['message'] as String?) ?? '',
  );
}
