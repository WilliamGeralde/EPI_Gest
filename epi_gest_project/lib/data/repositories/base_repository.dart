import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/domain/models/appwrite_model.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';

abstract class BaseRepository<T extends AppWriteModel> {
  final TablesDB databases;
  final String tableId;

  BaseRepository(this.databases, this.tableId);

  T fromMap(Map<String, dynamic> map);

  Future<List<T>> getAll(List<String> queries) async {
    try {
      final result = await databases.listRows(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        queries: queries
      );
      return result.rows.map((row) => fromMap(row.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception('Erro ao buscar dados: $e');
    }
  }

  Future<T> get(String id, List<String> queries) async {
    try {
      final result = await databases.getRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: id,
        queries: queries
      );
      return fromMap(result.data);
    } on AppwriteException catch (e) {
      throw Exception('Erro ao buscar documento: $e');
    }
  }

  Future<T> create(T item) async {
    try {
      final data = item.toMap();
      final result = await databases.createRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: ID.unique(),
        data: data,
      );
      return fromMap(result.data);
    } on AppwriteException catch (e) {
      throw Exception('Erro ao criar documento: $e');
    }
  }

  Future<T> update(String id, Map<String, dynamic> item) async {
    try {
      final result = await databases.updateRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: id,
        data: item,
      );
      return fromMap(result.data);
    } on AppwriteException catch (e) {
      throw Exception('Erro ao atualizar documento: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await databases.deleteRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: id,
      );
    } on AppwriteException catch (e) {
      throw Exception('Erro ao deletar documento: $e');
    }
  }
}
