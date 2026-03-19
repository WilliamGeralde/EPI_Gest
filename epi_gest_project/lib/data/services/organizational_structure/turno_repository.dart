import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/core/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/services/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class TurnoRepository extends BaseRepository<TurnoModel> implements TurnoRepositoryContract {
  TurnoRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseTurno);

  @override
  TurnoModel fromMap(Map<String, dynamic> map) {
    return TurnoModel.fromMap(map);
  }

  @override
  Future<List<TurnoModel>> getAllTurnos() async {
    return await getAll([]);
  }

  @override
  Future<TurnoModel> createTurno(TurnoModel turno) {
    return create(turno);
  }
}