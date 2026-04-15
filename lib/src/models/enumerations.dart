/// SIP registration states.
enum RegistrationState {
  registering,
  registered,
  failed,
  unregistering,
  offline;

  static RegistrationState fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REGISTERING':   return RegistrationState.registering;
      case 'REGISTERED':    return RegistrationState.registered;
      case 'FAILED':        return RegistrationState.failed;
      case 'UNREGISTERING': return RegistrationState.unregistering;
      case 'OFFLINE':       return RegistrationState.offline;
      default: throw ArgumentError('Unknown RegistrationState: $value');
    }
  }
}

/// SIP call states.
enum CallState {
  incoming,
  outgoing,
  ringing,
  established,
  held,
  closed;

  static CallState fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCOMING':    return CallState.incoming;
      case 'OUTGOING':    return CallState.outgoing;
      case 'RINGING':     return CallState.ringing;
      case 'ESTABLISHED': return CallState.established;
      case 'HELD':        return CallState.held;
      case 'CLOSED':      return CallState.closed;
      default: throw ArgumentError('Unknown CallState: $value');
    }
  }
}

/// Audio output routes.
enum AudioRoute {
  earpiece,
  speaker,
  wiredHeadset,
  bluetooth;

  /// Serialises to the Kotlin enum name used on the wire.
  String get wireName {
    switch (this) {
      case AudioRoute.earpiece:     return 'EARPIECE';
      case AudioRoute.speaker:      return 'SPEAKER';
      case AudioRoute.wiredHeadset: return 'WIRED_HEADSET';
      case AudioRoute.bluetooth:    return 'BLUETOOTH';
    }
  }

  static AudioRoute fromString(String value) {
    switch (value.toUpperCase()) {
      case 'EARPIECE':      return AudioRoute.earpiece;
      case 'SPEAKER':       return AudioRoute.speaker;
      case 'WIRED_HEADSET': return AudioRoute.wiredHeadset;
      case 'BLUETOOTH':     return AudioRoute.bluetooth;
      default: throw ArgumentError('Unknown AudioRoute: $value');
    }
  }
}
