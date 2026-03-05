import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/error/result.dart';
import 'package:nexscore/core/error/failures.dart';

void main() {
  group('Result<T>', () {
    test('success result has correct value', () {
      final result = Result<int>.success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.value, 42);
    });

    test('failure result has correct failure', () {
      final result = Result<int>.failure(const DatabaseFailure('db error'));
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.failure, isA<DatabaseFailure>());
      expect(result.failure.message, 'db error');
    });

    test('accessing value on failure throws', () {
      final result = Result<int>.failure(const ValidationFailure('bad input'));
      expect(() => result.value, throwsException);
    });

    test('accessing failure on success throws', () {
      final result = Result<String>.success('ok');
      expect(() => result.failure, throwsException);
    });

    test('fold calls onSuccess for success result', () {
      final result = Result<int>.success(10);
      final output = result.fold((f) => 'fail: ${f.message}', (v) => 'ok: $v');
      expect(output, 'ok: 10');
    });

    test('fold calls onFailure for failure result', () {
      final result = Result<int>.failure(const AuthFailure('unauthorized'));
      final output = result.fold((f) => 'fail: ${f.message}', (v) => 'ok: $v');
      expect(output, 'fail: unauthorized');
    });

    test('success with null value works', () {
      final result = Result<String?>.success(null);
      expect(result.isSuccess, true);
    });
  });

  group('Failure hierarchy', () {
    test('DatabaseFailure toString contains message', () {
      const f = DatabaseFailure('connection lost');
      expect(f.toString(), contains('connection lost'));
    });

    test('ValidationFailure preserves error object', () {
      const f = ValidationFailure('bad', error: 'detail');
      expect(f.error, 'detail');
    });

    test('AuthFailure preserves stack trace', () {
      final st = StackTrace.current;
      final f = AuthFailure('denied', stackTrace: st);
      expect(f.stackTrace, st);
    });

    test('UnexpectedFailure toString includes error when present', () {
      const f = UnexpectedFailure('oops', error: 'err123');
      expect(f.toString(), contains('err123'));
    });

    test('UnexpectedFailure toString without error', () {
      const f = UnexpectedFailure('oops');
      expect(f.toString(), contains('oops'));
      expect(f.toString(), isNot(contains('null')));
    });

    test('all failure types extend Failure', () {
      expect(const DatabaseFailure('a'), isA<Failure>());
      expect(const ValidationFailure('b'), isA<Failure>());
      expect(const AuthFailure('c'), isA<Failure>());
      expect(const UnexpectedFailure('d'), isA<Failure>());
    });
  });
}
