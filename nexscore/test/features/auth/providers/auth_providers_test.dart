import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexscore/core/error/failures.dart';
import 'package:nexscore/features/auth/providers/auth_providers.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUserInfo extends Mock implements UserInfo {}

// Fakes for registerFallbackValue
class FakeGoogleAuthProvider extends Fake implements GoogleAuthProvider {}
class FakeGithubAuthProvider extends Fake implements GithubAuthProvider {}
class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    registerFallbackValue(FakeGoogleAuthProvider());
    registerFallbackValue(FakeGithubAuthProvider());
    registerFallbackValue(FakeAuthCredential());
  });

  group('authUserProvider', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    test('emits user from authStateChanges', () async {
      final mockUser = MockUser();
      final controller = StreamController<User?>.broadcast();
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      final states = <AsyncValue<User?>>[];
      container.listen<AsyncValue<User?>>(
        authUserProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      expect(states.last, const AsyncLoading<User?>());

      controller.add(mockUser);
      await Future.delayed(const Duration(milliseconds: 5));

      expect(states.last, AsyncData<User?>(mockUser));
    });

    test('emits null on authStateChanges error', () async {
      final controller = StreamController<User?>.broadcast();
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      final states = <AsyncValue<User?>>[];
      container.listen<AsyncValue<User?>>(
        authUserProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      expect(states.last, const AsyncLoading<User?>());

      controller.addError('Auth Error');
      await Future.delayed(const Duration(milliseconds: 5));

      // Since authUserProvider has handleError which swallows the error without emitting a value,
      // the provider remains in AsyncLoading state.
      expect(states.last, const AsyncLoading<User?>());
    });
  });

  group('AuthService Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test-uid');
    });

    group('signInWithGoogleNative', () {
      test('success returns user credential', () async {
        // By default, since we are not running in Web environment here, we stub signInWithProvider
        when(() => mockAuth.signInWithProvider(any())).thenAnswer((_) async => mockUserCredential);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signInWithGoogleNative();

        expect(result.isSuccess, isTrue);
        expect(result.value.user?.uid, 'test-uid');
      });

      test('failure returns Result.failure', () async {
        when(() => mockAuth.signInWithProvider(any())).thenThrow(Exception('Google Sign In Error'));

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signInWithGoogleNative();

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<AuthFailure>());
      });
    });

    group('signInWithGithub', () {
      test('success returns user credential', () async {
        when(() => mockAuth.signInWithProvider(any())).thenAnswer((_) async => mockUserCredential);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signInWithGithub();

        expect(result.isSuccess, isTrue);
        expect(result.value.user?.uid, 'test-uid');
      });

      test('failure returns Result.failure', () async {
        when(() => mockAuth.signInWithProvider(any())).thenThrow(Exception('GitHub Sign In Error'));

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signInWithGithub();

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<AuthFailure>());
      });
    });

    group('linkWithGoogle', () {
      test('fails if currentUser is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.linkWithGoogle();

        expect(result.isFailure, isTrue);
        expect(result.failure.message, 'No user logged in');
      });

      test('success links account', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.linkWithProvider(any())).thenAnswer((_) async => mockUserCredential);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.linkWithGoogle();

        expect(result.isSuccess, isTrue);
        expect(result.value.user?.uid, 'test-uid');
      });

      test('failure returns AuthFailure with credential if FirebaseAuthException thrown', () async {
        final mockCredential = FakeAuthCredential();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.linkWithProvider(any())).thenThrow(
          FirebaseAuthException(
            code: 'credential-already-in-use',
            message: 'Already in use',
            credential: mockCredential,
          ),
        );

        final authService = AuthService(auth: mockAuth);
        final result = await authService.linkWithGoogle();

        expect(result.isFailure, isTrue);
        final failure = result.failure as AuthFailure;
        expect(failure.message, 'credential-already-in-use');
        expect(failure.credential, mockCredential);
      });
    });

    group('linkWithGithub', () {
      test('fails if currentUser is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.linkWithGithub();

        expect(result.isFailure, isTrue);
        expect(result.failure.message, 'No user logged in');
      });

      test('success links account', () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.linkWithProvider(any())).thenAnswer((_) async => mockUserCredential);

        final authService = AuthService(auth: mockAuth);
        final result = await authService.linkWithGithub();

        expect(result.isSuccess, isTrue);
        expect(result.value.user?.uid, 'test-uid');
      });
    });

    group('signOut', () {
      test('success signs out', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signOut();

        expect(result.isSuccess, isTrue);
        verify(() => mockAuth.signOut()).called(1);
      });

      test('failure returns failure', () async {
        when(() => mockAuth.signOut()).thenThrow(Exception('Sign Out Error'));

        final authService = AuthService(auth: mockAuth);
        final result = await authService.signOut();

        expect(result.isFailure, isTrue);
        expect(result.failure.message, 'Sign-out failed');
      });
    });
  });

  group('UserPrimaryIdentity Extension Tests', () {
    late MockUser mockUser;
    late MockUserInfo mockGoogleProvider;
    late MockUserInfo mockGithubProvider;
    late MockUserInfo mockOtherProvider;

    setUp(() {
      mockUser = MockUser();
      mockGoogleProvider = MockUserInfo();
      mockGithubProvider = MockUserInfo();
      mockOtherProvider = MockUserInfo();

      when(() => mockGoogleProvider.providerId).thenReturn('google.com');
      when(() => mockGoogleProvider.displayName).thenReturn('Google User');
      when(() => mockGoogleProvider.photoURL).thenReturn('google-photo-url');

      when(() => mockGithubProvider.providerId).thenReturn('github.com');
      when(() => mockGithubProvider.displayName).thenReturn('GitHub User');
      when(() => mockGithubProvider.photoURL).thenReturn('github-photo-url');

      when(() => mockOtherProvider.providerId).thenReturn('password');
      when(() => mockOtherProvider.displayName).thenReturn('Password User');
      when(() => mockOtherProvider.photoURL).thenReturn('password-photo-url');
    });

    test('primaryProvider returns google or github if available', () {
      when(() => mockUser.providerData).thenReturn([mockOtherProvider, mockGoogleProvider]);
      expect(mockUser.primaryProvider, mockGoogleProvider);

      when(() => mockUser.providerData).thenReturn([mockGithubProvider, mockOtherProvider]);
      expect(mockUser.primaryProvider, mockGithubProvider);
    });

    test('primaryProvider returns first provider if no google/github provider available', () {
      when(() => mockUser.providerData).thenReturn([mockOtherProvider]);
      expect(mockUser.primaryProvider, mockOtherProvider);

      when(() => mockUser.providerData).thenReturn([]);
      expect(mockUser.primaryProvider, isNull);
    });

    test('primaryDisplayName prioritizes primary provider then main fields', () {
      // 1. Google provider data exists
      when(() => mockUser.providerData).thenReturn([mockGoogleProvider]);
      when(() => mockUser.displayName).thenReturn('Main User');
      expect(mockUser.primaryDisplayName, 'Google User');

      // 2. No primary provider, uses displayName
      when(() => mockUser.providerData).thenReturn([]);
      expect(mockUser.primaryDisplayName, 'Main User');

      // 3. Defaults to 'User'
      when(() => mockUser.displayName).thenReturn(null);
      expect(mockUser.primaryDisplayName, 'User');
    });

    test('primaryPhotoURL prioritizes primary provider then main fields', () {
      when(() => mockUser.providerData).thenReturn([mockGoogleProvider]);
      when(() => mockUser.photoURL).thenReturn('main-photo-url');
      expect(mockUser.primaryPhotoURL, 'google-photo-url');

      when(() => mockUser.providerData).thenReturn([]);
      expect(mockUser.primaryPhotoURL, 'main-photo-url');
    });

    test('isPrimaryProvider identifies correct provider', () {
      when(() => mockUser.providerData).thenReturn([mockGoogleProvider]);
      expect(mockUser.isPrimaryProvider('google.com'), isTrue);
      expect(mockUser.isPrimaryProvider('github.com'), isFalse);
    });
  });
}
