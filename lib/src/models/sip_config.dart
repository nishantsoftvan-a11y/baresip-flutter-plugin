/// Configuration passed to [BareSipClient.initialize].
class SipConfig {
  final String username;
  final String password;
  final String displayName;
  final String host;
  final int port;
  final String transport;
  final List<String> audioCodecs;
  final String stunServer;
  final int logLevel;

  const SipConfig({
    required this.username,
    required this.password,
    required this.displayName,
    required this.host,
    this.port        = 5060,
    this.transport   = 'tcp',
    this.audioCodecs = const ['PCMU', 'PCMA', 'opus', 'G722'],
    this.stunServer  = '',
    this.logLevel    = 2,
  });

  Map<String, dynamic> toMap() => {
    'username':    username,
    'password':    password,
    'displayName': displayName,
    'host':        host,
    'port':        port,
    'transport':   transport,
    'audioCodecs': List<String>.from(audioCodecs),
    'stunServer':  stunServer,
    'logLevel':    logLevel,
  };

  factory SipConfig.fromMap(Map<String, dynamic> m) => SipConfig(
    username:    m['username']    as String,
    password:    m['password']    as String,
    displayName: m['displayName'] as String,
    host:        m['host']        as String,
    port:        (m['port']       as int?)    ?? 5060,
    transport:   (m['transport']  as String?) ?? 'tcp',
    audioCodecs: (m['audioCodecs'] as List?)?.cast<String>() ?? const ['PCMU', 'PCMA', 'opus', 'G722'],
    stunServer:  (m['stunServer'] as String?) ?? '',
    logLevel:    (m['logLevel']   as int?)    ?? 2,
  );

  @override
  bool operator ==(Object other) =>
      other is SipConfig &&
      username    == other.username &&
      password    == other.password &&
      displayName == other.displayName &&
      host        == other.host &&
      port        == other.port &&
      transport   == other.transport &&
      _listEq(audioCodecs, other.audioCodecs) &&
      stunServer  == other.stunServer &&
      logLevel    == other.logLevel;

  @override
  int get hashCode => Object.hash(
    username, password, displayName, host, port,
    transport, Object.hashAll(audioCodecs), stunServer, logLevel,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
