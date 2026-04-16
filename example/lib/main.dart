import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'credentials_store.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Attempt to restore saved credentials before the UI renders.
  final savedConfig = await CredentialsStore.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: BareSipApp(savedConfig: savedConfig),
    ),
  );
}

class BareSipApp extends StatelessWidget {
  final dynamic savedConfig; // SipConfig? — passed from main()
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
  final dynamic savedConfig; // SipConfig?
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
    // initialize() triggers notifyListeners() which rebuilds the navigator
    // and unmounts this widget — so we must NOT check mounted after it.
    // Instead, delegate both initialize + login to AppState so the login
    // call is not gated on this widget's mounted state.
    await state.initializeAndLogin(widget.savedConfig);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Show home once we have a config (even while registering)
    if (state.config != null) {
      return const HomeScreen();
    }
    return const SetupScreen();
  }
}
