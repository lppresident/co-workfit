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

    // Update in Firebase Auth
    await firebaseUser.updateDisplayName(newDisplayName);

    // Update in Firestore
    await firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .update({'displayName': newDisplayName});
  }

  @override
  Future<void> logout() async {
    // The order is important. Sign out from Google first.
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }
}
