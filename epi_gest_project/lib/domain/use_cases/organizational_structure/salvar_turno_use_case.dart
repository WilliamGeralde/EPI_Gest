import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class SalvarTurnoUseCase {
  final TurnoRepositoryContract _repository;

  SalvarTurnoUseCase(this._repository);

  Future<TurnoModel> call({
    required TurnoModel turno,
    required bool isEditing,
  }) {
    if (isEditing) {
      return _repository.updateTurno(turno);
    }

    return _repository.createTurno(turno);
  }
}
