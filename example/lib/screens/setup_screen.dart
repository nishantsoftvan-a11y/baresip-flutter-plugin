import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:baresip_flutter/baresip_flutter.dart';
import '../app_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl    = TextEditingController(text: '2003');
  final _passwordCtrl    = TextEditingController(text: '70626963');
  final _displayNameCtrl = TextEditingController(text: 'user33');

  // final _usernameCtrl    = TextEditingController(text: '2001');
  // final _passwordCtrl    = TextEditingController(text: '49631115');
  // final _displayNameCtrl = TextEditingController(text: 'user11');

  final _hostCtrl        = TextEditingController(text: 'kmlio-poc-dev-nlb-6f9b68524e0f9218.elb.us-east-1.amazonaws.com');
  final _portCtrl        = TextEditingController(text: '5060');
  final _stunCtrl        = TextEditingController();

  String _transport = 'tcp';
  bool _obscurePassword = true;
  bool _advanced = false;

  @override
  void dispose() {
    for (final c in [_usernameCtrl, _passwordCtrl, _displayNameCtrl, _hostCtrl, _portCtrl, _stunCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
    ].request();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await _requestPermissions();

    if (!mounted) return;
    final state = context.read<AppState>();
    final config = SipConfig(
      username:    _usernameCtrl.text.trim(),
      password:    _passwordCtrl.text,
      displayName: _displayNameCtrl.text.trim().isEmpty
          ? _usernameCtrl.text.trim()
          : _displayNameCtrl.text.trim(),
      host:        _hostCtrl.text.trim(),
      port:        int.tryParse(_portCtrl.text.trim()) ?? 5060,
      transport:   _transport,
      stunServer:  _stunCtrl.text.trim(),
    );

    await state.initializeAndLogin(config);
  }  
  
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                // Logo / header
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                Text('BareSip', style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 6),
                Text('Configure your SIP account', style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                )),
                const SizedBox(height: 36),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2535),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(_usernameCtrl,    'Username',     Icons.person_outline,    required: true),
                        const SizedBox(height: 16),
                        _passwordField(),
                        const SizedBox(height: 16),
                        _field(_hostCtrl,        'SIP Server',   Icons.dns_outlined,      required: true,
                            hint: 'sip.example.com'),
                        const SizedBox(height: 16),
                        _field(_displayNameCtrl, 'Display Name', Icons.badge_outlined),

                        // Advanced toggle
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _advanced = !_advanced),
                          child: Row(
                            children: [
                              Icon(_advanced ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.white38, size: 18),
                              const SizedBox(width: 6),
                              Text('Advanced settings',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
                            ],
                          ),
                        ),

                        if (_advanced) ...[
                          const SizedBox(height: 16),
                          _field(_portCtrl, 'Port', Icons.settings_ethernet,
                              keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          _transportPicker(),
                          const SizedBox(height: 16),
                          _field(_stunCtrl, 'STUN Server (optional)', Icons.router_outlined),
                        ],

                        const SizedBox(height: 28),

                        // Error
                        if (state.lastError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(state.lastError!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                                GestureDetector(
                                  onTap: state.clearError,
                                  child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: state.isBusy ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: state.isBusy
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    bool required = false, String? hint, TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label, icon, hint: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco('Password', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
    );
  }

  Widget _transportPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transport', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: ['tcp', 'udp', 'tls'].map((t) {
            final selected = _transport == t;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(t.toUpperCase()),
                selected: selected,
                onSelected: (_) => setState(() => _transport = t),
                selectedColor: const Color(0xFF1E88E5),
                backgroundColor: const Color(0xFF0F1923),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: const Color(0xFF0F1923),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}
