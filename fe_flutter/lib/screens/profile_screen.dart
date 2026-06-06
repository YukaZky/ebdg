import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'admin/admin_dashboard_screen.dart'; // Import screen admin baru

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
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (ApiService.token != null) {
      _fetchProfile();
    }
  }

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

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoggingIn = true);
    bool success = await ApiService.login(_emailController.text, _passwordController.text);
    setState(() => isLoggingIn = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Berhasil!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _emailController.clear();
      _passwordController.clear();
      _fetchProfile(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal! Kredensial tidak valid.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    setState(() => isLoading = true);
    bool success = await ApiService.logout();
    setState(() => isLoading = false);

    if (success) {
      setState(() {
        userProfile = null; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil keluar dari akun'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal melakukan logout.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ApiService.token == null) {
      return _buildLoginScreen(context);
    }
    return _buildProfileScreen(context);
  }

  // ==========================================
  // TAMPILAN 1: LOGIN SCREEN (FLOATING CARD)
  // ==========================================
  Widget _buildLoginScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Latar belakang abu muda
      body: Stack(
        children: [
          // Background Atas Gradien
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Gradien gelap elegan
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Konten Utama di Tengah
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logonobg.png',
                      height: 40, 
                      fit: BoxFit.contain,
                    ),
                    // --------------------------
                    const SizedBox(height: 16),
                    const Text(
                      "Bisnis Digital",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Masuk untuk melanjutkan belanja",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Kartu Form Login Mengambang
                    Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C5364)),
                          ),
                          const SizedBox(height: 24),
                          
                          // Input Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Alamat Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Input Password
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: const UnderlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Lupa Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text("Lupa Password?", style: TextStyle(color: Color(0xFF203A43))),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Login
                          SizedBox(
                            height: 50,
                            child: isLoggingIn
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C5364)))
                                : ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2C5364), // Sesuai dengan warna tema
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Teks Buat Akun
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum memiliki akun? ", style: TextStyle(color: Colors.black54)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            ).then((_) {
                              setState(() {});
                            });
                          },
                          child: const Text(
                            "Daftar Baru",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C5364)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAMPILAN 2: PROFILE SCREEN (FLOATING CARD)
  // ==========================================
  Widget _buildProfileScreen(BuildContext context) {
    bool isAdmin = false;
    if (userProfile != null) {
      isAdmin = userProfile!['is_admin'] == 1 || 
                userProfile!['utype'] == 'ADM' || 
                userProfile!['role'] == 'admin';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C5364)))
          : userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Gagal memuat profil."),
                      TextButton(onPressed: _fetchProfile, child: const Text("Muat Ulang"))
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Background Atas Gradien
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 250,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    
                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Profil Saya",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),
                          
                          // Kartu Profil
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Foto Profil Melingkar
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF2C5364), width: 2),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Color(0xFFE5E7EB),
                                    child: Icon(Icons.person, size: 40, color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  userProfile!['name'] ?? 'Nama Tidak Tersedia',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProfile!['email'] ?? 'Email Tidak Tersedia',
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                // Badge Role
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isAdmin ? "Administrator" : "Pelanggan",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? Colors.amber.shade900 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Area Tombol (Aksi)
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  if (isAdmin) ...[
                                    _buildActionMenu(
                                      icon: Icons.dashboard_customize_rounded,
                                      title: "Panel Admin",
                                      subtitle: "Kelola toko dan pesanan",
                                      color: const Color(0xFF203A43),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  
                                  // Tombol Logout
                                  _buildActionMenu(
                                    icon: Icons.logout_rounded,
                                    title: "Keluar Akun",
                                    subtitle: "Akhiri sesi belanja",
                                    color: Colors.redAccent,
                                    onTap: _handleLogout,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Widget Bantuan untuk Tombol Menu di Layar Profil
  Widget _buildActionMenu({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}