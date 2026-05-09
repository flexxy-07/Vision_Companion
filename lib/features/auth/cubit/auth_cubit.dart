import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vision_companion/features/auth/cubit/auth_state.dart';
import 'package:vision_companion/features/auth/repository/auth_repository.dart';

class AuthCubit extends Cubit<AuthState>{
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSub;

  AuthCubit(this._repo) : super(AuthInitial());

  void checkAuthState() {
    _authSub = _repo.authStateChanges.listen((user){
      if (user != null){
        emit(AuthAuthenticated(user));
      }else{
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final cred = await _repo.signUpWithEmail(email, password, password);
      emit(AuthAuthenticated(cred.user!));
    }on FirebaseAuthException catch(e){
      emit(AuthError(_mapError(e.code)));
    }catch(e){
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final cred = await _repo.signUpWithEmail(email, password, name);
      emit(AuthAuthenticated(cred.user!));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final cred = await _repo.signInWithGoogle();
      emit(AuthAuthenticated(cred.user!));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'Email already registered.';
      case 'weak-password': return 'Password too weak (min 6 chars).';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'Authentication failed. Please try again.';
    }
  }

   @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}