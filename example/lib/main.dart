import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baresip_flutter/baresip_flutter.dart';
import 'app_state.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Check if credentials are stored in SDK (via DataStore)
  final client = BareSipClient.instance;
  final hasCredentials = await client.hasStoredCredentials();
  Map<String, dynamic>? savedConfig;
  
  if (hasCredentials) {
    savedConfig = await client.getStoredConfig();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: BareSipApp(savedConfig: savedConfig),
    ),
  );
}

class BareSipApp extends StatelessWidget {
  final Map<String, dynamic>? savedConfig; // Config from SDK DataStore
  const BareSipApp({super.key, this.savedConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BareSip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1E88E5),
          surface: const Color(0xFF1A2535),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1923),
        fontFamily: 'Roboto',
      ),
      home: _RootNavigator(savedConfig: savedConfig),
    );
  }
}

/// Switches between SetupScreen and HomeScreen.
/// On first build, if saved credentials exist, triggers auto-login.
class _RootNavigator extends StatefulWidget {
  final Map<String, dynamic>? savedConfig; // Config from SDK
  const _RootNavigator({this.savedConfig});

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  bool _autoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedConfig != null) {
      // Trigger auto-login after the first frame so the Provider is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLogin());
    }
  }

  Future<void> _autoLogin() async {
    if (_autoLoginAttempted) return;
    _autoLoginAttempted = true;
    final state = context.read<AppState>();
    
    // Convert saved config map to SipConfig
    // Note: Password is not returned for security, but SDK has it stored
    final configMap = widget.savedConfig!;
    final config = SipConfig(
      username: configMap['username'] as String,
      password: '', // Password not returned for security, SDK will use stored one
      displayName: configMap['displayName'] as String,
      host: configMap['host'] as String,
      port: configMap['port'] as int,
      transport: configMap['transport'] as String,
      autoLogin: true, // Already stored with autoLogin enabled
    );
    
    // Use initializeAndLogin which handles both SDK init and login atomically
    try {
      await state.initializeAndLogin(config);
    } catch (e) {
      // If login fails, show setup screen
      debugPrint('Auto-login failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Show home once we have a config (even while registering)
    if (state.config != null) {
      return const HomeScreen();
    }
    
    // If we have saved config but no local config yet, show loading
    if (widget.savedConfig != null && !_autoLoginAttempted) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return const SetupScreen();
  }
}
