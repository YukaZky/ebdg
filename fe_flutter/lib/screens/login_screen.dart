import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool isLoggingIn = false;
  bool _isPasswordVisible = false;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _accent = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF6C4DFF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (isLoggingIn) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email dan password tidak boleh kosong.', isError: true);
      return;
    }

    setState(() => isLoggingIn = true);
    final success = await ApiService.login(email, password);
    if (!mounted) return;
    setState(() => isLoggingIn = false);

    if (success) {
      _showSnack('Login berhasil. Sesi akun tersimpan.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 0)),
        (_) => false,
      );
    } else {
      _showSnack('Login gagal. Periksa email dan password.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _purple, width: 1.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _logoBadge() {
    return Container(
      width: 74,
      height: 74,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Image.asset('assets/logonobg.png', fit: BoxFit.contain),
    );
  }

  Widget _background() {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary, Color(0xFF123A68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      Positioned(
        top: -70,
        right: -50,
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.18)),
        ),
      ),
      Positioned(
        top: 170,
        left: -70,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _purple.withOpacity(0.20)),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.64,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: _logoBadge()),
                const SizedBox(height: 22),
                const Center(
                  child: Text(
                    'Selamat Datang',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Masuk untuk belanja, cek pesanan, dan kelola toko.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.35),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 12))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Masuk Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primary)),
                    const SizedBox(height: 6),
                    Text('Gunakan akun yang sudah terdaftar.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                      decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey.shade600),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Lupa Password?', style: TextStyle(color: _purple, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoggingIn ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _purple.withOpacity(0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoggingIn
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Text('Masuk Sekarang', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Belum punya akun? ', style: TextStyle(color: Colors.grey.shade700)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: const Text('Daftar', style: TextStyle(color: _purple, fontWeight: FontWeight.w900)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
