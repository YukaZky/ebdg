class AppLinkConfig {
  AppLinkConfig._();

  /// Domain HTTPS yang dibagikan ke pengguna.
  static const String shareBaseUrl = 'https://geodesaconnect.id';

  /// Ubah nilai ini jika fallback harus diarahkan ke Play Store,
  /// App Store, halaman download, atau URL lain yang diizinkan backend.
  static const String fallbackUrl = 'https://geodesaconnect.id';

  /// Custom scheme sebagai jalur cadangan bila HTTPS App Link tidak
  /// langsung diambil oleh sistem operasi.
  static const String customScheme = 'geodesaconnect';

  static Uri productShareUri(String slug) => _shareUri('product', slug);

  static Uri storeShareUri(String slug) => _shareUri('store', slug);

  static Uri productAppUri(String slug) => Uri(
        scheme: customScheme,
        host: 'product',
        pathSegments: [slug],
      );

  static Uri storeAppUri(String slug) => Uri(
        scheme: customScheme,
        host: 'store',
        pathSegments: [slug],
      );

  static Uri _shareUri(String type, String slug) {
    final base = Uri.parse(shareBaseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      pathSegments: ['open', type, slug],
      queryParameters: {'fallback': fallbackUrl},
    );
  }

  static bool isShareHost(String host) {
    final expected = Uri.parse(shareBaseUrl).host.toLowerCase();
    return host.toLowerCase() == expected;
  }
}
