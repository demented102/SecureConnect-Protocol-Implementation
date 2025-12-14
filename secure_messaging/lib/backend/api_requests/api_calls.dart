import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class LoginApiCall {
  static Future<ApiCallResponse> call({
    String? username = '',
    String? password = '',
    String? totpCode = '',
  }) async {
    final ffApiRequestBody = '''
{
  "username": "${escapeStringForJson(username)}",
  "password": "${escapeStringForJson(password)}",
  "totp_code": "${escapeStringForJson(totpCode)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'loginApi',
      apiUrl: 'http://10.0.2.2:5000/login',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class UploadPublicKeyAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? publicKeyPem = '',
  }) async {
    final ffApiRequestBody = '''
{
  "public_key": "${escapeStringForJson(publicKeyPem)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'uploadPublicKeyAPI',
      apiUrl: 'http://10.0.2.2:5000/upload_public_key',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class SendMessageAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? payload = '',
  }) async {
    final ffApiRequestBody = '''
{
  "encrypted_payload": "${escapeStringForJson(payload)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'sendMessageAPI',
      apiUrl: 'http://10.0.2.2:5000/send_message',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetPublicKeyAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? username = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getPublicKeyAPI',
      apiUrl: 'http://10.0.2.2:5000/get_public_key',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${authToken}',
      },
      params: {
        'user': username,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetMessagesAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? messages = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getMessagesAPI',
      apiUrl: 'http://10.0.2.2:5000/get_messages',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetUsersAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUsersAPI',
      apiUrl: 'http://10.0.2.2:5000/get_users',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class SendFileAPICall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? recipient = '',
    String? wrappedKey = '',
    String? encryptedFile = '',
  }) async {
    final ffApiRequestBody = '''
{
  "recipient": "${escapeStringForJson(recipient)}",
  "wrapped_key": "${escapeStringForJson(wrappedKey)}",
  "encrypted_file": "${escapeStringForJson(encryptedFile)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'sendFileAPI',
      apiUrl: 'http://10.0.2.2:5000/send_file',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
