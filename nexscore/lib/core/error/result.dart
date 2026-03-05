import 'failures.dart';

class Result<T> {
  final T? _value;
  final Failure? _failure;

  const Result.success(T value) : _value = value, _failure = null;

  const Result.failure(Failure failure) : _value = null, _failure = failure;

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;

  T get value {
    if (isFailure) throw Exception('Cannot get value from a failure result.');
    return _value!;
  }

  Failure get failure {
    if (isSuccess) throw Exception('Cannot get failure from a success result.');
    return _failure!;
  }

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    if (isFailure) {
      return onFailure(_failure!);
    } else {
      return onSuccess(_value!);
    }
  }
}
