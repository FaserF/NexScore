abstract class Failure {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() => 'Failure: $message ${error != null ? '($error)' : ''}';
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.error, super.stackTrace});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.error, super.stackTrace});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.error, super.stackTrace});
}

class SyncFailure extends Failure {
  const SyncFailure(super.message, {super.error, super.stackTrace});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.error, super.stackTrace});
}
