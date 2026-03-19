import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/core/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/services/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class VinculoRepository extends BaseRepository<VinculoModel> implements VinculoRepositoryContract {
  VinculoRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseVinculo);

  @override
  VinculoModel fromMap(Map<String, dynamic> map) {
    return VinculoModel.fromMap(map);
  }

  @override
  Future<List<VinculoModel>> getAllVinculos() async {
    return await getAll([]);
  }

  @override
  Future<VinculoModel> createVinculo(VinculoModel vinculo) {
    return create(vinculo);
  }

  @override
  Future<VinculoModel> updateVinculo(VinculoModel vinculo) {
    final id = vinculo.id;
    if (id == null || id.isEmpty) {
      throw Exception('Vinculo sem id para atualizacao.');
    }

    return update(id, vinculo.toMap());
  }

  @override
  Future<void> updateVinculoStatus(String rowId, bool status) async {
    await update(rowId, {'status': status});
  }
}