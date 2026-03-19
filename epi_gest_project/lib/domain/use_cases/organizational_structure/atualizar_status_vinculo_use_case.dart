import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class AtualizarStatusVinculoUseCase {
  final VinculoRepositoryContract _repository;

  AtualizarStatusVinculoUseCase(this._repository);

  Future<void> call(String vinculoId, bool status) {
    return _repository.updateVinculoStatus(vinculoId, status);
  }
}
