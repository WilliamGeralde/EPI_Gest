import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';

abstract class TurnoRepositoryContract {
  Future<List<TurnoModel>> getAllTurnos();

  Future<TurnoModel> createTurno(TurnoModel turno);
}
