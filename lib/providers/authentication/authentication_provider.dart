import 'package:bahaar/services/firestore_service.dart';
import 'package:bahaar/services/registration/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bahaar/models/registration/user.dart' as appUser;

class AuthProvider with ChangeNotifier {
  final AuthenticationService _authenticationService = AuthenticationService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? error;
  appUser.User? _currentAppUser;

  /// Returns the current Firebase Auth user
  fb.User? get currentFirebaseUser => _authenticationService.getCurrentUser();

  /// Returns the current app user with full profile data
  appUser.User? get currentAppUser => _currentAppUser;

  /// Returns true if a user is logged in
  bool get isLoggedIn => currentFirebaseUser != null;

  /// Returns true if the current user is a guest
  bool get isGuest => _currentAppUser?.isGuest ?? false;

  /// Initializes the auth state by checking for an existing Firebase session
  /// and fetching the user profile if found
  Future<void> initializeAuthState() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser != null && _currentAppUser == null) {
      // User is logged in via Firebase but we don't have their profile yet
      if (firebaseUser.isAnonymous) {
        _currentAppUser = appUser.User.guest(id: firebaseUser.uid);
        notifyListeners();
      } else {
        await fetchCurrentUserProfile();
      }
    }
  }

  /// Fetches the current user's profile from Firestore
  Future<appUser.User?> fetchCurrentUserProfile() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _currentAppUser = appUser.User.fromMap({...doc.data()!, 'id': doc.id});
        notifyListeners();
        return _currentAppUser;
      }
    } catch (e) {
      // print('Error fetching user profile: $e');
    }
    return null;
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String userName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final displayName = '$firstName $lastName';
      final user = await _authenticationService.register(email, password, displayName: displayName);

      if (user != null) {
        final newUser = appUser.User(
          id: user.uid,
          email: user.email ?? email,
          firstName: firstName,
          lastName: lastName,
          userName: userName,
          password: password,
        );
        await _firestoreService.createUser(newUser);
        _currentAppUser = newUser;
        // print('User document created successfully for ${user.uid}');
      } else {
        error = 'Registration failed - no user returned';
      }
    } catch (e) {
      error = e.toString();
      // print('Registration error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = await _authenticationService.login(email, password);

      if (user == null) {
        error = 'Invalid email or password';
        return false;
      }

      // Fetch user profile from Firestore
      await fetchCurrentUserProfile();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAsGuest() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = await _authenticationService.signInAsGuest();

      if (user == null) {
        error = 'Failed to sign in as guest';
        return false;
      }

      // Create guest user profile
      _currentAppUser = appUser.User.guest(id: user.uid);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? userName,
    String? phone,
    String? location,
  }) async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null || _currentAppUser == null) return;

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (userName != null) updates['user_name'] = userName;
    if (phone != null) updates['phone'] = phone;
    if (location != null) updates['location'] = location;

    await _firestoreService.updateUser(firebaseUser.uid, updates);
    _currentAppUser = _currentAppUser!.copyWith(
      firstName: firstName ?? _currentAppUser!.firstName,
      lastName: lastName ?? _currentAppUser!.lastName,
      userName: userName ?? _currentAppUser!.userName,
      phone: phone ?? _currentAppUser!.phone,
      location: location ?? _currentAppUser!.location,
    );
    notifyListeners();
  }

  Future<bool> resetPassword(String email, {String languageCode = 'en'}) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      await _authenticationService.sendPasswordResetEmail(email, languageCode: languageCode);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authenticationService.signOut();
    _currentAppUser = null;
    notifyListeners();
  }
}

final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
