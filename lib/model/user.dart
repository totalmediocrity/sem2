import 'package:sem2/model/history.dart';
import 'package:conduit/conduit.dart';
import 'package:sem2/model/finance.dart';

class User extends ManagedObject<_User> implements _User{}
  class _User{
    @primaryKey
    int? id;
    @Column(unique: true, indexed: true)
    String? userName;
    @Column(unique: true, indexed: true)
    String? email;
    @Serialize(input: true, output: false)
    String?password;
    @Column(nullable: true)
    String? accessToken;
    @Column(nullable: true)
    String? refreshToken;


    ManagedSet<Finance>? financeList; 
    ManagedSet<History>? historyList;


    @Column(omitByDefault: true)
    String? salt;
    @Column(omitByDefault: true)
    String? hashPassword;
  }
