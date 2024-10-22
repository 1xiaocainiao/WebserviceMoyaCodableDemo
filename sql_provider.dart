import 'dart:convert';

import 'package:ai_app/config.dart';
import 'package:ai_app/models/ailist/ai_list_model.dart';
import 'package:ai_app/models/base_model.dart';
import 'package:ai_app/models/genera_image_param_model.dart';
import 'package:ai_app/tools/database/table_names.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';

Map<String, Database> _privateDatabaseContainer = {};

class SQLProvider {
  Database? db;

  static Future<SQLProvider> init(String userId) async {
    SQLProvider instance = SQLProvider();
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, "$databasePath/$userId.db");

    var storedDB = _privateDatabaseContainer[path];
    if (storedDB != null) {
      instance.db = storedDB;
      return instance;
    } else {
      try {
        var database = await openDatabase(path, onOpen: (Database db) {
          Config.printl("db open");
        });
        Config.printl(database);
        instance.db = database;
        _privateDatabaseContainer[path] = database;
        await instance.checkTableIsValidAndCreate();
      } catch (e) {
        Config.printl(e.toString());
      }
      return instance;
    }
  }

  Future<List<String>> getTables() async {
    if (db == null) {
      return Future.value([]);
    }

    List tables = await db!
        .rawQuery("select name from sqlite_master where type = 'table'");
    List<String> targetList = [];

    tables.forEach((item) {
      targetList.add(item["name"]);
    });

    return targetList;
  }

  Future checkTableIsValidAndCreate() async {
    List<CacheTableNameBindConfig> tableConfigs =
        CacheTableNames.getTableBinds();

    List<String> tables = await getTables();

    for (var i = 0; i < tableConfigs.length; i++) {
      if (!tables.contains(tableConfigs[i].tableName)) {
        createTable(tableConfigs[i]);
      } else {
        continue;
      }
    }
  }

  Future<bool> createTable(CacheTableNameBindConfig config) async {
    String createSql = "CREATE TABLE IF NOT EXISTS ${config.tableName} (";
    config.bindModel.toJson().forEach((key, value) {
      if (key == config.primaryKey) {
        createSql += "$key TEXT PRIMARY KEY, ";
      } else if (key == config.uniqueKey) {
        createSql += "$key TEXT UNIQUE, ";
      } else {
        createSql += "$key TEXT, ";
      }
    });
    createSql = createSql.substring(0, createSql.length - 2);
    createSql += ");";
    Config.printl(createSql);
    await db!.execute(createSql);
    return true;
  }

  Future<bool> insert(
      {required String tableName, required List<BaseModel> infos}) async {
    try {
      if (infos.length == 0) {
        return false;
      }

      BaseModel firstInfo = infos.first;

      var userDic = firstInfo.toJson();
      List<String> keysArray = [];
      List<String> questionMarkArray = [];
      List<String> valuesPlaceholaderArray = [];
      userDic.forEach((key, value) {
        keysArray.add(key);
        questionMarkArray.add("?");
      });
      String keysString = keysArray.join(", ");
      String keysSQL = "($keysString)";

      List<dynamic> valuesArray = [];

      for (var tempInfo in infos) {
        var tempInfoDic = tempInfo.toJson();
        for (var key in keysArray) {
          var tempValue = tempInfoDic[key];
          if (tempValue != null) {
            if (tempValue is String) {
              valuesArray.add(tempValue);
            } else {
              valuesArray.add(jsonEncode(tempValue));
            }
          } else {
            valuesArray.add("");
          }
        }
        valuesPlaceholaderArray.add("(${questionMarkArray.join(", ")})");
      }

      String valueSQL = valuesPlaceholaderArray.join(", ");

      String insertSQL =
          "INSERT OR REPLACE INTO $tableName $keysSQL VALUES $valueSQL;";

      Config.printl("insert sql -- $insertSQL");

      await this.db!.rawInsert(insertSQL, valuesArray);
      return true;
    } catch (e) {
      Config.printl(e.toString());
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> select(
      {required String tableName,
      required Map<String, dynamic> conditions,
      String? extendSql}) async {
    try {
      if (conditions.length > 0) {
        List<String> conditionsArray = [];
        conditions.forEach((key, value) {
          if (value is List<String>) {
            conditionsArray.add("$key in ('${value.join(", ")}')");
          } else {
            conditionsArray.add("$key = '$value'");
          }
        });

        String selectSQL = "";

        if (extendSql != null) {
          selectSQL =
              "SELECT * FROM $tableName WHERE ${conditionsArray.join(" and ")} ${extendSql};";
        } else {
          selectSQL =
              "SELECT * FROM $tableName WHERE ${conditionsArray.join(" and ")};";
        }

        Config.printl("selectd sql -- $selectSQL");
        var selectRelusts = await this.db!.rawQuery(selectSQL);
        selectRelusts = await processSelectedResult(selectRelusts);
        return selectRelusts;
      } else {
        String selectSQL = "";

        if (extendSql != null) {
          selectSQL = "SELECT * FROM $tableName ${extendSql};";
        } else {
          selectSQL = "SELECT * FROM $tableName;";
        }
        Config.printl("selectd sql -- $selectSQL");
        var selectRelusts = await this.db!.rawQuery(selectSQL);
        selectRelusts = await processSelectedResult(selectRelusts);
        return selectRelusts;
      }
    } catch (e) {
      Config.printl(e.toString());
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> processSelectedResult(
      List<Map<String, dynamic>> data) async {
    var result = List<Map<String, dynamic>>.from(data);
    for (var i = 0; i < result.length; i++) {
      var tempItem = Map<String, dynamic>.from(result[i]);
      for (var key in tempItem.keys) {
        var tempValue = tempItem[key];
        if (tempValue is String && tempValue.length > 0) {
          var firstChar = tempValue.substring(0, 1);
          if (firstChar == "[" || firstChar == "{") {
            var checkResult = await isJsonString(tempValue);
            if (checkResult.item1 == true) {
              tempItem[key] = checkResult.item2;
            } else {
              continue;
              // 不是json字符串，不做处理
            }
          } else {
            continue;
            // 不是json字符串，不做处理
          }
        } else {
          continue;
          // 不是字符串，不做处理
        }
      }
      result[i] = tempItem;
    }
    return result;
  }

  /// 暴力判断字符串是否是json
  Future<Tuple2<bool, dynamic>> isJsonString(String stringToCheck) async {
    try {
      var result = jsonDecode(stringToCheck);
      return Tuple2(true, result);
    } catch (e) {
      return Tuple2(false, null);
    }
  }

  Future<bool> delete(
      {required String tableName,
      required Map<String, dynamic> conditions}) async {
    try {
      String deleteSQL;
      if (conditions.length == 0) {
        deleteSQL = "DELETE FROM $tableName;";
      } else {
        List<String> conditionsArray = [];
        conditions.forEach((key, value) {
          if (value is List<String>) {
            conditionsArray.add("$key in ('${value.join(", ")}')");
          } else {
            conditionsArray.add("$key = '$value'");
          }
        });
        deleteSQL =
            "DELETE FROM $tableName WHERE ${conditionsArray.join(" and ")};";
      }

      Config.printl("delete sql -- $deleteSQL");

      this.db!.rawDelete(deleteSQL);
      return true;
    } catch (e) {
      Config.printl(e.toString());
      return false;
    }
  }

  /// 首页 ai list
  Future<bool> insertAIList(List<AIListItem> list) async {
    await delete(tableName: CacheTableNames.aiListTableName, conditions: {});
    return await insert(
        tableName: CacheTableNames.aiListTableName, infos: list);
  }

  Future<List<AIListItem>> selectAIList() async {
    var selects = await select(
        tableName: CacheTableNames.aiListTableName, conditions: {});
    if (selects.length > 0) {
      return selects.map((e) => AIListItem.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<AIListItem?> selectAIInfo(String ai_id) async {
    var selects = await select(
        tableName: CacheTableNames.aiListTableName,
        conditions: {"ai_id": ai_id});
    if (selects.length > 0) {
      return selects.map((e) => AIListItem.fromJson(e)).toList().last;
    } else {
      return null;
    }
  }

  /// 平台图片生成参数
  Future<bool> insertGeneraImageParamList(
      List<GeneraImageParamModel> list) async {
    await delete(
        tableName: CacheTableNames.generaImageParamTableName, conditions: {});
    return await insert(
        tableName: CacheTableNames.generaImageParamTableName, infos: list);
  }

  Future<List<GeneraImageParamModel>> selectGeneraImageParamList() async {
    var selects = await select(
        tableName: CacheTableNames.generaImageParamTableName, conditions: {});
    if (selects.length > 0) {
      return selects.map((e) => GeneraImageParamModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }
}
