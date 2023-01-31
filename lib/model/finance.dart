import 'package:sem2/model/user.dart';
import 'package:conduit/conduit.dart';

class Finance extends ManagedObject<_Finance> implements _Finance {}

class _Finance {
  @primaryKey
  int? id;
  @Column(nullable: false)
  int? number;
  @Column(nullable: false)
  String? name;
  @Column(nullable: false)
  String? description;
  @Column(nullable: false)
  String? category;
  @Column(nullable: false)
  String? noteDateCreated;
  @Column(nullable: false)
  String? total;
  @Column(nullable: false)
  String? status;
  @Relate(#financeList, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}