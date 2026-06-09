import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

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
    final request = html.HttpRequest();
    request
      ..open('POST', _endpoint)
      ..setRequestHeader('Content-Type', 'application/json');

    final load = request.onLoad.first;
    final error = request.onError.first.then<html.Event>((event) {
      throw const WebBookingCallableException(
        'unavailable',
        'Reservation service is unavailable.',
      );
    });
    request.send(jsonEncode({'data': data}));
    await Future.any<html.Event>([load, error]);
    return _decodeCallableResponse(request.responseText ?? '');
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
