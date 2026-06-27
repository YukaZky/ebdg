import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class AdminBrandApiService {
  static String? lastError;

  static String _messageFromBody(String body, {String fallback = 'Gagal menyimpan brand.'}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  static String _safeFileName(XFile file) {
    final raw = file.name.trim();
    if (raw.isNotEmpty && raw.contains('.')) return raw;
    final fromPath = file.path.split('/').last.split('\\').last.trim();
    if (fromPath.isNotEmpty && fromPath.contains('.')) return fromPath;
    return 'brand_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  static Future<bool> saveBrand(Map<String, String> fields, {XFile? image, int? brandId}) async {
    lastError = null;
    if (ApiService.token == null) {
      lastError = 'Sesi login habis. Silakan login ulang.';
      return false;
    }

    final uri = brandId == null
        ? Uri.parse('${ApiService.baseUrl}/admin/brands/store')
        : Uri.parse('${ApiService.baseUrl}/admin/brands/update/$brandId');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Authorization': 'Bearer ${ApiService.token}',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    });

    if (brandId != null) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _safeFileName(image)));
      }
    }

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      print('saveAdminBrand status: ${response.statusCode}');
      print('saveAdminBrand body: $body');

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        lastError = _messageFromBody(body, fallback: 'Gagal menyimpan brand. Kode: ${response.statusCode}');
      }
      return ok;
    } catch (e) {
      lastError = 'Gagal menyimpan brand: $e';
      return false;
    }
  }
}
