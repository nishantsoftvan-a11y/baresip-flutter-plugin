import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baresip_flutter/baresip_flutter.dart';
import '../app_state.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cfg   = state.config;

    return Dialog(
      backgroundColor: const Color(0xFF1A2535),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF1E88E5),
              child: Text(
                _initials(cfg?.displayName ?? cfg?.username ?? '?'),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Display name
            Text(
              cfg?.displayName.isNotEmpty == true ? cfg!.displayName : cfg?.username ?? '—',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // SIP address
            Text(
              cfg != null ? '${cfg.username}@${cfg.host}' : '—',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Status
            _StatusRow(state: state),
            const SizedBox(height: 20),

            // Details
            if (cfg != null) ...[
              _InfoTile(label: 'Server',    value: '${cfg.host}:${cfg.port}'),
              _InfoTile(label: 'Transport', value: cfg.transport.toUpperCase()),
              _InfoTile(label: 'Codecs',    value: cfg.audioCodecs.join(', ')),
              if (cfg.stunServer.isNotEmpty)
                _InfoTile(label: 'STUN', value: cfg.stunServer),
              const SizedBox(height: 20),
            ],

            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                // Go offline (stays on home screen, keeps config)
                if (state.isRegistered) ...[
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.cloud_off,
                      label: 'Go Offline',
                      color: Colors.orange,
                      onTap: () async {
                        Navigator.pop(context);
                        await state.goOffline();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Unregister — clears config and returns to SetupScreen
                Expanded(
                  child: _ActionButton(
                    icon: Icons.logout,
                    label: 'Unregister',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      await state.unregisterAndReset();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
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

class _StatusRow extends StatelessWidget {
  final AppState state;
  const _StatusRow({required this.state});

  @override
  Widget build(BuildContext context) {
    // Map SDK states → 4 display states
    final (label, color) = switch (state.regState) {
      RegistrationState.registered    => ('Registered',   Colors.green),
      RegistrationState.registering   => ('Registering',  Colors.orange),
      RegistrationState.unregistering => ('Unregistered', Colors.grey),
      RegistrationState.failed        => ('Unregistered', Colors.grey),
      RegistrationState.offline       => ('Idle',         Colors.blueGrey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          if (state.regState == RegistrationState.registering) ...[
            const SizedBox(width: 8),
            SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: color)),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
