import 'dart:convert';
import 'dart:io';

class WebBookingCallableException implements Exception {
  const WebBookingCallableException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class WebBookingCallable {
  WebBookingCallable({required String projectId, String? endpoint})
      : _endpoint = endpoint ??
            'https://asia-northeast2-$projectId.cloudfunctions.net/'
                'createWebReservation';

  final String _endpoint;

  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'data': data}));
      final response = await request.close();
      final responseText = await utf8.decoder.bind(response).join();
      return _decodeCallableResponse(responseText);
    } finally {
      client.close();
    }
  }
}

Map<String, dynamic> _decodeCallableResponse(String responseText) {
  final response = jsonDecode(responseText) as Map<String, dynamic>;
  final error = response['error'];
  if (error is Map) {
    final errorData = Map<String, dynamic>.from(error);
    throw WebBookingCallableException(
      _normalizeErrorCode(errorData['status'] as String?),
      errorData['message'] as String? ?? 'Reservation request failed.',
    );
  }

  final result = response['result'];
  if (result is! Map) {
    throw const WebBookingCallableException(
      'internal',
      'Reservation response was invalid.',
    );
  }
  return Map<String, dynamic>.from(result);
}

String _normalizeErrorCode(String? status) {
  return (status ?? 'internal').toLowerCase().replaceAll('_', '-');
}
