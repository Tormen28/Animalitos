// Excepciones personalizadas para la aplicación
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

// Tipos específicos de excepciones
class NetworkException extends AppException {
  NetworkException(String message, {dynamic originalError})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError);
}

class AuthException extends AppException {
  AuthException(String message, {dynamic originalError})
      : super(message, code: 'AUTH_ERROR', originalError: originalError);
}

class ValidationException extends AppException {
  ValidationException(String message, {dynamic originalError})
      : super(message, code: 'VALIDATION_ERROR', originalError: originalError);
}

class DatabaseException extends AppException {
  DatabaseException(String message, {dynamic originalError})
      : super(message, code: 'DATABASE_ERROR', originalError: originalError);
}

class InsufficientFundsException extends AppException {
  InsufficientFundsException(String message, {dynamic originalError})
      : super(message, code: 'INSUFFICIENT_FUNDS', originalError: originalError);
}
