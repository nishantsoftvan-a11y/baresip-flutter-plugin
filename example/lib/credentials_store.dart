import 'package:shared_preferences/shared_preferences.dart';
import 'package:baresip_flutter/baresip_flutter.dart';

/// Persists SIP credentials to SharedPreferences so the app can
/// auto-login after being killed and restarted.
class CredentialsStore {
  static const _kUsername    = 'sip_username';
  static const _kPassword    = 'sip_password';
  static const _kDisplayName = 'sip_display_name';
  static const _kHost        = 'sip_host';
  static const _kPort        = 'sip_port';
  static const _kTransport   = 'sip_transport';
  static const _kStunServer  = 'sip_stun_server';
  static const _kLogLevel    = 'sip_log_level';
  static const _kAutoLogin   = 'sip_auto_login';

  static Future<void> save(SipConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername,    config.username);
    await prefs.setString(_kPassword,    config.password);
    await prefs.setString(_kDisplayName, config.displayName);
    await prefs.setString(_kHost,        config.host);
    await prefs.setInt   (_kPort,        config.port);
    await prefs.setString(_kTransport,   config.transport);
    await prefs.setString(_kStunServer,  config.stunServer);
    await prefs.setInt   (_kLogLevel,    config.logLevel);
    await prefs.setBool  (_kAutoLogin,   true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoLogin, false);
  }

  /// Returns saved [SipConfig] if auto-login is enabled, null otherwise.
  static Future<SipConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLogin = prefs.getBool(_kAutoLogin) ?? false;
    if (!autoLogin) return null;

    final username = prefs.getString(_kUsername);
    final password = prefs.getString(_kPassword);
    final host     = prefs.getString(_kHost);
    if (username == null || password == null || host == null) return null;

    return SipConfig(
      username:    username,
      password:    password,
      displayName: prefs.getString(_kDisplayName) ?? username,
      host:        host,
      port:        prefs.getInt(_kPort)        ?? 5060,
      transport:   prefs.getString(_kTransport) ?? 'tcp',
      stunServer:  prefs.getString(_kStunServer) ?? '',
      logLevel:    prefs.getInt(_kLogLevel)    ?? 2,
    );
  }
}
