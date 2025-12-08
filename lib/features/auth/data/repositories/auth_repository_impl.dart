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
  Future<Either<String, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _authDataSource.signUpWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<Either<String, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _authDataSource.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    return await _authDataSource.signInWithGoogle();
  }

  @override
  Future<Either<String, void>> signOut() async {
    return await _authDataSource.signOut();
  }

  @override
  Future<Either<String, void>> sendPasswordResetEmail(String email) async {
    return await _authDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<Either<String, UserEntity>> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    return await _authDataSource.updateProfile(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _authDataSource.authStateChanges;
}
