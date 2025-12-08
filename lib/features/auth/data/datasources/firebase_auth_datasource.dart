import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:co_workfit/core/config/firebase_config.dart';
import 'package:co_workfit/features/auth/data/models/user_model.dart';

/// Firebase Auth 데이터소스
class FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// 현재 로그인된 사용자 가져오기
  Future<Either<String, UserModel?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Right(null);
      }

      // Firestore에서 사용자 데이터 가져오기
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Firestore에 사용자 데이터가 없으면 생성
        final newUser = UserModel.fromFirebaseUser(
          firebaseUser.uid,
          firebaseUser.email!,
          firebaseUser.displayName,
          firebaseUser.photoURL,
        );
        await _createUserInFirestore(newUser);
        return Right(newUser);
      }

      return Right(UserModel.fromFirestore(userDoc));
    } catch (e) {
      return Left('현재 사용자 정보를 가져오는데 실패했습니다: $e');
    }
  }

  /// 이메일/비밀번호로 회원가입
  Future<Either<String, UserModel>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Firebase Auth에 사용자 생성
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left('사용자 생성에 실패했습니다.');
      }

      // 사용자 프로필 업데이트
      await credential.user!.updateDisplayName(displayName);

      // UserModel 생성
      final userModel = UserModel.fromFirebaseUser(
        credential.user!.uid,
        email,
        displayName,
        null,
      );

      // Firestore에 사용자 데이터 저장
      await _createUserInFirestore(userModel);

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('회원가입에 실패했습니다: $e');
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<Either<String, UserModel>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left('로그인에 실패했습니다.');
      }

      // Firestore에서 사용자 데이터 가져오기
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Firestore에 사용자 데이터가 없으면 생성
        final newUser = UserModel.fromFirebaseUser(
          credential.user!.uid,
          credential.user!.email!,
          credential.user!.displayName,
          credential.user!.photoURL,
        );
        await _createUserInFirestore(newUser);
        return Right(newUser);
      }

      // lastActiveAt 업데이트
      await _updateLastActive(credential.user!.uid);

      return Right(UserModel.fromFirestore(userDoc));
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('로그인에 실패했습니다: $e');
    }
  }

  /// Google 로그인
  Future<Either<String, UserModel>> signInWithGoogle() async {
    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return const Left('Google 로그인이 취소되었습니다.');
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return const Left('Google 로그인에 실패했습니다.');
      }

      // Firestore에서 사용자 데이터 가져오기 또는 생성
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      UserModel userModel;
      if (!userDoc.exists) {
        // 새 사용자 생성
        userModel = UserModel.fromFirebaseUser(
          userCredential.user!.uid,
          userCredential.user!.email!,
          userCredential.user!.displayName,
          userCredential.user!.photoURL,
        );
        await _createUserInFirestore(userModel);
      } else {
        userModel = UserModel.fromFirestore(userDoc);
        await _updateLastActive(userCredential.user!.uid);
      }

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('Google 로그인에 실패했습니다: $e');
    }
  }

  /// 로그아웃
  Future<Either<String, void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left('로그아웃에 실패했습니다: $e');
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<Either<String, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left('비밀번호 재설정 이메일 전송에 실패했습니다: $e');
    }
  }

  /// 사용자 프로필 업데이트
  Future<Either<String, UserModel>> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left('로그인된 사용자가 없습니다.');
      }

      // Firebase Auth 프로필 업데이트
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Firestore 업데이트
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .update(updates);

      // 업데이트된 사용자 데이터 가져오기
      final userDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(userId)
          .get();

      return Right(UserModel.fromFirestore(userDoc));
    } catch (e) {
      return Left('프로필 업데이트에 실패했습니다: $e');
    }
  }

  /// Firestore에 사용자 생성
  Future<void> _createUserInFirestore(UserModel user) async {
    await _firestore
        .collection(FirebaseConfig.usersCollection)
        .doc(user.id)
        .set(user.toFirestore());
  }

  /// 마지막 활동 시간 업데이트
  Future<void> _updateLastActive(String userId) async {
    await _firestore
        .collection(FirebaseConfig.usersCollection)
        .doc(userId)
        .update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  /// FirebaseAuthException 처리
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'operation-not-allowed':
        return '이 인증 방식은 현재 사용할 수 없습니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 최소 6자 이상 입력해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
        return '존재하지 않는 사용자입니다.';
      case 'wrong-password':
        return '잘못된 비밀번호입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }

  /// 인증 상태 변경 스트림
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
