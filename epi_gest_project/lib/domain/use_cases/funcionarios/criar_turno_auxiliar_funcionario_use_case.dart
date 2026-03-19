import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class CriarTurnoAuxiliarFuncionarioUseCase {
  final TurnoRepositoryContract _repository;

  CriarTurnoAuxiliarFuncionarioUseCase(this._repository);

  Future<TurnoModel> call({
    required String nomeTurno,
    required String horaEntrada,
    required String horaSaida,
    required String inicioAlmoco,
    required String fimAlmoco,
  }) {
    final nomeNormalizado = nomeTurno.trim();
    if (nomeNormalizado.isEmpty) {
      throw Exception('Nome de turno obrigatorio.');
    }

    return _repository.createTurno(
      TurnoModel(
        turno: nomeNormalizado,
        horaEntrada: horaEntrada,
        horaSaida: horaSaida,
        inicioAlmoco: inicioAlmoco,
        fimAlomoco: fimAlmoco,
      ),
    );
  }
}
