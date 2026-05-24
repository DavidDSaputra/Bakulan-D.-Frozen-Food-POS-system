import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryConfigException implements Exception {
  const CloudinaryConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryService {
  CloudinaryService({
    String cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
    String uploadPreset = const String.fromEnvironment(
      'CLOUDINARY_UPLOAD_PRESET',
    ),
    http.Client? client,
  }) : _cloudName = cloudName,
       _uploadPreset = uploadPreset,
       _client = client ?? http.Client();

  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw const CloudinaryConfigException(
        'Cloudinary belum dikonfigurasi. Jalankan app dengan --dart-define CLOUDINARY_CLOUD_NAME dan CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = 'bakulan-products'
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final response = await _client.send(request);
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _readCloudinaryError(body);
      throw Exception(message ?? 'Gagal upload gambar ke Cloudinary.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['secure_url']?.toString() ?? '';
  }

  String? _readCloudinaryError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      return error?['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
