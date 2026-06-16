import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const AccountSettingsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _saving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.userProfile['name']?.toString() ?? '';
    _phoneCtrl.text = widget.userProfile['phone']?.toString() ?? '';
    _emailCtrl.text = widget.userProfile['email']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final updated = await ApiService.updateUserProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      currentPassword: _currentPasswordCtrl.text,
      password: _passwordCtrl.text,
      passwordConfirmation: _confirmPasswordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan akun berhasil diperbarui'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan. Periksa email atau password lama.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: !visible,
        validator: validator,
        decoration: _decoration(
          label,
          Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2442),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Data lengkap hanya ditampilkan di halaman ini. Di halaman akun utama, email dan nomor HP tetap disensor untuk menjaga privasi.',
                  style: TextStyle(color: Colors.white, height: 1.45),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Informasi Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: _decoration('Nama Akun', Icons.person_outline),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Nomor HP', Icons.phone_outlined),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email', Icons.email_outlined),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email wajib diisi';
                  if (!email.contains('@')) return 'Format email belum valid';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              const Text('Ubah Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Kosongkan bagian password jika tidak ingin mengganti password.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 12),
              _passwordField(
                controller: _currentPasswordCtrl,
                label: 'Password Lama',
                visible: _showCurrentPassword,
                onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                validator: (value) {
                  if (_passwordCtrl.text.isNotEmpty && (value == null || value.isEmpty)) return 'Password lama wajib diisi';
                  return null;
                },
              ),
              _passwordField(
                controller: _passwordCtrl,
                label: 'Password Baru',
                visible: _showNewPassword,
                onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              _passwordField(
                controller: _confirmPasswordCtrl,
                label: 'Konfirmasi Password Baru',
                visible: _showConfirmPassword,
                onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                validator: (value) {
                  if (_passwordCtrl.text.isNotEmpty && value != _passwordCtrl.text) return 'Konfirmasi password belum sama';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Pengaturan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C2442),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
