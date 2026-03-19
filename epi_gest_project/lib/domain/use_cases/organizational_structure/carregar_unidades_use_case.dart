import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/unidade_repository_contract.dart';

class CarregarUnidadesUseCase {
  final UnidadeRepositoryContract _repository;

  CarregarUnidadesUseCase(this._repository);

  Future<List<UnidadeModel>> call() {
    return _repository.getAllUnidades();
  }
}
