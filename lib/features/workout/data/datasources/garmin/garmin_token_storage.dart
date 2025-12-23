import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'models/garmin_credentials.dart';

/// Garmin OAuth 토큰을 안전하게 저장/조회하는 클래스
class GarminTokenStorage {
  static const String _keyCredentials = 'garmin_credentials';
  final FlutterSecureStorage _storage;

  GarminTokenStorage(this._storage);

  /// 인증 정보 저장
  Future<void> saveCredentials(GarminCredentials credentials) async {
    try {
      final json = jsonEncode(credentials.toJson());
      await _storage.write(key: _keyCredentials, value: json);
      AppLogger.info('GarminTokenStorage', 'Credentials saved for user: ${credentials.userId}');
    } catch (e, stackTrace) {
      AppLogger.error('GarminTokenStorage', 'Failed to save credentials', e, stackTrace);
      rethrow;
    }
  }

  /// 인증 정보 조회
  Future<GarminCredentials?> getCredentials() async {
    try {
      final json = await _storage.read(key: _keyCredentials);
      if (json == null) {
        AppLogger.debug('GarminTokenStorage', 'No credentials found');
        return null;
      }

      final credentials = GarminCredentials.fromJson(jsonDecode(json));

      if (credentials.isExpired) {
        AppLogger.warning('GarminTokenStorage', 'Credentials expired');
        await deleteCredentials();
        return null;
      }

      AppLogger.debug('GarminTokenStorage', 'Credentials loaded for user: ${credentials.userId}');
      return credentials;
    } catch (e, stackTrace) {
      AppLogger.error('GarminTokenStorage', 'Failed to load credentials', e, stackTrace);
      return null;
    }
  }

  /// 인증 정보 삭제
  Future<void> deleteCredentials() async {
    try {
      await _storage.delete(key: _keyCredentials);
      AppLogger.info('GarminTokenStorage', 'Credentials deleted');
    } catch (e, stackTrace) {
      AppLogger.error('GarminTokenStorage', 'Failed to delete credentials', e, stackTrace);
    }
  }

  /// 인증 여부 확인
  Future<bool> hasValidCredentials() async {
    final credentials = await getCredentials();
    return credentials != null && !credentials.isExpired;
  }
}
