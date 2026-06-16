import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProfilePhotoService {
  static Future<Map<String, dynamic>?> savePhoto(XFile file) async {
    if (ApiService.token == null) return null;

    final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/user-profile/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer ${ApiService.token}',
    });

    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: file.name.isEmpty ? 'profile.jpg' : file.name));

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ApiService.getUserProfile();
    }

    return null;
  }

  static String imageUrl(dynamic image) {
    final value = image?.toString().trim() ?? '';
    if (value.isEmpty || value == 'null') return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final clean = value.startsWith('/') ? value.substring(1) : value;
    if (clean.startsWith('uploads/') || clean.startsWith('storage/')) return '$base/$clean';
    return '$base/uploads/profiles/$clean';
  }
}
