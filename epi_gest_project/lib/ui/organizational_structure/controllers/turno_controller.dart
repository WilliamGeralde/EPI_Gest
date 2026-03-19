import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/atualizar_status_turno_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/carregar_turnos_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/salvar_turno_use_case.dart';

class TurnoController {
  final CarregarTurnosUseCase _carregarTurnosUseCase;
  final SalvarTurnoUseCase _salvarTurnoUseCase;
  final AtualizarStatusTurnoUseCase _atualizarStatusTurnoUseCase;

  TurnoController({
    required CarregarTurnosUseCase carregarTurnosUseCase,
    required SalvarTurnoUseCase salvarTurnoUseCase,
    required AtualizarStatusTurnoUseCase atualizarStatusTurnoUseCase,
  }) : _carregarTurnosUseCase = carregarTurnosUseCase,
       _salvarTurnoUseCase = salvarTurnoUseCase,
       _atualizarStatusTurnoUseCase = atualizarStatusTurnoUseCase;

  Future<List<TurnoModel>> carregarTurnos() {
    return _carregarTurnosUseCase();
  }

  Future<TurnoModel> salvarTurno({
    required TurnoModel turno,
    required bool isEditing,
  }) {
    return _salvarTurnoUseCase(turno: turno, isEditing: isEditing);
  }

  Future<void> atualizarStatusTurno(String turnoId, bool status) {
    return _atualizarStatusTurnoUseCase(turnoId, status);
  }
}
