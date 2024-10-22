import 'package:ai_app/models/ailist/ai_list_model.dart';
import 'package:ai_app/models/base_model.dart';
import 'package:ai_app/models/genera_image_param_model.dart';

class CacheTableNames {
  static const int dbVersion = 100;

  static const String aiListTableName = "aiListTableName";

  static const String generaImageParamTableName = "generaImageParamTableName";

  static List<CacheTableNameBindConfig> getTableBinds() {
    return [
      CacheTableNameBindConfig(
          tableName: CacheTableNames.aiListTableName,
          bindModel: AIListItem.empty(),
          uniqueKey: "ai_id"),
      CacheTableNameBindConfig(
          tableName: CacheTableNames.generaImageParamTableName,
          bindModel: GeneraImageParamModel.empty(),
          uniqueKey: "param_id"),
    ];
  }
}

class CacheTableNameBindConfig {
  String tableName;
  String primaryKey;
  String uniqueKey;
  BaseModel bindModel;

  CacheTableNameBindConfig(
      {required this.tableName,
      required this.bindModel,
      this.uniqueKey = "",
      this.primaryKey = ""});
}
