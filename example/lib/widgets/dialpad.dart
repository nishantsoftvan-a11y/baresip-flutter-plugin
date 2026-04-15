import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class Dialpad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCall;

  const Dialpad({super.key, required this.controller, required this.onCall});

  static const _keys = [
    ['1', ''],   ['2', 'ABC'],  ['3', 'DEF'],
    ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
    ['7', 'PQRS'],['8', 'TUV'], ['9', 'WXYZ'],
    ['*', ''],   ['0', '+'],    ['#', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final canCall = state.isRegistered && !state.isBusy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Digit grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _keys.length,
              itemBuilder: (_, i) {
                final digit = _keys[i][0];
                final sub   = _keys[i][1];
                return _DialKey(
                  digit: digit,
                  sub: sub,
                  onTap: () => controller.text += digit,
                );
              },
            ),
          ),

          // Call button row
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Call button
                GestureDetector(
                  onTap: canCall ? onCall : null,
                  child: Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: canCall ? Colors.green : Colors.green.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      boxShadow: canCall ? [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2),
                      ] : null,
                    ),
                    child: const Icon(Icons.call, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialKey extends StatelessWidget {
  final String digit;
  final String sub;
  final VoidCallback onTap;

  const _DialKey({required this.digit, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2535),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400)),
            if (sub.isNotEmpty)
              Text(sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
