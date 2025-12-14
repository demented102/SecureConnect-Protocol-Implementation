import 'package:flutter/material.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      _jwtToken = await secureStorage.getString('ff_jwtToken') ?? _jwtToken;
    });
    await _safeInitAsync(() async {
      _privateKey =
          await secureStorage.getString('ff_privateKey') ?? _privateKey;
    });
    await _safeInitAsync(() async {
      _username = await secureStorage.getString('ff_username') ?? _username;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  String _jwtToken = '';
  String get jwtToken => _jwtToken;
  set jwtToken(String value) {
    _jwtToken = value;
    secureStorage.setString('ff_jwtToken', value);
  }

  void deleteJwtToken() {
    secureStorage.delete(key: 'ff_jwtToken');
  }

  String _privateKey = '';
  String get privateKey => _privateKey;
  set privateKey(String value) {
    _privateKey = value;
    secureStorage.setString('ff_privateKey', value);
  }

  void deletePrivateKey() {
    secureStorage.delete(key: 'ff_privateKey');
  }

  String _username = '';
  String get username => _username;
  set username(String value) {
    _username = value;
    secureStorage.setString('ff_username', value);
  }

  void deleteUsername() {
    secureStorage.delete(key: 'ff_username');
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async => (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
