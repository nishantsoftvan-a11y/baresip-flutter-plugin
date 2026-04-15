import 'package:flutter/material.dart';
import 'package:baresip_flutter/baresip_flutter.dart';

class RegStatusChip extends StatelessWidget {
  final RegistrationState state;
  const RegStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      RegistrationState.registered    => ('Online',        Colors.green,  Icons.circle),
      RegistrationState.registering   => ('Connecting…',  Colors.orange, Icons.sync),
      RegistrationState.unregistering => ('Signing out…', Colors.orange, Icons.sync),
      RegistrationState.failed        => ('Failed',        Colors.red,    Icons.error),
      RegistrationState.offline       => ('Offline',       Colors.grey,   Icons.circle_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          state == RegistrationState.registering || state == RegistrationState.unregistering
              ? SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
                )
              : Icon(icon, color: color, size: 10),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
