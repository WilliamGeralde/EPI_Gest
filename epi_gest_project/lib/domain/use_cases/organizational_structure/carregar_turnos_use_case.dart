import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class CarregarTurnosUseCase {
  final TurnoRepositoryContract _repository;

  CarregarTurnosUseCase(this._repository);

  Future<List<TurnoModel>> call() {
    return _repository.getAllTurnos();
  }
}
