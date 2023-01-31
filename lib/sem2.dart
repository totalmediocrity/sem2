import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:sem2/controllers/app_auth_controller.dart';
import 'package:sem2/controllers/app_finance_controller.dart';
import 'package:sem2/controllers/app_token_controller.dart';
import 'package:sem2/controllers/app_user_controller.dart';

import 'package:sem2/model/history.dart';
import 'package:sem2/model/finance.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final PersistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), PersistentStore);
    return super.prepare();
  }

 @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user')
        .link(AppTokenContoller.new)!
        .link(() => AppUserController(managedContext))
    ..route('post/[:id]')
        .link(AppTokenContoller.new)!
        .link(() => AppFinanceController(managedContext));


  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '12345678';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'finance';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
