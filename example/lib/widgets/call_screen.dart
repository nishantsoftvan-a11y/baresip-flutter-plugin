import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baresip_flutter/baresip_flutter.dart';
import '../app_state.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: state.hasIncoming
            ? _IncomingCallView(state: state)
            : _ActiveCallView(state: state),
      ),
    );
  }
}

// ── Incoming call ─────────────────────────────────────────────────────────────

class _IncomingCallView extends StatelessWidget {
  final AppState state;
  const _IncomingCallView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 60),

        // Caller info
        Column(
          children: [
            _Avatar(uri: state.callPeerUri, size: 90),
            const SizedBox(height: 20),
            const Text('Incoming Call',
                style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(
              _formatUri(state.callPeerUri),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // Pulse animation ring
        _PulseRing(child: _Avatar(uri: state.callPeerUri, size: 60)),

        // Answer / Reject
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallActionButton(
                icon: Icons.call_end,
                color: Colors.red,
                label: 'Decline',
                onTap: state.rejectCall,
              ),
              _CallActionButton(
                icon: Icons.call,
                color: Colors.green,
                label: 'Answer',
                onTap: state.answerCall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Active / outgoing call ────────────────────────────────────────────────────

class _ActiveCallView extends StatelessWidget {
  final AppState state;
  const _ActiveCallView({required this.state});

  @override
  Widget build(BuildContext context) {
    final isEstablished = state.callState == CallState.established;
    final isHeld        = state.callState == CallState.held;

    return Column(
      children: [
        const SizedBox(height: 40),

        // Status label
        Text(
          state.callLabel,
          style: TextStyle(
            color: isEstablished ? Colors.greenAccent : Colors.white54,
            fontSize: isEstablished ? 22 : 16,
            fontWeight: isEstablished ? FontWeight.bold : FontWeight.normal,
            letterSpacing: isEstablished ? 2 : 1,
            fontFeatures: isEstablished ? const [FontFeature.tabularFigures()] : null,
          ),
        ),

        const SizedBox(height: 24),

        // Avatar
        _Avatar(uri: state.callPeerUri, size: 80),
        const SizedBox(height: 16),

        // Peer URI
        Text(
          _formatUri(state.callPeerUri),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),

        if (isHeld)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Call on hold',
                style: TextStyle(color: Colors.orange, fontSize: 13)),
          ),

        const Spacer(),

        // Control buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Row 1: mute, speaker, hold
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ToggleButton(
                    icon: state.isMuted ? Icons.mic_off : Icons.mic,
                    label: state.isMuted ? 'Unmute' : 'Mute',
                    active: state.isMuted,
                    onTap: isEstablished || isHeld ? state.toggleMute : null,
                  ),
                  _ToggleButton(
                    icon: state.currentRoute == AudioRoute.speaker
                        ? Icons.volume_up
                        : Icons.volume_down,
                    label: 'Speaker',
                    active: state.currentRoute == AudioRoute.speaker,
                    onTap: isEstablished ? state.toggleSpeaker : null,
                  ),
                  _ToggleButton(
                    icon: isHeld ? Icons.play_arrow : Icons.pause,
                    label: isHeld ? 'Resume' : 'Hold',
                    active: isHeld,
                    onTap: isEstablished || isHeld ? state.toggleHold : null,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Hang up
              GestureDetector(
                onTap: state.hangup,
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String uri;
  final double size;
  const _Avatar({required this.uri, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(uri);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _initials(String uri) {
    final clean = uri.replaceAll(RegExp(r'sip:|@.*'), '');
    if (clean.isEmpty) return '?';
    return clean[0].toUpperCase();
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _CallActionButton({
    required this.icon, required this.color,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ToggleButton({
    required this.icon, required this.label,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E88E5) : const Color(0xFF1A2535),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  final Widget child;
  const _PulseRing({required this.child});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _scale   = Tween(begin: 1.0, end: 1.6).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 0.6, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: _opacity.value),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

String _formatUri(String uri) {
  if (uri.isEmpty) return 'Unknown';
  return uri.replaceAll(RegExp(r'^sip:'), '').split('@').first;
}
