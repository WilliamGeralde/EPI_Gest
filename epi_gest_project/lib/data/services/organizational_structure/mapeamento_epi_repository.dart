import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/core/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/services/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/mapeamento_epi_repository_contract.dart';

class MapeamentoEpiRepository extends BaseRepository<MapeamentoEpiModel>
    implements MapeamentoEpiRepositoryContract {
  MapeamentoEpiRepository(TablesDB databases)
    : super(databases, AppwriteConstants.databaseMapeamentoEpi);

  @override
  MapeamentoEpiModel fromMap(Map<String, dynamic> map) {
    return MapeamentoEpiModel.fromMap(map);
  }

  @override
  Future<List<MapeamentoEpiModel>> getAllMapeamentos() async {
    try {
      return await getAll([
        Query.select([
          '*',
          'cargo_id.*',
          'setor_id.*',
          'riscos_ids.*',
          'epi_ids.*',
        ]),
        Query.orderDesc('\$createdAt'),
      ]);
    } catch (e) {
      throw Exception('Erro ao buscar mapeamentos: $e');
    }
  }

  Future<void> inativarMapeamento(String rowId) async {
    try {
      await update(rowId, {'status': false});
    } catch (e) {
      throw Exception('Falha ao inativar mapeamento: $e');
    }
  }

  Future<void> ativarMapeamento(String rowId) async {
    try {
      await update(rowId, {'status': true});
    } catch (e) {
      throw Exception('Falha ao ativar mapeamento: $e');
    }
  }
}
