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

  Future<void> _register() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok!')));
      return;
    }

    setState(() => _isLoading = true);
    
    bool success = await ApiService.register(
      _nameController.text, 
      _emailController.text, 
      _passwordController.text, 
      _passwordConfirmController.text
    );
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil! Silakan login.')));
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi gagal. Periksa kembali data Anda.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Akun Baru")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama Lengkap")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            TextField(controller: _passwordConfirmController, decoration: const InputDecoration(labelText: "Konfirmasi Password"), obscureText: true),
            const SizedBox(height: 20),
            _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text("Daftar")),
          ],
        ),
      ),
    );
  }
}