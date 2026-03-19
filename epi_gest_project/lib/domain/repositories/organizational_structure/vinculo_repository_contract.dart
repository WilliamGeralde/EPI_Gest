import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';

abstract class VinculoRepositoryContract {
  Future<List<VinculoModel>> getAllVinculos();

  Future<VinculoModel> createVinculo(VinculoModel vinculo);

  Future<VinculoModel> updateVinculo(VinculoModel vinculo);

  Future<void> updateVinculoStatus(String rowId, bool status);
}
