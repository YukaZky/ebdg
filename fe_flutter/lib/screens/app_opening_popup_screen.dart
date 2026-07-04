import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _openTarget(BuildContext context) async {
    final targetUrl = popupData['target_url']?.toString().trim() ?? '';
    if (targetUrl.isNotEmpty && targetUrl != 'null') {
      final uri = Uri.tryParse(targetUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (context.mounted) _openMain(context);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = popupData['image_url']?.toString().trim() ?? '';
    final title = popupData['title']?.toString().trim() ?? '';
    final subtitle = popupData['subtitle']?.toString().trim() ?? '';
    final buttonText = popupData['button_text']?.toString().trim().isNotEmpty == true
        ? popupData['button_text'].toString().trim()
        : 'Belanja Sekarang';

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 260,
                            child: Center(child: Icon(Icons.image_not_supported_outlined, size: 54)),
                          ),
                        ),
                        if (title.isNotEmpty || subtitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                            child: Column(
                              children: [
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openTarget(context),
                              child: Text(buttonText),
                            ),
                          ),
                        ),
                      ],
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.close_rounded, size: 30, color: Color(0xFF6B7280)),
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
}
