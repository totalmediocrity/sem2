import 'dart:io';
import 'package:conduit/conduit.dart';
import '../model/history.dart';
import '../model/finance.dart';
import '../model/user.dart';
import '../utils/app_response.dart';
import '../utils//AppUtils.dart';

class AppFinanceController extends ResourceController {
  AppFinanceController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> createFinance(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Finance finance) async {
    try {
      late final int financeId;
      final id = AppUtils.getIdFromHeader(header);
      final financeQuery = Query<Finance>(managedContext)
        ..where((finance) => finance.user!.id).equalTo(id);
      final finances = await financeQuery.fetch();
      final financeNumber = finances.length;
      final fUser = Query<User>(managedContext)
        ..where((user) => user.id).equalTo(id);
      final user = await fUser.fetchOne();
      await managedContext.transaction((transaction) async {
        final qCreateFinance = Query<Finance>(transaction)
          ..values.number = financeNumber + 1
          ..values.name = finance.name
          ..values.description = finance.description
          ..values.category = finance.category
          ..values.noteDateCreated = DateTime.now().toString()
          ..values.total = finance.total
          ..values.user = user
          ..values.status = "created";
        final createdFinance = await qCreateFinance.insert();
        financeId = createdFinance.id!;
      });
      final financeData = await managedContext.fetchObjectWithID<Finance>(financeId);
      financeData!.removePropertiesFromBackingMap(
        [
          "user",
          "id",
          "status",
        ],
      );
      createHistory(
        id,
        "Заметка с номером ${financeData.number} добавлена",
      );
      return AppResponse.ok(
        body: financeData.backing.contents,
        message: 'Успешное добавление',
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка добавления',
      );
    }
  }

  @Operation.put("number")
  Future<Response> updateNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("number") int number,
      @Bind.body() Finance finance) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final financeQuery = Query<Finance>(managedContext)
        ..where((finance) => finance.number).equalTo(number)
        ..where((finance) => finance.user!.id).equalTo(currentUserId)
        ..where((finance) => finance.status).notEqualTo("deleted");
      final financeDB = await financeQuery.fetchOne();
      if (financeDB == null) {
        return AppResponse.ok(
          message: "Заметка не найдена",
        );
      }
      final qUpdateFinance = Query<Finance>(managedContext)
        ..where((finance) => finance.id).equalTo(financeDB.id)
        ..values.category = finance.category
        ..values.name = finance.name
        ..values.description = finance.description
        ..values.noteDateCreated = DateTime.now().toString()
        ..values.status = "updated";
      await qUpdateFinance.update();
      createHistory(
        currentUserId,
        "Заметка с номером $number обновлена",
      );
      return AppResponse.ok(
        body: finance.backing.contents,
        message: "Успешное обновление",
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  @Operation.delete("number")
  Future<Response> deleteNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("number") int number) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final financeQuery = Query<Finance>(managedContext)
        ..where((finance) => finance.number).equalTo(number)
        ..where((finance) => finance.user!.id).equalTo(currentUserId)
        ..where((finance) => finance.status).notEqualTo("deleted");
      final finance = await financeQuery.fetchOne();
      if (finance == null) {
        return AppResponse.ok(message: "Заметка не найдена");
      }
      final qLogicDeleteNote = Query<Finance>(managedContext)
        ..where((finance) => finance.number).equalTo(number)
        ..values.status = "deleted";
      await qLogicDeleteNote.update();
      createHistory(
        currentUserId,
        "Заметка с номером $number удалена",
      );
      return AppResponse.ok(
        message: 'Успешное удаление',
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка удаления',
      );
    }
  }

  @Operation.get("number")
  Future<Response> getOneNote(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path("number") int number,
      {@Bind.query("restore") bool? restore}) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final deletedFinanceQuery = Query<Finance>(managedContext)
        ..where((finance) => finance.number).equalTo(number)
        ..where((finance) => finance.user!.id).equalTo(currentUserId)
        ..where((finance) => finance.status).equalTo("deleted");
      final deletedFinance = await deletedFinanceQuery.fetchOne();
      String message = "Успешное получение";
      if (deletedFinance != null && restore != null && restore) {
        deletedFinanceQuery.values.status = "restored";
        deletedFinanceQuery.update();
        message = "Успешное восстановление";
        createHistory(
          currentUserId,
          "Заметка с номером $number восстановлена",
        );
      }
      final financeQuery = Query<Finance>(managedContext)
        ..where((finance) => finance.number).equalTo(number)
        ..where((finance) => finance.user!.id).equalTo(currentUserId)
        ..where((finance) => finance.status).notEqualTo("deleted");
      final finance = await financeQuery.fetchOne();
      if (finance == null) {
        return AppResponse.ok(
          message: "Заметка не найдена",
        );
      }
      finance.removePropertiesFromBackingMap(
        [
          "user",
          "id",
        ],
      );
      return AppResponse.ok(
        body: finance.backing.contents,
        message: message,
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  @Operation.get()
  Future<Response> getFinances(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      {@Bind.query("search") String? search,
      @Bind.query("limit") int? limit,
      @Bind.query("offset") int? offset,
      @Bind.query("filter") String? filter}) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      Query<Finance>? financeQuery;
      if (search != null && Finance != "") {
        financeQuery = Query<Finance>(managedContext)
          ..where((finance) => finance.name).contains(search)
          ..where((finance) => finance.user!.id).equalTo(id);
      } else {
        financeQuery = Query<Finance>(managedContext)
          ..where((note) => note.user!.id).equalTo(id);
      }
      switch (filter) {
        case "created":
          financeQuery.where((finance) => finance.status).equalTo(filter);
          break;
        case "updated":
          financeQuery.where((finance) => finance.status).equalTo(filter);
          break;
        case "deleted":
          financeQuery.where((finance) => finance.status).equalTo(filter);
          break;
        case "restored":
          financeQuery.where((finance) => finance.status).equalTo(filter);
          break;
        default:
          financeQuery.where((finance) => finance.status).notEqualTo("deleted");
          break;
      }
      if (limit != null && limit > 0) {
        financeQuery.fetchLimit = limit;
      }
      if (offset != null && offset > 0) {
        financeQuery.offset = offset;
      }
      final finances = await financeQuery.fetch();
      List notesJson = List.empty(growable: true);
      for (final finance in finances) {
        finance.removePropertiesFromBackingMap(
          [
            "user",
            "id",
          ],
        );
        notesJson.add(finance.backing.contents);
      }
      if (notesJson.isEmpty) {
        return AppResponse.ok(
          message: "Заметки не найдены",
        );
      }
      return AppResponse.ok(
        message: 'Успешное получение',
        body: notesJson,
      );
    } catch (e) {
      return AppResponse.serverError(
        e,
        message: 'Ошибка получения',
      );
    }
  }

  void createHistory(int userId, String message) async {
    final user = await managedContext.fetchObjectWithID<User>(userId);
    final createHistoryRowQuery = Query<History>(managedContext)
      ..values.datetime = DateTime.now().toString()
      ..values.user = user
      ..values.message = message;
    createHistoryRowQuery.insert();
  }
}
