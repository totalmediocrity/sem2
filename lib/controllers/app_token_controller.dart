import 'dart:async';
import 'dart:io';

import 'package:conduit/conduit.dart';

import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../utils/app_response.dart';

class AppTokenContoller extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request) {
    try {
      // Получаем токен из header запроса
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      // Из header получаем token
      final token = const AuthorizationBearerParser().parse(header);
  final String secretKey =
      Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
      // Получаем jwtClaim для проверки token
      final jwtClaim = verifyJwtHS256Signature(token ?? "",secretKey );
      // Валидируем наш token
      jwtClaim.validate();
      return request;
    } on JwtException catch (e) {
      return AppResponse.serverError(e.message);
    }
  }
}