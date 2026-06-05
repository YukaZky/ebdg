import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  Map<String, dynamic>? userProfile;
  bool isLoading = false;
  bool isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    if (ApiService.token != null) {
      _fetchProfile();
    }
  }

  // Mengambil data profil dari backend Laravel jika token ada
  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getUserProfile();
      setState(() {
        userProfile = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Proses autentikasi login langsung dari dalam Tab
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => isLoggingIn = true);
    bool success = await ApiService.login(_emailController.text, _passwordController.text);
    setState(() => isLoggingIn = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil!')),
      );
      _emailController.clear();
      _passwordController.clear();
      _fetchProfile(); // Segera ambil profil & refresh halaman ke mode Terautentikasi
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Gagal! Akun tidak ditemukan.')),
      );
    }
  }

  // Proses logout
  Future<void> _handleLogout() async {
    setState(() => isLoading = true);
    bool success = await ApiService.logout();
    setState(() => isLoading = false);

    if (success) {
      setState(() {
        userProfile = null; // Menghapus data profil di state agar UI kembali ke form login
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil keluar dari akun')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal melakukan logout.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // KONDISI 1: Jika pengguna belum melakukan login
    if (ApiService.token == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Masuk ke Akun")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.blue),
              const SizedBox(height: 10),
              const Text(
                "Silakan login untuk menikmati fungsionalitas penuh keranjang belanja dan riwayat pesanan Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Alamat Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              isLoggingIn
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Login", style: TextStyle(fontSize: 16)),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ).then((_) {
                    // Memicu render ulang saat kembali dari RegisterScreen jika diperlukan
                    setState(() {});
                  });
                },
                child: const Text("Belum memiliki akun? Daftar Baru di Sini"),
              ),
            ],
          ),
        ),
      );
    }

    // KONDISI 2: Jika pengguna sudah login, tampilkan data profilnya
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Pengguna")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Gagal memuat profil atau sesi telah berakhir."),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchProfile,
                        child: const Text("Muat Ulang"),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, size: 40, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProfile!['name'] ?? 'Nama Tidak Tersedia',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userProfile!['email'] ?? 'Email Tidak Tersedia',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text("Keluar dari Akun"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}