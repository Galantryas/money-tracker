import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _enteredPin = '';
  bool _usePinMode = false;

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _submitPin() async {
    final success = await ref.read(authProvider.notifier).unlockWithPin(_enteredPin);
    if (!success) {
      setState(() {
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo & App Name
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Money Tracker',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _usePinMode
                    ? 'Masukkan 4-digit PIN keamanan'
                    : 'Aplikasi terkunci demi keamanan data keuangan Anda',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),

              const Spacer(flex: 1),

              // Error Message
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_usePinMode) ...[
                // Biometric Fingerprint Button
                GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).authenticate(),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 64,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).authenticate(),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                  icon: const Icon(Icons.touch_app_rounded, size: 20),
                  label: const Text(
                    'Pindai Sidik Jari',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _usePinMode = true;
                      _enteredPin = '';
                    });
                  },
                  child: Text(
                    'Gunakan PIN Fallback',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                // PIN Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? const Color(0xFF6366F1)
                            : (isDark ? Colors.white24 : Colors.black12),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Keypad 1-9, 0, Backspace
                Column(
                  children: [
                    for (var row = 0; row < 3; row++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var col = 1; col <= 3; col++)
                            _buildKeypadButton('${row * 3 + col}', theme, isDark),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch back to biometric
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.fingerprint,
                            color: Color(0xFF6366F1),
                          ),
                          onPressed: () {
                            setState(() {
                              _usePinMode = false;
                            });
                          },
                        ),
                        _buildKeypadButton('0', theme, isDark),
                        IconButton(
                          iconSize: 28,
                          icon: Icon(
                            Icons.backspace_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: _onDeleteTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text, ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () => _onNumberTap(text),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
