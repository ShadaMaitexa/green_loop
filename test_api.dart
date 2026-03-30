import 'dart:io';
import 'dart:convert';

void main() async {
  final urls = [
    'https://greenloop-hdwc.onrender.com/api/v1/auth/otp/verify/',
    'https://greenloop-hdwc.onrender.com/api/v1/auth/verify-otp/',
    'https://greenloop-hdwc.onrender.com/api/v1/auth/otp-verify/',
    'https://greenloop-hdwc.onrender.com/api/v1/user/otp/verify/',
    'https://greenloop-hdwc.onrender.com/api/v1/auth/verify/',
  ];
  final client = HttpClient();
  
  for (final url in urls) {
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.add('Content-Type', 'application/json');
      request.write('{}');
      final response = await request.close();
      print('$url -> Status: ${response.statusCode}');
      await response.drain();
    } catch(e) {
      print('$url -> Error: $e');
    }
  }
  client.close();
}
