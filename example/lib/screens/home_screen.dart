import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baresip_flutter/baresip_flutter.dart';
import '../app_state.dart';
import '../widgets/reg_status_chip.dart';
import '../widgets/dialpad.dart';
import '../widgets/call_screen.dart';
import '../widgets/profile_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dialCtrl = TextEditingController();

  @override
  void dispose() {
    _dialCtrl.dispose();
    super.dispose();
  }

  void _showProfile(BuildContext context) {
    showDialog(context: context, builder: (_) => const ProfileDialog());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Show call screen overlay when in a call
    if (state.isInCall) {
      return const CallScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2535),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: Color(0xFF1E88E5), size: 22),
            const SizedBox(width: 8),
            Text(
              state.config?.displayName.isNotEmpty == true
                  ? state.config!.displayName
                  : state.config?.username ?? 'BareSip',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // Network indicator
          if (!state.networkConnected)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.wifi_off, color: Colors.orange, size: 20),
            ),
          // Registration status chip
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: RegStatusChip(state: state.regState),
          ),
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showProfile(context),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1E88E5),
                child: Text(
                  _initials(state.config?.displayName ?? state.config?.username ?? '?'),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (state.lastError != null)
            _ErrorBanner(message: state.lastError!, onDismiss: state.clearError),

          // Registering / failed status bar
          if (state.regState != RegistrationState.registered)
            _RegStatusBar(state: state),

          // Dial input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: _DialInput(controller: _dialCtrl),
          ),

          // Dialpad
          Expanded(
            child: Dialpad(
              controller: _dialCtrl,
              onCall: () {
                final uri = _dialCtrl.text.trim();
                if (uri.isNotEmpty) {
                  context.read<AppState>().startCall(uri);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _RegStatusBar extends StatelessWidget {
  final AppState state;
  const _RegStatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    // Map SDK states → 4 display states
    final (color, icon, spinning) = switch (state.regState) {
      RegistrationState.registering   => (Colors.orange,   Icons.sync,          true),
      RegistrationState.registered    => (Colors.green,    Icons.check_circle,  false),
      RegistrationState.unregistering => (Colors.grey,     Icons.remove_circle_outline, false),
      RegistrationState.failed        => (Colors.grey,     Icons.remove_circle_outline, false),
      RegistrationState.offline       => (Colors.blueGrey, Icons.radio_button_unchecked, false),
    };

    return Container(
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(state.regLabel,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          if (spinning) ...[
            const SizedBox(width: 10),
            SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
          ],
        ],
      ),
    );
  }
}

class _DialInput extends StatelessWidget {
  final TextEditingController controller;
  const _DialInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2535),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 1.5),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter number or SIP URI',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, v, child) => v.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white38),
                    onPressed: () {
                      final t = controller.text;
                      if (t.isNotEmpty) controller.text = t.substring(0, t.length - 1);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
