import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class AtualizarStatusTurnoUseCase {
  final TurnoRepositoryContract _repository;

  AtualizarStatusTurnoUseCase(this._repository);

  Future<void> call(String turnoId, bool status) {
    return _repository.updateTurnoStatus(turnoId, status);
  }
}
