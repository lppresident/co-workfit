import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/auth/data/models/user_model.dart';
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:co_workfit/core/errors/exceptions.dart'; // We need to create this exception file.

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  ProfileRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> getProfileData() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw AuthException('No user is currently signed in.');
    }

    final docSnapshot =
        await firestore.collection('users').doc(firebaseUser.uid).get();

    if (!docSnapshot.exists) {
      throw ServerException('User document not found in Firestore.');
    }

    return UserModel.fromFirestore(docSnapshot);
  }

  @override
  Future<void> updateDisplayName(String newDisplayName) async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw AuthException('No user is currently signed in.');
    }

    // 실제로는 nickname을 업데이트 (displayName은 유지)
    // 1. 닉네임 컬렉션에서 기존 닉네임 삭제
    final userDoc = await firestore.collection('users').doc(firebaseUser.uid).get();
    final currentNickname = userDoc.data()?['nickname'] as String?;

    if (currentNickname != null) {
      await firestore.collection('nicknames').doc(currentNickname).delete();
    }

    // 2. 새 닉네임을 nicknames 컬렉션에 추가
    await firestore.collection('nicknames').doc(newDisplayName).set({
      'userId': firebaseUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. users 컬렉션에서 nickname 업데이트
    await firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .update({
          'nickname': newDisplayName,
          'isNicknameSet': true,
        });

    // 4. 사용자가 참여 중인 모든 챌린지의 participantNicknames 업데이트
    final challengesQuery = await firestore
        .collection('challenges')
        .where('participants', arrayContains: firebaseUser.uid)
        .get();

    final batch = firestore.batch();
    for (final doc in challengesQuery.docs) {
      final data = doc.data();
      final updateData = <String, dynamic>{
        'participantNicknames.${firebaseUser.uid}': newDisplayName,
      };

      // 사용자가 챌린지 생성자인 경우 creatorNickname도 업데이트
      if (data['createdBy'] == firebaseUser.uid) {
        updateData['creatorNickname'] = newDisplayName;
      }

      batch.update(doc.reference, updateData);
    }
    await batch.commit();

    // 5. 사용자의 모든 기여 기록(contributions)의 닉네임 업데이트
    final contributionsQuery = await firestore
        .collectionGroup('contributions')
        .where('userId', isEqualTo: firebaseUser.uid)
        .get();

    final contributionsBatch = firestore.batch();
    for (final doc in contributionsQuery.docs) {
      contributionsBatch.update(doc.reference, {
        'userNickname': newDisplayName,
      });
    }
    await contributionsBatch.commit();
  }

  @override
  Future<void> logout() async {
    // The order is important. Sign out from Google first.
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }
}
