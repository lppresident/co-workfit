import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:co_workfit/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 인증 레포지토리 구현
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;

  AuthRepositoryImpl(this._authDataSource);

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    return await _authDataSource.getCurrentUser();
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    return await _authDataSource.signInWithGoogle();
  }

  @override
  Future<Either<String, UserEntity>> signInWithApple() async {
    return await _authDataSource.signInWithApple();
  }

  @override
  Future<Either<String, bool>> checkNicknameAvailability(String nickname) async {
    return await _authDataSource.checkNicknameAvailability(nickname);
  }

  @override
  Future<Either<String, void>> signOut() async {
    return await _authDataSource.signOut();
  }

  @override
  Future<Either<String, UserEntity>> updateProfile({
    required String userId,
    String? displayName,
    String? nickname,
    String? photoUrl,
  }) async {
    return await _authDataSource.updateProfile(
      userId: userId,
      displayName: displayName,
      nickname: nickname,
      photoUrl: photoUrl,
    );
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _authDataSource.authStateChanges;
}
