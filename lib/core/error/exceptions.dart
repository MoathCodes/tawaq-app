// class CacheException implements Exception {
//   final String message;
//   final StackTrace? stackTrace;
//   final Object? originalException;

//   CacheException({
//     required this.message,
//     this.stackTrace,
//     this.originalException,
//   });

//   @override
//   int get hashCode =>
//       message.hashCode ^ stackTrace.hashCode ^ originalException.hashCode;

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is CacheException &&
//         other.message == message &&
//         other.stackTrace == stackTrace &&
//         other.originalException == originalException;
//   }

//   @override
//   String toString() =>
//       'CacheException(message: $message, stackTrace: $stackTrace, originalException: $originalException)';
// }

// class DatabaseException implements Exception {
//   final String message;
//   final StackTrace? stackTrace;
//   final Object? originalException;

//   DatabaseException({
//     required this.message,
//     this.stackTrace,
//     this.originalException,
//   });

//   @override
//   int get hashCode =>
//       message.hashCode ^ stackTrace.hashCode ^ originalException.hashCode;

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is DatabaseException &&
//         other.message == message &&
//         other.stackTrace == stackTrace &&
//         other.originalException == originalException;
//   }

//   @override
//   String toString() =>
//       'DatabaseException(message: $message, stackTrace: $stackTrace, originalException: $originalException)';
// }
