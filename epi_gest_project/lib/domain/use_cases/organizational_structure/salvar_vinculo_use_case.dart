import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class SalvarVinculoUseCase {
  final VinculoRepositoryContract _repository;

  SalvarVinculoUseCase(this._repository);

  Future<VinculoModel> call({
    required VinculoModel vinculo,
    required bool isEditing,
  }) {
    if (isEditing) {
      return _repository.updateVinculo(vinculo);
    }

    return _repository.createVinculo(vinculo);
  }
}
