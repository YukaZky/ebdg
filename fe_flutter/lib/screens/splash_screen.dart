import 'package:flutter/material.dart';
import 'main_screen.dart'; // Karena berada dalam folder yang sama (screens/)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Mengatur delay selama 3 detik sebelum pindah halaman
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background diubah menjadi putih
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan logo aplikasi yang Anda unggah
            Image.asset(
              'assets/logoapk.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            // Loading indicator dan SizedBox di bawahnya sudah dihapus
          ],
        ),
      ),
    );
  }
}