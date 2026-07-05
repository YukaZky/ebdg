import 'package:flutter/material.dart';
import 'main_screen.dart';

class AppOpeningPopupScreen extends StatelessWidget {
  final Map<String, dynamic> popupData;

  const AppOpeningPopupScreen({Key? key, required this.popupData}) : super(key: key);

  void _openMain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = popupData['image_url']?.toString().trim() ?? '';
    final size = MediaQuery.of(context).size;
    final maxPopupWidth = (size.width * 0.78).clamp(240.0, 340.0).toDouble();
    final maxPopupHeight = (size.height * 0.58).clamp(300.0, 520.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: MainScreen()),
          const Positioned.fill(
            child: ModalBarrier(
              color: Colors.transparent,
              dismissible: false,
            ),
          ),
          SafeArea(
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxPopupWidth,
                      maxHeight: maxPopupHeight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: maxPopupWidth,
                          height: 320,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -12,
                    top: -12,
                    child: InkWell(
                      onTap: () => _openMain(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close_rounded, size: 30, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
