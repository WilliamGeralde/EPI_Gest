import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/core/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/services/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/unidade_repository_contract.dart';

class UnidadeRepository extends BaseRepository<UnidadeModel>
    implements UnidadeRepositoryContract {
  UnidadeRepository(TablesDB databases)
    : super(databases, AppwriteConstants.databaseLocalTrabalho);

  @override
  UnidadeModel fromMap(Map<String, dynamic> map) {
    return UnidadeModel.fromMap(map);
  }

  @override
  Future<List<UnidadeModel>> getAllUnidades() async {
    return await getAll([]);
  }

  @override
  Future<UnidadeModel> createUnidade(UnidadeModel unidade) {
    return create(unidade);
  }

  @override
  Future<UnidadeModel> updateUnidade(UnidadeModel unidade) {
    final id = unidade.id;
    if (id == null || id.isEmpty) {
      throw Exception('Unidade sem id para atualizacao.');
    }

    return update(id, unidade.toMap());
  }

  @override
  Future<void> updateUnidadeStatus(String rowId, bool status) async {
    await update(rowId, {'status': status});
  }

  Future<void> inativarUnidade(String rowId) async {
    try {
      await update(rowId, {'status': false});
    } catch (e) {
      throw Exception('Falha ao inativar unidade.');
    }
  }

  Future<void> ativarUnidade(String rowId) async {
    try {
      await update(rowId, {'status': true});
    } catch (e) {
      throw Exception('Falha ao reativar unidade.');
    }
  }
}
