import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class CarregarVinculosUseCase {
  final VinculoRepositoryContract _repository;

  CarregarVinculosUseCase(this._repository);

  Future<List<VinculoModel>> call() {
    return _repository.getAllVinculos();
  }
}
