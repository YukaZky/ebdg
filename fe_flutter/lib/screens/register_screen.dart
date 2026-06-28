import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  static const Color _primary = Color(0xFF0C2442);
  static const Color _purple = Color(0xFF6C4DFF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _register() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('Semua data wajib diisi.', isError: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('Format email tidak valid.', isError: true);
      return;
    }
    if (password.length < 8) {
      _showSnack('Password minimal 8 karakter.', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnack('Password tidak cocok.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.register(name, email, password, confirm);
    if (!mounted) return;

    if (success) {
      final loggedIn = await ApiService.login(email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (loggedIn) {
        _showSnack('Registrasi berhasil. Anda sudah masuk.');
        Navigator.pop(context, true);
      } else {
        _showSnack('Registrasi berhasil. Silakan login.', isError: false);
        Navigator.pop(context, true);
      }
      return;
    }

    setState(() => _isLoading = false);
    _showSnack('Registrasi gagal. Email mungkin sudah terdaftar atau data belum valid.', isError: true);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _purple, width: 1.4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Stack(children: [
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_primary, Color(0xFF123A68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.14)),
              ),
              const SizedBox(height: 16),
              const Text('Buat Akun Baru', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Daftar untuk mulai belanja dan mengelola pesanan Anda.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 12))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Data Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primary)),
                  const SizedBox(height: 20),
                  TextField(controller: _nameController, enabled: !_isLoading, textInputAction: TextInputAction.next, decoration: _decoration('Nama Lengkap', Icons.person_outline_rounded)),
                  const SizedBox(height: 14),
                  TextField(controller: _emailController, enabled: !_isLoading, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: _decoration('Email', Icons.email_outlined)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Password', Icons.lock_outline_rounded, suffix: IconButton(icon: Icon(_passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: _isLoading ? null : () => setState(() => _passwordVisible = !_passwordVisible))),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordConfirmController,
                    enabled: !_isLoading,
                    obscureText: !_confirmVisible,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                    decoration: _decoration('Konfirmasi Password', Icons.verified_user_outlined, suffix: IconButton(icon: Icon(_confirmVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded), onPressed: _isLoading ? null : () => setState(() => _confirmVisible = !_confirmVisible))),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Daftar Sekarang', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey.shade700)),
                GestureDetector(onTap: _isLoading ? null : () => Navigator.pop(context), child: const Text('Masuk', style: TextStyle(color: _purple, fontWeight: FontWeight.w900))),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
