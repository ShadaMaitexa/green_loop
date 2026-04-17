import 'dart:io';
import 'dart:convert';

void main() async {
  final baseUrl = 'https://greenloop-hdwc.onrender.com';
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  // Test 1: GET today's attendance (no auth — expect 401, shows endpoint exists)
  print('=== Testing GET /api/v1/hks/attendance/today/ ===');
  try {
    final req = await client.getUrl(Uri.parse('$baseUrl/api/v1/hks/attendance/today/'));
    req.headers.add('Accept', 'application/json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  print('');
  print('=== Testing POST /api/v1/hks/attendance/ with GeoJSON payload ===');
  // Test 2: POST attendance with GeoJSON (the current format) — no auth so 401, but see if it's even the right shape
  try {
    final req = await client.postUrl(Uri.parse('$baseUrl/api/v1/hks/attendance/'));
    req.headers.contentType = ContentType.json;
    req.headers.add('Accept', 'application/json');
    final payload = jsonEncode({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [77.5946, 12.9716],
      },
      'properties': {
        'ppe_photo_url': 'https://example.com/selfie.jpg',
        'has_gloves': true,
        'has_mask': true,
        'has_vest': true,
        'has_boots': true,
        'status': 'PRESENT',
      },
    });
    req.write(payload);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  print('');
  print('=== Testing POST /api/v1/hks/attendance/ with FLAT payload ===');
  // Test 3: Try flat payload — maybe the API doesn't want GeoJSON wrapper
  try {
    final req = await client.postUrl(Uri.parse('$baseUrl/api/v1/hks/attendance/'));
    req.headers.contentType = ContentType.json;
    req.headers.add('Accept', 'application/json');
    final payload = jsonEncode({
      'ppe_photo_url': 'https://example.com/selfie.jpg',
      'has_gloves': true,
      'has_mask': true,
      'has_vest': true,
      'has_boots': true,
      'status': 'PRESENT',
      'latitude': 12.9716,
      'longitude': 77.5946,
    });
    req.write(payload);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  // Test 4: Check what OPTIONS says about the endpoint
  print('');
  print('=== Testing OPTIONS /api/v1/hks/attendance/ ===');
  try {
    final req = await client.openUrl('OPTIONS', Uri.parse('$baseUrl/api/v1/hks/attendance/'));
    req.headers.add('Accept', 'application/json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    print('Status: ${res.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
