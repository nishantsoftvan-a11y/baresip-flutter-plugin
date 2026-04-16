import 'package:flutter/material.dart';
import 'package:baresip_flutter/baresip_flutter.dart';

class RegStatusChip extends StatelessWidget {
  final RegistrationState state;
  const RegStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Map SDK states → 4 display states
    final (label, color, isSpinning) = switch (state) {
      RegistrationState.registered    => ('Registered',    Colors.green,  false),
      RegistrationState.registering   => ('Registering',   Colors.orange, true),
      RegistrationState.unregistering => ('Unregistered',  Colors.grey,   false),
      RegistrationState.failed        => ('Unregistered',  Colors.grey,   false),
      RegistrationState.offline       => ('Idle',          Colors.blueGrey, false),
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
          isSpinning
              ? SizedBox(
                  width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
                )
              : Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
