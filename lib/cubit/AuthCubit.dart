import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> loginWithEmail(String email, String password) async {
    emit(AuthLoading());

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      emit(AuthSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      String error = 'Login failed';

      if (e.code == 'user-not-found') {
        error = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        error = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        error = 'The email is badly formatted.';
      }

      emit(AuthError(error));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      await user?.updateDisplayName(fullName);

      emit(AuthSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        default:
          errorMessage = 'Something went wrong. Try again.';
      }
      emit(AuthError(errorMessage));
    }
  }
}
